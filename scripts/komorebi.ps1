function Resolve-WinuxKomorebiDirectory {
    param([string]$ConfiguredPath = $env:KOMOREBI_CONFIG_HOME, [string]$HomePath = $HOME)
    if ($ConfiguredPath) {
        if (-not [IO.Path]::IsPathRooted($ConfiguredPath) -or [IO.Path]::GetPathRoot($ConfiguredPath).Length -lt 3) {
            throw 'Use um caminho absoluto em KOMOREBI_CONFIG_HOME.'
        }
        return [IO.Path]::GetFullPath($ConfiguredPath)
    }
    return $HomePath
}

function Get-WinuxKomorebiFiles {
    param(
        [Parameter(Mandatory)][string]$SourceDirectory,
        [string]$DestinationDirectory = (Resolve-WinuxKomorebiDirectory)
    )
    $ErrorActionPreference = 'Stop'
    if ((Test-Path -LiteralPath $DestinationDirectory) -and -not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
        throw "O destino do Komorebi deve ser uma pasta: $DestinationDirectory"
    }
    $configuration = $null
    foreach ($name in @('komorebi.json', 'komorebi.bar.json', 'applications.json', 'applications.LICENSE')) {
        $source = Join-Path $SourceDirectory $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Arquivo do Komorebi nao encontrado: $source" }
        $destination = Join-Path $DestinationDirectory $name
        if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "O destino deve ser um arquivo: $destination"
        }
        if ($name -ne 'applications.LICENSE') {
            $parsed = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($source)) -ErrorAction Stop
            if ($parsed -isnot [pscustomobject]) { throw "Objeto JSON esperado: $source" }
            if ($name -eq 'komorebi.json') { $configuration = $parsed }
        }
    }
    # O caminho e gerado no dispositivo; o arquivo versionado preserva a origem pessoal.
    $configuration.app_specific_configuration_path = Join-Path $DestinationDirectory 'applications.json'
    $encoding = New-Object Text.UTF8Encoding($false)
    $bytes = $encoding.GetBytes((ConvertTo-Json -InputObject $configuration -Depth 100 -WarningAction Stop) + [Environment]::NewLine)
    @{ Destination = (Join-Path $DestinationDirectory 'komorebi.json'); Bytes = $bytes }
    foreach ($name in @('komorebi.bar.json', 'applications.json', 'applications.LICENSE')) {
        @{ SourcePath = (Join-Path $SourceDirectory $name); Destination = (Join-Path $DestinationDirectory $name) }
    }
}
