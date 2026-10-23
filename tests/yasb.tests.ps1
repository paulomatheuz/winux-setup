param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$yasbTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $yasbTestRun -Force | Out-Null
. (Join-Path $RepositoryRoot 'scripts\yasb.ps1')
Assert-Test ((Resolve-WinuxYasbDirectory -ConfiguredPath '' -HomePath $yasbTestRun) -eq (Join-Path $yasbTestRun '.config\yasb')) 'Default directory incorrect.'
foreach ($invalid in @('relative', 'C:relative', '\relative')) {
    Assert-Failure { Resolve-WinuxYasbDirectory -ConfiguredPath $invalid } 'caminho absoluto'
}
$savedDirectory = $env:YASB_CONFIG_HOME
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $yasbTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') {
        return Microsoft.PowerShell.Management\Join-Path $yasbTestRun 'unexpected-fastfetch'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -in @('fastfetch', 'yasb', 'komorebic')) { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
try {
    $env:YASB_CONFIG_HOME = Join-Path $yasbTestRun 'custom [bar]'
    [IO.Directory]::CreateDirectory($env:YASB_CONFIG_HOME) | Out-Null
    $config = Join-Path $env:YASB_CONFIG_HOME 'config.yaml'
    $styles = Join-Path $env:YASB_CONFIG_HOME 'styles.css'
    $localEnvironment = Join-Path $env:YASB_CONFIG_HOME '.env'
    [IO.File]::WriteAllText($config, '# original configuration')
    [IO.File]::WriteAllText($styles, '/* original styles */')
    [IO.File]::WriteAllText($localEnvironment, 'LOCAL_SENTINEL=preserve')
    $setup = Join-Path $RepositoryRoot 'setup.ps1'
    $installer = Join-Path $RepositoryRoot 'scripts\install.ps1'
    & $setup -Components Yasb -Check
    & $setup -Components Yasb -WhatIf
    & $installer -Components Yasb -WhatIf
    Assert-Test ([IO.File]::ReadAllText($config) -eq '# original configuration' -and [IO.File]::ReadAllText($styles) -eq '/* original styles */') 'Dry run changed files.'
    Assert-Test (-not (Test-Path (Join-Path $yasbTestRun 'backups'))) 'Dry run created backups.'
    & $setup -Components Yasb -Confirm:$false
    $sourceRoot = Join-Path $RepositoryRoot 'config\yasb'
    foreach ($name in @('config.yaml', 'styles.css', 'YASB.LICENSE')) {
        Assert-Test ((Get-FileHash -LiteralPath (Join-Path $env:YASB_CONFIG_HOME $name)).Hash -eq (Get-FileHash (Join-Path $sourceRoot $name)).Hash) "Personal file changed: $name"
    }
    Assert-Test ([IO.File]::ReadAllText($localEnvironment) -eq 'LOCAL_SENTINEL=preserve') 'Local environment overwritten.'
    $backupRoot = Join-Path $yasbTestRun 'backups'
    $backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
    $record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
    Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 3) 'Backup incomplete.'
    foreach ($entry in @($record.Files | Where-Object Existed)) {
        $expected = if ($entry.Destination -eq $config) { '# original configuration' } else { '/* original styles */' }
        Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $entry.BackupFile)) -eq $expected) 'Original lost.'
    }
    & $setup -Components Yasb -Confirm:$false
    & $installer -Components Yasb -Confirm:$false
    Assert-Test (@(Get-ChildItem $backupRoot).Count -eq 1) 'Reapply created backup.'
    Assert-Test (-not (Test-Path (Join-Path $yasbTestRun 'unexpected-fastfetch'))) 'Unrelated files applied.'
    $env:YASB_CONFIG_HOME = Join-Path $yasbTestRun 'new-directory'
    & $setup -Components Yasb -Confirm:$false
    Assert-Test (Test-Path (Join-Path $env:YASB_CONFIG_HOME 'styles.css')) 'New files not created.'
    Assert-Test (-not (Test-Path (Join-Path $env:YASB_CONFIG_HOME '.env'))) 'Setup created private settings.'
    $env:YASB_CONFIG_HOME = $config
    Assert-Failure { & $setup -Components Yasb -Check } 'deve ser uma pasta'
    $broken = Join-Path $yasbTestRun 'missing-style'
    [IO.Directory]::CreateDirectory($broken) | Out-Null
    [IO.File]::WriteAllText((Join-Path $broken 'config.yaml'), 'watch_config: true')
    Assert-Failure { Get-WinuxYasbFiles -SourceDirectory $broken -DestinationDirectory (Join-Path $yasbTestRun 'unused') } 'nao encontrado'
    Assert-Test (-not (Test-Path (Join-Path $yasbTestRun 'unused'))) 'Incomplete source created destination.'
} finally { $env:YASB_CONFIG_HOME = $savedDirectory }
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); PersonalFiles='passed'; LocalEnvironment='passed'; DryRun='passed'; Backups='passed'; Reapply='passed'; CustomDirectory='passed'; InvalidInput='passed'} | ConvertTo-Json -Compress
