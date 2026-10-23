param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Failure([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true; Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message }
    Assert-Test $failed 'Expected failure.'
}
$whkdTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $whkdTestRun -Force | Out-Null
. (Join-Path $RepositoryRoot 'scripts\whkd.ps1')
Assert-Test ((Resolve-WinuxWhkdDirectory -ConfiguredPath '' -HomePath $whkdTestRun) -eq (Join-Path $whkdTestRun '.config')) 'Default directory incorrect.'
foreach ($invalid in @('relative', 'C:relative', '\relative')) {
    Assert-Failure { Resolve-WinuxWhkdDirectory -ConfiguredPath $invalid } 'caminho absoluto'
}
$sourceRoot = Join-Path $RepositoryRoot 'config\whkd'
$source = Join-Path $sourceRoot 'whkdrc'
$text = [IO.File]::ReadAllText($source)
Assert-Test ($text -match '(?m)^\.shell powershell\s*$') 'PowerShell shell changed.'
# Parse commands without executing shortcuts or registering keyboard hooks.
$bindings = @{}
foreach ($line in ($text -split '\r?\n')) {
    if ($line -match '^\s*(?:#|\.|$)') { continue }
    $parts = $line -split ':', 2
    Assert-Test ($parts.Count -eq 2) 'Binding without command.'
    $keys = (($parts[0].ToLowerInvariant() -replace '\s', '' -split '\+' | Sort-Object) -join '+')
    Assert-Test (-not $bindings.ContainsKey($keys)) ('Duplicate binding: ' + $parts[0])
    $bindings[$keys] = $true
    $tokens = $null
    $parseErrors = $null
    [Management.Automation.Language.Parser]::ParseInput($parts[1], [ref]$tokens, [ref]$parseErrors) | Out-Null
    Assert-Test ($parseErrors.Count -eq 0) ('Invalid PowerShell command: ' + $parts[0])
}
Assert-Test ($text -match 'alt \+ 8\s+: komorebic focus-workspace 7' -and $text -match 'alt \+ shift \+ 8\s+: komorebic move-to-workspace 7') 'Existing eighth-workspace shortcuts changed.'
$savedDirectory = $env:WHKD_CONFIG_HOME
$savedKomorebiDirectory = $env:KOMOREBI_CONFIG_HOME
$savedYasbDirectory = $env:YASB_CONFIG_HOME
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $whkdTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') {
        return Microsoft.PowerShell.Management\Join-Path $whkdTestRun 'unexpected-fastfetch'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -in @('fastfetch', 'whkd', 'komorebic')) { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
try {
    $env:WHKD_CONFIG_HOME = Join-Path $whkdTestRun 'custom [keys]'
    [IO.Directory]::CreateDirectory($env:WHKD_CONFIG_HOME) | Out-Null
    $destination = Join-Path $env:WHKD_CONFIG_HOME 'whkdrc'
    [IO.File]::WriteAllText($destination, '# original shortcuts')
    $setup = Join-Path $RepositoryRoot 'setup.ps1'
    $installer = Join-Path $RepositoryRoot 'scripts\install.ps1'
    & $setup -Components Whkd -Check
    & $setup -Components Whkd -WhatIf
    & $installer -Components Whkd -WhatIf
    Assert-Test ([IO.File]::ReadAllText($destination) -eq '# original shortcuts') 'Dry run changed shortcuts.'
    Assert-Test (-not (Test-Path (Join-Path $whkdTestRun 'backups'))) 'Dry run created backups.'
    & $setup -Components Whkd -Confirm:$false
    Assert-Test ((Get-FileHash -LiteralPath $destination).Hash -eq (Get-FileHash $source).Hash) 'Personal shortcuts changed.'
    $backupRoot = Join-Path $whkdTestRun 'backups'
    $backup = @(Get-ChildItem $backupRoot -Directory)[0].FullName
    $record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
    Assert-Test ($record.Status -eq 'Complete' -and $record.Files.Count -eq 1) 'Backup incomplete.'
    Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $record.Files[0].BackupFile)) -eq '# original shortcuts') 'Original lost.'
    & $setup -Components Whkd -Confirm:$false
    & $installer -Components Whkd -Confirm:$false
    Assert-Test (@(Get-ChildItem $backupRoot).Count -eq 1) 'Reapply created backup.'
    Assert-Test (-not (Test-Path (Join-Path $whkdTestRun 'unexpected-fastfetch'))) 'Unrelated files applied.'
    $env:WHKD_CONFIG_HOME = Join-Path $whkdTestRun 'new-directory'
    & $setup -Components Whkd -Confirm:$false
    Assert-Test (Test-Path (Join-Path $env:WHKD_CONFIG_HOME 'whkdrc')) 'New configuration not created.'
    $env:WHKD_CONFIG_HOME = $destination
    Assert-Failure { & $setup -Components Whkd -Check } 'deve ser uma pasta'
    $empty = Join-Path $whkdTestRun 'missing-source'
    Assert-Failure { Get-WinuxWhkdFiles -SourceDirectory $empty -DestinationDirectory (Join-Path $whkdTestRun 'unused') } 'nao encontrado'
    Assert-Test (-not (Test-Path (Join-Path $whkdTestRun 'unused'))) 'Missing source created destination.'
    $combined = Join-Path $whkdTestRun 'combined'
    $env:WHKD_CONFIG_HOME = Join-Path $combined 'keys'
    $env:KOMOREBI_CONFIG_HOME = Join-Path $combined 'windows'
    $env:YASB_CONFIG_HOME = Join-Path $combined 'bar'
    & $setup -Components Komorebi, Yasb, Whkd -WhatIf
    Assert-Test (-not (Test-Path $combined)) 'Combined dry run wrote files.'
    & $setup -Components Komorebi, Yasb, Whkd -Confirm:$false
    $latest = @(Get-ChildItem $backupRoot -Directory | Sort-Object Name)[-1].FullName
    $combinedRecord = Get-Content (Join-Path $latest 'manifest.json') -Raw | ConvertFrom-Json
    Assert-Test ($combinedRecord.Status -eq 'Complete' -and $combinedRecord.Files.Count -eq 8) 'Combined application incomplete.'
    Assert-Test ((Get-FileHash -LiteralPath (Join-Path $env:WHKD_CONFIG_HOME 'whkdrc')).Hash -eq (Get-FileHash $source).Hash) 'Combined application changed shortcuts.'
} finally {
    $env:WHKD_CONFIG_HOME = $savedDirectory
    $env:KOMOREBI_CONFIG_HOME = $savedKomorebiDirectory
    $env:YASB_CONFIG_HOME = $savedYasbDirectory
}
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); CommandsParsed='passed'; DuplicateBindings='passed'; PersonalShortcuts='passed'; DryRun='passed'; Backups='passed'; Reapply='passed'; CustomDirectory='passed'; InvalidInput='passed'} | ConvertTo-Json -Compress
