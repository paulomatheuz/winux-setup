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

    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'Este setup requer Windows.'
}

if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Use Windows PowerShell 5.1 ou PowerShell 7.'
}

# O perfil usa a configuracao e a logo do Fastfetch.
$selectedComponents = @('Fastfetch')
if ($Components -contains 'PowerShell') {
    $selectedComponents += 'PowerShell'
}

$installer = Join-Path $PSScriptRoot 'scripts\install.ps1'
$requiredFiles = @(
    $installer
    (Join-Path $PSScriptRoot 'config\fastfetch\config-purple.jsonc')
    (Join-Path $PSScriptRoot 'config\fastfetch\Spider2-ascii.txt')
)
if ($selectedComponents -contains 'PowerShell') {
    $requiredFiles += Join-Path $PSScriptRoot 'config\powershell\profile.ps1'
}

$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingFiles.Count -gt 0) {
    throw ('Arquivos do projeto nao encontrados: ' + ($missingFiles -join ', '))
}

if (-not (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'Fastfetch nao foi encontrado no PATH. Instale-o e abra uma nova sessao antes de executar o setup.'
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
