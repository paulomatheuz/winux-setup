param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$rainTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($rainTestRun) | Out-Null
$fixture = Join-Path $rainTestRun 'repo'
foreach ($directory in @('scripts', 'config\starship')) { [IO.Directory]::CreateDirectory((Join-Path $fixture $directory)) | Out-Null }
Copy-Item (Join-Path $RepositoryRoot 'setup.ps1') $fixture
foreach ($name in @('install-rain.ps1', 'configuration.ps1', 'install.ps1', 'starship.ps1')) {
    Copy-Item (Join-Path $RepositoryRoot ('scripts\' + $name)) (Join-Path $fixture 'scripts')
}
Copy-Item (Join-Path $RepositoryRoot 'config\starship\starship.toml') (Join-Path $fixture 'config\starship')
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
function New-TestArchive([string]$Path, [switch]$MissingLicense) {
    $zip = [IO.Compression.ZipFile]::Open($Path, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($name in @('matrix-rain.exe', 'README.md', 'LICENSE', '../ignored.txt')) {
            if ($MissingLicense -and $name -eq 'LICENSE') { continue }
            $entry = $zip.CreateEntry($name)
            $writer = New-Object IO.StreamWriter($entry.Open())
            try { $writer.Write('fixture-' + $name) } finally { $writer.Dispose() }
        }
    } finally { $zip.Dispose() }
}
$rainTestArchive = Join-Path $rainTestRun 'release.zip'
New-TestArchive $rainTestArchive
$archiveHash = (Get-FileHash $rainTestArchive).Hash
$manifest = [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'portable-programs.psd1'))
$fixtureManifest = Join-Path $fixture 'portable-programs.psd1'
$testManifest = [regex]::Replace($manifest, "(?m)(SHA256 = ')[a-fA-F0-9]{64}", ('${1}' + $archiveHash))
[IO.File]::WriteAllText($fixtureManifest, $testManifest)
$rainTestTarget = Join-Path $rainTestRun 'target [rain]'
$rainTestMode = 'Normal'
$rainTestExistingPath = $false
$rainTestDownloads = New-Object 'System.Collections.Generic.List[string]'
$rainTestTemporaryDirectories = New-Object 'System.Collections.Generic.List[string]'
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $rainTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq 'Tools\matrix-rain') { return $rainTestTarget }
    $resolved = Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
    if ($ChildPath -like 'winux-rain-*') { $rainTestTemporaryDirectories.Add($resolved) }
    return $resolved
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -eq 'matrix-rain') {
        if ($rainTestExistingPath) { return [pscustomobject]@{Source='existing-not-executed'} }
        return
    }
    if ($Name -eq 'fastfetch') { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
function Invoke-WebRequest {
    [CmdletBinding()] param([string]$Uri, [string]$OutFile, [switch]$UseBasicParsing)
    $rainTestDownloads.Add($Uri)
    if ($rainTestMode -eq 'DownloadError') { throw 'Simulated download failure.' }
    if ($rainTestMode -eq 'Corrupt') { [IO.File]::WriteAllText($OutFile, 'corrupt'); return }
    [IO.File]::Copy($rainTestArchive, $OutFile)
    if ($rainTestMode -eq 'Concurrent') {
        [IO.Directory]::CreateDirectory($rainTestTarget) | Out-Null
        [IO.File]::WriteAllText((Join-Path $rainTestTarget 'matrix-rain.exe'), 'concurrent-installation')
    }
}
$installer = Join-Path $fixture 'scripts\install-rain.ps1'
& $installer -Check -Architecture x64
& $installer -WhatIf -Architecture arm64
Assert-Test ($rainTestDownloads.Count -eq 0 -and -not (Test-Path $rainTestTarget)) 'Dry run downloaded or wrote files.'
$rainTestExistingPath = $true
& $installer -Architecture x64 -Confirm:$false
Assert-Test ($rainTestDownloads.Count -eq 0) 'Existing PATH installation downloaded again.'
$rainTestExistingPath = $false
[IO.Directory]::CreateDirectory($rainTestTarget) | Out-Null
[IO.File]::WriteAllText((Join-Path $rainTestTarget 'README.md'), 'original-readme')
& $installer -Architecture x64 -Confirm:$false
Assert-Test ([IO.File]::ReadAllText((Join-Path $rainTestTarget 'matrix-rain.exe')) -eq 'fixture-matrix-rain.exe') 'Executable fixture not installed.'
Assert-Test (-not (Test-Path (Join-Path $rainTestRun 'ignored.txt'))) 'Unexpected archive path extracted.'
$backupRoot = Join-Path $rainTestRun 'backups'
$backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
$record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 3) 'Installation record incomplete.'
$entry = @($record.Files | Where-Object Existed)[0]
Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $entry.BackupFile)) -eq 'original-readme') 'Original readme lost.'
& $installer -Architecture x64 -Confirm:$false
Assert-Test ($rainTestDownloads.Count -eq 1 -and @(Get-ChildItem $backupRoot).Count -eq 1) 'Reinstall overwrote existing installation.'
Assert-Test ($rainTestDownloads[0] -like '*windows_amd64.zip') 'Incorrect x64 asset.'
$rainTestTarget = Join-Path $rainTestRun 'arm64'
& $installer -Architecture arm64 -Confirm:$false
Assert-Test ($rainTestDownloads[-1] -like '*windows_arm64.zip') 'Incorrect ARM64 asset.'
$backupsBeforeFailures = @(Get-ChildItem $backupRoot).Count
foreach ($mode in @('Corrupt', 'DownloadError')) {
    $rainTestTarget = Join-Path $rainTestRun $mode
    $rainTestMode = $mode
    $pattern = if ($mode -eq 'Corrupt') { 'SHA256' } else { 'download failure' }
    Assert-Failure { & $installer -Architecture x64 -Confirm:$false } $pattern
    Assert-Test (-not (Test-Path $rainTestTarget)) 'Download failure wrote destination.'
}
$rainTestTarget = Join-Path $rainTestRun 'concurrent'
$rainTestMode = 'Concurrent'
Assert-Failure { & $installer -Architecture x64 -Confirm:$false } 'mudou desde'
Assert-Test ([IO.File]::ReadAllText((Join-Path $rainTestTarget 'matrix-rain.exe')) -eq 'concurrent-installation') 'Concurrent executable overwritten.'
$rainTestMode = 'Normal'
$rainTestArchive = Join-Path $rainTestRun 'missing-license.zip'
New-TestArchive $rainTestArchive -MissingLicense
$badHash = (Get-FileHash $rainTestArchive).Hash
[IO.File]::WriteAllText($fixtureManifest, $testManifest.Replace($archiveHash, $badHash))
$rainTestTarget = Join-Path $rainTestRun 'incomplete'
Assert-Failure { & $installer -Architecture x64 -Confirm:$false } 'LICENSE'
Assert-Test (-not (Test-Path $rainTestTarget)) 'Incomplete ZIP wrote destination.'
Assert-Test (@(Get-ChildItem $backupRoot).Count -eq $backupsBeforeFailures) 'Failed installation created backups.'
$rainTestArchive = Join-Path $rainTestRun 'release.zip'
[IO.File]::WriteAllText($fixtureManifest, $testManifest)
$savedStarshipConfig = $env:STARSHIP_CONFIG
try {
    $env:STARSHIP_CONFIG = Join-Path $rainTestRun 'starship.toml'
    $rainTestTarget = Join-Path $rainTestRun 'root-integration'
    & (Join-Path $fixture 'setup.ps1') -Components Starship -InstallRain -Check
    & (Join-Path $fixture 'setup.ps1') -Components Starship -InstallRain -WhatIf
    Assert-Test (-not (Test-Path $rainTestTarget)) 'Root dry run installed rain.'
    & (Join-Path $fixture 'setup.ps1') -Components Starship -InstallRain -Confirm:$false
    Assert-Test (Test-Path (Join-Path $rainTestTarget 'matrix-rain.exe')) 'Root flag did not install rain.'
    Assert-Test (Test-Path $env:STARSHIP_CONFIG) 'Root flag skipped selected configuration.'
} finally { $env:STARSHIP_CONFIG = $savedStarshipConfig }
Assert-Test ($rainTestTemporaryDirectories.Count -gt 0) 'Temporary directories were not tracked.'
foreach ($temporaryDirectory in $rainTestTemporaryDirectories) {
    Assert-Test (-not (Test-Path -LiteralPath $temporaryDirectory)) 'Temporary installation files were not cleaned.'
}
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); DryRun='passed'; ExistingInstallation='passed'; Architectures='passed'; Checksum='passed'; ArchiveFiles='passed'; ConcurrentInstallation='passed'; Backups='passed'; RootIntegration='passed'} | ConvertTo-Json -Compress
