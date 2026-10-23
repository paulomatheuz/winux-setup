# =========================
# VISUAL ATUAL: Fastfetch
# =========================

$ConfigRoot = Split-Path -Parent $PSScriptRoot
$RepositoryFastfetch = Join-Path $ConfigRoot 'fastfetch'

# Works both inside this repository and after scripts/install.ps1 copies it.
if (Test-Path -LiteralPath $RepositoryFastfetch) {
    $FastfetchRoot = $RepositoryFastfetch
} else {
    $FastfetchRoot = $PSScriptRoot
}

$global:WinuxLogoPath = Join-Path $FastfetchRoot 'Spider2-ascii.txt'
$global:FastfetchConfig = Join-Path $FastfetchRoot 'config-purple.jsonc'

function Show-Fastfetch {
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        fastfetch --config $global:FastfetchConfig -l $global:WinuxLogoPath
    }
}

# Prompt Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# =========================
# COMANDOS ANTIGOS
# =========================

# Troca a logo apenas na aba atual:
# winuxt "C:\caminho\para\outra-logo.txt"
function winuxt {
    param(
        [string]$logo
    )

    if ($logo) {
        $global:WinuxLogoPath = $logo
        Write-Host "Caminho da logo atualizado para: $logo" -ForegroundColor Green
    }
}

# clear e cls limpam e redesenham o Fastfetch.
# Não use Microsoft.PowerShell.Utility\Clear-Host aqui.
Remove-Item Alias:clear -Force -ErrorAction SilentlyContinue
Remove-Item Alias:cls -Force -ErrorAction SilentlyContinue

function Clear-Terminal {
    Clear-Host
    Show-Fastfetch
}

function clear {
    Clear-Terminal
}

function cls {
    Clear-Terminal
}

# Wake-on-LAN:
# Send-WakeOnLan -MacAddress "AA:BB:CC:DD:EE:FF"
function Send-WakeOnLan {
    param(
        [Parameter(Mandatory)]
        [string]$MacAddress
    )

    $MacAddress = $MacAddress -replace '[:-]', ''

    if ($MacAddress.Length -ne 12) {
        Write-Host "MAC invalido. Use AA:BB:CC:DD:EE:FF" -ForegroundColor Red
        return
    }

    $packet = @()

    for ($i = 0; $i -lt 6; $i++) {
        $packet += 0xFF
    }

    for ($i = 0; $i -lt 16; $i++) {
        for ($j = 0; $j -lt 12; $j += 2) {
            $packet += [Convert]::ToByte($MacAddress.Substring($j, 2), 16)
        }
    }

    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Connect([System.Net.IPAddress]::Broadcast, 9)
    $udp.Send($packet, $packet.Length) | Out-Null
    $udp.Close()
}

# ls, ll e la com lsd
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

function ls {
    if (Get-Command lsd -ErrorAction SilentlyContinue) {
        lsd --group-dirs first --icon always --color always @args
    } else {
        Get-ChildItem @args
    }
}

function ll {
    if (Get-Command lsd -ErrorAction SilentlyContinue) {
        lsd -l --group-dirs first --icon always --color always @args
    } else {
        Get-ChildItem @args
    }
}

function la {
    if (Get-Command lsd -ErrorAction SilentlyContinue) {
        lsd -la --group-dirs first --icon always --color always @args
    } else {
        Get-ChildItem -Force @args
    }
}

# Modulo z para navegar por pastas usadas anteriormente (opcional)
if (Get-Module -ListAvailable -Name z) {
    Import-Module z -ErrorAction SilentlyContinue
}

Remove-Item Alias:cd -Force -ErrorAction SilentlyContinue

function cd {
    param(
        [string]$Path
    )

    if ($Path) {
        if (Get-Command z -ErrorAction SilentlyContinue) {
            try {
                z $Path
            } catch {
                Set-Location -LiteralPath $Path -ErrorAction Stop
            }
        } else {
            Set-Location -LiteralPath $Path -ErrorAction Stop
        }
    } else {
        Set-Location ~
    }

    ls
}

# Ferramentas portateis: prefere o PATH e depois os caminhos pessoais.
function Find-WinuxExecutable {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Candidates,
        [string]$SearchRoot,
        [string]$FileName
    )
    $application = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue
    if ($application) { return $application.Source }
    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    if ($SearchRoot -and (Test-Path -LiteralPath $SearchRoot -PathType Container)) {
        $match = Get-ChildItem -LiteralPath $SearchRoot -Filter $FileName -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName | Select-Object -First 1
        if ($match) { return $match.FullName }
    }
}

function btop {
    # O pacote WinGet publica o executavel como btop.
    foreach ($command in @('btop4win', 'btop')) {
        $application = Get-Command $command -CommandType Application -ErrorAction SilentlyContinue
        if ($application) { & $application.Source @args; return }
    }
    $root = Join-Path $HOME 'Tools\btop4win'
    $executable = Find-WinuxExecutable -Command btop4win -Candidates @(
        (Join-Path $root 'btop4win\btop4win.exe')
        (Join-Path $root 'btop4win.exe')
    ) -SearchRoot $root -FileName 'btop4win.exe'
    if (-not $executable) {
        Write-Error 'btop4win nao foi encontrado no PATH nem em $HOME\Tools\btop4win.'
        return
    }
    & $executable @args
}

function rain {
    param([double]$Velocidade = 0.3)
    $executable = Find-WinuxExecutable -Command matrix-rain -Candidates @(
        (Join-Path $HOME 'Tools\matrix-rain\matrix-rain.exe')
    )
    if (-not $executable) {
        Write-Error 'matrix-rain nao foi encontrado no PATH nem em $HOME\Tools\matrix-rain.'
        return
    }
    & $executable -color white -charset matrix -density 25 -fps 60 -speed $Velocidade
}

# GitHub CLI: preserva o ajuste local sem duplicar o PATH a cada abertura.
if ($env:ProgramFiles -and -not (Get-Command gh -CommandType Application -ErrorAction SilentlyContinue)) {
    $githubCliDirectory = Join-Path $env:ProgramFiles 'GitHub CLI'
    if ((Test-Path -LiteralPath (Join-Path $githubCliDirectory 'gh.exe') -PathType Leaf) -and
        ($env:PATH -split ';') -notcontains $githubCliDirectory) {
        $env:PATH = $githubCliDirectory + ';' + $env:PATH
    }
}

# Autocomplete e historico: os modulos opcionais nao sao baixados no perfil.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    try {
        Set-PSReadLineOption -EditMode Windows -ErrorAction Stop
        Set-PSReadLineKeyHandler -Key Tab -Function Complete -ErrorAction Stop
    } catch {
        Write-Verbose 'Atalhos do PSReadLine indisponiveis nesta sessao.'
    }
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
        Write-Verbose 'Previsoes do PSReadLine indisponiveis nesta sessao.'
    }
}

# Exibe o visual ao abrir o Terminal
Clear-Host
Show-Fastfetch

