# Chuva / matrix-rain

O comando `rain` usa [smford/matrix-rain](https://github.com/smford/matrix-rain), o mesmo programa do ambiente pessoal, cuja versão foi confirmada como 1.1.0. Mantém cor branca, caracteres Matrix, densidade 25, 60 FPS e velocidade padrão de 0.3:

```powershell
rain
rain 0.8
```

O perfil procura `matrix-rain` no PATH e depois `$HOME/Tools/matrix-rain/matrix-rain.exe`. Não baixa nem inicia a animação ao abrir o terminal. Use Q, Esc ou Ctrl+C para sair da animação.

## Instalar

Para instalar somente o programa, sem aplicar outras configurações:

```powershell
.\scripts\install-rain.ps1 -Check
.\scripts\install-rain.ps1 -WhatIf
.\scripts\install-rain.ps1
```

Para combinar com o setup principal:

```powershell
.\setup.ps1 -InstallRain -Check
.\setup.ps1 -InstallRain -WhatIf
.\setup.ps1 -InstallRain
```

O setup principal continua aplicando os componentes selecionados; por padrão, Fastfetch e PowerShell, com seus pré-requisitos. O script dedicado dispensa Fastfetch e WinGet.

Em um dispositivo novo, combine com as instalações anteriores:

```powershell
.\setup.ps1 -InstallPrograms -InstallModules -InstallRain -AcceptAgreements
```

`-AcceptAgreements` trata os termos do WinGet e dos módulos. O instalador portátil não apresenta um aceite interativo; a licença MIT do matrix-rain acompanha o arquivo instalado `LICENSE`.

## Origem e destino

`portable-programs.psd1` fixa os arquivos oficiais da [versão 1.1.0](https://github.com/smford/matrix-rain/releases/tag/v1.1.0) para Windows x64 e ARM64, com seus SHA-256 publicados na API da release. A arquitetura é detectada pelas variáveis do Windows; o script dedicado também aceita `-Architecture x64` ou `-Architecture arm64`.

O ZIP é baixado para uma pasta temporária exclusiva e conferido antes da aplicação. Apenas `matrix-rain.exe`, `README.md` e `LICENSE` são copiados para `$HOME/Tools/matrix-rain`. Nomes do arquivo ZIP não viram destinos de extração. A pasta temporária é removida ao terminar ou falhar. Nenhum binário é versionado.

Se o executável já existir no PATH ou no destino, a instalação é preservada, mesmo que tenha outra versão. Uma instalação concorrente detectada antes da aplicação também impede a substituição do executável.

Os arquivos aplicados usam o [registro e o backup do setup](backups.md). Se README ou LICENSE já existirem sem o executável, são salvos antes da aplicação. O instalador não altera o PATH, o perfil ou variáveis persistentes. Aplique o componente `PowerShell` para disponibilizar a função `rain` quando necessário.

O script dedicado aceita `-DestinationDirectory` com caminho absoluto. Um destino diferente não altera a busca do perfil: coloque o executável no PATH ou use a pasta padrão.

## Verificação

`-Check` verifica catálogo, arquitetura, destino e instalações existentes. `-WhatIf` descreve a instalação. Ambos funcionam sem downloads; a disponibilidade online é conferida no download real.

```powershell
.\tests\rain.tests.ps1 -TestRoot "$env:TEMP\winux-rain-tests"
```

Os testes usam ZIPs fictícios e downloads simulados. Verificam arquiteturas, checksum, arquivos esperados, falhas, preservação de instalações, concorrência, backups e integração com o setup no PowerShell 5.1 e 7. Não instalam nem executam um binário real. A aparência em outro dispositivo continua pendente.
