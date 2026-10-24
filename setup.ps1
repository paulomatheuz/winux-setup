<#
.SYNOPSIS
Aplica os componentes disponiveis do winux-setup.
.EXAMPLE
.\setup.ps1 -Check
.EXAMPLE
.\setup.ps1 -Components Fastfetch -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Fastfetch', 'PowerShell', 'WindowsTerminal', 'Starship', 'Komorebi', 'Yasb', 'Whkd', 'Btop', 'VisualAssets')]
    [string[]]$Components = @('Fastfetch', 'PowerShell'),

    [switch]$Check,

    [ValidateNotNullOrEmpty()]
    [string]$DeviceConfig,

    [switch]$SkipProfile,

    [ValidateNotNullOrEmpty()]
    [string]$TerminalSettingsPath,

    [ValidateNotNullOrEmpty()]
    [string]$BtopDirectory,

    [switch]$InstallPrograms,

    [switch]$InstallRain,

    [switch]$EnableStartup,

    [ValidateNotNullOrEmpty()]
    [string[]]$Programs,

    [switch]$AcceptAgreements,

    [switch]$InstallModules,

    [ValidateNotNullOrEmpty()]
    [ValidateSet('z', 'PSReadLine')]
    [string[]]$Modules
)

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'Este setup requer Windows.'
}

if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Use Windows PowerShell 5.1 ou PowerShell 7.'
}

$configurationDirectories = @{}
if ($DeviceConfig) {
    . (Join-Path $PSScriptRoot 'scripts\device.ps1')
    $device = Read-WinuxDeviceConfiguration -Path $DeviceConfig
    if ($device.ContainsKey('Components') -and -not $PSBoundParameters.ContainsKey('Components')) { $Components = $device.Components }
    if ($Components -contains 'WindowsTerminal' -and $device.ContainsKey('TerminalSettingsPath') -and -not $PSBoundParameters.ContainsKey('TerminalSettingsPath')) { $TerminalSettingsPath = $device.TerminalSettingsPath }
    if ($Components -contains 'Btop' -and $device.ContainsKey('BtopDirectory') -and -not $PSBoundParameters.ContainsKey('BtopDirectory')) { $BtopDirectory = $device.BtopDirectory }
    $configurationDirectories = $device.ConfigDirectories
    Write-Host ('Dispositivo: ' + [IO.Path]::GetFullPath($DeviceConfig))
}
$sourceDirectories = @{}
foreach ($name in @('Komorebi','Yasb','Whkd','Btop')) {
    $sourceDirectories[$name] = Join-Path $PSScriptRoot ('config\' + $name.ToLowerInvariant())
    if ($configurationDirectories.ContainsKey($name)) { $sourceDirectories[$name] = $configurationDirectories[$name] }
}
if (-not $InstallPrograms -and $PSBoundParameters.ContainsKey('Programs')) {
    throw 'Use -InstallPrograms junto com -Programs.'
}
if (-not $InstallModules -and $PSBoundParameters.ContainsKey('Modules')) {
    throw 'Use -InstallModules junto com -Modules.'
}
if ($AcceptAgreements -and -not ($InstallPrograms -or $InstallModules)) {
    throw 'Use -InstallPrograms ou -InstallModules junto com -AcceptAgreements.'
}

# O perfil usa a configuracao e a logo do Fastfetch.
$selectedComponents = @()
if ($Components -contains 'Fastfetch' -or $Components -contains 'PowerShell') {
    $selectedComponents += 'Fastfetch'
}
if ($Components -contains 'PowerShell') {
    $selectedComponents += 'PowerShell'
}
if ($Components -contains 'WindowsTerminal') { $selectedComponents += 'WindowsTerminal' }
if ($Components -contains 'Starship') { $selectedComponents += 'Starship' }
if ($Components -contains 'Komorebi') { $selectedComponents += 'Komorebi' }
if ($Components -contains 'Yasb') { $selectedComponents += 'Yasb' }
if ($Components -contains 'Whkd') { $selectedComponents += 'Whkd' }
if ($Components -contains 'Btop') { $selectedComponents += 'Btop' }
if ($Components -contains 'VisualAssets') { $selectedComponents += 'VisualAssets' }
if ($BtopDirectory -and $selectedComponents -notcontains 'Btop') {
    throw 'Use -Components Btop junto com -BtopDirectory.'
}
if ($TerminalSettingsPath -and $selectedComponents -notcontains 'WindowsTerminal') {
    throw 'Use -Components WindowsTerminal junto com -TerminalSettingsPath.'
}

$installer = Join-Path $PSScriptRoot 'scripts\install.ps1'
$requiredFiles = @(
    $installer
    (Join-Path $PSScriptRoot 'scripts\configuration.ps1')
)
if ($selectedComponents -contains 'Fastfetch') {
    $requiredFiles += Join-Path $PSScriptRoot 'config\fastfetch\config-purple.jsonc'
    $requiredFiles += Join-Path $PSScriptRoot 'config\fastfetch\Spider2-ascii.txt'
}
if ($selectedComponents -contains 'WindowsTerminal') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\windows-terminal.ps1'
    $requiredFiles += Join-Path $PSScriptRoot 'config\windows-terminal\settings.json.example'
}
if ($selectedComponents -contains 'PowerShell') {
    $requiredFiles += Join-Path $PSScriptRoot 'config\powershell\profile.ps1'
}
if ($selectedComponents -contains 'Starship') {
    $requiredFiles += Join-Path $PSScriptRoot 'config\starship\starship.toml'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\starship.ps1'
}

if ($InstallPrograms) {
    $requiredFiles += Join-Path $PSScriptRoot 'packages.psd1'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\install-programs.ps1'
    if (-not $Programs -or $Programs -contains 'JetBrainsMonoNerdFont') {
        $requiredFiles += Join-Path $PSScriptRoot 'fonts.psd1'
        $requiredFiles += Join-Path $PSScriptRoot 'scripts\fonts.ps1'
    }
}
if ($selectedComponents -contains 'Komorebi') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\komorebi.ps1'
    foreach ($name in @('komorebi.json', 'komorebi.bar.json', 'applications.json', 'applications.LICENSE')) {
        $requiredFiles += Join-Path $sourceDirectories.Komorebi $name
    }
}

if ($InstallModules) {
    $requiredFiles += Join-Path $PSScriptRoot 'modules.psd1'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\install-modules.ps1'
}
if ($selectedComponents -contains 'Yasb') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\yasb.ps1'
    $requiredFiles += Join-Path $sourceDirectories.Yasb 'config.yaml'
    $requiredFiles += Join-Path $sourceDirectories.Yasb 'styles.css'
    $requiredFiles += Join-Path $sourceDirectories.Yasb 'YASB.LICENSE'
}

if ($selectedComponents -contains 'Whkd') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\whkd.ps1'
    $requiredFiles += Join-Path $sourceDirectories.Whkd 'whkdrc'
}
if ($selectedComponents -contains 'Btop') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\btop.ps1'
    $requiredFiles += Join-Path $sourceDirectories.Btop 'btop.conf'
    $requiredFiles += Join-Path $sourceDirectories.Btop 'themes\NeutralPurple.theme'
    $requiredFiles += Join-Path $sourceDirectories.Btop 'BTOP.LICENSE'
}
if ($InstallRain) {
    $requiredFiles += Join-Path $PSScriptRoot 'portable-programs.psd1'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\install-rain.ps1'
}
if ($selectedComponents -contains 'VisualAssets') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\visual-assets.ps1'
    $requiredFiles += Join-Path $PSScriptRoot 'assets\manifest.json'
}
if ($EnableStartup) {
    foreach ($name in @('startup.ps1', 'configure-startup.ps1', 'start-desktop.ps1')) { $requiredFiles += Join-Path $PSScriptRoot ('scripts\' + $name) }
}
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingFiles.Count -gt 0) {
    throw ('Arquivos do projeto nao encontrados: ' + ($missingFiles -join ', '))
}

if ($selectedComponents -contains 'VisualAssets') {
    . (Join-Path $PSScriptRoot 'scripts\configuration.ps1')
    . (Join-Path $PSScriptRoot 'scripts\visual-assets.ps1')
    Get-WinuxVisualAssetFiles -SourceDirectory (Join-Path $PSScriptRoot 'assets') | Out-Null
}
if ($selectedComponents -contains 'WindowsTerminal') {
    . (Join-Path $PSScriptRoot 'scripts\configuration.ps1')
    . (Join-Path $PSScriptRoot 'scripts\windows-terminal.ps1')
    $terminalDestination = Resolve-WinuxTerminalSettingsPath -Path $TerminalSettingsPath
    $terminalArguments = @{ SourcePath = (Join-Path $PSScriptRoot 'config\windows-terminal\settings.json.example'); Destination = $terminalDestination }
    if ($selectedComponents -contains 'VisualAssets') { $terminalArguments.IconPath = Get-WinuxTerminalIconPath }
    New-WinuxTerminalConfiguration @terminalArguments | Out-Null
    Write-Host ('Windows Terminal: ' + $terminalDestination)
}
if ($selectedComponents -contains 'Starship') {
    . (Join-Path $PSScriptRoot 'scripts\starship.ps1')
    $starshipDestination = Resolve-WinuxStarshipConfigPath
    if ((Test-Path -LiteralPath $starshipDestination) -and -not (Test-Path -LiteralPath $starshipDestination -PathType Leaf)) {
        throw "O destino do Starship deve ser um arquivo: $starshipDestination"
    }
    Write-Host ('Starship: ' + $starshipDestination)
}
if ($selectedComponents -contains 'Komorebi') {
    . (Join-Path $PSScriptRoot 'scripts\komorebi.ps1')
    Get-WinuxKomorebiFiles -SourceDirectory $sourceDirectories.Komorebi | Out-Null
    Write-Host ('Komorebi: ' + (Resolve-WinuxKomorebiDirectory))
}
if ($selectedComponents -contains 'Yasb') {
    . (Join-Path $PSScriptRoot 'scripts\yasb.ps1')
    Get-WinuxYasbFiles -SourceDirectory $sourceDirectories.Yasb | Out-Null
    Write-Host ('YASB: ' + (Resolve-WinuxYasbDirectory))
}
if ($selectedComponents -contains 'Whkd') {
    . (Join-Path $PSScriptRoot 'scripts\whkd.ps1')
    Get-WinuxWhkdFiles -SourceDirectory $sourceDirectories.Whkd | Out-Null
    Write-Host ('whkd: ' + (Join-Path (Resolve-WinuxWhkdDirectory) 'whkdrc'))
}
if ($selectedComponents -contains 'Btop') {
    . (Join-Path $PSScriptRoot 'scripts\btop.ps1')
    $btopDestination = Resolve-WinuxBtopDirectory -Path $BtopDirectory
    Get-WinuxBtopFiles -SourceDirectory $sourceDirectories.Btop -DestinationDirectory $btopDestination | Out-Null
    Write-Host ('btop: ' + $btopDestination)
}
if ($EnableStartup) {
    $expectedPrograms = @()
    if ($InstallPrograms) {
        $expectedPrograms = @('Komorebi', 'Whkd', 'Yasb')
        if ($Programs) { $expectedPrograms = @($expectedPrograms | Where-Object { $Programs -contains $_ }) }
    }
    $expectedComponents = @($selectedComponents | Where-Object { $_ -in @('Komorebi', 'Whkd', 'Yasb') })
    & (Join-Path $PSScriptRoot 'scripts\configure-startup.ps1') -Check -ExpectedPrograms $expectedPrograms -ExpectedComponents $expectedComponents
}
$hasFastfetch = [bool](Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue)
if ($selectedComponents -contains 'Fastfetch' -and -not $hasFastfetch -and (-not $InstallPrograms -or ($Programs -and $Programs -notcontains 'Fastfetch'))) {
    throw 'Fastfetch nao foi encontrado no PATH. Instale-o ou use -InstallPrograms com Fastfetch selecionado.'
}

if ($InstallPrograms) {
    $programArguments = @{
        Check = $Check
        AcceptAgreements = $AcceptAgreements
        WhatIf = $WhatIfPreference
    }
    if ($Programs) {
        $programArguments.Programs = $Programs
    }
    & (Join-Path $PSScriptRoot 'scripts\install-programs.ps1') @programArguments
}

if ($InstallModules) {
    $moduleArguments = @{
        Check = $Check
        AcceptAgreements = $AcceptAgreements
        WhatIf = $WhatIfPreference
    }
    if ($Modules) { $moduleArguments.Modules = $Modules }
    & (Join-Path $PSScriptRoot 'scripts\install-modules.ps1') @moduleArguments
}

if ($selectedComponents -contains 'Fastfetch' -and -not $Check -and -not $WhatIfPreference -and -not (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'Fastfetch ainda nao esta disponivel no PATH. Abra uma nova sessao e execute o setup novamente. As configuracoes nao foram aplicadas.'
}

if ($InstallRain) {
    & (Join-Path $PSScriptRoot 'scripts\install-rain.ps1') -Check:$Check -WhatIf:$WhatIfPreference
}
Write-Host ('Componentes: ' + ($selectedComponents -join ', '))

if ($Check) {
    Write-Host 'Pre-requisitos verificados. Nenhum arquivo foi alterado.'
    return
}

$target = $selectedComponents -join ', '
if ($PSCmdlet.ShouldProcess($target, 'Aplicar os componentes selecionados')) {
    $arguments = @{ Components = $selectedComponents; SkipProfile = $SkipProfile; Confirm = $false }
    if ($configurationDirectories.Count -gt 0) { $arguments.ConfigurationDirectories = $configurationDirectories }
    if ($TerminalSettingsPath) { $arguments.TerminalSettingsPath = $TerminalSettingsPath }
    if ($BtopDirectory) { $arguments.BtopDirectory = $BtopDirectory }
    & $installer @arguments
    if ($EnableStartup) { & (Join-Path $PSScriptRoot 'scripts\configure-startup.ps1') -Confirm:$false }
}

