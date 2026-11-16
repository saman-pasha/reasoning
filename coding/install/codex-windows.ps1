#Requires -Version 5.1
# Configure Codex's reasoning provider, model catalog and profile on Windows.
#
#   $env:REASONING_BASE_URL = "http://127.0.0.1:8787/v1"
#   $env:CODING_ENDPOINT_TOKEN = "..."
#   powershell -ExecutionPolicy Bypass -File coding\install\codex-windows.ps1
#
# The backend must already be running at REASONING_BASE_URL (the default
# is the local endpoint). The script backs up %USERPROFILE%\.codex\config.toml,
# merges the provider and defaults into it, and copies the model catalog
# and the reasoning profile beside it. Existing providers are kept.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CodingDir = Split-Path -Parent $ScriptDir
$CatalogSource = Join-Path $CodingDir 'endpoint\config\codex-model-catalog.json'
$ProfileSource = Join-Path $CodingDir 'endpoint\config\codex-reasoning.config.toml'
foreach ($path in @($CatalogSource, $ProfileSource)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "missing Codex file: $path"
    }
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
        $secure = Read-Host -AsSecureString 'Reasoning bearer token (blank keeps the existing token)'
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

$CodexHome = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $env:USERPROFILE '.codex'
}
$ConfigPath = Join-Path $CodexHome 'config.toml'
$CatalogPath = Join-Path $CodexHome 'model-catalog.json'
$ProfilePath = Join-Path $CodexHome 'reasoning.config.toml'
if (-not (Test-Path -LiteralPath $CodexHome)) {
    New-Item -ItemType Directory -Path $CodexHome -Force | Out-Null
}

foreach ($path in @($ConfigPath, $CatalogPath, $ProfilePath)) {
    if (Test-Path -LiteralPath $path) {
        Copy-Item -LiteralPath $path -Destination "$path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    }
}
Copy-Item -LiteralPath $CatalogSource -Destination $CatalogPath
Copy-Item -LiteralPath $ProfileSource -Destination $ProfilePath

$lines = @()
if (Test-Path -LiteralPath $ConfigPath) {
    $lines = Get-Content -Encoding UTF8 -LiteralPath $ConfigPath
}
$out = New-Object System.Collections.Generic.List[string]
$skip = $false
$inTable = $false
$oldToken = $null
foreach ($line in $lines) {
    $s = $line.Trim()
    if ($s -match '^\[(.+)\]$') {
        $name = $matches[1]
        if ($name -eq 'model_providers.reasoning' -or
            $name.StartsWith('model_providers.reasoning.')) {
            $skip = $true
            $inTable = $true
            continue
        }
        $skip = $false
        $inTable = $true
        $out.Add($line)
        continue
    }
    if ($skip) {
        if ($s -match '^experimental_bearer_token\s*=\s*"(.*)"\s*$') {
            $oldToken = $matches[1]
        }
        continue
    }
    if (-not $inTable -and $s -match '^model_catalog_json\s*=') {
        continue
    }
    $out.Add($line)
}

if (-not $Token -and $oldToken) {
    $Token = $oldToken
}

function TomlString([string]$s) {
    return '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"'
}

$catalogToml = $CatalogPath.Replace('\', '/')
$managed = @(
    ('model_catalog_json = ' + (TomlString $catalogToml))
)
$provider = @(
    '',
    '[model_providers.reasoning]',
    'name = "Reasoning Coding Art"',
    ('base_url = ' + (TomlString $BaseUrl))
)
if ($Token) {
    $provider += ('experimental_bearer_token = ' + (TomlString $Token))
}

$final = New-Object System.Collections.Generic.List[string]
foreach ($line in $managed) { $final.Add($line) }
$final.Add('')
foreach ($line in $out) { $final.Add($line) }
foreach ($line in $provider) { $final.Add($line) }
$text = ($final -join "`r`n").TrimEnd() + "`r`n"
[IO.File]::WriteAllText($ConfigPath, $text, (New-Object System.Text.UTF8Encoding($false)))

$root = if ($BaseUrl.EndsWith('/v1')) {
    $BaseUrl.Substring(0, $BaseUrl.Length - 3)
} else {
    $BaseUrl.TrimEnd('/')
}
try {
    Invoke-RestMethod -Uri "$root/health" -TimeoutSec 5 | Out-Null
    Write-Host "backend: healthy at $root/health"
} catch {
    Write-Warning "no healthy backend at $root/health; the Codex config is written anyway"
}

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Host "Codex is not on PATH; install Codex 0.163 or later and rerun this script."
}

Write-Host "Codex reasoning provider configured in $CodexHome"
Write-Host "  model catalog: $CatalogPath"
Write-Host "  profile: $ProfilePath"
Write-Host "  base URL: $BaseUrl"
if (-not $Token) {
    Write-Host "  no bearer token was written; set CODING_ENDPOINT_TOKEN and rerun if the endpoint requires one"
}
Write-Host "No default model or provider was changed; select it with: codex -p reasoning"
Write-Host "Restart Codex: codex app-server daemon restart"
Write-Host "Try: codex -p reasoning -m c-r0 `"Reply with OK.`""
