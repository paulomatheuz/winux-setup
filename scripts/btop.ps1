function Resolve-WinuxBtopDirectory {
    param([string]$Path, [string]$HomePath = $HOME)
    if ($Path) {
        if (-not [IO.Path]::IsPathRooted($Path) -or [IO.Path]::GetPathRoot($Path).Length -lt 3) {
            throw 'Use um caminho absoluto em -BtopDirectory.'
        }
        return [IO.Path]::GetFullPath($Path)
    }
    foreach ($name in @('btop4win', 'btop')) {
        $application = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
        if (-not $application) { continue }
        $item = Get-Item -LiteralPath $application.Source -Force -ErrorAction Stop
        $visited = @{}
        while ($item.LinkType -eq 'SymbolicLink') {
            if ($visited.ContainsKey($item.FullName)) { throw 'Link circular do btop. Informe -BtopDirectory.' }
            $visited[$item.FullName] = $true
            $target = @($item.Target)
            if ($target.Count -ne 1 -or -not $target[0]) { throw 'Link do btop sem destino. Informe -BtopDirectory.' }
            $targetPath = $target[0]
            if (-not [IO.Path]::IsPathRooted($targetPath)) { $targetPath = Join-Path (Split-Path -Parent $item.FullName) $targetPath }
            $item = Get-Item -LiteralPath $targetPath -Force -ErrorAction Stop
        }
        if ($item.Name -ieq 'btop4win.exe') { return Split-Path -Parent $item.FullName }
    }
    $portableRoot = Join-Path $HomePath 'Tools\btop4win'
    foreach ($directory in @((Join-Path $portableRoot 'btop4win'), $portableRoot)) {
        if (Test-Path -LiteralPath (Join-Path $directory 'btop4win.exe') -PathType Leaf) { return $directory }
    }
    if (Test-Path -LiteralPath $portableRoot -PathType Container) {
        $match = Get-ChildItem -LiteralPath $portableRoot -Filter 'btop4win.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName | Select-Object -First 1
        if ($match) { return Split-Path -Parent $match.FullName }
    }
    return Join-Path $portableRoot 'btop4win'
}

function Get-WinuxBtopFiles {
    param([Parameter(Mandatory)][string]$SourceDirectory, [Parameter(Mandatory)][string]$DestinationDirectory)
    if ((Test-Path -LiteralPath $DestinationDirectory) -and -not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
        throw "O destino do btop deve ser uma pasta: $DestinationDirectory"
    }
    $files = @()
    foreach ($relative in @('btop.conf', 'themes\NeutralPurple.theme', 'BTOP.LICENSE')) {
        $source = Join-Path $SourceDirectory $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Arquivo do btop nao encontrado: $source" }
        $destination = Join-Path $DestinationDirectory $relative
        if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "O destino deve ser um arquivo: $destination"
        }
        $files += @{ SourcePath = $source; Destination = $destination }
    }
    return $files
}
