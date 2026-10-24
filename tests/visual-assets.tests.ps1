param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$visualTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($visualTestRun) | Out-Null
. (Join-Path $RepositoryRoot 'scripts\configuration.ps1')
. (Join-Path $RepositoryRoot 'scripts\visual-assets.ps1')
$source = Join-Path $RepositoryRoot 'assets'
$homeFixture = Join-Path $visualTestRun 'home'
$plans = @(Get-WinuxVisualAssetFiles -SourceDirectory $source -HomePath $homeFixture)
Assert-Test ($plans.Count -eq 19) 'Expected 18 wallpapers and one icon.'
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $visualTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -like 'Pictures\*') {
        return Microsoft.PowerShell.Management\Join-Path $homeFixture $ChildPath
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -eq 'fastfetch') { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
$existingWallpaper = $plans[0].Destination
[IO.Directory]::CreateDirectory((Split-Path -Parent $existingWallpaper)) | Out-Null
[IO.File]::WriteAllText($existingWallpaper, 'previous-wallpaper')
$unmanaged = Join-Path $homeFixture 'Pictures\wallpaper\keep-local.txt'
[IO.File]::WriteAllText($unmanaged, 'keep-local')
$settings = Join-Path $visualTestRun 'settings.json'
$originalSettings = '{"defaultProfile":"custom","profiles":{"list":[{"guid":"{61c54bbd-c2c6-5271-96e7-009a87ff44bf}","icon":"previous.ico","commandline":"keep.exe"}]}}'
[IO.File]::WriteAllText($settings, $originalSettings)
$setup = Join-Path $RepositoryRoot 'setup.ps1'
$installer = Join-Path $RepositoryRoot 'scripts\install.ps1'
& $setup -Components VisualAssets, WindowsTerminal -TerminalSettingsPath $settings -Check
& $setup -Components VisualAssets, WindowsTerminal -TerminalSettingsPath $settings -WhatIf
Assert-Test ([IO.File]::ReadAllText($existingWallpaper) -eq 'previous-wallpaper') 'Dry run replaced wallpaper.'
Assert-Test ([IO.File]::ReadAllText($settings) -eq $originalSettings) 'Dry run changed Terminal.'
$backupRoot = Join-Path $visualTestRun 'backups'
Assert-Test (-not (Test-Path $backupRoot)) 'Dry run created backup.'
& $setup -Components VisualAssets, WindowsTerminal -TerminalSettingsPath $settings -Confirm:$false
$value = Get-Content $settings -Raw | ConvertFrom-Json
$profile = @($value.profiles.list | Where-Object guid -eq '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}')[0]
Assert-Test ($profile.icon -eq (Get-WinuxTerminalIconPath -HomePath $homeFixture) -and $profile.commandline -eq 'keep.exe' -and $value.defaultProfile -eq 'custom') 'Terminal icon integration changed local profile properties.'
foreach ($plan in $plans) {
    Assert-Test ((Get-FileHash -LiteralPath $plan.Destination).Hash -eq (Get-WinuxBytesHash $plan.Bytes)) 'Media bytes changed during copy.'
}
Assert-Test ([IO.File]::ReadAllText($unmanaged) -eq 'keep-local') 'Local gallery file removed.'
$backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
$record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 20) 'Incomplete backup record.'
foreach ($pair in @(@{Path=$existingWallpaper;Text='previous-wallpaper'}, @{Path=$settings;Text=$originalSettings})) {
    $entry = @($record.Files | Where-Object Destination -eq $pair.Path)[0]
    Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $entry.BackupFile)) -eq $pair.Text) 'Original backup lost.'
}
& $setup -Components VisualAssets, WindowsTerminal -TerminalSettingsPath $settings -Confirm:$false
& $installer -Components VisualAssets, WindowsTerminal -TerminalSettingsPath $settings -Confirm:$false
& $installer -Components WindowsTerminal -TerminalSettingsPath $settings -Confirm:$false
Assert-Test (@(Get-ChildItem $backupRoot).Count -eq 1) 'Reapply changed files or icon.'
$brokenSource = Join-Path $visualTestRun 'broken'
[IO.Directory]::CreateDirectory($brokenSource) | Out-Null
$brokenManifest = Join-Path $brokenSource 'manifest.json'
[IO.File]::WriteAllText($brokenManifest, '{"Files":[{"Path":"wallpapers/../outside.jpg","SHA256":"' + ('0' * 64) + '"}]}')
Assert-Failure { Get-WinuxVisualAssetFiles -SourceDirectory $brokenSource -HomePath $homeFixture } 'Caminho'
[IO.File]::WriteAllText($brokenManifest, '{"Files":[{"Path":"icons/terminal.ico","SHA256":"' + ('0' * 64) + '"}]}')
Assert-Failure { Get-WinuxVisualAssetFiles -SourceDirectory $brokenSource -HomePath $homeFixture } 'nao encontrado'
[IO.Directory]::CreateDirectory((Join-Path $brokenSource 'icons')) | Out-Null
[IO.File]::WriteAllText((Join-Path $brokenSource 'icons\terminal.ico'), 'modified')
Assert-Failure { Get-WinuxVisualAssetFiles -SourceDirectory $brokenSource -HomePath $homeFixture } 'SHA256 diferente'
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); MediaHashes='passed'; DryRun='passed'; Copies='passed'; Backups='passed'; TerminalIcon='passed'; LocalFilesPreserved='passed'; Reapply='passed'; InvalidSources='passed'} | ConvertTo-Json -Compress
