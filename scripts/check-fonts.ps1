[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.'
}
. (Join-Path $PSScriptRoot 'fonts.ps1')
$report = @(Get-WinuxFontReport)
$report
$missing = @($report | Where-Object { -not $_.Available -and -not $_.Optional })
Write-Host ('Fontes necessarias nao encontradas: ' + $missing.Count + '. A verificacao nao instala fontes nem altera configuracoes.')
