function Get-WinuxTerminalIconPath {
    param([string]$HomePath = $HOME)
    return Join-Path $HomePath 'Pictures\winux-setup\terminal.ico'
}

function Get-WinuxVisualAssetFiles {
    param([Parameter(Mandatory)][string]$SourceDirectory, [string]$HomePath = $HOME)
    $ErrorActionPreference = 'Stop'
    $manifest = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $SourceDirectory 'manifest.json')))
    $files = @()
    $seen = @{}
    foreach ($entry in $manifest.Files) {
        if ($entry.Path -notmatch '^(wallpapers/[^\\/]+\.(png|jpg|jpeg)|icons/terminal\.ico)$' -or $entry.SHA256 -notmatch '^[A-Fa-f0-9]{64}$') {
            throw 'Caminho ou SHA256 invalido no manifesto de recursos visuais.'
        }
        if ($seen.ContainsKey($entry.Path)) { throw 'Recurso visual repetido no manifesto.' }
        $seen[$entry.Path] = $true
        $source = Join-Path $SourceDirectory $entry.Path
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Recurso visual nao encontrado: $source" }
        [byte[]]$bytes = [IO.File]::ReadAllBytes($source)
        if ((Get-WinuxBytesHash -Bytes $bytes) -ne $entry.SHA256) { throw "SHA256 diferente do manifesto: $source" }
        $destination = if ($entry.Path -eq 'icons/terminal.ico') {
            Get-WinuxTerminalIconPath -HomePath $HomePath
        } else { Join-Path $HomePath ('Pictures\wallpaper\' + ($entry.Path -replace '^wallpapers/', '')) }
        if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "O destino deve ser um arquivo: $destination"
        }
        $files += @{ Destination = $destination; Bytes = $bytes }
    }
    if (-not $seen.ContainsKey('icons/terminal.ico')) { throw 'O manifesto deve incluir icons/terminal.ico.' }
    return $files
}
