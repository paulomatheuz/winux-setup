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
$starshipTestRun = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $starshipTestRun -Force | Out-Null
. (Join-Path $RepositoryRoot 'scripts\starship.ps1')
Assert-Test ((Resolve-WinuxStarshipConfigPath -ConfiguredPath '' -HomePath $starshipTestRun) -eq (Join-Path $starshipTestRun '.config\starship.toml')) 'Default path incorrect.'
Assert-Failure { Resolve-WinuxStarshipConfigPath -ConfiguredPath 'relative.toml' } 'caminho absoluto'
Assert-Failure { Resolve-WinuxStarshipConfigPath -ConfiguredPath 'C:relative.toml' } 'caminho absoluto'
Assert-Failure { Resolve-WinuxStarshipConfigPath -ConfiguredPath '\relative.toml' } 'caminho absoluto'
$savedConfig = $env:STARSHIP_CONFIG
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $HOME -and $ChildPath -eq '.winux-setup\backups') {
        return Microsoft.PowerShell.Management\Join-Path $starshipTestRun 'backups'
    }
    if ($Path -eq $HOME -and $ChildPath -eq '.config\fastfetch') {
        return Microsoft.PowerShell.Management\Join-Path $starshipTestRun 'unexpected-fastfetch'
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function Get-Command {
    [CmdletBinding()]
    param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -in @('fastfetch', 'starship')) { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
try {
    $env:STARSHIP_CONFIG = Join-Path $starshipTestRun 'custom [prompt].toml'
    $source = Join-Path $RepositoryRoot 'config\starship\starship.toml'
    Assert-Test ((Resolve-WinuxStarshipConfigPath) -eq $env:STARSHIP_CONFIG) 'Custom path ignored.'
    $original = '# existing custom prompt' + [Environment]::NewLine + 'add_newline = false'
    [IO.File]::WriteAllText($env:STARSHIP_CONFIG, $original)
    $setup = Join-Path $RepositoryRoot 'setup.ps1'
    & $setup -Components Starship -Check
    & $setup -Components Starship -WhatIf
    & (Join-Path $RepositoryRoot 'scripts\install.ps1') -Components Starship -WhatIf
    Assert-Test ([IO.File]::ReadAllText($env:STARSHIP_CONFIG) -ceq $original) 'Dry-run changed configuration.'
    Assert-Test (-not (Test-Path (Join-Path $starshipTestRun 'backups'))) 'Dry-run created backup.'
    & $setup -Components Starship -Confirm:$false
    Assert-Test ((Get-FileHash -LiteralPath $env:STARSHIP_CONFIG).Hash -eq (Get-FileHash $source).Hash) 'Source not applied.'
    $backup = @(Get-ChildItem (Join-Path $starshipTestRun 'backups') -Directory)[0].FullName
    $record = Get-Content (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
    Assert-Test ($record.Status -eq 'Complete' -and $record.Files[0].Existed) 'Backup record incorrect.'
    Assert-Test ([IO.File]::ReadAllText((Join-Path $backup $record.Files[0].BackupFile)) -ceq $original) 'Original not preserved.'
    & $setup -Components Starship -Confirm:$false
    & (Join-Path $RepositoryRoot 'scripts\install.ps1') -Components Starship -Confirm:$false
    Assert-Test (@(Get-ChildItem (Join-Path $starshipTestRun 'backups')).Count -eq 1) 'Reapply created another backup.'
    Assert-Test (-not (Test-Path (Join-Path $starshipTestRun 'unexpected-fastfetch'))) 'Starship applied unrelated files.'
    $env:STARSHIP_CONFIG = Join-Path $starshipTestRun 'new\starship.toml'
    & $setup -Components Starship -Confirm:$false
    Assert-Test ((Get-FileHash -LiteralPath $env:STARSHIP_CONFIG).Hash -eq (Get-FileHash $source).Hash) 'New file not created.'
    $env:STARSHIP_CONFIG = $starshipTestRun
    Assert-Failure { & $setup -Components Starship -Check } 'deve ser um arquivo'
    $env:STARSHIP_CONFIG = 'relative.toml'
    Assert-Failure { & $setup -Components Starship -Check } 'caminho absoluto'
} finally { $env:STARSHIP_CONFIG = $savedConfig }
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); Selection='passed'; CustomDestination='passed'; DryRun='passed'; Backups='passed'; Reapply='passed'; NewFile='passed'; InvalidDestination='passed'} | ConvertTo-Json -Compress
