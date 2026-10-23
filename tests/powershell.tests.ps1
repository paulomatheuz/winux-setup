param(
    [Parameter(Mandatory)][string]$TestRoot,
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = 'Stop'
function Assert-Test($Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Assert-Failure([scriptblock]$Action,[string]$Pattern){
    $failed=$false
    try{& $Action | Out-Null}catch{$failed=$true;Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message}
    Assert-Test $failed 'Expected a failure.'
}
$global:taskProfileRoot=Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $global:taskProfileRoot -Force | Out-Null
$global:taskActualHome=$HOME
$global:taskOptional=$false
$global:taskTools=$false
$global:taskZFails=$false
$global:taskFastfetchCalls=New-Object 'System.Collections.Generic.List[object]'
$global:taskLsdCalls=New-Object 'System.Collections.Generic.List[object]'
$global:taskReadlineCalls=New-Object 'System.Collections.Generic.List[object]'
$global:taskZCalls=0
$global:taskClears=0
function global:Join-Path{
    param([string]$Path,[string]$ChildPath)
    if($Path -eq $global:taskActualHome -and $ChildPath -like 'Tools\*'){
        return Microsoft.PowerShell.Management\Join-Path $global:taskProfileRoot $ChildPath
    }
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function global:Get-Command{
    [CmdletBinding()]param([string[]]$Name,[System.Management.Automation.CommandTypes]$CommandType)
    if($Name -contains 'gh'){return [pscustomobject]@{Source='gh-test-only'}}
    if($Name -contains 'btop4win'){if($global:taskTools){return [pscustomobject]@{Source='Invoke-TestBtop'}};return}
    if($Name -contains 'matrix-rain'){if($global:taskTools){return [pscustomobject]@{Source='Invoke-TestRain'}};return}
    if($Name[0] -in @('fastfetch','starship','lsd','z','Set-PSReadLineOption','Set-PSReadLineKeyHandler')){
        if($global:taskOptional){return [pscustomobject]@{Source=$Name[0]}}
        return
    }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
function global:Get-Module{param([switch]$ListAvailable,[string]$Name);if($global:taskOptional){[pscustomobject]@{Name=$Name;Version=[version]'2.4.5'}}}
function global:Import-Module{param([string]$Name,[string]$ErrorAction)}
function global:Clear-Host{$global:taskClears++}
function global:fastfetch{$global:taskFastfetchCalls.Add(@($args))}
function global:starship{'function prompt { "test> " }'}
function global:lsd{$global:taskLsdCalls.Add(@($args))}
function global:Set-PSReadLineOption{$global:taskReadlineCalls.Add(@($args))}
function global:Set-PSReadLineKeyHandler{$global:taskReadlineCalls.Add(@($args))}
function global:Invoke-TestBtop{$global:taskBtopArguments=@($args)}
function global:Invoke-TestRain{$global:taskRainArguments=@($args)}
function global:z{
    param([string]$Path)
    $global:taskZCalls++
    if($global:taskZFails){throw 'z unavailable'}
    Microsoft.PowerShell.Management\Set-Location -LiteralPath $Path
}
$profilePath=Join-Path $RepositoryRoot 'config\powershell\profile.ps1'
$tokens=$null;$parseErrors=$null
[System.Management.Automation.Language.Parser]::ParseFile($profilePath,[ref]$tokens,[ref]$parseErrors)|Out-Null
Assert-Test ($parseErrors.Count -eq 0) 'Profile syntax errors.'
. $profilePath
Assert-Test ($global:taskFastfetchCalls.Count -eq 0) 'Startup ran unavailable Fastfetch.'
Assert-Failure {btop} 'btop4win nao foi encontrado'
Assert-Failure {rain} 'matrix-rain nao foi encontrado'

$folder=Join-Path $global:taskProfileRoot 'folder[1]'
New-Item -ItemType Directory -Path $folder | Out-Null
$previousLocation=(Microsoft.PowerShell.Management\Get-Location).Path
try{
    cd $folder | Out-Null
    Assert-Test ((Microsoft.PowerShell.Management\Get-Location).Path -eq $folder) 'cd fallback did not preserve literal path.'
}finally{Microsoft.PowerShell.Management\Set-Location -LiteralPath $previousLocation}

$global:taskOptional=$true
. $profilePath
Assert-Test ($global:taskFastfetchCalls.Count -eq 1) 'Startup did not run available Fastfetch.'
Assert-Test ($global:taskReadlineCalls.Count -ge 4) 'Readline options missing.'
$logo=Join-Path $global:taskProfileRoot 'alternate-logo.txt'
winuxt $logo
Clear-Terminal
Assert-Test ($global:taskFastfetchCalls[1] -contains $logo) 'Temporary logo was not preserved.'
ls '--test';ll '--test';la '--test'
Assert-Test ($global:taskLsdCalls.Count -eq 3) 'lsd wrappers were not used.'
Assert-Test ($global:taskLsdCalls[1] -contains '-l') 'll did not request long output.'
Assert-Test ($global:taskLsdCalls[2] -contains '-la') 'la did not request hidden files.'
try{
    cd $folder | Out-Null
    Assert-Test ($global:taskZCalls -eq 1) 'cd did not use z.'
    $global:taskZFails=$true
    cd $folder | Out-Null
    Assert-Test ((Microsoft.PowerShell.Management\Get-Location).Path -eq $folder) 'cd did not recover after z failed.'
}finally{Microsoft.PowerShell.Management\Set-Location -LiteralPath $previousLocation}

$global:taskTools=$true
btop '--help'
Assert-Test ($global:taskBtopArguments -contains '--help') 'btop lost arguments.'
rain
Assert-Test ($global:taskRainArguments[-1] -eq 0.3) 'rain default speed changed.'
foreach($value in @('-color','white','-charset','matrix','-density',25,'-fps',60,'-speed')){
    Assert-Test ($global:taskRainArguments -contains $value) ('rain argument missing: '+$value)
}
rain 0.8
Assert-Test ($global:taskRainArguments[-1] -eq 0.8) 'rain did not forward speed.'

$global:taskTools=$false
$portableRoot=Join-Path $global:taskProfileRoot 'portable'
$nested=Join-Path $portableRoot 'nested'
New-Item -ItemType Directory -Path $nested -Force | Out-Null
$candidate=Join-Path $nested 'btop4win.exe'
[IO.File]::WriteAllBytes($candidate,[byte[]](0))
Assert-Test ((Find-WinuxExecutable -Command btop4win -Candidates @($candidate)) -eq $candidate) 'Portable candidate was not found.'
Assert-Test ((Find-WinuxExecutable -Command btop4win -SearchRoot $portableRoot -FileName 'btop4win.exe') -eq $candidate) 'Nested portable executable was not found.'
$global:taskTools=$true
Assert-Test ((Find-WinuxExecutable -Command btop4win -Candidates @($candidate)) -eq 'Invoke-TestBtop') 'PATH did not take priority.'
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString();OptionalDependencies='passed';Navigation='passed';TerminalCommands='passed';PortableTools='passed';RainParameters='passed'}|ConvertTo-Json -Compress
