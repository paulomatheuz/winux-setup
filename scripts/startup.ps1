function Get-WinuxStartupSettings {
    param([string[]]$ExpectedPrograms = @(), [string[]]$ExpectedComponents = @())
    $ErrorActionPreference = 'Stop'
    $executables = [ordered]@{}
    foreach ($name in @('Komorebi', 'Whkd', 'Yasb')) {
        $commands = switch ($name) { 'Komorebi' { @('komorebic-no-console', 'komorebic') }; 'Whkd' { @('whkd') }; 'Yasb' { @('yasb') } }
        $path = $null
        foreach ($command in $commands) {
            $application = Get-Command $command -CommandType Application -ErrorAction SilentlyContinue
            if ($application) {
                $path = $application.Path
                if (-not $path) { $path = $application.Source }
                break
            }
        }
        if (-not $path -and $ExpectedPrograms -notcontains $name) { throw "Programa necessario para inicializacao nao encontrado: $name" }
        $executables[$name] = $path
    }
    $homes = [ordered]@{
        Komorebi = if ($env:KOMOREBI_CONFIG_HOME) { $env:KOMOREBI_CONFIG_HOME } else { $HOME }
        Whkd = if ($env:WHKD_CONFIG_HOME) { $env:WHKD_CONFIG_HOME } else { Join-Path $HOME '.config' }
        Yasb = if ($env:YASB_CONFIG_HOME) { $env:YASB_CONFIG_HOME } else { Join-Path $HOME '.config\yasb' }
    }
    foreach ($name in @('Komorebi', 'Whkd', 'Yasb')) {
        if (-not [IO.Path]::IsPathRooted($homes[$name]) -or [IO.Path]::GetPathRoot($homes[$name]).Length -lt 3) { throw "Use um diretorio de configuracao absoluto para $name." }
        $homes[$name] = [IO.Path]::GetFullPath($homes[$name])
        $required = switch ($name) { 'Komorebi' { @('komorebi.json') }; 'Whkd' { @('whkdrc') }; 'Yasb' { @('config.yaml', 'styles.css') } }
        foreach ($file in $required) {
            $path = Join-Path $homes[$name] $file
            if (-not (Test-Path -LiteralPath $path -PathType Leaf) -and $ExpectedComponents -notcontains $name) { throw "Configuracao necessaria para inicializacao nao encontrada: $path" }
        }
    }
    return [ordered]@{ SchemaVersion = 1; Executables = $executables; ConfigHomes = $homes }
}

function Assert-WinuxStartupShortcut {
    param([string]$Path, [ValidateSet('Komorebi', 'Yasb')][string]$Component)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "O atalho deve ser um arquivo: $Path" }
    $shell = New-Object -ComObject WScript.Shell
    $link = $null
    try {
        $link = $shell.CreateShortcut($Path)
        if ($link.Description -eq ('winux-setup: ' + $Component)) { return }
        $targetName = [IO.Path]::GetFileName($link.TargetPath)
        $arguments = $link.Arguments.Trim()
        $compatible = if ($Component -eq 'Komorebi') {
            $targetName -in @('komorebic.exe', 'komorebic-no-console.exe') -and $arguments -in @('start', 'start --whkd')
        } else { ($targetName -eq 'yasb.exe' -and -not $arguments) -or ($targetName -eq 'yasbc.exe' -and $arguments -eq 'start') }
        if (-not $compatible) { throw "Atalho existente com comando personalizado; revise antes de substituir: $Path" }
    } finally {
        if ($link) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($link) }
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
}

function New-WinuxStartupShortcutBytes {
    param([string]$Destination, [string]$Target, [string]$Arguments, [string]$WorkingDirectory, [string]$Component)
    $shell = New-Object -ComObject WScript.Shell
    $link = $null
    $temporary = $null
    try {
        $description = 'winux-setup: ' + $Component
        if (Test-Path -LiteralPath $Destination -PathType Leaf) {
            $link = $shell.CreateShortcut($Destination)
            if ($link.TargetPath -eq $Target -and $link.Arguments -ceq $Arguments -and
                $link.WorkingDirectory -eq $WorkingDirectory -and $link.WindowStyle -eq 7 -and $link.Description -eq $description) {
                return ,([IO.File]::ReadAllBytes($Destination))
            }
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($link)
            $link = $null
        }
        $temporary = Join-Path ([IO.Path]::GetTempPath()) ('winux-startup-' + [guid]::NewGuid().ToString('N') + '.lnk')
        $link = $shell.CreateShortcut($temporary)
        $link.TargetPath = $Target
        $link.Arguments = $Arguments
        $link.WorkingDirectory = $WorkingDirectory
        $link.WindowStyle = 7
        $link.Description = $description
        $link.Save()
        return ,([IO.File]::ReadAllBytes($temporary))
    } finally {
        if ($link) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($link) }
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
        if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}
