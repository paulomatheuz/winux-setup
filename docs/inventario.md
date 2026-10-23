# Inventário do ambiente

Levantamento realizado em 23/10/2026 para orientar a migração das configurações pessoais para o winux-setup.

Esta etapa registra os arquivos e as dependências encontrados. A importação das configurações, a instalação dos programas e as mudanças de comportamento ficam para as próximas etapas.

Os caminhos usam `$HOME` para representar a pasta do usuário. São as origens encontradas neste computador, não os destinos definitivos do futuro instalador.

## Configurações a preservar

| Componente | Arquivos locais encontrados | O que levar para o setup |
| --- | --- | --- |
| Komorebi | `$HOME/komorebi.json` e `$HOME/applications.json` | Layouts, espaços de trabalho, regras de aplicativos, bordas, cores, transparência, animações e espaçamentos. |
| Barra do Komorebi | `$HOME/komorebi.bar.json` | Configuração encontrada; confirmar se será usada junto ao YASB ou mantida apenas como alternativa. |
| YASB | `$HOME/.config/yasb/config.yaml` e `$HOME/.config/yasb/styles.css` | Configuração e CSS personalizados, incluindo posição, dimensões, widgets, cores, fontes e detalhes visuais. |
| whkd | `$HOME/.config/whkdrc` | Atalhos e integração com o Komorebi. |
| PowerShell | `$HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` e `$HOME/Documents/WindowsPowerShell/profile.ps1` | Combinar as personalizações dos dois perfis, incluindo os comandos auxiliares. |
| Windows Terminal | `$HOME/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` | Tema, fontes e preferências pessoais; tratar identificadores e perfis gerados pelo dispositivo separadamente. |
| Fastfetch | `$HOME/Documents/fastfetch/config-purple.jsonc` e `Spider2-ascii.txt` na mesma pasta | Comparar a configuração e a arte ASCII locais com as cópias já existentes no repositório. |
| Starship | Inicialização encontrada no perfil do PowerShell | Preservar a integração; um arquivo personalizado `$HOME/.config/starship.toml` não foi encontrado, nem uma variável de usuário `STARSHIP_CONFIG`. |
| btop4win | `$HOME/Tools/btop4win/btop4win/btop.conf` e `themes/NeutralPurple.theme` na mesma pasta | Configuração, tema selecionado e função `btop` do PowerShell. |
| Chuva / efeito Matrix | `$HOME/Tools/matrix-rain/matrix-rain.exe`, chamado pela função `rain` | Preservar a função e seus parâmetros; identificar a versão e preparar a instalação do programa. |

As configurações personalizadas serão a base da migração, incluindo as alterações feitas no CSS e nos arquivos do Komorebi e do YASB.

## Dependências identificadas

As versões abaixo descrevem o ambiente observado; não são versões obrigatórias nem garantem compatibilidade em outro computador.

| Dependência | Evidência encontrada |
| --- | --- |
| Komorebi | `komorebic --version`: 0.1.41. |
| YASB | Versão do executável: 2.0.7. |
| whkd | `whkd --version`: 0.2.10. |
| Starship | `starship --version`: 1.27.0. |
| Fastfetch | `fastfetch --version`: 2.70.0. |
| lsd | `lsd --version`: 1.2.0. |
| Módulo z | Módulo de usuário encontrado: 1.1.14. |
| PSReadLine | Módulo de usuário encontrado: 2.4.5; existem outras cópias no ambiente. |
| btop4win | Executável portátil encontrado. O changelog local começa em 1.0.5; a versão do binário ainda precisa ser confirmada. |
| matrix-rain | Executável e README encontrados. O README identifica o projeto `smford/matrix-rain`; a versão do binário ainda precisa ser confirmada. |
| Windows PowerShell | Executável do Windows e perfis de usuário encontrados. |
| PowerShell 7 | A pasta de perfis do usuário existe e está vazia. O executável encontrado na sessão pertence ao ambiente de execução desta tarefa e não comprova uma instalação pessoal. |
| Windows Terminal | Comando `wt` e configuração local encontrados. |
| Git e WinGet | Comandos disponíveis; fontes e identificadores dos pacotes serão verificados na etapa de instalação. |
| Fontes | Arquivos JetBrains Mono Nerd Font encontrados. O Terminal pede `JetBrainsMonoNL Nerd Font Propo`; o CSS do YASB usa `JetBrainsMono NFP`, `Segoe UI` e `Segoe Fluent Icons`. A barra do Komorebi pede `JetBrains Mono`. |

## Integrações e aparência atuais

### Komorebi e whkd

- Um monitor configurado, com sete espaços de trabalho: I a VII.
- Layouts: BSP, VerticalStack, HorizontalStack, UltrawideVerticalStack, Rows, Grid e RightMainVerticalStack.
- Espaçamento padrão entre espaços de trabalho e contêineres: 3.
- A configuração referencia `$Env:USERPROFILE/applications.json`.
- O whkd usa `powershell` como shell e possui atalhos para foco, movimentação, pilhas, redimensionamento e espaços de trabalho.
- Existem atalhos para oito espaços de trabalho, enquanto o Komorebi define sete. Confirmar a intenção antes de ajustar.
- Um atalho de inicialização do Windows chama `komorebic-no-console.exe start --whkd`. Ele deverá ser recriado com o caminho do dispositivo, em vez de copiar o arquivo `.lnk`.

### YASB

- Barra no topo, com largura de 100%, altura de 32 e seleção de todas as telas.
- Esquerda: home e taskbar.
- Centro: clock e apps.
- Direita: media, wallpapers, wifi, microphone, volume, notifications e power_menu.
- Os widgets de espaços de trabalho, layout do Komorebi e janela ativa estão definidos, mas comentados na lista da barra. Preservar essa escolha.
- Os comandos de integração iniciam e encerram o Komorebi com whkd.
- O widget de wallpapers aponta para `$HOME/Pictures/wallpaper`; foram encontrados 18 arquivos nessa pasta. A seleção de imagens para distribuição fica pendente.
- Há configuração de clima com uma chave preenchida e localização local. O widget não aparece na lista ativa da barra. A chave e a localização não devem ser copiadas para a configuração pública; prever valores locais opcionais sem alterar o CSS.

### Terminal, PowerShell e Fastfetch

- O Terminal utiliza o esquema `Spider Purple` e a fonte `JetBrainsMonoNL Nerd Font Propo`.
- O perfil usado no terminal aponta o Fastfetch para `$HOME/Documents/fastfetch`. O instalador atual do repositório usa `$HOME/.config/fastfetch`.
- O repositório já contém uma versão do perfil com Starship, Fastfetch, lsd, módulo z, PSReadLine e funções auxiliares.
- O arquivo local `profile.ps1` também define `btop` e `rain`; essas funções ainda não estão no perfil versionado.
- Preservar as personalizações dos dois perfis e adaptar os caminhos na etapa de integração, considerando a edição do PowerShell utilizada.

### btop4win e chuva

- O btop4win seleciona `NeutralPurple.theme` por um caminho absoluto do usuário.
- Preferências encontradas: fundo do tema desativado, truecolor ativado, gráficos `tty`, caixas `cpu mem proc`, atualização de 1500 ms e ordenação dos processos por memória.
- A função `btop` procura o executável dentro de `$HOME/Tools/btop4win`.
- A função `rain` chama matrix-rain com cor branca, caracteres Matrix, densidade 25, 60 FPS e velocidade padrão de 0.3.
- Binários, arquivos ZIP e logs encontrados nessas pastas não fazem parte da importação de configurações.

## Base já existente no repositório

| Arquivo | Função atual |
| --- | --- |
| `config/powershell/profile.ps1` | Perfil compartilhável com Starship, Fastfetch e comandos auxiliares. |
| `config/windows-terminal/settings.json.example` | Esquema Spider Purple e preferências de fonte. |
| `config/fastfetch/config-purple.jsonc` | Configuração do Fastfetch. |
| `config/fastfetch/Spider2-ascii.txt` | Arte ASCII utilizada pelo perfil. |
| `scripts/install.ps1` | Copia Fastfetch e perfil; adiciona a integração ao perfil do PowerShell, com backup antes da inclusão. Não instala programas. |

## Pontos para as próximas etapas

- Importar os arquivos pessoais do Komorebi, YASB e whkd, preservando o visual e os atalhos.
- Comparar os arquivos locais do terminal e do Fastfetch com as cópias versionadas antes de escolher a base.
- Adaptar caminhos de usuário, tema do btop4win, wallpapers e inicialização automática.
- Separar a configuração compartilhada dos ajustes de monitores e dos valores privados.
- Confirmar o uso da barra própria do Komorebi e a diferença de quantidade de espaços de trabalho nos atalhos.
- Confirmar as versões e fontes de instalação do btop4win e do matrix-rain.
- Verificar as famílias de fontes necessárias e quais imagens poderão acompanhar o projeto.
- Verificar uma eventual configuração do Starship em outro local, caso exista.
- Validar a importação e a inicialização em outro dispositivo quando o instalador estiver pronto.

Backups, logs, históricos, credenciais e identificadores pessoais não serão incluídos na importação. Esta etapa altera somente a documentação.
