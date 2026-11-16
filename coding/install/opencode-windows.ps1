#Requires -Version 5.1
# Configure OpenCode's reasoning provider on Windows.
#
#   $env:REASONING_BASE_URL = "http://127.0.0.1:8787/v1"
#   $env:CODING_ENDPOINT_TOKEN = "..."
#   powershell -ExecutionPolicy Bypass -File coding\install\opencode-windows.ps1
#
# The backend must already be running at REASONING_BASE_URL (the default
# is the local endpoint). The provider is merged into
# %USERPROFILE%\.config\opencode\opencode.json (or %APPDATA%\opencode\
# opencode.json when that is the existing file, or OPENCODE_CONFIG).
# Other providers are kept and the old file is backed up.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CodingDir = Split-Path -Parent $ScriptDir
$SourceConfig = Join-Path $CodingDir 'endpoint\config\opencode.json'
if (-not (Test-Path -LiteralPath $SourceConfig)) {
    throw "missing provider template: $SourceConfig"
}

$BaseUrl = if ($env:REASONING_BASE_URL) {
    $env:REASONING_BASE_URL
} elseif ($env:CODING_ENDPOINT_BASE_URL) {
    $env:CODING_ENDPOINT_BASE_URL
} else {
    'http://127.0.0.1:8787/v1'
}
$BaseUrl = $BaseUrl.TrimEnd('/')
$Token = $env:CODING_ENDPOINT_TOKEN

if (-not $Token) {
    try {
        $secure = Read-Host -AsSecureString 'Reasoning bearer token (blank uses {env:CODING_ENDPOINT_TOKEN})'
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            if ($bstr -ne [IntPtr]::Zero) {
                $Token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            }
        } finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    } catch {
        $Token = $null
    }
}

$candidates = @(
    (Join-Path $env:USERPROFILE '.config\opencode\opencode.json'),
    (Join-Path $env:APPDATA 'opencode\opencode.json')
)
$ConfigPath = if ($env:OPENCODE_CONFIG) {
    $env:OPENCODE_CONFIG
} else {
    $existing = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($existing) { $existing } else { $candidates[0] }
}
$ConfigDir = Split-Path -Parent $ConfigPath
if (-not (Test-Path -LiteralPath $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}
if (Test-Path -LiteralPath $ConfigPath) {
    Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
}

$src = Get-Content -Raw -Encoding UTF8 -LiteralPath $SourceConfig | ConvertFrom-Json
if (Test-Path -LiteralPath $ConfigPath) {
    try {
        $dst = Get-Content -Raw -Encoding UTF8 -LiteralPath $ConfigPath | ConvertFrom-Json
    } catch {
        throw "$ConfigPath is not valid JSON: $($_.Exception.Message)"
    }
} else {
    $dst = [pscustomobject]@{}
}

if ($null -eq $dst.PSObject.Properties['providers']) {
    $dst | Add-Member -MemberType NoteProperty -Name providers -Value ([pscustomobject]@{})
}
if ($null -eq $src.PSObject.Properties['providers'] -or
    $null -eq $src.providers.PSObject.Properties['reasoning']) {
    throw "the provider template has no providers.reasoning entry"
}

$oldKey = $null
if ($null -ne $dst.providers.PSObject.Properties['reasoning']) {
    $old = $dst.providers.reasoning
    if ($null -ne $old.PSObject.Properties['settings']) {
        $oldSettings = $old.settings
        if ($null -ne $oldSettings.PSObject.Properties['apiKey']) {
            $oldKey = $oldSettings.apiKey
        }
    }
}

$reasoning = $src.providers.reasoning
if ($null -eq $reasoning.PSObject.Properties['settings']) {
    $reasoning | Add-Member -MemberType NoteProperty -Name settings -Value ([pscustomobject]@{})
}
$apiKey = if ($Token) {
    $Token
} elseif ($oldKey) {
    $oldKey
} else {
    '{env:CODING_ENDPOINT_TOKEN}'
}
$reasoning.settings | Add-Member -MemberType NoteProperty -Name baseURL -Value $BaseUrl -Force
$reasoning.settings | Add-Member -MemberType NoteProperty -Name apiKey -Value $apiKey -Force
$dst.providers | Add-Member -MemberType NoteProperty -Name reasoning -Value $reasoning -Force

if ($null -eq $dst.PSObject.Properties['$schema'] -and
    $null -ne $src.PSObject.Properties['$schema']) {
    $dst | Add-Member -MemberType NoteProperty -Name '$schema' -Value $src.PSObject.Properties['$schema'].Value
}

$json = $dst | ConvertTo-Json -Depth 100
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($ConfigPath, $json + "`r`n", $utf8)

$root = if ($BaseUrl.EndsWith('/v1')) {
    $BaseUrl.Substring(0, $BaseUrl.Length - 3)
} else {
    $BaseUrl.TrimEnd('/')
}
try {
    Invoke-RestMethod -Uri "$root/health" -TimeoutSec 5 | Out-Null
    Write-Host "backend: healthy at $root/health"
} catch {
    Write-Warning "no healthy backend at $root/health; the client config is written anyway"
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host "OpenCode is not on PATH; install it and rerun this script."
}

Write-Host "OpenCode reasoning provider configured at $ConfigPath"
Write-Host "  base URL: $BaseUrl"
if (-not $Token) {
    Write-Host "  apiKey: the existing one, or {env:CODING_ENDPOINT_TOKEN}; set it before running OpenCode"
}
Write-Host "Try: opencode -m reasoning/c-r0"
