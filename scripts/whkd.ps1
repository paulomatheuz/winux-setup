function Resolve-WinuxWhkdDirectory {
    param([string]$ConfiguredPath = $env:WHKD_CONFIG_HOME, [string]$HomePath = $HOME)
    if ($ConfiguredPath) {
        if (-not [IO.Path]::IsPathRooted($ConfiguredPath) -or [IO.Path]::GetPathRoot($ConfiguredPath).Length -lt 3) {
            throw 'Use um caminho absoluto em WHKD_CONFIG_HOME.'
        }
        return [IO.Path]::GetFullPath($ConfiguredPath)
    }
    return Join-Path $HomePath '.config'
}

function Get-WinuxWhkdFiles {
    param([Parameter(Mandatory)][string]$SourceDirectory, [string]$DestinationDirectory = (Resolve-WinuxWhkdDirectory))
    if ((Test-Path -LiteralPath $DestinationDirectory) -and -not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
        throw "O destino do whkd deve ser uma pasta: $DestinationDirectory"
    }
    $source = Join-Path $SourceDirectory 'whkdrc'
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Arquivo do whkd nao encontrado: $source" }
    $destination = Join-Path $DestinationDirectory 'whkdrc'
    if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
        throw "O destino deve ser um arquivo: $destination"
    }
    return @{ SourcePath = $source; Destination = $destination }
}
