param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$deviceTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
$local = Join-Path $deviceTestRun 'device [notebook]'
[IO.Directory]::CreateDirectory($local) | Out-Null
$encoding = New-Object Text.UTF8Encoding($false)
. (Join-Path $RepositoryRoot 'scripts\device.ps1')
function Write-Device($Object) {
    [IO.File]::WriteAllText((Join-Path $local 'device.json'),(ConvertTo-Json -InputObject $Object -Depth 20),$encoding)
}
$deviceFile = Join-Path $local 'device.json'
foreach ($folder in @('komorebi','yasb','whkd','btop')) {
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot ('config\'+$folder)) -Destination $local -Recurse
}
$komorebiPath = Join-Path $local 'komorebi\komorebi.json'
$komorebi = ConvertFrom-Json ([IO.File]::ReadAllText($komorebiPath))
$komorebi.border = -not $komorebi.border
[IO.File]::WriteAllText($komorebiPath,(ConvertTo-Json -InputObject $komorebi -Depth 100),$encoding)
foreach ($path in @('yasb\config.yaml','yasb\styles.css','whkd\whkdrc','btop\btop.conf')) {
    $comment = if ($path.EndsWith('.css')) { "`n/* notebook */`n" } else { "`n# notebook`n" }
    [IO.File]::AppendAllText((Join-Path $local $path),$comment,$encoding)
}
$definition = @{SchemaVersion=1; Components=@('Komorebi','Yasb','Whkd','Btop'); ConfigDirectories=@{Komorebi='komorebi'; Yasb='yasb'; Whkd='whkd'; Btop='btop'}; BtopDirectory='output\btop'; TerminalSettingsPath='output\terminal.json'}
Write-Device $definition
$read = Read-WinuxDeviceConfiguration $deviceFile
Assert-Test ($read.ConfigDirectories.Yasb -eq (Join-Path $local 'yasb') -and $read.BtopDirectory -eq (Join-Path $local 'output\btop')) 'Relative paths resolved incorrectly.'
$invalidCases = @(
    @{Data=@{SchemaVersion=2}; Pattern='SchemaVersion'}
    @{Data=@{SchemaVersion='1'}; Pattern='SchemaVersion'}
    @{Data=@{SchemaVersion=1; EnableStartup=$true}; Pattern='desconhecida'}
    @{Data=@{SchemaVersion=1; Components=@()}; Pattern='lista nao vazia'}
    @{Data=@{SchemaVersion=1; Components='Yasb'}; Pattern='lista nao vazia'}
    @{Data=@{SchemaVersion=1; Components=@('Unknown')}; Pattern='Componente desconhecido'}
    @{Data=@{SchemaVersion=1; Components=@($null)}; Pattern='Componente desconhecido'}
    @{Data=@{SchemaVersion=1; ConfigDirectories=@{Yasb='missing'}}; Pattern='nao encontrada'}
    @{Data=@{SchemaVersion=1; ConfigDirectories=@{Fastfetch='yasb'}}; Pattern='desconhecida'}
    @{Data=@{SchemaVersion=1; ConfigDirectories=@{Yasb=7}}; Pattern='caminho de texto'}
    @{Data=@{SchemaVersion=1; ConfigDirectories='yasb'}; Pattern='objeto JSON'}
    @{Data=@{SchemaVersion=1; BtopDirectory=$null}; Pattern='nulo'}
    @{Data=@{SchemaVersion=1; BtopDirectory='C:relative'}; Pattern='absoluto completo'}
    @{Data=@{SchemaVersion=1; BtopDirectory='\relative'}; Pattern='absoluto completo'}
)
foreach ($case in $invalidCases) { Write-Device $case.Data; Assert-Failure { Read-WinuxDeviceConfiguration $deviceFile } $case.Pattern }
[IO.File]::WriteAllText($deviceFile,'{broken')
Assert-Failure { Read-WinuxDeviceConfiguration $deviceFile } '.'
Write-Device $definition
$saved = @{}
foreach ($name in @('KOMOREBI_CONFIG_HOME','YASB_CONFIG_HOME','WHKD_CONFIG_HOME')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
function Join-Path {
    param([string]$Path,[string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') { return Microsoft.PowerShell.Management\Join-Path $deviceTestRun 'backups' }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') { return Microsoft.PowerShell.Management\Join-Path $deviceTestRun 'unexpected-fastfetch' }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
$setup = Join-Path $RepositoryRoot 'setup.ps1'
$sourceHashes = @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'config') -File -Recurse | Get-FileHash | Select-Object Path,Hash | ConvertTo-Json -Compress)
try {
    $env:KOMOREBI_CONFIG_HOME = Join-Path $deviceTestRun 'installed-komorebi'
    $env:YASB_CONFIG_HOME = Join-Path $deviceTestRun 'installed-yasb'
    $env:WHKD_CONFIG_HOME = Join-Path $deviceTestRun 'installed-whkd'
    & $setup -DeviceConfig $deviceFile -Check
    & $setup -DeviceConfig $deviceFile -WhatIf
    Assert-Test (-not (Test-Path $env:KOMOREBI_CONFIG_HOME) -and -not (Test-Path (Join-Path $deviceTestRun 'backups')) -and -not (Test-Path (Join-Path $local 'output'))) 'Dry run changed files.'
    [IO.Directory]::CreateDirectory($env:KOMOREBI_CONFIG_HOME) | Out-Null
    $destination = Join-Path $env:KOMOREBI_CONFIG_HOME 'komorebi.json'
    [IO.File]::WriteAllText($destination,'{"border":false}')
    & $setup -DeviceConfig $deviceFile -Confirm:$false
    $installed = ConvertFrom-Json ([IO.File]::ReadAllText($destination))
    Assert-Test ($installed.border -eq $komorebi.border -and $installed.app_specific_configuration_path -eq (Join-Path $env:KOMOREBI_CONFIG_HOME 'applications.json')) 'Device Komorebi config or rules path lost.'
    foreach ($pair in @(
        @{Source='yasb\config.yaml'; Target=(Join-Path $env:YASB_CONFIG_HOME 'config.yaml')}
        @{Source='yasb\styles.css'; Target=(Join-Path $env:YASB_CONFIG_HOME 'styles.css')}
        @{Source='whkd\whkdrc'; Target=(Join-Path $env:WHKD_CONFIG_HOME 'whkdrc')}
        @{Source='btop\btop.conf'; Target=(Join-Path $local 'output\btop\btop.conf')}
    )) { Assert-Test ((Get-FileHash -LiteralPath (Join-Path $local $pair.Source)).Hash -eq (Get-FileHash -LiteralPath $pair.Target).Hash) ('Device file changed: '+$pair.Source) }
    Assert-Test (-not (Test-Path (Join-Path $local 'output\terminal.json'))) 'Unselected device destination applied.'
    $backupRoot = Join-Path $deviceTestRun 'backups'
    $backup = @(Get-ChildItem -LiteralPath $backupRoot -Directory)[0].FullName
    $record = ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $backup 'manifest.json')))
    $entry = @($record.Files | Where-Object Destination -eq $destination)[0]
    Assert-Test ($record.Status -eq 'Complete' -and [IO.File]::ReadAllText((Join-Path $backup $entry.BackupFile)) -eq '{"border":false}') 'Device backup lost.'
    & $setup -DeviceConfig $deviceFile -Confirm:$false
    Assert-Test (@(Get-ChildItem -LiteralPath $backupRoot -Directory).Count -eq 1) 'Device reapply changed files.'
    $alternate = Join-Path $deviceTestRun 'cli-btop'
    & $setup -DeviceConfig $deviceFile -Components Btop -BtopDirectory $alternate -Confirm:$false
    Assert-Test (Test-Path -LiteralPath (Join-Path $alternate 'btop.conf')) 'Explicit CLI destination ignored.'
    & $setup -DeviceConfig $deviceFile -Components Whkd -Check
    & $setup -DeviceConfig $deviceFile -Components WindowsTerminal -Check
    Assert-Test (-not (Test-Path (Join-Path $local 'output\terminal.json'))) 'Terminal preflight wrote a file.'
    # Removing a selected source must fail before applying any other component.
    $missing = Join-Path $local 'yasb\styles.css'
    $bytes = [IO.File]::ReadAllBytes($missing)
    [IO.File]::Delete($missing)
    $before = (Get-FileHash -LiteralPath $destination).Hash
    Assert-Failure { & $setup -DeviceConfig $deviceFile -Confirm:$false } 'nao encontrados'
    Assert-Test ((Get-FileHash -LiteralPath $destination).Hash -eq $before) 'Invalid device applied partial configuration.'
    [IO.File]::WriteAllBytes($missing,$bytes)
    # Omitting the device returns to the shared sources through the normal installer.
    & $setup -Components Whkd -Confirm:$false
    Assert-Test ((Get-FileHash -LiteralPath (Join-Path $env:WHKD_CONFIG_HOME 'whkdrc')).Hash -eq (Get-FileHash -LiteralPath (Join-Path $RepositoryRoot 'config\whkd\whkdrc')).Hash) 'Shared default changed.'
    $afterHashes = @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'config') -File -Recurse | Get-FileHash | Select-Object Path,Hash | ConvertTo-Json -Compress)
    Assert-Test ($sourceHashes[0] -ceq $afterHashes[0]) 'Shared configuration modified.'
    Assert-Test (-not (Test-Path (Join-Path $deviceTestRun 'unexpected-fastfetch'))) 'Unselected component applied.'
} finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name],'Process') }
}
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); Validation='passed'; RelativePaths='passed'; DryRun='passed'; LocalConfigs='passed'; CliPrecedence='passed'; Backup='passed'; Reapply='passed'; SharedDefaults='passed'} | ConvertTo-Json -Compress
