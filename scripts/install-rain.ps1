[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Check,
    [ValidateNotNullOrEmpty()][string]$DestinationDirectory,
    [ValidateSet('x64', 'arm64')][string]$Architecture
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.'
}
if (-not $DestinationDirectory) { $DestinationDirectory = Join-Path $HOME 'Tools\matrix-rain' }
if (-not [IO.Path]::IsPathRooted($DestinationDirectory) -or [IO.Path]::GetPathRoot($DestinationDirectory).Length -lt 3) {
    throw 'Use um caminho absoluto em -DestinationDirectory.'
}
$DestinationDirectory = [IO.Path]::GetFullPath($DestinationDirectory)
if (-not $Architecture) {
    $nativeArchitecture = $env:PROCESSOR_ARCHITEW6432
    if (-not $nativeArchitecture) { $nativeArchitecture = $env:PROCESSOR_ARCHITECTURE }
    switch ($nativeArchitecture) {
        'AMD64' { $Architecture = 'x64' }
        'ARM64' { $Architecture = 'arm64' }
        default { throw 'matrix-rain requer Windows x64 ou ARM64. Informe -Architecture se necessario.' }
    }
}
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$catalog = Import-PowerShellDataFile -LiteralPath (Join-Path $repositoryRoot 'portable-programs.psd1')
$asset = $catalog.Rain.Assets[$Architecture]
if (-not $asset -or $asset.SHA256 -notmatch '^[a-fA-F0-9]{64}$' -or
    $asset.Url -notmatch '^https://github\.com/smford/matrix-rain/releases/download/v[0-9.]+/matrix-rain_[0-9.]+_windows_(amd64|arm64)\.zip$') {
    throw 'Entrada invalida no catalogo portatil do matrix-rain.'
}
. (Join-Path $PSScriptRoot 'configuration.ps1')
$backupRoot = Join-Path $HOME '.winux-setup\backups'
if ((Test-Path -LiteralPath $DestinationDirectory) -and -not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
    throw "O destino do matrix-rain deve ser uma pasta: $DestinationDirectory"
}
$executable = Join-Path $DestinationDirectory 'matrix-rain.exe'
if ((Get-Command matrix-rain -CommandType Application -ErrorAction SilentlyContinue) -or
    (Test-Path -LiteralPath $executable -PathType Leaf)) {
    Write-Host 'matrix-rain: instalacao existente preservada.'
    return
}
foreach ($name in @('matrix-rain.exe', 'README.md', 'LICENSE')) {
    $path = Join-Path $DestinationDirectory $name
    if ((Test-Path -LiteralPath $path) -and -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "O destino deve ser um arquivo: $path" }
}
Write-Host ('matrix-rain ' + $catalog.Rain.Version + ' (' + $Architecture + '): ' + $DestinationDirectory)
if ($Check) {
    Write-Host 'Catalogo e destino verificados. Nenhum download ou instalacao foi executado.'
    return
}
if (-not $PSCmdlet.ShouldProcess($DestinationDirectory, 'Baixar matrix-rain, verificar SHA256 e instalar sem substituir executavel existente')) { return }
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path $temporaryBase ('winux-rain-' + [guid]::NewGuid().ToString('N'))))
try {
    [IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    $archivePath = Join-Path $temporaryRoot 'release.zip'
    Invoke-WebRequest -Uri $asset.Url -OutFile $archivePath -UseBasicParsing -ErrorAction Stop | Out-Null
    if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $asset.SHA256) {
        throw 'O SHA256 do matrix-rain nao corresponde ao catalogo. Nenhum arquivo foi instalado.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    $files = @()
    try {
        # Nomes do ZIP nunca viram destinos; le apenas os tres arquivos esperados.
        foreach ($name in @('matrix-rain.exe', 'README.md', 'LICENSE')) {
            $entries = @($archive.Entries | Where-Object { $_.FullName -ieq $name })
            if ($entries.Count -ne 1 -or $entries[0].Length -eq 0) { throw "Arquivo ausente, vazio ou repetido no ZIP: $name" }
            $sourcePath = Join-Path $temporaryRoot $name
            $inputStream = $entries[0].Open()
            $outputStream = [IO.File]::Create($sourcePath)
            try { $inputStream.CopyTo($outputStream) }
            finally { $outputStream.Dispose(); $inputStream.Dispose() }
            $file = @{ SourcePath = $sourcePath; Destination = (Join-Path $DestinationDirectory $name) }
            if ($name -eq 'matrix-rain.exe') { $file.ExpectedSHA256 = $null }
            $files += $file
        }
    } finally { $archive.Dispose() }
    $result = Invoke-WinuxConfiguration -Files $files -BackupRoot $backupRoot -Confirm:$false
    Write-Host ('matrix-rain instalado. Registro e backups: ' + $result.BackupPath)
} finally {
    # Confere a pasta exclusiva antes da limpeza recursiva.
    if ([IO.Path]::GetDirectoryName($temporaryRoot) -eq $temporaryBase -and
        [IO.Path]::GetFileName($temporaryRoot) -match '^winux-rain-[a-f0-9]{32}$' -and
        (Test-Path -LiteralPath $temporaryRoot -PathType Container)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
