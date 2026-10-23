[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateNotNullOrEmpty()][ValidateSet('z', 'PSReadLine')][string[]]$Modules = @('z', 'PSReadLine'),
    [switch]$Check,
    [switch]$AcceptAgreements
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.'
}
$catalog = Import-PowerShellDataFile -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules.psd1')
$selected = @($catalog.Modules | Where-Object { $_.Name -in $Modules })
if ($selected.Count -eq 0) { throw 'Nenhum modulo selecionado no catalogo.' }
$installCommand = Get-Command Install-Module -ErrorAction SilentlyContinue
if (-not $installCommand) { throw 'Install-Module nao esta disponivel. Instale PowerShellGet antes de continuar.' }
foreach ($command in 'Get-PackageProvider', 'Install-PackageProvider', 'Get-PSRepository') {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Comando necessario nao encontrado: $command" }
}
$providerReady = $false
foreach ($entry in $selected) {
    $installed = @(Get-Module -ListAvailable -Name $entry.Name | Where-Object { $_.Version -ge [version]$entry.MinimumVersion })
    if ($installed.Count -gt 0) {
        Write-Host ($entry.Name + ': versao compativel ja disponivel.')
        continue
    }
    if ($Check) {
        Write-Host ($entry.Name + ': instalar ' + $entry.MinimumVersion + ' para o usuario atual.')
        continue
    }
    if (-not $PSCmdlet.ShouldProcess(($entry.Name + ' ' + $entry.MinimumVersion), 'Instalar modulo da PSGallery para o usuario atual')) { continue }
    if (-not $AcceptAgreements) {
        throw 'Use -AcceptAgreements apos revisar os termos da PSGallery e dos modulos. Nenhum modulo foi instalado.'
    }
    if (-not $providerReady) {
        $nuget = @(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge [version]'2.8.5.201' })
        if ($nuget.Count -eq 0) {
            Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        $repository = Get-PSRepository -Name PSGallery -ErrorAction Stop
        $location = [uri]$repository.SourceLocation
        if ($location.Scheme -ne 'https' -or $location.Host -notin @('www.powershellgallery.com', 'powershellgallery.com') -or $location.AbsolutePath.TrimEnd('/') -ne '/api/v2') {
            throw 'A PSGallery registrada nao aponta para a fonte oficial esperada.'
        }
        $providerReady = $true
    }
    $arguments = @{
        Name = $entry.Name
        RequiredVersion = $entry.MinimumVersion
        Repository = 'PSGallery'
        Scope = 'CurrentUser'
        Force = $true
        AllowClobber = $true
        ErrorAction = 'Stop'
    }
    if ($installCommand.Parameters.ContainsKey('AcceptLicense')) { $arguments.AcceptLicense = $true }
    Install-Module @arguments
    if (-not (Get-Module -ListAvailable -Name $entry.Name | Where-Object { $_.Version -ge [version]$entry.MinimumVersion })) {
        throw ('Modulo ainda indisponivel depois da instalacao: ' + $entry.Name)
    }
    Write-Host ($entry.Name + ': instalado. Abra uma nova sessao para utiliza-lo.')
}
if ($Check) { Write-Host 'Verificacao local concluida, sem downloads nem consulta online.' }
