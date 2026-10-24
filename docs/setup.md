# Uso do setup

O ponto de entrada do projeto é `setup.ps1`, na raiz do repositório.

## Componentes disponíveis

| Componente | O que aplica |
| --- | --- |
| `Fastfetch` | Configuração e logo ASCII do Fastfetch. |
| `PowerShell` | Perfil compartilhável e sua integração ao perfil da sessão. Inclui os arquivos do Fastfetch, que são uma dependência desse perfil. |
| `WindowsTerminal` | Preferências visuais e atalhos, combinados com os perfis locais e aplicados com backup. |
| `Starship` | Base do prompt, aplicada no caminho padrão ou em `STARSHIP_CONFIG`, com backup. |
| `Komorebi` | Configuração pessoal, regras de aplicativos e barra alternativa, com backup. |
| `Yasb` | Configuração e CSS pessoais, com backup e preservação do `.env` local. |
| `Whkd` | Arquivo pessoal de atalhos, com backup e respeito a `WHKD_CONFIG_HOME`. |
| `Btop` | Configuração pessoal e tema NeutralPurple, aplicados na pasta do executável ou em `-BtopDirectory`. |
| `VisualAssets` | Wallpapers e ícone pessoais, com backup e integração opcional com WindowsTerminal. |

Sem `-Components`, Fastfetch e PowerShell são selecionados. WindowsTerminal, Starship, Komorebi, Yasb, Whkd, Btop e VisualAssets são opcionais. matrix-rain é instalado com `-InstallRain`; seus parâmetros estão no perfil PowerShell. A instalação dos demais programas tem uma seleção separada, descrita em [Instalação dos programas](programas.md).

## Verificar antes de aplicar

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Check
```

O comando verifica:

- se a sessão está no Windows e usa PowerShell 5.1 ou superior;
- se o instalador e os arquivos necessários aos componentes selecionados existem;
- se o executável do Fastfetch está disponível no PATH, quando Fastfetch ou PowerShell estiver selecionado;
- se o destino e o JSON do Windows Terminal permitem a aplicação, quando esse componente estiver selecionado.

A verificação não copia arquivos, não edita o perfil e não instala programas. Fontes, o tema do Windows Terminal e as dependências opcionais continuam seguindo as instruções do README.

## Simular a aplicação

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -WhatIf
```

O setup verifica os pré-requisitos e informa a operação prevista, sem aplicar as configurações.

## Aplicar os componentes disponíveis

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Somente o Fastfetch:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Components Fastfetch
```

Perfil do PowerShell com sua dependência do Fastfetch:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Components PowerShell
```

Para copiar os arquivos do perfil sem editar a integração no perfil da sessão, acrescente `-SkipProfile`. Esse comportamento mantém a opção do instalador anterior.

## Compatibilidade

O comando `powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1` continua disponível. Sem parâmetros, aplica os mesmos arquivos de antes. O script também aceita `-Components`, `-SkipProfile` e `-WhatIf`.

A entrada principal acrescenta a verificação do sistema e do executável do Fastfetch. Os dois scripts verificam a presença dos arquivos de configuração antes de copiá-los.

Os destinos, os marcadores e o backup do perfil continuam descritos em [Estrutura do projeto](estrutura.md). Todos os arquivos existentes que precisarem mudar são salvos antes das substituições, com registro por execução. Arquivos idênticos não são regravados. Consulte [Backups das configurações](backups.md). A restauração automática será implementada em uma etapa própria.

## Instalar programas antes de aplicar as configurações

Use `-InstallPrograms` para executar a instalação via WinGet antes da aplicação das configurações. A opção `-Programs` seleciona programas do catálogo, enquanto `-Components` seleciona configurações. Por exemplo, `-Programs PowerShell` instala PowerShell 7 e `-Components PowerShell` aplica o perfil na edição da sessão atual.

`-Check` e `-WhatIf` também funcionam com `-InstallPrograms`, sem executar o WinGet. Os aceites de termos são opcionais e explícitos por meio de `-AcceptAgreements`. Veja o [catálogo e os exemplos](programas.md).

Ao selecionar Fastfetch ou PowerShell, se o Fastfetch estiver ausente e não tiver sido selecionado para instalação, o setup interrompe a execução antes de alterar as configurações. A seleção isolada do Windows Terminal dispensa essa dependência.

## Perfil pessoal e módulos

O perfil reúne os comandos dos dois perfis locais, incluindo `btop`, `rain` e `Clear-Terminal`. A instalação opcional de z e PSReadLine usa `-InstallModules`; a seleção usa `-Modules`, e os aceites são explícitos com `-AcceptAgreements`.

Os modos `-Check` e `-WhatIf` também se aplicam aos módulos. Para instalar programas e módulos na mesma execução, combine `-InstallPrograms -InstallModules -AcceptAgreements`. Os catálogos e as instalações são separados da seleção de configurações em `-Components`.

Veja o [perfil do PowerShell e suas dependências](powershell.md) para exemplos, requisitos e limitações.

## Recursos visuais

Use `-Components VisualAssets` para copiar os wallpapers e o ícone com backup. Dentro do PowerShell, `-Components VisualAssets, WindowsTerminal` também aplica a referência do ícone, respeitando `-TerminalSettingsPath`. `-Check` e `-WhatIf` conferem os recursos sem alterar arquivos. Veja [Recursos visuais](recursos-visuais.md).

## Fontes

Para instalar a fonte usada pelo Terminal e pelo YASB, selecione `-InstallPrograms -Programs JetBrainsMonoNerdFont`. Sem `-Programs`, ela faz parte do catálogo completo. Execute `scripts/check-fonts.ps1` para uma verificação somente leitura das famílias e dos aliases. Veja [Fontes](fontes.md) para instalações existentes, dependências do Windows e a barra alternativa.

## Instalação do Chuva

Use `-InstallRain` para instalar matrix-rain na pasta reconhecida pelo perfil. A opção pode ser combinada com `-InstallPrograms` e `-InstallModules` e aceita `-Check` e `-WhatIf`. Não existe componente `Rain`: os parâmetros já estão na função `rain` do perfil. Veja [Chuva](chuva.md).

## Configuração do btop

Use `-Components Btop` para aplicar a configuração pessoal e NeutralPurple com backup. O componente aceita `-Check`, `-WhatIf` e `-BtopDirectory`. O programa pode ser instalado com `-InstallPrograms -Programs Btop`. Veja [btop4win](btop.md) para a busca do executável, o alias do WinGet e o modo TTY preservado.

## Atalhos do whkd

Use `-Components Whkd` para aplicar os atalhos pessoais com backup. O componente aceita `-Check` e `-WhatIf` e respeita `WHKD_CONFIG_HOME`. Dentro do PowerShell, `-Components Komorebi, Yasb, Whkd` aplica as três configurações em uma execução, sem iniciar aplicativos. Veja [whkd](whkd.md).

## Configuração do YASB

Use `-Components Yasb` para aplicar YAML e CSS pessoais com backup. O componente aceita `-Check` e `-WhatIf`, respeita `YASB_CONFIG_HOME` e preserva o `.env` existente. Veja [YASB](yasb.md) para clima, wallpapers, fontes e integrações.

## Configuração do Komorebi

Use `-Components Komorebi` para aplicar os arquivos pessoais com backup, sem iniciar os aplicativos. O componente aceita `-Check` e `-WhatIf` e respeita `KOMOREBI_CONFIG_HOME`. Veja [Komorebi](komorebi.md) para destinos, regras, barra e monitores.

## Base do prompt Starship

O componente `Starship` aplica a base do prompt com backup e aceita `-Check` e `-WhatIf`. O destino usa `STARSHIP_CONFIG` ou `$HOME/.config/starship.toml`. Veja [Starship](starship.md) para a diferença entre instalar o programa, inicializar o shell e aplicar a configuração.

## Preferências do Windows Terminal

Use `-Components WindowsTerminal` para aplicar temas, fonte, transparência e atalhos com backup, preservando os perfis locais. O componente aceita `-Check`, `-WhatIf` e `-TerminalSettingsPath`. Sem seleção explícita, o setup continua usando apenas Fastfetch e PowerShell.

Dentro do PowerShell, combine os componentes com `-Components Fastfetch, PowerShell, WindowsTerminal`. As opções do componente e a detecção das edições estão em [Windows Terminal](windows-terminal.md). O instalador `scripts/install.ps1` também aceita essas opções.

