#Requires -Version 5.1
# Change OpenCode's reasoning URL and token in an existing config on Windows.
#
#   powershell -ExecutionPolicy Bypass -File coding\install\opencode-config-windows.ps1
#
# The full installer must have added providers.reasoning first. This script
# asks for the URL and token, updates those two settings, backs up the
# config, and changes nothing else. It starts no backend.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "no OpenCode config at $ConfigPath; run coding\install\opencode-windows.ps1 first"
}

$d = Get-Content -Raw -Encoding UTF8 -LiteralPath $ConfigPath | ConvertFrom-Json
if ($null -eq $d.PSObject.Properties['providers'] -or
    $null -eq $d.providers.PSObject.Properties['reasoning']) {
    throw "no providers.reasoning in $ConfigPath; run coding\install\opencode-windows.ps1 first"
}
$settings = $d.providers.reasoning.PSObject.Properties['settings']
if ($null -eq $settings) {
    $d.providers.reasoning | Add-Member -MemberType NoteProperty -Name settings -Value ([pscustomobject]@{})
}
$defaultUrl = $d.providers.reasoning.settings.baseURL
if (-not $defaultUrl) { $defaultUrl = 'http://127.0.0.1:8787/v1' }

$URL = if ($env:REASONING_BASE_URL) {
    $env:REASONING_BASE_URL
} elseif ($env:CODING_ENDPOINT_BASE_URL) {
    $env:CODING_ENDPOINT_BASE_URL
} else {
    $null
}
if (-not $URL) {
    $entered = Read-Host "Reasoning backend URL [$defaultUrl]"
    $URL = if ([string]::IsNullOrWhiteSpace($entered)) { $defaultUrl } else { $entered }
}
$URL = $URL.TrimEnd('/')

$Token = $env:CODING_ENDPOINT_TOKEN
if (-not $Token) {
    try {
        $secure = Read-Host -AsSecureString 'Bearer token (blank keeps the existing token)'
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

Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
$d.providers.reasoning.settings | Add-Member -MemberType NoteProperty -Name baseURL -Value $URL -Force
if ($Token) {
    $d.providers.reasoning.settings | Add-Member -MemberType NoteProperty -Name apiKey -Value $Token -Force
}
$json = $d | ConvertTo-Json -Depth 100
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($ConfigPath, $json + "`r`n", $utf8)

Write-Host "OpenCode reasoning settings updated in $ConfigPath"
Write-Host "  base URL: $URL"
if (-not $Token) { Write-Host "  bearer token: unchanged" }
