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

function clear {
    Clear-Host
    Show-Fastfetch
}

function cls {
    clear
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
        try {
            z $Path
        } catch {
            Set-Location $Path
        }
    } else {
        Set-Location ~
    }

    ls
}

# Autocomplete e historico
Import-Module PSReadLine -ErrorAction SilentlyContinue
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function Complete

try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
} catch {
}

# Exibe o visual ao abrir o Terminal
Clear-Host
Show-Fastfetch
