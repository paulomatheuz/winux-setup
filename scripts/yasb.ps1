function Resolve-WinuxYasbDirectory {
    param([string]$ConfiguredPath = $env:YASB_CONFIG_HOME, [string]$HomePath = $HOME)
    if ($ConfiguredPath) {
        if (-not [IO.Path]::IsPathRooted($ConfiguredPath) -or [IO.Path]::GetPathRoot($ConfiguredPath).Length -lt 3) {
            throw 'Use um caminho absoluto em YASB_CONFIG_HOME.'
        }
        return [IO.Path]::GetFullPath($ConfiguredPath)
    }
    return Join-Path $HomePath '.config\yasb'
}

function Get-WinuxYasbFiles {
    param([Parameter(Mandatory)][string]$SourceDirectory, [string]$DestinationDirectory = (Resolve-WinuxYasbDirectory))
    if ((Test-Path -LiteralPath $DestinationDirectory) -and -not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
        throw "O destino do YASB deve ser uma pasta: $DestinationDirectory"
    }
    $files = @()
    foreach ($name in @('config.yaml', 'styles.css', 'YASB.LICENSE')) {
        $source = Join-Path $SourceDirectory $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Arquivo do YASB nao encontrado: $source" }
        $destination = Join-Path $DestinationDirectory $name
        if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "O destino deve ser um arquivo: $destination"
        }
        $files += @{ SourcePath = $source; Destination = $destination }
    }
    return $files
}
