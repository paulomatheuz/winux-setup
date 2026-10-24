[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Fastfetch', 'PowerShell', 'WindowsTerminal', 'Starship', 'Komorebi', 'Yasb', 'Whkd', 'Btop', 'VisualAssets')]
    [string[]]$Components = @('Fastfetch', 'PowerShell'),

    [switch]$SkipProfile,

    [ValidateNotNullOrEmpty()]
    [string]$TerminalSettingsPath,

    [ValidateNotNullOrEmpty()]
    [string]$BtopDirectory,

    [hashtable]$ConfigurationDirectories = @{}
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectories = @{}
foreach ($name in $ConfigurationDirectories.Keys) {
    if ($name -notin @('Komorebi','Yasb','Whkd','Btop')) { throw "Pasta de configuracao desconhecida: $name" }
    $path = $ConfigurationDirectories[$name]
    if ($path -isnot [string] -or -not [IO.Path]::IsPathRooted($path) -or [IO.Path]::GetPathRoot($path).Length -lt 3 -or -not (Test-Path -LiteralPath $path -PathType Container)) { throw "Pasta de configuracao absoluta nao encontrada: $path" }
}
foreach ($name in @('Komorebi','Yasb','Whkd','Btop')) {
    $sourceDirectories[$name] = Join-Path $repositoryRoot ('config\' + $name.ToLowerInvariant())
    if ($ConfigurationDirectories.ContainsKey($name)) { $sourceDirectories[$name] = $ConfigurationDirectories[$name] }
}
$sourceFastfetch = Join-Path $repositoryRoot 'config\fastfetch'
$sourceProfile = Join-Path $repositoryRoot 'config\powershell\profile.ps1'
$fastfetchHome = Join-Path $HOME '.config\fastfetch'
$installedProfile = Join-Path $fastfetchHome 'custom-windows-terminal-profile.ps1'

$configurationModule = Join-Path $PSScriptRoot 'configuration.ps1'
. $configurationModule
$backupRoot = Join-Path $HOME '.winux-setup\backups'

$includePowerShell = $Components -contains 'PowerShell'
$includeFastfetch = $Components -contains 'Fastfetch' -or $includePowerShell
if ($BtopDirectory -and $Components -notcontains 'Btop') { throw 'Use -Components Btop junto com -BtopDirectory.' }
if ($TerminalSettingsPath -and $Components -notcontains 'WindowsTerminal') {
    throw 'Use -Components WindowsTerminal junto com -TerminalSettingsPath.'
}
$requiredFiles = @()
if ($includeFastfetch) { $requiredFiles += @(
    (Join-Path $sourceFastfetch 'config-purple.jsonc')
    (Join-Path $sourceFastfetch 'Spider2-ascii.txt')
) }
if ($includePowerShell) {
    $requiredFiles += $sourceProfile
}
foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Arquivo de configuracao nao encontrado: $file"
    }
}

$commands = @()
if ($includeFastfetch) { $commands += 'fastfetch' }
if ($includePowerShell) {
    $commands += 'starship', 'lsd'
}
foreach ($command in $commands) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Warning "$command nao foi encontrado. Ele e opcional, exceto fastfetch."
    }
}

$files = @()
if ($Components -contains 'VisualAssets') {
    . (Join-Path $PSScriptRoot 'visual-assets.ps1')
    $files += @(Get-WinuxVisualAssetFiles -SourceDirectory (Join-Path $repositoryRoot 'assets'))
}
if ($includeFastfetch) { $files += @(
    @{ SourcePath = (Join-Path $sourceFastfetch 'config-purple.jsonc'); Destination = (Join-Path $fastfetchHome 'config-purple.jsonc') }
    @{ SourcePath = (Join-Path $sourceFastfetch 'Spider2-ascii.txt'); Destination = (Join-Path $fastfetchHome 'Spider2-ascii.txt') }
) }
if ($includePowerShell) {
    $files += @{ SourcePath = $sourceProfile; Destination = $installedProfile }
    if (-not $SkipProfile) {
        $files += @{ Destination = $PROFILE; Bytes = (Get-WinuxProfileBytes -Path $PROFILE) }
    }
}
if ($Components -contains 'WindowsTerminal') {
    . (Join-Path $PSScriptRoot 'windows-terminal.ps1')
    $destination = Resolve-WinuxTerminalSettingsPath -Path $TerminalSettingsPath
    $terminalArguments = @{ SourcePath = (Join-Path $repositoryRoot 'config\windows-terminal\settings.json.example'); Destination = $destination }
    if ($Components -contains 'VisualAssets') { $terminalArguments.IconPath = Get-WinuxTerminalIconPath }
    $files += New-WinuxTerminalConfiguration @terminalArguments
}
if ($Components -contains 'Starship') {
    . (Join-Path $PSScriptRoot 'starship.ps1')
    $files += @{
        SourcePath = Join-Path $repositoryRoot 'config\starship\starship.toml'
        Destination = Resolve-WinuxStarshipConfigPath
    }
}
if ($Components -contains 'Komorebi') {
    . (Join-Path $PSScriptRoot 'komorebi.ps1')
    $files += @(Get-WinuxKomorebiFiles -SourceDirectory $sourceDirectories.Komorebi)
}
if ($Components -contains 'Yasb') {
    . (Join-Path $PSScriptRoot 'yasb.ps1')
    $files += @(Get-WinuxYasbFiles -SourceDirectory $sourceDirectories.Yasb)
}
if ($Components -contains 'Whkd') {
    . (Join-Path $PSScriptRoot 'whkd.ps1')
    $files += Get-WinuxWhkdFiles -SourceDirectory $sourceDirectories.Whkd
}
if ($Components -contains 'Btop') {
    . (Join-Path $PSScriptRoot 'btop.ps1')
    $btopDestination = Resolve-WinuxBtopDirectory -Path $BtopDirectory
    $files += @(Get-WinuxBtopFiles -SourceDirectory $sourceDirectories.Btop -DestinationDirectory $btopDestination)
    Write-Host ('btop: ' + $btopDestination)
}
$result = Invoke-WinuxConfiguration -Files $files -BackupRoot $backupRoot -WhatIf:$WhatIfPreference
if ($result.Status -eq 'Applied') {
    Write-Host ('Configuracao aplicada. Backup e registro: ' + $result.BackupPath) -ForegroundColor Green
    Write-Host 'Feche e abra o Windows Terminal.'
    if ($Components -contains 'Komorebi') { Write-Host 'Recarregue a configuracao ou reinicie o Komorebi pelos seus controles habituais.' }
    if ($Components -contains 'Yasb') { Write-Host 'O YASB pode recarregar os arquivos automaticamente se estiver em execucao.' }
    if ($Components -contains 'Whkd') { Write-Host 'Reinicie o whkd pelos seus controles habituais para carregar os atalhos.' }
    if ($Components -contains 'Btop') { Write-Host 'Feche e abra o btop4win para carregar a configuracao.' }
} elseif ($result.Status -eq 'Unchanged') {
    Write-Host 'As configuracoes selecionadas ja estao atualizadas.'
}

