function Resolve-WinuxStarshipConfigPath {
    param([string]$ConfiguredPath = $env:STARSHIP_CONFIG, [string]$HomePath = $HOME)
    if ($ConfiguredPath) {
        if (-not [IO.Path]::IsPathRooted($ConfiguredPath) -or [IO.Path]::GetPathRoot($ConfiguredPath).Length -lt 3) {
            throw 'Use um caminho absoluto em STARSHIP_CONFIG antes de aplicar o componente Starship.'
        }
        return [IO.Path]::GetFullPath($ConfiguredPath)
    }
    return Join-Path $HomePath '.config\starship.toml'
}
