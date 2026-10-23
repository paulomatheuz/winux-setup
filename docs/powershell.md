# Perfil do PowerShell

O perfil em `config/powershell/profile.ps1` reúne as personalizações encontradas nos dois perfis locais do inventário. Ele funciona dentro do repositório e depois da cópia para a pasta do Fastfetch.

## Comandos preservados

| Comando | Comportamento |
| --- | --- |
| `clear`, `cls` e `Clear-Terminal` | Limpam a tela e redesenham o Fastfetch quando disponível. |
| `winuxt <arquivo>` | Troca a logo do Fastfetch apenas na sessão atual. |
| `ls`, `ll` e `la` | Usam lsd quando disponível e os comandos nativos como alternativa. |
| `cd <pasta>` | Usa z quando disponível; sem ele, ou após uma falha, navega pelo caminho literal. |
| `Send-WakeOnLan` | Mantém a função auxiliar existente. |
| `btop` | Procura btop4win no PATH e depois nas pastas portáteis do usuário; repassa os argumentos. |
| `rain [velocidade]` | Executa matrix-rain com os parâmetros pessoais encontrados. |

O efeito de chuva mantém cor branca, caracteres Matrix, densidade 25, 60 FPS e velocidade padrão de 0.3. Por exemplo, `rain 0.8` muda a velocidade.

btop4win é procurado em `$HOME/Tools/btop4win/btop4win/btop4win.exe`, `$HOME/Tools/btop4win/btop4win.exe` e subpastas dessa pasta. matrix-rain é procurado em `$HOME/Tools/matrix-rain/matrix-rain.exe`. Ambos priorizam executáveis disponíveis no PATH.

Os comandos são incluídos agora; a instalação dos binários, a configuração do btop4win e seu tema continuam nas etapas próprias dessas ferramentas.

O ajuste do GitHub CLI usa a pasta `GitHub CLI` dentro de `$env:ProgramFiles`, caso o executável exista ali e ainda não esteja disponível no PATH. A entrada não é duplicada ao recarregar o perfil. O GitHub CLI não é instalado por esse ajuste.

## Dependências opcionais

- Starship inicializa o prompt quando está disponível.
- O componente opcional `Starship` aplica a base do prompt com backup; veja [destinos e configuração](starship.md).
- z permite navegação por pastas usadas anteriormente.
- PSReadLine configura o modo de edição Windows, Tab e previsões quando os recursos estão disponíveis.
- lsd adiciona ícones e cores às listagens.

O perfil não baixa dependências durante a abertura do terminal. A ausência dos módulos opcionais não impede seu carregamento.

## Instalação dos módulos

O catálogo `modules.psd1` define as versões mínimas observadas:

| Módulo | Versão mínima |
| --- | --- |
| [z](https://www.powershellgallery.com/packages/z/1.1.14) | 1.1.14 |
| [PSReadLine](https://www.powershellgallery.com/packages/PSReadLine/2.4.5) | 2.4.5 |

A instalação usa PowerShellGet e PSGallery, no escopo do usuário atual. Uma versão disponível igual ou superior à mínima é preservada. Quando necessário, a versão mínima do catálogo é instalada.

Verificar sem baixar ou consultar a fonte online:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallModules -Check
```

Simular:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallModules -WhatIf
```

Instalar os módulos e aplicar as configurações disponíveis, após revisar os termos:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallModules -AcceptAgreements
```

Para selecionar módulos dentro de uma sessão PowerShell:

```powershell
.\setup.ps1 -InstallModules -Modules z,PSReadLine -AcceptAgreements
```

Para instalar somente os módulos, sem aplicar configurações:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-modules.ps1 -AcceptAgreements
```

O script específico também aceita `-Modules`, `-Check` e `-WhatIf`.

`-AcceptAgreements` autoriza o uso da PSGallery e os aceites de licença suportados pelo PowerShellGet instalado. O provedor NuGet é instalado para o usuário atual se estiver ausente ou abaixo de 2.8.5.201. A política global de confiança dos repositórios não é modificada.

A fonte PSGallery registrada precisa apontar para o endpoint oficial HTTPS `powershellgallery.com/api/v2`. Se os comandos do PowerShellGet ou a fonte estiverem ausentes, ou houver falha de rede ou instalação, a execução é interrompida. Nenhum módulo é baixado no modo de verificação ou simulação.

Os comandos e o escopo seguem a documentação de [Install-Module](https://learn.microsoft.com/en-us/powershell/module/powershellget/install-module?view=powershellget-2.x) e [Install-PackageProvider](https://learn.microsoft.com/en-us/powershell/module/packagemanagement/install-packageprovider?view=powershellget-2.x). Se um PowerShellGet antigo não suportar o aceite de uma licença exigida, será necessário atualizá-lo antes de repetir a operação.

Módulos são instalados para a edição do PowerShell que executa o comando. Abra uma nova sessão depois da instalação para carregar as versões disponíveis. Usar PowerShell 5.1 não aplica automaticamente o perfil ou os módulos ao PowerShell 7.

## Backups e limites

A aplicação do perfil continua usando os [backups de configuração](backups.md). Os arquivos de perfil locais anteriores são preservados nesses backups quando alterados.

Uma falha na instalação dos módulos impede a aplicação das configurações naquela execução. Programas ou módulos que já tenham sido instalados não são removidos automaticamente. A restauração dos arquivos de configuração não desinstala módulos.

O arquivo personalizado do Starship, as preferências completas do Windows Terminal e os arquivos do Komorebi e do YASB continuam nas etapas de integração correspondentes. Histórico de comandos e a base de navegação do z não são incluídos no repositório.

## Testes

Os testes usam ferramentas e instalações simuladas:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\powershell.tests.ps1 -TestRoot "$env:TEMP\winux-setup-tests"
powershell -ExecutionPolicy Bypass -File .\tests\modules.tests.ps1 -TestRoot "$env:TEMP\winux-setup-tests"
```

