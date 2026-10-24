function ConvertFrom-WinuxTerminalJson {
    param([Parameter(Mandatory)][string]$Text)
    # Retira comentarios e virgulas finais sem alterar strings JSON.
    $clean = New-Object Text.StringBuilder
    $quoted = $false
    $escaped = $false
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $c = $Text[$i]
        if ($quoted) {
            [void]$clean.Append($c)
            if ($escaped) { $escaped = $false }
            elseif ($c -eq '\') { $escaped = $true }
            elseif ($c -eq '"') { $quoted = $false }
        } elseif ($c -eq '"') {
            $quoted = $true
            [void]$clean.Append($c)
        } elseif ($c -eq '/' -and $i + 1 -lt $Text.Length -and $Text[$i + 1] -eq '/') {
            while ($i -lt $Text.Length -and $Text[$i] -ne "`n") { $i++ }
            [void]$clean.AppendLine()
        } elseif ($c -eq '/' -and $i + 1 -lt $Text.Length -and $Text[$i + 1] -eq '*') {
            $end = $Text.IndexOf('*/', $i + 2)
            if ($end -lt 0) { throw 'Comentario JSON incompleto.' }
            $i = $end + 1
            [void]$clean.Append(' ')
        } else { [void]$clean.Append($c) }
    }
    $text = $clean.ToString()
    $clean.Clear() | Out-Null
    $quoted = $false
    $escaped = $false
    for ($i = 0; $i -lt $text.Length; $i++) {
        $c = $text[$i]
        if ($quoted) {
            [void]$clean.Append($c)
            if ($escaped) { $escaped = $false }
            elseif ($c -eq '\') { $escaped = $true }
            elseif ($c -eq '"') { $quoted = $false }
        } elseif ($c -eq '"') {
            $quoted = $true
            [void]$clean.Append($c)
        } elseif ($c -eq ',') {
            $next = $i + 1
            while ($next -lt $text.Length -and [char]::IsWhiteSpace($text[$next])) { $next++ }
            if ($next -ge $text.Length -or $text[$next] -notin @('}', ']')) { [void]$clean.Append($c) }
        } else { [void]$clean.Append($c) }
    }
    $value = ConvertFrom-Json -InputObject $clean.ToString() -ErrorAction Stop
    if ($value -isnot [pscustomobject]) { throw 'A configuracao do Terminal deve ser um objeto JSON.' }
    return $value
}

function Set-WinuxTerminalProperty {
    param($Target, [string]$Name, $Value)
    $property = $Target.PSObject.Properties[$Name]
    if ($property) { $property.Value = $Value }
    else { $Target | Add-Member NoteProperty $Name $Value }
}

function Merge-WinuxTerminalObject {
    param($Target, $Source)
    foreach ($property in $Source.PSObject.Properties) {
        $existing = $Target.PSObject.Properties[$property.Name]
        if ($property.Value -is [pscustomobject]) {
            if ($existing -and $existing.Value -isnot [pscustomobject]) {
                throw ('Objeto JSON esperado: ' + $property.Name)
            }
            if (-not $existing) { $Target | Add-Member NoteProperty $property.Name ([pscustomobject]@{}) }
            Merge-WinuxTerminalObject $Target.($property.Name) $property.Value
        } else {
            Set-WinuxTerminalProperty $Target $property.Name $property.Value
        }
    }
}

function Resolve-WinuxTerminalSettingsPath {
    param([string]$Path, [string]$LocalAppData = $env:LOCALAPPDATA)
    if ($Path) { return [IO.Path]::GetFullPath($Path) }
    if (-not $LocalAppData) { throw 'Informe -TerminalSettingsPath.' }
    $candidates = @(
        'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
        'Packages\Microsoft.WindowsTerminalCanary_8wekyb3d8bbwe\LocalState\settings.json'
        'Microsoft\Windows Terminal\settings.json'
    ) | ForEach-Object { Join-Path $LocalAppData $_ }
    $existing = @($candidates | Where-Object { Test-Path -LiteralPath $_ })
    if ($existing.Count -gt 1) { throw 'Mais de uma configuracao do Terminal encontrada. Informe -TerminalSettingsPath.' }
    if ($existing.Count -eq 1) { return $existing[0] }
    return $candidates[0]
}

function Get-WinuxTerminalKey {
    param([string]$Keys)
    return (($Keys.ToLowerInvariant() -replace '\s', '' -split '\+' | Sort-Object) -join '+')
}

function New-WinuxTerminalConfiguration {
    param([Parameter(Mandatory)][string]$SourcePath, [Parameter(Mandatory)][string]$Destination, [string]$IconPath)
    $ErrorActionPreference = 'Stop'
    $source = ConvertFrom-WinuxTerminalJson ([IO.File]::ReadAllText($SourcePath))
    if ($IconPath) {
        $iconProfile = @($source.profiles.list | Where-Object { [guid]$_.guid -eq [guid]'61c54bbd-c2c6-5271-96e7-009a87ff44bf' })
        if ($iconProfile.Count -ne 1) { throw 'Perfil integrado do PowerShell nao encontrado para aplicar o icone.' }
        Set-WinuxTerminalProperty $iconProfile[0] 'icon' $IconPath
    }
    $hash = $null
    [byte[]]$original = @()
    $target = [pscustomobject]@{}
    if (Test-Path -LiteralPath $Destination) {
        $original = [IO.File]::ReadAllBytes($Destination)
        $hash = Get-WinuxBytesHash $original
        # StreamReader detecta BOM UTF-8/UTF-16/UTF-32, sem reler o destino.
        $stream = New-Object IO.MemoryStream(,$original)
        $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8, $true)
        try { $target = ConvertFrom-WinuxTerminalJson $reader.ReadToEnd() }
        finally { $reader.Dispose(); $stream.Dispose() }
    }
    $before = ConvertTo-Json -InputObject $target -Depth 100 -Compress -WarningAction Stop
    foreach ($name in @('profiles', 'schemes', 'keybindings')) {
        $property = $target.PSObject.Properties[$name]
        if ($property -and (($name -eq 'profiles' -and $property.Value -isnot [pscustomobject]) -or
            ($name -ne 'profiles' -and $property.Value -isnot [array]))) {
            throw "Estrutura JSON invalida: $name"
        }
    }
    $preferences = [pscustomobject]@{}
    foreach ($name in @('copyFormatting', 'copyOnSelect', 'theme', 'useAcrylicInTabRow')) {
        $preferences | Add-Member NoteProperty $name $source.$name
    }
    if (-not $target.PSObject.Properties['$schema']) { $preferences | Add-Member NoteProperty '$schema' $source.'$schema' }
    Merge-WinuxTerminalObject $target $preferences
    Merge-WinuxTerminalObject $target ([pscustomobject]@{profiles = [pscustomobject]@{defaults = $source.profiles.defaults}})
    if ($target.profiles.PSObject.Properties['list'] -and $target.profiles.list -isnot [array]) { throw 'profiles.list deve ser uma lista.' }
    $profiles = @($target.profiles.list | Where-Object { $null -ne $_ })
    foreach ($profile in $source.profiles.list) {
        $matches = @($profiles | Where-Object { $_.guid -and ([guid]$_.guid -eq [guid]$profile.guid) })
        if ($matches.Count -gt 1) { throw 'GUID de perfil repetido.' }
        if ($matches.Count -eq 0) { $profiles += $profile }
        else { Merge-WinuxTerminalObject $matches[0] $profile }
    }
    Set-WinuxTerminalProperty $target.profiles 'list' $profiles
    $schemes = @($target.schemes | Where-Object { $null -ne $_ })
    foreach ($scheme in $source.schemes) {
        $matches = @($schemes | Where-Object { $_.name -ceq $scheme.name })
        if ($matches.Count -gt 1) { throw 'Nome de esquema repetido.' }
        if ($matches.Count -eq 0) { $schemes += $scheme }
        else { Merge-WinuxTerminalObject $matches[0] $scheme }
    }
    Set-WinuxTerminalProperty $target 'schemes' $schemes
    $bindings = @($target.keybindings | Where-Object { $null -ne $_ })
    foreach ($binding in $source.keybindings) {
        $key = Get-WinuxTerminalKey $binding.keys
        $remaining = @()
        foreach ($existing in $bindings) {
            $keys = @($existing.keys | Where-Object { (Get-WinuxTerminalKey $_) -ne $key })
            if ($keys.Count -eq @($existing.keys).Count) { $remaining += $existing }
            elseif ($keys.Count -gt 0) {
                Set-WinuxTerminalProperty $existing 'keys' $keys
                $remaining += $existing
            }
        }
        $bindings = $remaining
        $bindings += $binding
    }
    Set-WinuxTerminalProperty $target 'keybindings' $bindings
    $after = ConvertTo-Json -InputObject $target -Depth 100 -Compress -WarningAction Stop
    [byte[]]$bytes = $original
    if (-not $hash -or $before -cne $after) {
        $encoding = New-Object Text.UTF8Encoding($false)
        $bytes = $encoding.GetBytes((ConvertTo-Json -InputObject $target -Depth 100 -WarningAction Stop) + [Environment]::NewLine)
    }
    return @{ Destination = $Destination; Bytes = $bytes; ExpectedSHA256 = $hash }
}
