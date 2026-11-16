#Requires -Version 5.1
# Change Codex's reasoning URL and token in an existing config on Windows.
#
#   powershell -ExecutionPolicy Bypass -File coding\install\codex-config-windows.ps1
#
# The full installer must have added [model_providers.reasoning] first.
# This script asks for the URL and token, updates those two settings, backs
# up config.toml, and changes nothing else. It starts no backend.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$CodexHome = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $env:USERPROFILE '.codex'
}
$ConfigPath = Join-Path $CodexHome 'config.toml'
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "no Codex config at $ConfigPath; run coding\install\codex-windows.ps1 first"
}

$lines = @(Get-Content -Encoding UTF8 -LiteralPath $ConfigPath)
$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '[model_providers.reasoning]') {
        $start = $i
        break
    }
}
if ($start -lt 0) {
    throw "no [model_providers.reasoning] in $ConfigPath; run coding\install\codex-windows.ps1 first"
}
$end = $lines.Count
for ($i = $start + 1; $i -lt $lines.Count; $i++) {
    $s = $lines[$i].Trim()
    if ($s -match '^\[.+\]$') {
        $end = $i
        break
    }
}

$defaultUrl = 'http://127.0.0.1:8787/v1'
for ($i = $start + 1; $i -lt $end; $i++) {
    if ($lines[$i].Trim() -match '^base_url\s*=\s*"(.*)"\s*$') {
        $defaultUrl = $matches[1]
        break
    }
}

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

function TomlString([string]$s) {
    return '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"'
}

$block = New-Object System.Collections.Generic.List[string]
$foundUrl = $false
$foundToken = $false
for ($i = $start + 1; $i -lt $end; $i++) {
    $line = $lines[$i]
    $s = $line.Trim()
    if ($s -match '^base_url\s*=') {
        $block.Add('base_url = ' + (TomlString $URL))
        $foundUrl = $true
    } elseif ($Token -and $s -match '^experimental_bearer_token\s*=') {
        $block.Add('experimental_bearer_token = ' + (TomlString $Token))
        $foundToken = $true
    } else {
        $block.Add($line)
    }
}
if (-not $foundUrl) {
    $block.Insert(0, 'base_url = ' + (TomlString $URL))
    $foundUrl = $true
}
if ($Token -and -not $foundToken) {
    $at = 0
    for ($i = 0; $i -lt $block.Count; $i++) {
        if ($block[$i].Trim() -match '^base_url\s*=') {
            $at = $i + 1
            break
        }
    }
    $block.Insert($at, 'experimental_bearer_token = ' + (TomlString $Token))
}

Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
$final = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $start; $i++) { $final.Add($lines[$i]) }
$final.Add($lines[$start])
foreach ($line in $block) { $final.Add($line) }
for ($i = $end; $i -lt $lines.Count; $i++) { $final.Add($lines[$i]) }
$text = ($final -join "`r`n").TrimEnd() + "`r`n"
[IO.File]::WriteAllText($ConfigPath, $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Codex reasoning settings updated in $ConfigPath"
Write-Host "  base URL: $URL"
if (-not $Token) { Write-Host "  bearer token: unchanged" }
Write-Host "Restart Codex: codex app-server daemon restart"
