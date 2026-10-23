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
    [ValidateSet('Fastfetch', 'PowerShell')]
    [string[]]$Components = @('Fastfetch', 'PowerShell'),

    [switch]$Check,

    [switch]$SkipProfile,

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
$selectedComponents = @('Fastfetch')
if ($Components -contains 'PowerShell') {
    $selectedComponents += 'PowerShell'
}

$installer = Join-Path $PSScriptRoot 'scripts\install.ps1'
$requiredFiles = @(
    $installer
    (Join-Path $PSScriptRoot 'scripts\configuration.ps1')
    (Join-Path $PSScriptRoot 'config\fastfetch\config-purple.jsonc')
    (Join-Path $PSScriptRoot 'config\fastfetch\Spider2-ascii.txt')
)
if ($selectedComponents -contains 'PowerShell') {
    $requiredFiles += Join-Path $PSScriptRoot 'config\powershell\profile.ps1'
}

if ($InstallPrograms) {
    $requiredFiles += Join-Path $PSScriptRoot 'packages.psd1'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\install-programs.ps1'
}

if ($InstallModules) {
    $requiredFiles += Join-Path $PSScriptRoot 'modules.psd1'
    $requiredFiles += Join-Path $PSScriptRoot 'scripts\install-modules.ps1'
}

$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingFiles.Count -gt 0) {
    throw ('Arquivos do projeto nao encontrados: ' + ($missingFiles -join ', '))
}

$hasFastfetch = [bool](Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue)
if (-not $hasFastfetch -and (-not $InstallPrograms -or ($Programs -and $Programs -notcontains 'Fastfetch'))) {
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

if (-not $Check -and -not $WhatIfPreference -and -not (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'Fastfetch ainda nao esta disponivel no PATH. Abra uma nova sessao e execute o setup novamente. As configuracoes nao foram aplicadas.'
}

Write-Host ('Componentes: ' + ($selectedComponents -join ', '))

if ($Check) {
    Write-Host 'Pre-requisitos verificados. Nenhum arquivo foi alterado.'
    return
}

$target = Join-Path $HOME '.config\fastfetch'
if ($PSCmdlet.ShouldProcess($target, 'Aplicar os componentes selecionados')) {
    & $installer -Components $selectedComponents -SkipProfile:$SkipProfile -Confirm:$false
}
