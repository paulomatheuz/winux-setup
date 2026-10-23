function Get-WinuxBytesHash {
    param([AllowEmptyCollection()][byte[]]$Bytes)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        [BitConverter]::ToString($algorithm.ComputeHash($Bytes)).Replace('-', '')
    } finally {
        $algorithm.Dispose()
    }
}

function Get-WinuxProfileBytes {
    param([Parameter(Mandatory)][string]$Path)
    $ErrorActionPreference = 'Stop'
    [byte[]]$original = @()
    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "O perfil deve ser um arquivo: $Path"
        }
        $original = [IO.File]::ReadAllBytes($Path)
    }

    # Sem BOM, o bloco ASCII funciona tanto com UTF-8 quanto com ANSI.
    $encoding = [Text.Encoding]::UTF8
    if ($original.Length -ge 4 -and $original[0] -eq 255 -and $original[1] -eq 254 -and $original[2] -eq 0 -and $original[3] -eq 0) {
        $encoding = [Text.Encoding]::UTF32
    } elseif ($original.Length -ge 4 -and $original[0] -eq 0 -and $original[1] -eq 0 -and $original[2] -eq 254 -and $original[3] -eq 255) {
        $encoding = New-Object Text.UTF32Encoding($true, $true)
    } elseif ($original.Length -ge 2 -and $original[0] -eq 255 -and $original[1] -eq 254) {
        $encoding = [Text.Encoding]::Unicode
    } elseif ($original.Length -ge 2 -and $original[0] -eq 254 -and $original[1] -eq 255) {
        $encoding = [Text.Encoding]::BigEndianUnicode
    }

    $startMarker = '# >>> custom-windows-terminal >>>'
    $endMarker = '# <<< custom-windows-terminal <<<'
    $text = $encoding.GetString($original)
    $startCount = [regex]::Matches($text, [regex]::Escape($startMarker)).Count
    $endCount = [regex]::Matches($text, [regex]::Escape($endMarker)).Count
    if ($startCount -eq 1 -and $endCount -eq 1 -and $text.IndexOf($startMarker) -lt $text.IndexOf($endMarker)) {
        return ,$original
    }
    if ($startCount -ne 0 -or $endCount -ne 0) {
        throw "O perfil possui marcadores incompletos ou repetidos. Revise antes de continuar: $Path"
    }

    $block = [Environment]::NewLine + $startMarker + [Environment]::NewLine +
        '. "$HOME\.config\fastfetch\custom-windows-terminal-profile.ps1"' +
        [Environment]::NewLine + $endMarker + [Environment]::NewLine
    return ,([byte[]]($original + $encoding.GetBytes($block)))
}

function Save-WinuxConfigurationRecord {
    param([Parameter(Mandatory)]$Record, [Parameter(Mandatory)][string]$Path)
    $temporary = $Path + '.tmp'
    try {
        $encoding = New-Object Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($temporary, ($Record | ConvertTo-Json -Depth 8), $encoding)
        if ([IO.File]::Exists($Path)) {
            [IO.File]::Replace($temporary, $Path, [NullString]::Value)
        } else {
            [IO.File]::Move($temporary, $Path)
        }
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Invoke-WinuxConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable[]]$Files,
        [Parameter(Mandatory)][string]$BackupRoot
    )

    $ErrorActionPreference = 'Stop'
    $changes = @()
    $destinations = @{}
    foreach ($file in $Files) {
        if ([string]::IsNullOrWhiteSpace($file.Destination)) { throw 'Destino nao informado.' }
        $destination = [IO.Path]::GetFullPath($file.Destination)
        if ($destinations.ContainsKey($destination)) { throw "Destino repetido: $destination" }
        $destinations[$destination] = $true
        if ($file.ContainsKey('Bytes')) {
            if ($null -eq $file.Bytes) { throw "Conteudo nao informado: $destination" }
            [byte[]]$desired = $file.Bytes
        } else {
            if (-not (Test-Path -LiteralPath $file.SourcePath -PathType Leaf)) {
                throw ('Arquivo de origem nao encontrado: ' + $file.SourcePath)
            }
            [byte[]]$desired = [IO.File]::ReadAllBytes($file.SourcePath)
        }
        $existed = Test-Path -LiteralPath $destination
        [byte[]]$original = @()
        $originalHash = $null
        if ($existed) {
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                throw "O destino deve ser um arquivo: $destination"
            }
            $original = [IO.File]::ReadAllBytes($destination)
            $originalHash = Get-WinuxBytesHash -Bytes $original
        }
        $desiredHash = Get-WinuxBytesHash -Bytes $desired
        if ($existed -and $originalHash -eq $desiredHash) { continue }
        $changes += [pscustomobject]@{
            Destination = $destination
            Existed = [bool]$existed
            Original = $original
            Bytes = $desired
            OriginalSHA256 = $originalHash
            DesiredSHA256 = $desiredHash
        }
    }

    if ($changes.Count -eq 0) {
        return [pscustomobject]@{ Status = 'Unchanged'; ChangedFiles = 0; BackupPath = $null }
    }
    if (-not $PSCmdlet.ShouldProcess(($changes.Destination -join ', '), 'Salvar backups e aplicar configuracoes')) {
        return [pscustomobject]@{ Status = 'Planned'; ChangedFiles = $changes.Count; BackupPath = $null }
    }

    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [Guid]::NewGuid().ToString('N')
    $runDirectory = Join-Path ([IO.Path]::GetFullPath($BackupRoot)) $runId
    New-Item -ItemType Directory -Path $runDirectory -Force -ErrorAction Stop | Out-Null
    $recordPath = Join-Path $runDirectory 'manifest.json'
    $record = [pscustomobject]@{
        SchemaVersion = 1
        CreatedUtc = [DateTime]::UtcNow.ToString('o')
        Status = 'Preparing'
        Files = @($changes | ForEach-Object {
            [pscustomobject]@{
                Destination = $_.Destination
                Existed = $_.Existed
                BackupFile = $null
                OriginalSHA256 = $_.OriginalSHA256
                DesiredSHA256 = $_.DesiredSHA256
                Status = 'Pending'
            }
        })
    }

    try {
        Save-WinuxConfigurationRecord -Record $record -Path $recordPath
        # Todos os originais sao salvos antes da primeira substituicao.
        for ($index = 0; $index -lt $changes.Count; $index++) {
            if ($changes[$index].Existed) {
                $backupName = '{0:D4}.original' -f $index
                $backupPath = Join-Path $runDirectory $backupName
                [IO.File]::WriteAllBytes($backupPath, $changes[$index].Original)
                if ((Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash -ne $changes[$index].OriginalSHA256) {
                    throw "Falha ao verificar backup: $backupPath"
                }
                $record.Files[$index].BackupFile = $backupName
            }
        }
        $record.Status = 'Applying'
        Save-WinuxConfigurationRecord -Record $record -Path $recordPath

        for ($index = 0; $index -lt $changes.Count; $index++) {
            $change = $changes[$index]
            $existsNow = [IO.File]::Exists($change.Destination)
            if ($existsNow -ne $change.Existed -or
                ($existsNow -and (Get-FileHash -LiteralPath $change.Destination -Algorithm SHA256).Hash -ne $change.OriginalSHA256)) {
                throw ('O destino mudou durante a aplicacao: ' + $change.Destination)
            }
            $parent = Split-Path -Parent $change.Destination
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
            $temporary = Join-Path $parent ('.winux-' + [Guid]::NewGuid().ToString('N') + '.tmp')
            try {
                [IO.File]::WriteAllBytes($temporary, $change.Bytes)
                if ($change.Existed) {
                    [IO.File]::Replace($temporary, $change.Destination, [NullString]::Value)
                } else {
                    [IO.File]::Move($temporary, $change.Destination)
                }
            } finally {
                if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
            }
            $record.Files[$index].Status = 'Applied'
            Save-WinuxConfigurationRecord -Record $record -Path $recordPath
        }
        $record.Status = 'Complete'
        Save-WinuxConfigurationRecord -Record $record -Path $recordPath
    } catch {
        $failure = $_
        $record.Status = 'Failed'
        try { Save-WinuxConfigurationRecord -Record $record -Path $recordPath } catch {
            Write-Warning "Nao foi possivel atualizar o registro em $recordPath"
        }
        throw $failure
    }
    [pscustomobject]@{ Status = 'Applied'; ChangedFiles = $changes.Count; BackupPath = $runDirectory }
}
