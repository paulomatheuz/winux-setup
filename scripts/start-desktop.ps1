[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Komorebi', 'Yasb')][string]$Component, [switch]$Check)
$ErrorActionPreference = 'Stop'
$logPath = Join-Path $PSScriptRoot 'desktop-startup.log'
function Test-WinuxDesktopProcess {
    param([string]$Name)
    $session = [Diagnostics.Process]::GetCurrentProcess().SessionId
    return [bool]@(Get-Process -Name $Name -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $session }).Count
}
try {
    $settings = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'startup.json')))
    if ($settings.SchemaVersion -ne 1) { throw 'Versao desconhecida da configuracao de inicializacao.' }
    $required = if ($Component -eq 'Komorebi') {
        @($settings.Executables.Komorebi, $settings.Executables.Whkd, (Join-Path $settings.ConfigHomes.Komorebi 'komorebi.json'), (Join-Path $settings.ConfigHomes.Whkd 'whkdrc'))
    } else { @($settings.Executables.Yasb, (Join-Path $settings.ConfigHomes.Yasb 'config.yaml'), (Join-Path $settings.ConfigHomes.Yasb 'styles.css')) }
    foreach ($path in $required) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Arquivo necessario para iniciar $Component nao encontrado: $path" } }
    if ($Check) { Write-Host ('Inicializacao de ' + $Component + ' verificada. Nenhum aplicativo foi iniciado.'); return }
    $env:KOMOREBI_CONFIG_HOME = $settings.ConfigHomes.Komorebi
    $env:WHKD_CONFIG_HOME = $settings.ConfigHomes.Whkd
    $env:YASB_CONFIG_HOME = $settings.ConfigHomes.Yasb
    $directories = @($settings.Executables.PSObject.Properties | ForEach-Object { Split-Path -Parent $_.Value } | Select-Object -Unique)
    $env:PATH = ($directories + @($env:PATH)) -join ';'
    if ($Component -eq 'Komorebi') {
        $whkdRunning = Test-WinuxDesktopProcess -Name whkd
        if (-not (Test-WinuxDesktopProcess -Name komorebi)) {
            $arguments = @('start')
            if (-not $whkdRunning) { $arguments += '--whkd' }
            $process = Start-Process -FilePath $settings.Executables.Komorebi -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru
            if ($process.ExitCode -ne 0) { throw ('Falha ao iniciar Komorebi: ' + $process.ExitCode) }
        } elseif (-not $whkdRunning) {
            Start-Process -FilePath $settings.Executables.Whkd -WindowStyle Hidden | Out-Null
        }
    } elseif (-not (Test-WinuxDesktopProcess -Name yasb)) {
        Start-Process -FilePath $settings.Executables.Yasb -WindowStyle Hidden | Out-Null
    }
    [IO.File]::AppendAllText($logPath, ([DateTime]::Now.ToString('o') + ' ' + $Component + ': verificado/iniciado.' + [Environment]::NewLine))
} catch {
    $failure = $_
    try { [IO.File]::AppendAllText($logPath, ([DateTime]::Now.ToString('o') + ' ' + $Component + ': ' + $failure.Exception.Message + [Environment]::NewLine)) } catch {}
    throw $failure
}
