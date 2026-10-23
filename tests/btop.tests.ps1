param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$btopTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($btopTestRun) | Out-Null
$btopTestApplication = ''
$btopTestLink = Join-Path $btopTestRun 'links\btop.exe'
$btopTestTarget = Join-Path $btopTestRun 'package\btop4win.exe'
$btopTestWingetCalls = New-Object 'System.Collections.Generic.List[object]'
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $btopTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') {
        return Microsoft.PowerShell.Management\Join-Path $btopTestRun 'unexpected-fastfetch'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -eq 'winget') { return [pscustomobject]@{Source='Invoke-TestWinget'} }
    if ($Name -eq 'fastfetch') { return }
    if ($Name -eq 'btop4win') {
        if ($btopTestApplication -eq 'direct') { return [pscustomobject]@{Source=$btopTestTarget} }
        return
    }
    if ($Name -eq 'btop') {
        if ($btopTestApplication -eq 'alias') { return [pscustomobject]@{Source=$btopTestLink} }
        return
    }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
function Get-Item {
    [CmdletBinding()] param([string]$LiteralPath, [switch]$Force)
    if ($LiteralPath -eq $btopTestLink) {
        return [pscustomobject]@{FullName=$btopTestLink; Name='btop.exe'; LinkType='SymbolicLink'; Target=@('..\package\btop4win.exe')}
    }
    Microsoft.PowerShell.Management\Get-Item -LiteralPath $LiteralPath -Force:$Force
}
function Invoke-TestWinget {
    $btopTestWingetCalls.Add(@($args))
    $global:LASTEXITCODE = 0
}
. (Join-Path $RepositoryRoot 'scripts\btop.ps1')
$emptyHome = Join-Path $btopTestRun 'empty-home'
Assert-Test ((Resolve-WinuxBtopDirectory -HomePath $emptyHome) -eq (Join-Path $emptyHome 'Tools\btop4win\btop4win')) 'Default destination incorrect.'
foreach ($invalid in @('relative', 'C:relative', '\relative')) { Assert-Failure { Resolve-WinuxBtopDirectory -Path $invalid } 'caminho absoluto' }
[IO.Directory]::CreateDirectory((Split-Path -Parent $btopTestTarget)) | Out-Null
[IO.File]::WriteAllBytes($btopTestTarget, [byte[]]@(0))
$btopTestApplication = 'direct'
Assert-Test ((Resolve-WinuxBtopDirectory -HomePath $emptyHome) -eq (Split-Path -Parent $btopTestTarget)) 'PATH executable not found.'
$btopTestApplication = 'alias'
Assert-Test ((Resolve-WinuxBtopDirectory -HomePath $emptyHome) -eq (Split-Path -Parent $btopTestTarget)) 'WinGet link not resolved.'
$btopTestApplication = ''
$portable = Join-Path $emptyHome 'Tools\btop4win\nested'
[IO.Directory]::CreateDirectory($portable) | Out-Null
[IO.File]::WriteAllBytes((Join-Path $portable 'btop4win.exe'), [byte[]]@(0))
Assert-Test ((Resolve-WinuxBtopDirectory -HomePath $emptyHome) -eq $portable) 'Portable executable not found.'
$destination = Join-Path $btopTestRun 'custom [monitor]'
[IO.Directory]::CreateDirectory((Join-Path $destination 'themes')) | Out-Null
$config = Join-Path $destination 'btop.conf'
$theme = Join-Path $destination 'themes\NeutralPurple.theme'
[IO.File]::WriteAllText($config, '# original config')
[IO.File]::WriteAllText($theme, '# original theme')
$sourceRoot = Join-Path $RepositoryRoot 'config\btop'
$setup = Join-Path $RepositoryRoot 'setup.ps1'
$installer = Join-Path $RepositoryRoot 'scripts\install.ps1'
& $setup -Components Btop -BtopDirectory $destination -Check
& $setup -Components Btop -BtopDirectory $destination -WhatIf
& $installer -Components Btop -BtopDirectory $destination -WhatIf
Assert-Test ([IO.File]::ReadAllText($config) -eq '# original config' -and [IO.File]::ReadAllText($theme) -eq '# original theme') 'Dry run changed files.'
Assert-Test (-not (Test-Path (Join-Path $btopTestRun 'backups'))) 'Dry run created backups.'
& $setup -Components Btop -BtopDirectory $destination -Confirm:$false
foreach ($relative in @('btop.conf', 'themes\NeutralPurple.theme', 'BTOP.LICENSE')) {
    Assert-Test ((Get-FileHash -LiteralPath (Join-Path $destination $relative)).Hash -eq (Get-FileHash (Join-Path $sourceRoot $relative)).Hash) 'Personal settings changed.'
}
$backupRoot = Join-Path $btopTestRun 'backups'
$backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
$record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 3) 'Backup incomplete.'
foreach ($entry in @($record.Files | Where-Object Existed)) {
    $expected = if ($entry.Destination -eq $config) { '# original config' } else { '# original theme' }
    Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $entry.BackupFile)) -eq $expected) 'Original lost.'
}
& $setup -Components Btop -BtopDirectory $destination -Confirm:$false
& $installer -Components Btop -BtopDirectory $destination -Confirm:$false
Assert-Test (@(Get-ChildItem $backupRoot).Count -eq 1) 'Reapply created backup.'
Assert-Test (-not (Test-Path (Join-Path $btopTestRun 'unexpected-fastfetch'))) 'Unrelated files applied.'
Assert-Failure { & $setup -Components Starship -BtopDirectory $destination -Check } 'Use -Components Btop'
Assert-Failure { & $setup -Components Btop -BtopDirectory $config -Check } 'deve ser uma pasta'
$savedPath = $env:PATH
try {
    $newDestination = Join-Path $btopTestRun 'new-destination'
    & $setup -Components Btop -BtopDirectory $newDestination -InstallPrograms -Programs Btop -AcceptAgreements -Confirm:$false
    Assert-Test ($btopTestWingetCalls.Count -eq 1) 'Unexpected installation calls.'
    foreach ($argument in @('aristocratos.btop4win', '--version', '1.0.5', '--no-upgrade', '--accept-package-agreements')) {
        Assert-Test ($btopTestWingetCalls[0] -contains $argument) ('Missing WinGet argument: ' + $argument)
    }
    Assert-Test (Test-Path (Join-Path $newDestination 'btop.conf')) 'New configuration not created.'
} finally { $env:PATH = $savedPath }
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); PersonalFiles='passed'; DestinationDiscovery='passed'; WinGetLink='passed'; DryRun='passed'; Backups='passed'; Reapply='passed'; SimulatedInstallation='passed'} | ConvertTo-Json -Compress
