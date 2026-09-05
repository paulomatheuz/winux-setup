[CmdletBinding()]
param(
    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceFastfetch = Join-Path $repositoryRoot 'config\fastfetch'
$sourceProfile = Join-Path $repositoryRoot 'PowerShell\profile.ps1'
$fastfetchHome = Join-Path $HOME '.config\fastfetch'
$installedProfile = Join-Path $fastfetchHome 'custom-windows-terminal-profile.ps1'

New-Item -ItemType Directory -Force -Path $fastfetchHome | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceFastfetch 'config-purple.jsonc') -Destination $fastfetchHome -Force
Copy-Item -LiteralPath (Join-Path $sourceFastfetch 'Spider2-ascii.txt') -Destination $fastfetchHome -Force
Copy-Item -LiteralPath $sourceProfile -Destination $installedProfile -Force

if (-not $SkipProfile) {
    $startMarker = '# >>> custom-windows-terminal >>>'
    $endMarker = '# <<< custom-windows-terminal <<<'

    if (-not (Test-Path -LiteralPath $PROFILE)) {
        New-Item -ItemType File -Force -Path $PROFILE | Out-Null
    }

    $profileContent = Get-Content -Raw -LiteralPath $PROFILE

    if ($profileContent -notmatch [regex]::Escape($startMarker)) {
        Copy-Item -LiteralPath $PROFILE -Destination "$PROFILE.backup-before-custom-windows-terminal" -Force
        Add-Content -LiteralPath $PROFILE -Value @"

$startMarker
. "`$HOME\.config\fastfetch\custom-windows-terminal-profile.ps1"
$endMarker
"@
    }
}

foreach ($command in 'fastfetch', 'starship', 'lsd') {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Warning "$command nao foi encontrado. Ele e opcional, exceto fastfetch."
    }
}

Write-Host 'Instalacao concluida. Feche e abra o Windows Terminal.' -ForegroundColor Green