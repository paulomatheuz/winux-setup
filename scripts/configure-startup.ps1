[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Check,
    [string]$StartupDirectory,
    [string]$StateDirectory,
    [ValidateSet('Komorebi', 'Whkd', 'Yasb')][string[]]$ExpectedPrograms = @(),
    [ValidateSet('Komorebi', 'Whkd', 'Yasb')][string[]]$ExpectedComponents = @()
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.' }
if (-not $Check -and ($ExpectedPrograms.Count -gt 0 -or $ExpectedComponents.Count -gt 0)) { throw 'As instalacoes previstas so podem ser informadas junto com -Check.' }
if (-not $StartupDirectory) { $StartupDirectory = [Environment]::GetFolderPath('Startup') }
if (-not $StateDirectory) { $StateDirectory = Join-Path $HOME '.winux-setup\startup' }
foreach ($directory in @($StartupDirectory, $StateDirectory)) {
    if (-not [IO.Path]::IsPathRooted($directory) -or [IO.Path]::GetPathRoot($directory).Length -lt 3) { throw 'Informe diretorios absolutos para a inicializacao.' }
    if ((Test-Path -LiteralPath $directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) { throw "O destino deve ser uma pasta: $directory" }
}
. (Join-Path $PSScriptRoot 'startup.ps1')
. (Join-Path $PSScriptRoot 'configuration.ps1')
$launcherSource = Join-Path $PSScriptRoot 'start-desktop.ps1'
if (-not (Test-Path -LiteralPath $launcherSource -PathType Leaf)) { throw 'O script start-desktop.ps1 nao foi encontrado.' }
$settings = Get-WinuxStartupSettings -ExpectedPrograms $ExpectedPrograms -ExpectedComponents $ExpectedComponents
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if (-not (Test-Path -LiteralPath $powerShell -PathType Leaf)) { throw 'Windows PowerShell nao encontrado para a inicializacao.' }
foreach ($component in @('Komorebi', 'Yasb')) {
    Assert-WinuxStartupShortcut -Path (Join-Path $StartupDirectory ($component.ToLowerInvariant() + '.lnk')) -Component $component
}
Write-Host ('Inicializacao do desktop: ' + $StartupDirectory)
if ($Check) { Write-Host 'Programas, configuracoes e atalhos verificados. Nenhum arquivo foi alterado.'; return }
if (-not $PSCmdlet.ShouldProcess($StartupDirectory, 'Configurar Komorebi com whkd e YASB para o proximo login, com backup')) { return }
$encoding = New-Object Text.UTF8Encoding($false)
$launcher = Join-Path $StateDirectory 'start-desktop.ps1'
$files = @(
    @{SourcePath=$launcherSource; Destination=$launcher}
    @{Destination=(Join-Path $StateDirectory 'startup.json'); Bytes=$encoding.GetBytes((ConvertTo-Json -InputObject $settings -Depth 5) + [Environment]::NewLine)}
)
foreach ($component in @('Komorebi', 'Yasb')) {
    $destination = Join-Path $StartupDirectory ($component.ToLowerInvariant() + '.lnk')
    $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcher + '" -Component ' + $component
    $bytes = New-WinuxStartupShortcutBytes -Destination $destination -Target $powerShell -Arguments $arguments -WorkingDirectory $StateDirectory -Component $component
    $files += @{Destination=$destination; Bytes=$bytes}
}
$result = Invoke-WinuxConfiguration -Files $files -BackupRoot (Join-Path $HOME '.winux-setup\backups') -Confirm:$false
Write-Host ('Inicializacao: ' + $result.Status + '. Nenhum aplicativo foi iniciado.')
if ($result.BackupPath) { Write-Host ('Registro e backup: ' + $result.BackupPath) }
