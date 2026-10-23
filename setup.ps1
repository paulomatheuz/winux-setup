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
    [ValidateSet('Fastfetch', 'PowerShell', 'WindowsTerminal', 'Starship', 'Komorebi', 'Yasb', 'Whkd', 'Btop')]
    [string[]]$Components = @('Fastfetch', 'PowerShell'),

    [switch]$Check,

    [switch]$SkipProfile,

    [ValidateNotNullOrEmpty()]
    [string]$TerminalSettingsPath,

    [ValidateNotNullOrEmpty()]
    [string]$BtopDirectory,

    [switch]$InstallPrograms,

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
}
if ($selectedComponents -contains 'Komorebi') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\komorebi.ps1'
    foreach ($name in @('komorebi.json', 'komorebi.bar.json', 'applications.json', 'applications.LICENSE')) {
        $requiredFiles += Join-Path $PSScriptRoot ('config\komorebi\' + $name)
    }
}

if ($InstallModules) {
    $requiredFiles += Join-Path $PSScriptRoot 'modules.psd1'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\install-modules.ps1'
}
if ($selectedComponents -contains 'Yasb') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\yasb.ps1'
    $requiredFiles += Join-Path $PSScriptRoot 'config\yasb\config.yaml'
    $requiredFiles += Join-Path $PSScriptRoot 'config\yasb\styles.css'
    $requiredFiles += Join-Path $PSScriptRoot 'config\yasb\YASB.LICENSE'
}

if ($selectedComponents -contains 'Whkd') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\whkd.ps1'
    $requiredFiles += Join-Path $PSScriptRoot 'config\whkd\whkdrc'
}
if ($selectedComponents -contains 'Btop') {
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\btop.ps1'
    $requiredFiles += Join-Path $PSScriptRoot 'config\btop\btop.conf'
    $requiredFiles += Join-Path $PSScriptRoot 'config\btop\themes\NeutralPurple.theme'
    $requiredFiles += Join-Path $PSScriptRoot 'config\btop\BTOP.LICENSE'
}
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingFiles.Count -gt 0) {
    throw ('Arquivos do projeto nao encontrados: ' + ($missingFiles -join ', '))
}

if ($selectedComponents -contains 'WindowsTerminal') {
    . (Join-Path $PSScriptRoot 'scripts\configuration.ps1')
    . (Join-Path $PSScriptRoot 'scripts\windows-terminal.ps1')
    $terminalDestination = Resolve-WinuxTerminalSettingsPath -Path $TerminalSettingsPath
    New-WinuxTerminalConfiguration -SourcePath (Join-Path $PSScriptRoot 'config\windows-terminal\settings.json.example') -Destination $terminalDestination | Out-Null
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
    Get-WinuxKomorebiFiles -SourceDirectory (Join-Path $PSScriptRoot 'config\komorebi') | Out-Null
    Write-Host ('Komorebi: ' + (Resolve-WinuxKomorebiDirectory))
}
if ($selectedComponents -contains 'Yasb') {
    . (Join-Path $PSScriptRoot 'scripts\yasb.ps1')
    Get-WinuxYasbFiles -SourceDirectory (Join-Path $PSScriptRoot 'config\yasb') | Out-Null
    Write-Host ('YASB: ' + (Resolve-WinuxYasbDirectory))
}
if ($selectedComponents -contains 'Whkd') {
    . (Join-Path $PSScriptRoot 'scripts\whkd.ps1')
    Get-WinuxWhkdFiles -SourceDirectory (Join-Path $PSScriptRoot 'config\whkd') | Out-Null
    Write-Host ('whkd: ' + (Join-Path (Resolve-WinuxWhkdDirectory) 'whkdrc'))
}
if ($selectedComponents -contains 'Btop') {
    . (Join-Path $PSScriptRoot 'scripts\btop.ps1')
    $btopDestination = Resolve-WinuxBtopDirectory -Path $BtopDirectory
    Get-WinuxBtopFiles -SourceDirectory (Join-Path $PSScriptRoot 'config\btop') -DestinationDirectory $btopDestination | Out-Null
    Write-Host ('btop: ' + $btopDestination)
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

Write-Host ('Componentes: ' + ($selectedComponents -join ', '))

if ($Check) {
    Write-Host 'Pre-requisitos verificados. Nenhum arquivo foi alterado.'
    return
}

$target = $selectedComponents -join ', '
if ($PSCmdlet.ShouldProcess($target, 'Aplicar os componentes selecionados')) {
    $arguments = @{ Components = $selectedComponents; SkipProfile = $SkipProfile; Confirm = $false }
    if ($TerminalSettingsPath) { $arguments.TerminalSettingsPath = $TerminalSettingsPath }
    if ($BtopDirectory) { $arguments.BtopDirectory = $BtopDirectory }
    & $installer @arguments
}

