function Get-WinuxRestoreFiles {
    param([Parameter(Mandatory)][string]$BackupPath)
    $ErrorActionPreference = 'Stop'
    $directory = Get-Item -LiteralPath $BackupPath -ErrorAction Stop
    if (-not $directory.PSIsContainer) { throw 'Informe a pasta que contem o manifest.json do backup.' }
    $manifestPath = Join-Path $directory.FullName 'manifest.json'
    $record = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($manifestPath)) -ErrorAction Stop
    if ($record -isnot [pscustomobject] -or ($record.SchemaVersion -isnot [int] -and $record.SchemaVersion -isnot [long]) -or $record.SchemaVersion -ne 1 -or $record.Status -isnot [string] -or $record.Status -notin @('Complete','Failed','Applying')) { throw 'Manifesto de backup nao suportado ou ainda em preparacao.' }
    if ($record.Files -isnot [array] -or $record.Files.Count -eq 0) { throw 'Manifesto sem lista de arquivos.' }
    $destinations = @{}
    $files = @()
    foreach ($entry in $record.Files) {
        if ($entry -isnot [pscustomobject] -or $entry.Destination -isnot [string] -or [string]::IsNullOrWhiteSpace($entry.Destination) -or
            -not [IO.Path]::IsPathRooted($entry.Destination) -or [IO.Path]::GetPathRoot($entry.Destination).Length -lt 3 -or
            $entry.Existed -isnot [bool] -or $entry.Status -isnot [string] -or $entry.Status -notin @('Pending','Applied')) { throw 'Entrada invalida no manifesto de backup.' }
        $destination = [IO.Path]::GetFullPath($entry.Destination)
        $backupPrefix = $directory.FullName.TrimEnd('\') + '\'
        if ($destination.StartsWith($backupPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'O backup de origem nao pode ser um destino da restauracao.' }
        if ($destinations.ContainsKey($destination)) { throw "Destino repetido no backup: $destination" }
        $destinations[$destination] = $true
        $operation = 'Write'
        if (@($entry.PSObject.Properties.Name) -contains 'Operation') { $operation = $entry.Operation }
        if ($operation -isnot [string] -or $operation -notin @('Write','Remove')) { throw 'Operacao desconhecida no manifesto.' }
        if (($operation -eq 'Write' -and ($entry.DesiredSHA256 -isnot [string] -or $entry.DesiredSHA256 -notmatch '^[a-fA-F0-9]{64}$')) -or
            ($operation -eq 'Remove' -and ($null -ne $entry.DesiredSHA256 -or -not $entry.Existed))) { throw 'Hash do conteudo aplicado invalido.' }
        [byte[]]$original = @()
        if ($entry.Existed) {
            if ($entry.BackupFile -isnot [string] -or $entry.BackupFile -notmatch '^[0-9]{4,}\.original$' -or
                $entry.OriginalSHA256 -isnot [string] -or $entry.OriginalSHA256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'Referencia ou hash do arquivo original invalido.' }
            $originalPath = Join-Path $directory.FullName $entry.BackupFile
            $original = [IO.File]::ReadAllBytes($originalPath)
            if ((Get-WinuxBytesHash -Bytes $original) -ne $entry.OriginalSHA256) { throw "Backup corrompido: $originalPath" }
        } elseif ($null -ne $entry.BackupFile -or $null -ne $entry.OriginalSHA256) { throw 'Arquivo novo com referencia a um original.' }
        $exists = Test-Path -LiteralPath $destination
        $currentHash = $null
        if ($exists) {
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "O destino deve ser um arquivo: $destination" }
            $currentHash = Get-WinuxBytesHash -Bytes ([IO.File]::ReadAllBytes($destination))
        }
        # Uma falha pode ocorrer entre a troca do arquivo e a gravacao do estado.
        # O conteudo atual decide se a entrada foi aplicada ou ja esta restaurada.
        if (($entry.Existed -and $exists -and $currentHash -eq $entry.OriginalSHA256) -or (-not $entry.Existed -and -not $exists)) { continue }
        if ($currentHash -ne $entry.DesiredSHA256) { throw "O arquivo mudou depois do setup; preserve suas edicoes antes de restaurar: $destination" }
        if ($entry.Existed) {
            $files += @{Destination=$destination; Bytes=$original; ExpectedSHA256=$currentHash}
        } else {
            $files += @{Destination=$destination; Remove=$true; ExpectedSHA256=$currentHash}
        }
    }
    return $files
}
