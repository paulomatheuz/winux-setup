[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$BackupPath,
    [switch]$Check,
    [ValidateNotNullOrEmpty()][string]$BackupRoot
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.' }
. (Join-Path $PSScriptRoot 'configuration.ps1')
. (Join-Path $PSScriptRoot 'restore.ps1')
if (-not $BackupRoot) { $BackupRoot = Join-Path $HOME '.winux-setup\backups' }
$files = @(Get-WinuxRestoreFiles -BackupPath $BackupPath)
Write-Host ('Arquivos a restaurar: ' + $files.Count)
if ($Check) { Write-Host 'Backup e destinos verificados. Nenhum arquivo foi alterado.'; return }
if ($files.Count -eq 0) { Write-Host 'Os arquivos ja estao no estado anterior ao backup.'; return }
if ($PSCmdlet.ShouldProcess(($files.Destination -join ', '), 'Restaurar o backup e salvar o estado atual antes de substituir ou remover arquivos')) {
    $result = Invoke-WinuxConfiguration -Files $files -BackupRoot $BackupRoot -Confirm:$false
    Write-Host ('Restauracao: ' + $result.Status)
    if ($result.BackupPath) { Write-Host ('Backup do estado anterior a restauracao: ' + $result.BackupPath) }
    Write-Host 'Reabra ou recarregue os aplicativos afetados para usar os arquivos restaurados.'
}
