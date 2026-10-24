param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed=$true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$startupTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($startupTestRun) | Out-Null
$startupTestProcesses = New-Object 'System.Collections.Generic.List[object]'
$startupTestRootCalls = New-Object 'System.Collections.Generic.List[object]'
$startupTestRunning = @()
$startupTestExitCode = 0
$startupTestMissing = $false
$startupTestPrograms = @{}
foreach ($name in @('komorebic-no-console', 'whkd', 'yasb')) {
    $path = Join-Path $startupTestRun ('programs\' + $name + '.exe')
    [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    [IO.File]::WriteAllText($path, 'not-an-executable')
    $startupTestPrograms[$name] = $path
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($startupTestPrograms.ContainsKey($Name)) {
        if ($startupTestMissing) { return }
        return [pscustomobject]@{Path=$startupTestPrograms[$Name];Source=$startupTestPrograms[$Name]}
    }
    if ($Name -in @('komorebic', 'fastfetch')) { return }
    if ($Name -eq 'winget') { return [pscustomobject]@{Source='never-invoked'} }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $startupTestRun 'backups'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Process {
    [CmdletBinding()] param([string]$Name)
    if ($startupTestRunning -contains $Name) { return [pscustomobject]@{Name=$Name;SessionId=[Diagnostics.Process]::GetCurrentProcess().SessionId} }
}
function Start-Process {
    [CmdletBinding()] param([string]$FilePath, [string[]]$ArgumentList, [string]$WindowStyle, [switch]$Wait, [switch]$PassThru)
    $startupTestProcesses.Add([pscustomobject]@{Path=$FilePath;Arguments=$ArgumentList;Hidden=($WindowStyle -eq 'Hidden')})
    if ($PassThru) { return [pscustomobject]@{ExitCode=$startupTestExitCode} }
}
$saved = @{}
foreach ($name in @('KOMOREBI_CONFIG_HOME','WHKD_CONFIG_HOME','YASB_CONFIG_HOME','STARSHIP_CONFIG','PATH')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
$startupDirectory = Join-Path $startupTestRun 'startup-target'
$stateDirectory = Join-Path $startupTestRun 'state [desktop]'
$configure = Join-Path $RepositoryRoot 'scripts\configure-startup.ps1'
try {
    foreach ($pair in @(@{Env='KOMOREBI_CONFIG_HOME';Files=@('komorebi.json')}, @{Env='WHKD_CONFIG_HOME';Files=@('whkdrc')}, @{Env='YASB_CONFIG_HOME';Files=@('config.yaml','styles.css')})) {
        $directory = Join-Path $startupTestRun ('config\' + $pair.Env)
        [IO.Directory]::CreateDirectory($directory) | Out-Null
        [Environment]::SetEnvironmentVariable($pair.Env,$directory,'Process')
        foreach($file in $pair.Files) { [IO.File]::WriteAllText((Join-Path $directory $file),'fixture') }
    }
    & $configure -Check -StartupDirectory $startupDirectory -StateDirectory $stateDirectory
    & $configure -WhatIf -StartupDirectory $startupDirectory -StateDirectory $stateDirectory
    Assert-Test (-not (Test-Path $startupDirectory) -and -not (Test-Path $stateDirectory)) 'Check or WhatIf wrote startup files.'
    $startupTestMissing = $true
    Assert-Failure { & $configure -Check -StartupDirectory $startupDirectory -StateDirectory $stateDirectory } 'Programa necessario'
    & $configure -Check -ExpectedPrograms Komorebi,Whkd,Yasb -StartupDirectory $startupDirectory -StateDirectory $stateDirectory
    Assert-Failure { & $configure -ExpectedPrograms Komorebi -StartupDirectory $startupDirectory -StateDirectory $stateDirectory } 'so podem'
    $startupTestMissing = $false
    [IO.Directory]::CreateDirectory($startupDirectory) | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $legacy = Join-Path $startupDirectory 'komorebi.lnk'
    $link = $shell.CreateShortcut($legacy)
    $link.TargetPath = $startupTestPrograms['komorebic-no-console']
    $link.Arguments = 'start --whkd'
    $link.Save()
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($link)
    $legacyHash = (Get-FileHash -LiteralPath $legacy).Hash
    $other = Join-Path $startupDirectory 'keep-local.txt'
    [IO.File]::WriteAllText($other,'keep')
    & $configure -StartupDirectory $startupDirectory -StateDirectory $stateDirectory -Confirm:$false
    Assert-Test ($startupTestProcesses.Count -eq 0) 'Registration launched desktop programs.'
    $link = $shell.CreateShortcut($legacy)
    Assert-Test ($link.TargetPath -like '*powershell.exe' -and $link.Arguments -like '*-Component Komorebi' -and $link.WindowStyle -eq 7) 'Incorrect generated shortcut.'
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($link)
    Assert-Test ([IO.File]::ReadAllText($other) -eq 'keep') 'Unmanaged startup file modified.'
    $backupRoot = Join-Path $startupTestRun 'backups'
    $backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
    $record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
    Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 4) 'Incomplete startup backup.'
    $entry = @($record.Files | Where-Object Destination -eq $legacy)[0]
    Assert-Test ((Get-FileHash (Join-Path $backup $entry.BackupFile)).Hash -eq $legacyHash) 'Legacy shortcut backup changed.'
    & $configure -StartupDirectory $startupDirectory -StateDirectory $stateDirectory -Confirm:$false
    Assert-Test (@(Get-ChildItem $backupRoot).Count -eq 1) 'Reapply rewrote shortcuts.'
    $conflict = Join-Path $startupTestRun 'conflict'
    [IO.Directory]::CreateDirectory($conflict) | Out-Null
    $link = $shell.CreateShortcut((Join-Path $conflict 'komorebi.lnk'))
    $link.TargetPath = $startupTestPrograms['komorebic-no-console']
    $link.Arguments = 'start --whkd --bar'
    $link.Save()
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($link)
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    Assert-Failure { & $configure -StartupDirectory $conflict -StateDirectory $stateDirectory -Confirm:$false } 'comando personalizado'
    $launcher = Join-Path $stateDirectory 'start-desktop.ps1'
    $pathBefore = $env:PATH
    & $launcher -Component Komorebi -Check
    Assert-Test ($env:PATH -eq $pathBefore -and $startupTestProcesses.Count -eq 0) 'Launcher Check modified environment or launched programs.'
    & $launcher -Component Komorebi
    Assert-Test ($startupTestProcesses.Count -eq 1 -and $startupTestProcesses[0].Arguments -contains '--whkd') 'Komorebi did not start with whkd.'
    $startupTestRunning = @('whkd')
    & $launcher -Component Komorebi
    Assert-Test ($startupTestProcesses[1].Arguments -notcontains '--whkd') 'Existing whkd started twice.'
    $startupTestRunning = @('komorebi')
    & $launcher -Component Komorebi
    Assert-Test ($startupTestProcesses[2].Path -eq $startupTestPrograms['whkd']) 'Missing whkd was not started.'
    $startupTestRunning = @('komorebi','whkd')
    & $launcher -Component Komorebi
    Assert-Test ($startupTestProcesses.Count -eq 3) 'Running Komorebi started twice.'
    & $launcher -Component Yasb
    $startupTestRunning += 'yasb'
    & $launcher -Component Yasb
    Assert-Test ($startupTestProcesses.Count -eq 4 -and @($startupTestProcesses | Where-Object { -not $_.Hidden }).Count -eq 0) 'Duplicate or visible startup process.'
    $startupTestRunning = @()
    $startupTestExitCode = 5
    Assert-Failure { & $launcher -Component Komorebi } 'Falha ao iniciar'
    Assert-Test ([IO.File]::ReadAllText((Join-Path $stateDirectory 'desktop-startup.log')) -match 'Falha ao iniciar') 'Startup failure was not logged.'
    $rootFixture = Join-Path $startupTestRun 'root-repo'
    foreach($directory in @('scripts','config\starship')) { [IO.Directory]::CreateDirectory((Join-Path $rootFixture $directory)) | Out-Null }
    Copy-Item (Join-Path $RepositoryRoot 'setup.ps1') $rootFixture
    foreach($name in @('install.ps1','configuration.ps1','starship.ps1','startup.ps1','start-desktop.ps1','install-programs.ps1')) { Copy-Item (Join-Path $RepositoryRoot ('scripts\'+$name)) (Join-Path $rootFixture 'scripts') }
    Copy-Item (Join-Path $RepositoryRoot 'packages.psd1') $rootFixture
    Copy-Item (Join-Path $RepositoryRoot 'config\starship\starship.toml') (Join-Path $rootFixture 'config\starship')
    $stub = 'param([switch]$Check,[string[]]$ExpectedPrograms,[string[]]$ExpectedComponents,[switch]$Confirm); $startupTestRootCalls.Add([pscustomobject]@{Check=[bool]$Check;ExpectedPrograms=$ExpectedPrograms})'
    [IO.File]::WriteAllText((Join-Path $rootFixture 'scripts\configure-startup.ps1'), $stub)
    $env:STARSHIP_CONFIG = Join-Path $startupTestRun 'starship.toml'
    $rootSetup = Join-Path $rootFixture 'setup.ps1'
    & $rootSetup -Components Starship -EnableStartup -Check
    & $rootSetup -Components Starship -EnableStartup -WhatIf
    Assert-Test (-not (Test-Path $env:STARSHIP_CONFIG)) 'Root dry run wrote configuration.'
    & $rootSetup -Components Starship -EnableStartup -Confirm:$false
    Assert-Test ($startupTestRootCalls.Count -eq 4 -and -not $startupTestRootCalls[3].Check -and (Test-Path $env:STARSHIP_CONFIG)) 'Root startup integration order incorrect.'
    & $rootSetup -Components Starship -EnableStartup -InstallPrograms -Programs Komorebi,Whkd,Yasb -Check
    Assert-Test ($startupTestRootCalls[-1].ExpectedPrograms.Count -eq 3) 'Root did not pass planned installations.'
} finally {
    foreach($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name],'Process') }
}
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); DryRun='passed'; ShortcutMigration='passed'; Backups='passed'; Reapply='passed'; Conflicts='passed'; SimulatedLaunch='passed'; ProcessGuards='passed'; FailureLog='passed'; RootIntegration='passed'} | ConvertTo-Json -Compress
