param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$komorebiTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $komorebiTestRun -Force | Out-Null
. (Join-Path $RepositoryRoot 'scripts\komorebi.ps1')
Assert-Test ((Resolve-WinuxKomorebiDirectory -ConfiguredPath '' -HomePath $komorebiTestRun) -eq $komorebiTestRun) 'Default directory incorrect.'
foreach ($invalid in @('relative', 'C:relative', '\relative')) {
    Assert-Failure { Resolve-WinuxKomorebiDirectory -ConfiguredPath $invalid } 'caminho absoluto'
}
$savedDirectory = $env:KOMOREBI_CONFIG_HOME
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $komorebiTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') {
        return Microsoft.PowerShell.Management\Join-Path $komorebiTestRun 'unexpected-fastfetch'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -in @('fastfetch', 'komorebic')) { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
try {
    $env:KOMOREBI_CONFIG_HOME = Join-Path $komorebiTestRun 'custom [desktop]'
    [IO.Directory]::CreateDirectory($env:KOMOREBI_CONFIG_HOME) | Out-Null
    $destination = Join-Path $env:KOMOREBI_CONFIG_HOME 'komorebi.json'
    [IO.File]::WriteAllText($destination, '{"border":false}')
    $setup = Join-Path $RepositoryRoot 'setup.ps1'
    $installer = Join-Path $RepositoryRoot 'scripts\install.ps1'
    & $setup -Components Komorebi -Check
    & $setup -Components Komorebi -WhatIf
    & $installer -Components Komorebi -WhatIf
    Assert-Test ([IO.File]::ReadAllText($destination) -eq '{"border":false}') 'Dry run changed configuration.'
    Assert-Test (-not (Test-Path (Join-Path $komorebiTestRun 'backups'))) 'Dry run created backups.'
    & $setup -Components Komorebi -Confirm:$false
    $installed = Get-Content -LiteralPath $destination -Raw | ConvertFrom-Json
    $sourceRoot = Join-Path $RepositoryRoot 'config\komorebi'
    $expected = Get-Content (Join-Path $sourceRoot 'komorebi.json') -Raw | ConvertFrom-Json
    Assert-Test ($installed.app_specific_configuration_path -eq (Join-Path $env:KOMOREBI_CONFIG_HOME 'applications.json')) 'Application rules path incorrect.'
    $installed.app_specific_configuration_path = $expected.app_specific_configuration_path
    Assert-Test (($installed | ConvertTo-Json -Depth 100 -Compress) -ceq ($expected | ConvertTo-Json -Depth 100 -Compress)) 'Personal preferences changed.'
    Assert-Test ($installed.monitors.Count -eq 1 -and $installed.monitors[0].workspaces.Count -eq 7) 'Workspace layout changed.'
    foreach ($name in @('applications.json', 'komorebi.bar.json', 'applications.LICENSE')) {
        Assert-Test ((Get-FileHash -LiteralPath (Join-Path $env:KOMOREBI_CONFIG_HOME $name)).Hash -eq (Get-FileHash (Join-Path $sourceRoot $name)).Hash) "File changed: $name"
    }
    $backupRoot = Join-Path $komorebiTestRun 'backups'
    $backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
    $record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
    Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 4) 'Backup record incomplete.'
    $entry = @($record.Files | Where-Object Destination -eq $destination)[0]
    Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $entry.BackupFile)) -eq '{"border":false}') 'Original lost.'
    & $setup -Components Komorebi -Confirm:$false
    & $installer -Components Komorebi -Confirm:$false
    Assert-Test (@(Get-ChildItem $backupRoot).Count -eq 1) 'Reapply created backup.'
    Assert-Test (-not (Test-Path (Join-Path $komorebiTestRun 'unexpected-fastfetch'))) 'Unrelated files applied.'
    $env:KOMOREBI_CONFIG_HOME = Join-Path $komorebiTestRun 'new-directory'
    & $setup -Components Komorebi -Confirm:$false
    Assert-Test (Test-Path (Join-Path $env:KOMOREBI_CONFIG_HOME 'komorebi.json')) 'New configuration not created.'
    $env:KOMOREBI_CONFIG_HOME = $destination
    Assert-Failure { & $setup -Components Komorebi -Check } 'deve ser uma pasta'
    $broken = Join-Path $komorebiTestRun 'broken-source'
    Copy-Item $sourceRoot $broken -Recurse
    [IO.File]::WriteAllText((Join-Path $broken 'komorebi.json'), '{invalid}')
    Assert-Failure { Get-WinuxKomorebiFiles -SourceDirectory $broken -DestinationDirectory (Join-Path $komorebiTestRun 'unused') } '.'
    Assert-Test (-not (Test-Path (Join-Path $komorebiTestRun 'unused'))) 'Invalid source created destination.'
} finally { $env:KOMOREBI_CONFIG_HOME = $savedDirectory }
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); Selection='passed'; PersonalPreferences='passed'; RulesAndBar='passed'; DryRun='passed'; Backups='passed'; Reapply='passed'; CustomDirectory='passed'; InvalidInput='passed'} | ConvertTo-Json -Compress
