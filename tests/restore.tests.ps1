param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$restoreTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($restoreTestRun) | Out-Null
. (Join-Path $RepositoryRoot 'scripts\configuration.ps1')
. (Join-Path $RepositoryRoot 'scripts\restore.ps1')
$restore = Join-Path $RepositoryRoot 'scripts\restore-backup.ps1'
$backups = Join-Path $restoreTestRun 'backups'
$undoBackups = Join-Path $restoreTestRun 'undo-backups'
$existing = Join-Path $restoreTestRun 'existing [config].bin'
$empty = Join-Path $restoreTestRun 'empty.txt'
$created = Join-Path $restoreTestRun 'created.txt'
$unmanaged = Join-Path $restoreTestRun 'unmanaged.txt'
[byte[]]$original = @(0,255,128,65,0,66)
[IO.File]::WriteAllBytes($existing,$original)
[IO.File]::WriteAllBytes($empty,[byte[]]@())
[IO.File]::WriteAllText($unmanaged,'keep')
$result = Invoke-WinuxConfiguration -BackupRoot $backups -Files @(
    @{Destination=$existing; Bytes=[byte[]]@(1,2,3)}
    @{Destination=$empty; Bytes=[byte[]]@(4)}
    @{Destination=$created; Bytes=[byte[]]@(5,6)}
) -Confirm:$false
$backup = $result.BackupPath
$manifest = Join-Path $backup 'manifest.json'
$initialManifest = [IO.File]::ReadAllText($manifest)
# Legacy records have no Operation field; they remain restorable.
$legacy = ConvertFrom-Json $initialManifest
foreach ($entry in $legacy.Files) { $entry.PSObject.Properties.Remove('Operation') }
Save-WinuxConfigurationRecord $legacy $manifest
$legacyHash = (Get-FileHash -LiteralPath $manifest).Hash
& $restore -BackupPath $backup -BackupRoot $undoBackups -Check
& $restore -BackupPath $backup -BackupRoot $undoBackups -WhatIf
Assert-Test ((Get-WinuxBytesHash ([IO.File]::ReadAllBytes($existing))) -eq (Get-WinuxBytesHash ([byte[]]@(1,2,3))) -and (Test-Path -LiteralPath $created) -and -not (Test-Path -LiteralPath $undoBackups)) 'Dry run changed files.'
& $restore -BackupPath $backup -BackupRoot $undoBackups -Confirm:$false
Assert-Test ((Get-WinuxBytesHash ([IO.File]::ReadAllBytes($existing))) -eq (Get-WinuxBytesHash $original)) 'Original binary lost.'
Assert-Test ((Get-Item -LiteralPath $empty).Length -eq 0 -and -not (Test-Path -LiteralPath $created)) 'New/empty files restored incorrectly.'
Assert-Test ([IO.File]::ReadAllText($unmanaged) -eq 'keep') 'Unmanaged file changed.'
Assert-Test ((Get-FileHash -LiteralPath $manifest).Hash -eq $legacyHash) 'Source backup modified.'
$undo = @(Get-ChildItem -LiteralPath $undoBackups -Directory)[0].FullName
$undoRecord = ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $undo 'manifest.json')))
Assert-Test ($undoRecord.Status -eq 'Complete' -and @($undoRecord.Files | Where-Object Operation -eq 'Remove').Count -eq 1) 'Undo backup incomplete.'
& $restore -BackupPath $backup -BackupRoot $undoBackups -Confirm:$false
Assert-Test (@(Get-ChildItem -LiteralPath $undoBackups -Directory).Count -eq 1) 'Repeated restore created backup.'
# Restoring the restoration backup recreates the deleted file and applied bytes.
$redoBackups = Join-Path $restoreTestRun 'redo-backups'
& $restore -BackupPath $undo -BackupRoot $redoBackups -Confirm:$false
Assert-Test ((Get-WinuxBytesHash ([IO.File]::ReadAllBytes($existing))) -eq (Get-WinuxBytesHash ([byte[]]@(1,2,3))) -and (Get-WinuxBytesHash ([IO.File]::ReadAllBytes($created))) -eq (Get-WinuxBytesHash ([byte[]]@(5,6)))) 'Undo of restore failed.'
# A later edit blocks all changes, even if it is the last entry in the plan.
[IO.File]::WriteAllText($created,'edited afterwards')
$currentHash = (Get-FileHash -LiteralPath $existing).Hash
Assert-Failure { & $restore -BackupPath $backup -BackupRoot $undoBackups -Confirm:$false } 'mudou depois'
Assert-Test ((Get-FileHash -LiteralPath $existing).Hash -eq $currentHash -and [IO.File]::ReadAllText($created) -eq 'edited afterwards') 'Conflict applied partial restore.'
[IO.File]::WriteAllBytes($created,[byte[]]@(5,6))
# Corruption and malformed metadata must fail before touching destinations.
$originalCopy = Join-Path $backup $legacy.Files[0].BackupFile
$originalBytes = [IO.File]::ReadAllBytes($originalCopy)
[IO.File]::WriteAllText($originalCopy,'corrupt')
Assert-Failure { & $restore -BackupPath $backup -BackupRoot $undoBackups -Confirm:$false } 'corrompido'
[IO.File]::WriteAllBytes($originalCopy,$originalBytes)
$mutations = @(
    @{Change={param($r) $r.SchemaVersion=2}; Pattern='nao suportado'}
    @{Change={param($r) $r.Status='Preparing'}; Pattern='preparacao'}
    @{Change={param($r) $r.Files[0].BackupFile='..\outside.original'}; Pattern='Referencia'}
    @{Change={param($r) $r.Files[0].DesiredSHA256='invalid'}; Pattern='Hash'}
    @{Change={param($r) $r.Files[0].Destination='relative'}; Pattern='Entrada invalida'}
    @{Change={param($r) $r.Files[1].Destination=$r.Files[0].Destination}; Pattern='repetido'}
    @{Change={param($r) $r.Files[0].Destination=(Join-Path $backup 'manifest.json')}; Pattern='backup de origem'}
    @{Change={param($r) $r.Files[2].Existed='false'}; Pattern='Entrada invalida'}
)
$validManifest = [IO.File]::ReadAllText($manifest)
foreach ($mutation in $mutations) {
    $record = ConvertFrom-Json $validManifest
    & $mutation.Change $record
    Save-WinuxConfigurationRecord $record $manifest
    Assert-Failure { & $restore -BackupPath $backup -BackupRoot $undoBackups -Confirm:$false } $mutation.Pattern
    Assert-Test ((Get-FileHash -LiteralPath $existing).Hash -eq $currentHash) 'Invalid manifest changed destination.'
}
[IO.File]::WriteAllText($manifest,$validManifest)
# An interrupted apply can leave applied bytes with Pending metadata.
$partial = ConvertFrom-Json $validManifest
$partial.Status='Failed'
foreach ($entry in $partial.Files) { $entry.Status='Pending' }
Save-WinuxConfigurationRecord $partial $manifest
[IO.File]::WriteAllBytes($empty,[byte[]]@())
& $restore -BackupPath $backup -BackupRoot $undoBackups -Confirm:$false
Assert-Test ((Get-WinuxBytesHash ([IO.File]::ReadAllBytes($existing))) -eq (Get-WinuxBytesHash $original) -and -not (Test-Path -LiteralPath $created)) 'Partial apply not recovered.'
# Planning pins the current bytes; changes before execution are rejected.
& $restore -BackupPath $undo -BackupRoot $redoBackups -Confirm:$false
$plan = @(Get-WinuxRestoreFiles $backup)
[IO.File]::WriteAllText($existing,'changed during planning')
Assert-Failure { Invoke-WinuxConfiguration -Files $plan -BackupRoot $undoBackups -Confirm:$false } 'mudou desde'
Assert-Test ([IO.File]::ReadAllText($existing) -eq 'changed during planning') 'Concurrent edit overwritten.'
Assert-Test (@(Get-ChildItem -LiteralPath $undoBackups -Directory).Count -eq 2) 'Failed planning created backup.'
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); Legacy='passed'; DryRun='passed'; BinaryAndEmpty='passed'; NewFileRemoval='passed'; Undo='passed'; Conflicts='passed'; Integrity='passed'; PartialApply='passed'; Concurrency='passed'; Reapply='passed'} | ConvertTo-Json -Compress
