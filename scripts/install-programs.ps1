[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateNotNullOrEmpty()]
    [string[]]$Programs,

    [switch]$Check,

    [switch]$AcceptAgreements
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Use Windows PowerShell 5.1 ou PowerShell 7 no Windows.'
}

$catalogPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'packages.psd1'
$catalog = Import-PowerShellDataFile -LiteralPath $catalogPath
$available = @($catalog.Packages)
$knownNames = @($available | ForEach-Object { $_.Name })
if ($available.Count -eq 0 -or @($knownNames | Select-Object -Unique).Count -ne $available.Count) {
    throw 'O catalogo de programas esta vazio ou possui nomes repetidos.'
}
foreach ($package in $available) {
    if ([string]::IsNullOrWhiteSpace($package.Name) -or [string]::IsNullOrWhiteSpace($package.Id)) {
        throw 'Cada programa deve possuir Name e Id no catalogo.'
    }
}
if ($Programs) {
    $unknown = @($Programs | Where-Object { $_ -notin $knownNames })
    if ($unknown.Count -gt 0) {
        throw ('Programas desconhecidos: ' + ($unknown -join ', ') + '. Opcoes: ' + ($knownNames -join ', '))
    }
    $selected = @($available | Where-Object { $_.Name -in $Programs })
} else {
    $selected = $available
}

$winget = Get-Command winget -CommandType Application -ErrorAction SilentlyContinue
if (-not $winget) {
    throw 'WinGet nao foi encontrado. Instale ou atualize o Instalador de Aplicativo da Microsoft e abra uma nova sessao.'
}

Write-Host ('Programas: ' + (($selected | ForEach-Object { $_.Name }) -join ', '))
if ($Check) {
    Write-Host 'Catalogo e comando WinGet verificados. A disponibilidade online dos pacotes sera verificada pelo WinGet ao instalar.'
    return
}

foreach ($package in $selected) {
    if ($package.Name -eq 'JetBrainsMonoNerdFont') {
        . (Join-Path $PSScriptRoot 'fonts.ps1')
        $fontReport = @(Get-WinuxFontReport | Where-Object { $_.Package -eq $package.Name })
        if ($fontReport.Count -gt 0 -and @($fontReport | Where-Object { -not $_.Available }).Count -eq 0) {
            Write-Host 'JetBrainsMonoNerdFont: familias necessarias ja disponiveis; fontes existentes preservadas.'
            continue
        }
    }
    $target = $package.Id
    if ($package.Version) {
        $target += ' ' + $package.Version
    }
    if (-not $PSCmdlet.ShouldProcess($target, 'Instalar com WinGet sem atualizar instalacoes existentes')) {
        continue
    }

    $arguments = @(
        'install', '--id', $package.Id, '--exact',
        '--source', 'winget', '--no-upgrade',
        '--silent', '--disable-interactivity'
    )
    if ($package.Version) {
        $arguments += '--version', $package.Version
    }
    if ($AcceptAgreements) {
        $arguments += '--accept-source-agreements', '--accept-package-agreements'
    }

    try {
        & $winget.Source @arguments | Out-Host
        $exitCode = $LASTEXITCODE
    } catch {
        throw ('Nao foi possivel executar o WinGet para ' + $package.Id + ': ' + $_.Exception.Message)
    }

    $resultCode = '0x{0:X8}' -f ([int64]$exitCode -band 4294967295L)
    switch ($resultCode) {
        '0x00000000' { Write-Host ($package.Name + ': concluido.') }
        '0x8A15002B' { Write-Host ($package.Name + ': instalacao existente preservada.') }
        '0x8A150061' { Write-Host ($package.Name + ': ja instalado.') }
        '0x8A15010D' { Write-Host ($package.Name + ': ja instalado.') }
        default {
            throw ('Falha ao instalar ' + $package.Id + ' (WinGet ' + $resultCode + '). Confira a mensagem acima. Se a falha exigir aceite de termos, use -AcceptAgreements apos revisar as licencas. As configuracoes nao serao aplicadas nesta execucao.')
        }
    }
}

if (-not $WhatIfPreference) {
    # Atualiza somente o PATH desta sessao; preserva as entradas anteriores.
    $paths = @(
        $env:PATH
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
    )
    $env:PATH = (((($paths -join ';') -split ';') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique) -join ';')
}

