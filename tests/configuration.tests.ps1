param(
    [Parameter(Mandatory)][string]$TestRoot,
    [string]$RepositoryRoot
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
. (Join-Path $RepositoryRoot 'scripts\configuration.ps1')
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch {
        $failed = $true
        Assert-Test ($_.Exception.Message -match $Pattern) ('Unexpected error: ' + $_.Exception.Message)
    }
    Assert-Test $failed 'Expected an error.'
}
$root = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
$source = Join-Path $root 'source.txt'
$destination = Join-Path $root 'destination.txt'
$newDestination = Join-Path $root 'new.txt'
$backups = Join-Path $root 'backups'
[IO.File]::WriteAllBytes($source, [byte[]](1,2,3))
[IO.File]::WriteAllBytes($destination, [byte[]](9,8))
$files = @(@{SourcePath=$source;Destination=$destination},@{Destination=$newDestination;Bytes=[byte[]]@()})
$result = Invoke-WinuxConfiguration -Files $files -BackupRoot $backups -WhatIf
Assert-Test ($result.Status -eq 'Planned') 'WhatIf status is incorrect.'
Assert-Test (-not (Test-Path -LiteralPath $backups)) 'WhatIf created backups.'
Assert-Test (-not (Test-Path -LiteralPath $newDestination)) 'WhatIf created a destination.'
Assert-Test (([IO.File]::ReadAllBytes($destination) -join ',') -eq '9,8') 'WhatIf changed a file.'

$result = Invoke-WinuxConfiguration -Files $files -BackupRoot $backups -Confirm:$false
$manifest = Get-Content -Raw -LiteralPath (Join-Path $result.BackupPath 'manifest.json') | ConvertFrom-Json
Assert-Test ($manifest.Status -eq 'Complete' -and $manifest.Files.Count -eq 2) 'Manifest is incomplete.'
Assert-Test ($manifest.Files[0].Status -eq 'Applied') 'Applied status is missing.'
$originalBackup = Join-Path $result.BackupPath $manifest.Files[0].BackupFile
Assert-Test (([IO.File]::ReadAllBytes($originalBackup) -join ',') -eq '9,8') 'Original backup differs.'
Assert-Test (-not $manifest.Files[1].Existed -and $null -eq $manifest.Files[1].BackupFile) 'New file metadata is incorrect.'
Assert-Test ((Get-Item -LiteralPath $newDestination).Length -eq 0) 'Empty content was not applied.'
$firstBackupPath = $result.BackupPath
$lastWrite = (Get-Item -LiteralPath $destination).LastWriteTimeUtc
$again = Invoke-WinuxConfiguration -Files $files -BackupRoot $backups -Confirm:$false
Assert-Test ($again.Status -eq 'Unchanged') 'Repeated application was not skipped.'
Assert-Test (@(Get-ChildItem -LiteralPath $backups -Directory).Count -eq 1) 'Repeated application created a backup.'
Assert-Test ((Get-Item -LiteralPath $destination).LastWriteTimeUtc -eq $lastWrite) 'Identical destination was rewritten.'

[IO.File]::WriteAllBytes($source, [byte[]](4,5))
$second = Invoke-WinuxConfiguration -Files $files -BackupRoot $backups -Confirm:$false
Assert-Test ($second.BackupPath -ne $firstBackupPath) 'Backups reused a directory.'
Assert-Test (([IO.File]::ReadAllBytes($originalBackup) -join ',') -eq '9,8') 'Previous backup was overwritten.'

$emptySource = Join-Path $root 'filled.txt'
[IO.File]::WriteAllBytes($emptySource, [byte[]](7))
$emptyResult = Invoke-WinuxConfiguration -Files @(@{SourcePath=$emptySource;Destination=$newDestination}) -BackupRoot $backups -Confirm:$false
$emptyRecord = Get-Content -Raw -LiteralPath (Join-Path $emptyResult.BackupPath 'manifest.json') | ConvertFrom-Json
Assert-Test ((Get-Item -LiteralPath (Join-Path $emptyResult.BackupPath $emptyRecord.Files[0].BackupFile)).Length -eq 0) 'Empty original was not backed up.'

$failureBackups = Join-Path $root 'invalid-backups'
Assert-Failure { Invoke-WinuxConfiguration -Files @(@{SourcePath=$source;Destination=$destination},@{SourcePath=(Join-Path $root 'missing');Destination=(Join-Path $root 'other')}) -BackupRoot $failureBackups -Confirm:$false } 'origem nao encontrado'
Assert-Test (-not (Test-Path -LiteralPath $failureBackups)) 'Preflight created backups.'
Assert-Failure { Invoke-WinuxConfiguration -Files @(@{SourcePath=$source;Destination=$destination},@{SourcePath=$source;Destination=$destination}) -BackupRoot $failureBackups -Confirm:$false } 'Destino repetido'

$blockedBackup = Join-Path $root 'blocked-backup'
[IO.File]::WriteAllBytes($blockedBackup,[byte[]](0))
$before = (Get-FileHash -LiteralPath $destination).Hash
Assert-Failure { Invoke-WinuxConfiguration -Files @(@{SourcePath=$emptySource;Destination=$destination}) -BackupRoot $blockedBackup -Confirm:$false } '.*'
Assert-Test ((Get-FileHash -LiteralPath $destination).Hash -eq $before) 'Backup failure changed a destination.'

$locked = Join-Path $root 'locked.txt'
[IO.File]::WriteAllBytes($locked,[byte[]](6))
$failureRoot = Join-Path $root 'partial'
$handle = [IO.File]::Open($locked,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
try {
    Assert-Failure { Invoke-WinuxConfiguration -Files @(@{SourcePath=$emptySource;Destination=$destination},@{SourcePath=$emptySource;Destination=$locked}) -BackupRoot $failureRoot -Confirm:$false } '.*'
} finally { $handle.Dispose() }
$failedRun = Get-ChildItem -LiteralPath $failureRoot -Directory | Select-Object -First 1
$failedRecord = Get-Content -Raw -LiteralPath (Join-Path $failedRun.FullName 'manifest.json') | ConvertFrom-Json
Assert-Test ($failedRecord.Status -eq 'Failed') 'Failed status is missing.'
Assert-Test ($failedRecord.Files[0].Status -eq 'Applied' -and $failedRecord.Files[1].Status -eq 'Pending') 'Partial application was not recorded.'
foreach($entry in $failedRecord.Files){
    Assert-Test (Test-Path -LiteralPath (Join-Path $failedRun.FullName $entry.BackupFile)) 'A backup was missing after failure.'
}

$encodings = @(
    (New-Object Text.UTF8Encoding($false)),
    (New-Object Text.UTF8Encoding($true)),
    [Text.Encoding]::Unicode,
    [Text.Encoding]::BigEndianUnicode,
    [Text.Encoding]::UTF32,
    (New-Object Text.UTF32Encoding($true,$true))
)
$index = 0
foreach($encoding in $encodings){
    $profile = Join-Path $root ('profile-' + $index + '.ps1')
    [byte[]]$original = $encoding.GetPreamble() + $encoding.GetBytes('# ' + [char]0x00E7)
    [IO.File]::WriteAllBytes($profile,$original)
    [byte[]]$merged = Get-WinuxProfileBytes -Path $profile
    Assert-Test ($merged.Length -gt $original.Length) 'Profile integration was not appended.'
    Assert-Test (($merged[0..($original.Length-1)] -join ',') -eq ($original -join ',')) 'Original profile bytes changed.'
    [IO.File]::WriteAllBytes($profile,$merged)
    [byte[]]$repeated = Get-WinuxProfileBytes -Path $profile
    Assert-Test (($repeated -join ',') -eq ($merged -join ',')) 'Profile integration was duplicated.'
    $index++
}
$missingProfile = Join-Path $root 'missing-profile.ps1'
[byte[]]$initial = Get-WinuxProfileBytes -Path $missingProfile
Assert-Test ($initial.Length -gt 0 -and -not (Test-Path -LiteralPath $missingProfile)) 'Planning created the profile.'
$malformed = Join-Path $root 'malformed.ps1'
[IO.File]::WriteAllText($malformed, '# >>> custom-windows-terminal >>>')
Assert-Failure { Get-WinuxProfileBytes -Path $malformed } 'marcadores incompletos'
$inverted = Join-Path $root 'inverted.ps1'
[IO.File]::WriteAllText($inverted, '# <<< custom-windows-terminal <<< # >>> custom-windows-terminal >>>')
Assert-Failure { Get-WinuxProfileBytes -Path $inverted } 'marcadores incompletos'
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString();BackupIntegrity='passed';NewAndEmptyFiles='passed';Idempotency='passed';FailureRecords='passed';ProfileEncodings='passed';TestDirectory=$root} | ConvertTo-Json -Compress

