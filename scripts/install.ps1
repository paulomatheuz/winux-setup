[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Fastfetch', 'PowerShell')]
    [string[]]$Components = @('Fastfetch', 'PowerShell'),

    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceFastfetch = Join-Path $repositoryRoot 'config\fastfetch'
$sourceProfile = Join-Path $repositoryRoot 'config\powershell\profile.ps1'
$fastfetchHome = Join-Path $HOME '.config\fastfetch'
$installedProfile = Join-Path $fastfetchHome 'custom-windows-terminal-profile.ps1'

$configurationModule = Join-Path $PSScriptRoot 'configuration.ps1'
. $configurationModule
$backupRoot = Join-Path $HOME '.winux-setup\backups'

$includePowerShell = $Components -contains 'PowerShell'
$requiredFiles = @(
    (Join-Path $sourceFastfetch 'config-purple.jsonc')
    (Join-Path $sourceFastfetch 'Spider2-ascii.txt')
)
if ($includePowerShell) {
    $requiredFiles += $sourceProfile
}
foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Arquivo de configuracao nao encontrado: $file"
    }
}

$commands = @('fastfetch')
if ($includePowerShell) {
    $commands += 'starship', 'lsd'
}
foreach ($command in $commands) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Warning "$command nao foi encontrado. Ele e opcional, exceto fastfetch."
    }
}

$files = @(
    @{ SourcePath = (Join-Path $sourceFastfetch 'config-purple.jsonc'); Destination = (Join-Path $fastfetchHome 'config-purple.jsonc') }
    @{ SourcePath = (Join-Path $sourceFastfetch 'Spider2-ascii.txt'); Destination = (Join-Path $fastfetchHome 'Spider2-ascii.txt') }
)
if ($includePowerShell) {
    $files += @{ SourcePath = $sourceProfile; Destination = $installedProfile }
    if (-not $SkipProfile) {
        $files += @{ Destination = $PROFILE; Bytes = (Get-WinuxProfileBytes -Path $PROFILE) }
    }
}
$result = Invoke-WinuxConfiguration -Files $files -BackupRoot $backupRoot -WhatIf:$WhatIfPreference
if ($result.Status -eq 'Applied') {
    Write-Host ('Configuracao aplicada. Backup e registro: ' + $result.BackupPath) -ForegroundColor Green
    Write-Host 'Feche e abra o Windows Terminal.'
} elseif ($result.Status -eq 'Unchanged') {
    Write-Host 'As configuracoes selecionadas ja estao atualizadas.'
}
