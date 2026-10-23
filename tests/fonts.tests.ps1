param([Parameter(Mandatory)][string]$TestRoot, [string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
function Assert-Test($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
. (Join-Path $RepositoryRoot 'scripts\fonts.ps1')
$catalogPath = Join-Path $RepositoryRoot 'fonts.psd1'
$names = @('JetBrainsMonoNL NFP', 'JetBrainsMono Nerd Font Propo', 'Segoe UI', 'Segoe Fluent Icons')
$report = @(Get-WinuxFontReport -AvailableNames $names -CatalogPath $catalogPath)
Assert-Test ($report.Count -eq 5) 'Incomplete font report.'
Assert-Test (@($report | Where-Object { -not $_.Optional -and -not $_.Available }).Count -eq 0) 'Valid aliases not recognized.'
$bar = @($report | Where-Object Optional)[0]
Assert-Test (-not $bar.Available -and $bar.ConfiguredName -eq 'JetBrains Mono') 'Patched family confused with original family.'
$empty = @(Get-WinuxFontReport -AvailableNames @() -CatalogPath $catalogPath)
Assert-Test (@($empty | Where-Object Available).Count -eq 0) 'Empty input queried real fonts.'
$differentWidth = @(Get-WinuxFontReport -AvailableNames @('JetBrainsMono NFM', 'JetBrainsMonoNL NFM') -CatalogPath $catalogPath)
Assert-Test (@($differentWidth | Where-Object Available).Count -eq 0) 'Mono variant confused with Propo variant.'
$original = @(Get-WinuxFontReport -AvailableNames @('JetBrains Mono') -CatalogPath $catalogPath)
Assert-Test (@($original | Where-Object Available).Count -eq 1 -and @($original | Where-Object Available)[0].Optional) 'Original family aliased incorrectly.'
$run = Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($run) | Out-Null
$fontTestCalls = New-Object 'System.Collections.Generic.List[object]'
$fontTestNames = @()
function New-Object {
    [CmdletBinding()] param([string]$TypeName)
    if ($TypeName -eq 'System.Drawing.Text.InstalledFontCollection') {
        $collection = [pscustomobject]@{Families=@($fontTestNames | ForEach-Object { [pscustomobject]@{Name=$_} })}
        $collection | Add-Member ScriptMethod Dispose {}
        return $collection
    }
    Microsoft.PowerShell.Utility\New-Object -TypeName $TypeName
}
function Get-Command {
    [CmdletBinding()] param([string]$Name, [System.Management.Automation.CommandTypes]$CommandType)
    if ($Name -eq 'winget') { return [pscustomobject]@{Source='Invoke-TestWinget'} }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
function Invoke-TestWinget {
    $fontTestCalls.Add(@($args))
    $global:LASTEXITCODE = 0
}
$installer = Join-Path $RepositoryRoot 'scripts\install-programs.ps1'
& $installer -Programs JetBrainsMonoNerdFont -Check
& $installer -Programs JetBrainsMonoNerdFont -WhatIf
Assert-Test ($fontTestCalls.Count -eq 0) 'Dry run invoked WinGet.'
$savedPath = $env:PATH
try {
    & $installer -Programs JetBrainsMonoNerdFont -AcceptAgreements -Confirm:$false
    Assert-Test ($fontTestCalls.Count -eq 1) 'Unexpected installation calls.'
    foreach ($argument in @('DEVCOM.JetBrainsMonoNerdFont', '--exact', '--source', 'winget', '--version', '3.3.0', '--no-upgrade', '--silent', '--accept-source-agreements', '--accept-package-agreements')) {
        Assert-Test ($fontTestCalls[0] -contains $argument) ('Missing WinGet argument: ' + $argument)
    }
    $fontTestNames = @('JetBrainsMonoNL NFP', 'JetBrainsMono NFP')
    & $installer -Programs JetBrainsMonoNerdFont -Confirm:$false
    Assert-Test ($fontTestCalls.Count -eq 1) 'Manual font installation was not preserved.'
    $fontTestNames = @('JetBrainsMono NFP')
    & $installer -Programs JetBrainsMonoNerdFont -Confirm:$false
    Assert-Test ($fontTestCalls.Count -eq 2) 'Partial font installation skipped required family.'
} finally { $env:PATH = $savedPath }
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString(); FontAliases='passed'; MissingFamilies='passed'; DistinctVariants='passed'; OptionalBar='passed'; DryRun='passed'; SimulatedInstallation='passed'} | ConvertTo-Json -Compress
