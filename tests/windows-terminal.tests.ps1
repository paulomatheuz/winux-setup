param(
    [Parameter(Mandatory)][string]$TestRoot,
    [string]$RepositoryRoot
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch {
        $failed = $true
        Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message
    }
    Assert-Test $failed 'Expected failure.'
}
$run = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $run -Force | Out-Null
. (Join-Path $RepositoryRoot 'scripts\configuration.ps1')
. (Join-Path $RepositoryRoot 'scripts\windows-terminal.ps1')
$source = Join-Path $RepositoryRoot 'config\windows-terminal\settings.json.example'
$destination = Join-Path $run 'settings.json'
$backups = Join-Path $run 'backups'
$fixture = @'
{
  // Preserve local profiles and commands
  "defaultProfile": "{12345678-1234-1234-1234-123456789012}",
  "custom": "https://example.org/a/*text*/ // literal \"quote\" \\",
  "profiles": {
    "defaults": {"font": {"weight": "bold"}},
    "list": [
      {"guid":"{61c54bbd-c2c6-5271-96e7-009a87ff44bf}", "commandline":"local.exe", "hidden":true, "icon":"local.ico"},
      {"guid":"{12345678-1234-1234-1234-123456789012}", "source":"Local.Source", "name":"Personal"},
    ],
  },
  "schemes": [{"name":"Other","background":"#FFFFFF"}, {"name":"Spider Purple","background":"#FFFFFF","extra":true}],
  "actions": [{"command":"copy","id":"local.copy"}],
  "themes": [{"name":"Local"}],
  "newTabMenu": [{"type":"remainingProfiles"}],
  "keybindings": [
    {"command":"paste", "keys":" C + CTRL "},
    {"command":"copy", "keys":["ctrl+v", "ctrl+x"]},
    {"command":"find", "keys":"ctrl+alt+t"},
  ], /* final comment */
}
'@
[IO.File]::WriteAllText($destination, $fixture)
$plan = New-WinuxTerminalConfiguration $source $destination
$result = Invoke-WinuxConfiguration -Files @($plan) -BackupRoot $backups -WhatIf
Assert-Test ($result.Status -eq 'Planned' -and -not (Test-Path $backups)) 'WhatIf wrote files.'
Assert-Test ([IO.File]::ReadAllText($destination) -ceq $fixture) 'WhatIf changed original.'
$result = Invoke-WinuxConfiguration -Files @($plan) -BackupRoot $backups -Confirm:$false
$record = Get-Content (Join-Path $result.BackupPath 'manifest.json') -Raw | ConvertFrom-Json
Assert-Test ($record.Status -eq 'Complete') 'Backup not complete.'
Assert-Test ([IO.File]::ReadAllText((Join-Path $result.BackupPath $record.Files[0].BackupFile)) -ceq $fixture) 'Original bytes lost.'
$value = Get-Content $destination -Raw | ConvertFrom-Json
Assert-Test ($value.defaultProfile -eq '{12345678-1234-1234-1234-123456789012}') 'Default profile changed.'
Assert-Test ($value.custom -eq (ConvertFrom-WinuxTerminalJson $fixture).custom) 'JSON strings changed.'
Assert-Test ($value.profiles.defaults.font.weight -eq 'bold' -and $value.profiles.defaults.font.size -eq 12) 'Font merge failed.'
$ps = @($value.profiles.list | Where-Object guid -eq '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}')[0]
Assert-Test ($ps.commandline -eq 'local.exe' -and $ps.hidden -and $ps.icon -eq 'local.ico' -and $ps.opacity -eq 40) 'Profile merge failed.'
Assert-Test (@($value.profiles.list).Count -eq 3 -and $value.profiles.list[1].source -eq 'Local.Source') 'Custom profile lost.'
Assert-Test (@($value.schemes).Count -eq 4 -and $value.schemes[1].extra) 'Scheme merge failed.'
Assert-Test ($value.actions[0].id -eq 'local.copy' -and $value.themes[0].name -eq 'Local' -and $value.newTabMenu[0].type -eq 'remainingProfiles') 'Unmanaged properties lost.'
Assert-Test (@($value.keybindings).Count -eq 6 -and @($value.keybindings | Where-Object { $_.keys -contains 'ctrl+x' }).Count -eq 1) 'Shortcut preservation failed.'
Assert-Test (@($value.keybindings | Where-Object id -eq 'Terminal.CopyToClipboard').Count -eq 1) 'Shortcut override failed.'
$hash = (Get-FileHash $destination).Hash
$plan = New-WinuxTerminalConfiguration $source $destination
$result = Invoke-WinuxConfiguration -Files @($plan) -BackupRoot $backups
Assert-Test ($result.Status -eq 'Unchanged' -and (Get-FileHash $destination).Hash -eq $hash -and @(Get-ChildItem $backups).Count -eq 1) 'Reapply changed files.'
# Comments are retained on a semantic no-op.
[IO.File]::AppendAllText($destination, '// keep this comment')
$plan = New-WinuxTerminalConfiguration $source $destination
Assert-Test ((Get-WinuxBytesHash $plan.Bytes) -eq (Get-FileHash $destination).Hash) 'No-op removed comments.'
[IO.File]::AppendAllText($destination, ' // concurrent edit')
Assert-Failure { Invoke-WinuxConfiguration -Files @($plan) -BackupRoot $backups } 'mudou desde'
$new = Join-Path $run 'new.json'
$plan = New-WinuxTerminalConfiguration $source $new
[IO.File]::WriteAllText($new, '{}')
Assert-Failure { Invoke-WinuxConfiguration -Files @($plan) -BackupRoot $backups } 'mudou desde'
[IO.File]::Delete($new)
$result = Invoke-WinuxConfiguration -Files @($plan) -BackupRoot $backups -Confirm:$false
$created = Get-Content $new -Raw | ConvertFrom-Json
Assert-Test ($created.profiles.list.Count -eq 2 -and -not $created.profiles.list[0].commandline -and -not $created.defaultProfile) 'New settings are not portable.'
[IO.File]::WriteAllText($new, '{/* incomplete')
Assert-Failure { New-WinuxTerminalConfiguration $source $new } 'Comentario'
foreach ($invalid in @('[]', '{"profiles":[]}', '{"schemes":{}}', '{"profiles":{"list":{}}}', '{bad}')) {
    [IO.File]::WriteAllText($new, $invalid)
    Assert-Failure { New-WinuxTerminalConfiguration $source $new } '.'
}
$appData = Join-Path $run 'appdata'
$stable = Resolve-WinuxTerminalSettingsPath -LocalAppData $appData
Assert-Test ($stable -like '*Microsoft.WindowsTerminal_8wekyb3d8bbwe*') 'Stable default incorrect.'
foreach ($relative in @('Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json', 'Packages\Microsoft.WindowsTerminalCanary_8wekyb3d8bbwe\LocalState\settings.json', 'Microsoft\Windows Terminal\settings.json')) {
    $candidate = Join-Path $appData $relative
    New-Item -ItemType Directory (Split-Path $candidate) -Force | Out-Null
    [IO.File]::WriteAllText($candidate, '{}')
    Assert-Test ((Resolve-WinuxTerminalSettingsPath -LocalAppData $appData) -eq $candidate) 'Edition detection failed.'
    New-Item -ItemType Directory (Split-Path $stable) -Force | Out-Null
    [IO.File]::WriteAllText($stable, '{}')
    Assert-Failure { Resolve-WinuxTerminalSettingsPath -LocalAppData $appData } 'Mais de uma'
    Assert-Test ((Resolve-WinuxTerminalSettingsPath -Path $new -LocalAppData $appData) -eq $new) 'Explicit selection failed.'
    [IO.File]::Delete($stable)
    [IO.File]::Delete($candidate)
}
# These modes must work without requiring Fastfetch or touching the real settings.
[IO.File]::WriteAllText($new, '{}')
& (Join-Path $RepositoryRoot 'setup.ps1') -Components WindowsTerminal -TerminalSettingsPath $new -Check
& (Join-Path $RepositoryRoot 'setup.ps1') -Components WindowsTerminal -TerminalSettingsPath $new -WhatIf
Assert-Test ([IO.File]::ReadAllText($new) -eq '{}') 'Setup dry-run wrote settings.'
Assert-Failure { & (Join-Path $RepositoryRoot 'setup.ps1') -Components Fastfetch -TerminalSettingsPath $new -Check } 'Use -Components'
# An isolated checkout proves Terminal-only setup has no Fastfetch dependency.
$minimal = Join-Path $run 'minimal'
New-Item -ItemType Directory (Join-Path $minimal 'scripts') -Force | Out-Null
New-Item -ItemType Directory (Join-Path $minimal 'config\windows-terminal') -Force | Out-Null
Copy-Item (Join-Path $RepositoryRoot 'setup.ps1') $minimal
foreach ($script in @('install.ps1', 'configuration.ps1', 'windows-terminal.ps1')) {
    Copy-Item (Join-Path $RepositoryRoot ('scripts\' + $script)) (Join-Path $minimal 'scripts')
}
Copy-Item $source (Join-Path $minimal 'config\windows-terminal\settings.json.example')
$terminalTestRun = $run
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $terminalTestRun 'integration-backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') {
        return Microsoft.PowerShell.Management\Join-Path $terminalTestRun 'unexpected-fastfetch'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()]
    param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -eq 'fastfetch') { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
& (Join-Path $minimal 'setup.ps1') -Components WindowsTerminal -TerminalSettingsPath $new -Check
& (Join-Path $minimal 'setup.ps1') -Components WindowsTerminal -TerminalSettingsPath $new -Confirm:$false
$applied = (Get-FileHash $new).Hash
& (Join-Path $minimal 'scripts\install.ps1') -Components WindowsTerminal -TerminalSettingsPath $new -Confirm:$false
Assert-Test ((Get-FileHash $new).Hash -eq $applied) 'Installer reapply changed settings.'
Assert-Test (-not (Test-Path (Join-Path $run 'unexpected-fastfetch'))) 'Terminal setup wrote Fastfetch files.'
Assert-Test (@(Get-ChildItem (Join-Path $run 'integration-backups')).Count -eq 1) 'Integration backup mismatch.'
[pscustomobject]@{ PowerShell = $PSVersionTable.PSVersion.ToString(); TerminalMerge = 'passed'; Backups = 'passed'; Reapply = 'passed'; ConcurrentChanges = 'passed'; Jsonc = 'passed'; EditionDetection = 'passed'; DryRun = 'passed' } | ConvertTo-Json -Compress
