function Resolve-WinuxDevicePath {
    param($Value, [string]$BaseDirectory)
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) { throw 'Informe um caminho de texto nao vazio no dispositivo.' }
    if ([IO.Path]::IsPathRooted($Value)) {
        if ([IO.Path]::GetPathRoot($Value).Length -lt 3) { throw 'Use um caminho absoluto completo ou relativo ao arquivo do dispositivo.' }
        return [IO.Path]::GetFullPath($Value)
    }
    if ($Value.Contains(':')) { throw 'Use um caminho absoluto completo ou relativo ao arquivo do dispositivo.' }
    return [IO.Path]::GetFullPath((Join-Path $BaseDirectory $Value))
}

function Read-WinuxDeviceConfiguration {
    param([Parameter(Mandatory)][string]$Path)
    $ErrorActionPreference = 'Stop'
    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($file.PSIsContainer) { throw 'A configuracao do dispositivo deve ser um arquivo JSON.' }
    $settings = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($file.FullName)) -ErrorAction Stop
    if ($settings -isnot [pscustomobject]) { throw 'Objeto JSON esperado na configuracao do dispositivo.' }
    $allowed = @('SchemaVersion','Components','TerminalSettingsPath','BtopDirectory','ConfigDirectories')
    foreach ($property in $settings.PSObject.Properties) {
        if ($property.Name -notin $allowed) { throw "Opcao desconhecida no dispositivo: $($property.Name)" }
        if ($null -eq $property.Value) { throw "Valor nulo no dispositivo: $($property.Name)" }
    }
    if (($settings.SchemaVersion -isnot [int] -and $settings.SchemaVersion -isnot [long]) -or $settings.SchemaVersion -ne 1) { throw 'Use SchemaVersion 1 na configuracao do dispositivo.' }
    $result = @{}
    $properties = @($settings.PSObject.Properties.Name)
    if ($properties -contains 'Components') {
        $valid = @('Fastfetch','PowerShell','WindowsTerminal','Starship','Komorebi','Yasb','Whkd','Btop','VisualAssets')
        if ($settings.Components -isnot [array] -or $settings.Components.Count -eq 0) { throw 'Components deve ser uma lista nao vazia.' }
        foreach ($component in $settings.Components) {
            if ($component -isnot [string] -or $component -notin $valid) { throw "Componente desconhecido no dispositivo: $component" }
        }
        $result.Components = @($settings.Components | Select-Object -Unique)
    }
    foreach ($name in @('TerminalSettingsPath','BtopDirectory')) {
        if ($properties -contains $name) { $result[$name] = Resolve-WinuxDevicePath -Value $settings.$name -BaseDirectory $file.DirectoryName }
    }
    $result.ConfigDirectories = @{}
    if ($properties -contains 'ConfigDirectories') {
        if ($settings.ConfigDirectories -isnot [pscustomobject]) { throw 'ConfigDirectories deve ser um objeto JSON.' }
        foreach ($property in $settings.ConfigDirectories.PSObject.Properties) {
            if ($property.Name -notin @('Komorebi','Yasb','Whkd','Btop')) { throw "Pasta de configuracao desconhecida: $($property.Name)" }
            $directory = Resolve-WinuxDevicePath -Value $property.Value -BaseDirectory $file.DirectoryName
            if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw "Pasta de configuracao nao encontrada: $directory" }
            $result.ConfigDirectories[$property.Name] = $directory
        }
    }
    return $result
}
