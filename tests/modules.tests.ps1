param(
    [Parameter(Mandatory)][string]$TestRoot,
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference='Stop'
function Assert-Test($Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Assert-Failure([scriptblock]$Action,[string]$Pattern){
    $failed=$false
    try{& $Action | Out-Null}catch{$failed=$true;Assert-Test ($_.Exception.Message -match $Pattern) $_.Exception.Message}
    Assert-Test $failed 'Expected a failure.'
}
$global:taskModuleRoot=Join-Path ([IO.Path]::GetFullPath($TestRoot)) ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $global:taskModuleRoot -Force|Out-Null
$global:taskActualHome=$HOME
$global:taskInstalled=@{}
$global:taskModuleCalls=New-Object 'System.Collections.Generic.List[object]'
$global:taskProviderCalls=0
$global:taskRepositoryCalls=0
$global:taskProviderAvailable=$false
$global:taskRepositoryUrl='https://www.powershellgallery.com/api/v2'
$global:taskInstallFails=$false
$global:taskExposeModule=$true
$global:taskSupportsLicense=$true
$global:taskMissingCommand=''
$global:taskConfigurationTarget=Join-Path $global:taskModuleRoot 'config'
function global:Join-Path{
    param([string]$Path,[string]$ChildPath)
    if($Path -eq $global:taskActualHome -and $ChildPath -eq '.config\fastfetch'){return $global:taskConfigurationTarget}
    if($Path -eq $global:taskActualHome -and $ChildPath -eq '.winux-setup\backups'){return Microsoft.PowerShell.Management\Join-Path $global:taskModuleRoot 'backups'}
    Microsoft.PowerShell.Management\Join-Path $Path $ChildPath
}
function global:Get-Command{
    [CmdletBinding()]param([string[]]$Name,[System.Management.Automation.CommandTypes]$CommandType)
    if($Name -contains $global:taskMissingCommand){return}
    if($Name -contains 'Install-Module'){
        $parameters=@{}
        if($global:taskSupportsLicense){$parameters.AcceptLicense=$null}
        return [pscustomobject]@{Name='Install-Module';Parameters=$parameters}
    }
    if($Name[0] -in @('Get-PackageProvider','Install-PackageProvider','Get-PSRepository')){return [pscustomobject]@{Name=$Name[0]}}
    $arguments=@{Name=$Name;ErrorAction='SilentlyContinue'}
    if($PSBoundParameters.ContainsKey('CommandType')){$arguments.CommandType=$CommandType}
    Microsoft.PowerShell.Core\Get-Command @arguments
}
function global:Get-Module{
    [CmdletBinding()]param([switch]$ListAvailable,[string]$Name)
    if($global:taskInstalled.ContainsKey($Name)){[pscustomobject]@{Name=$Name;Version=[version]$global:taskInstalled[$Name]}}
}
function global:Get-PackageProvider{
    [CmdletBinding()]param([string]$Name,[switch]$ListAvailable)
    if($global:taskProviderAvailable){[pscustomobject]@{Name='NuGet';Version=[version]'2.8.5.201'}}
}
function global:Install-PackageProvider{
    [CmdletBinding(SupportsShouldProcess=$true)]param([string]$Name,[string]$MinimumVersion,[string]$Scope,[switch]$Force)
    Assert-Test ($Name -eq 'NuGet' -and $Scope -eq 'CurrentUser' -and $MinimumVersion -eq '2.8.5.201') 'Unsafe provider arguments.'
    $global:taskProviderCalls++;$global:taskProviderAvailable=$true
}
function global:Get-PSRepository{
    [CmdletBinding()]param([string]$Name)
    $global:taskRepositoryCalls++
    [pscustomobject]@{Name=$Name;SourceLocation=$global:taskRepositoryUrl}
}
function global:Install-Module{
    [CmdletBinding()]param([string]$Name,[string]$RequiredVersion,[string]$Repository,[string]$Scope,[switch]$Force,[switch]$AllowClobber,[switch]$AcceptLicense)
    $global:taskModuleCalls.Add(@{}+$PSBoundParameters)
    Assert-Test ($Repository -eq 'PSGallery' -and $Scope -eq 'CurrentUser') 'Unexpected module source or scope.'
    if($global:taskInstallFails){throw 'Simulated module installation failure'}
    if($global:taskExposeModule){$global:taskInstalled[$Name]=$RequiredVersion}
}
$script=Join-Path $RepositoryRoot 'scripts\install-modules.ps1'
$setup=Join-Path $RepositoryRoot 'setup.ps1'
$tokens=$null;$errors=$null
[System.Management.Automation.Language.Parser]::ParseFile($script,[ref]$tokens,[ref]$errors)|Out-Null
Assert-Test ($errors.Count -eq 0) 'Module script syntax errors.'
& $script -Check
& $script -WhatIf
Assert-Test ($global:taskModuleCalls.Count -eq 0 -and $global:taskProviderCalls -eq 0 -and $global:taskRepositoryCalls -eq 0) 'Check or WhatIf performed an installation or repository lookup.'
Assert-Failure {& $script} 'AcceptAgreements'
Assert-Test ($global:taskProviderCalls -eq 0) 'Provider installed before consent.'
$global:taskMissingCommand='Install-Module'
Assert-Failure {& $script -Check} 'PowerShellGet'
$global:taskMissingCommand=''
& $script -AcceptAgreements
Assert-Test ($global:taskModuleCalls.Count -eq 2 -and $global:taskProviderCalls -eq 1) 'Expected module installation or provider bootstrap is missing.'
Assert-Test ($global:taskModuleCalls[0].RequiredVersion -eq '1.1.14') 'z baseline changed.'
Assert-Test ($global:taskModuleCalls[1].RequiredVersion -eq '2.4.5') 'PSReadLine baseline changed.'
Assert-Test $global:taskModuleCalls[0].AcceptLicense 'License flag missing when supported.'
$before=$global:taskModuleCalls.Count
$global:taskInstalled['PSReadLine']='2.5.0'
& $script -AcceptAgreements
Assert-Test ($global:taskModuleCalls.Count -eq $before) 'Existing compatible modules were reinstalled.'

$global:taskInstalled=@{};$global:taskModuleCalls.Clear()
$global:taskRepositoryUrl='https://example.invalid/api/v2'
Assert-Failure {& $script -AcceptAgreements} 'fonte oficial'
Assert-Test ($global:taskModuleCalls.Count -eq 0) 'Non-official repository was used.'
$global:taskRepositoryUrl='https://www.powershellgallery.com/api/v2/'
$global:taskSupportsLicense=$false
& $script -Modules @('z','z') -AcceptAgreements
Assert-Test ($global:taskModuleCalls.Count -eq 1) 'Duplicate modules were installed.'
Assert-Test (-not $global:taskModuleCalls[0].ContainsKey('AcceptLicense')) 'Unsupported license parameter was passed.'

$global:taskInstalled=@{};$global:taskModuleCalls.Clear();$global:taskSupportsLicense=$true
Assert-Failure {& $setup -Modules z} 'Use -InstallModules'
& $setup -InstallModules -Check
& $setup -InstallModules -WhatIf
Assert-Test ($global:taskModuleCalls.Count -eq 0 -and -not (Test-Path -LiteralPath $global:taskConfigurationTarget)) 'Setup check or simulation changed files.'
$global:taskInstallFails=$true
Assert-Failure {& $setup -InstallModules -AcceptAgreements -SkipProfile} 'Simulated module installation failure'
Assert-Test (-not (Test-Path -LiteralPath $global:taskConfigurationTarget)) 'Failed module install applied configurations.'
$global:taskInstallFails=$false;$global:taskExposeModule=$false
Assert-Failure {& $script -Modules z -AcceptAgreements} 'ainda indisponivel'
$global:taskExposeModule=$true
& $setup -InstallModules -AcceptAgreements -SkipProfile
Assert-Test (Test-Path -LiteralPath (Join-Path $global:taskConfigurationTarget 'custom-windows-terminal-profile.ps1')) 'Setup did not apply the profile after installing modules.'
[pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString();ModuleSelection='passed';CheckAndWhatIf='passed';VersionsAndScope='passed';ProviderBootstrap='passed';ExistingModules='passed';ConsentAndFailures='passed';RootIntegration='passed'}|ConvertTo-Json -Compress
