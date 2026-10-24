# Estrutura do projeto

## Organização

| Pasta | Conteúdo |
| --- | --- |
| `config/` | Configurações compartilháveis, separadas por ferramenta. |
| `scripts/` | Scripts de instalação e manutenção. |
| `assets/` | Recursos visuais usados pelo projeto. |
| `docs/` | Inventário, organização e instruções complementares. |
| `devices/` | Exemplo compartilhado e ajustes locais por dispositivo, ignorados pelo Git. |

Cada ferramenta tem sua própria pasta em `config/` quando seus arquivos são incorporados. As configurações pessoais do Komorebi, do YASB e do whkd já estão incluídas, incluindo o `styles.css` personalizado. As origens estão registradas no [inventário](inventario.md).

## Arquivos atuais

| Caminho no repositório | Uso |
| --- | --- |
| `config/fastfetch/config-purple.jsonc` | Configuração do Fastfetch. |
| `config/btop/btop.conf` | Configuração pessoal do btop4win, com caminho portátil do tema. |
| `config/btop/themes/NeutralPurple.theme` | Tema pessoal preservado integralmente. |
| `config/btop/BTOP.LICENSE` | Licença da base btop4win. |
| `scripts/btop.ps1` | Busca do executável e planejamento da configuração e do tema. |
| `tests/btop.tests.ps1` | Verificações isoladas do btop e instalação simulada. |
| `config/komorebi/komorebi.json` | Preferências pessoais, layouts e espaços de trabalho. |
| `config/komorebi/komorebi.bar.json` | Barra alternativa, sem ativação automática. |
| `config/komorebi/applications.json` | Cópia local das regras de aplicativos. |
| `config/komorebi/applications.LICENSE` | Licença da base de regras. |
| `scripts/komorebi.ps1` | Planejamento dos arquivos e adaptação do caminho das regras. |
| `tests/komorebi.tests.ps1` | Verificações isoladas do componente Komorebi. |
| `config/yasb/config.yaml` | Barra, widgets e integrações pessoais, sem valores privados do clima. |
| `config/yasb/styles.css` | CSS pessoal preservado integralmente. |
| `config/yasb/.env.example` | Modelo sem valores para a configuração local do clima. |
| `config/yasb/YASB.LICENSE` | Licença da base YASB. |
| `scripts/yasb.ps1` | Planejamento dos arquivos e resolução do destino do YASB. |
| `tests/yasb.tests.ps1` | Verificações isoladas de aplicação, backups e preservação do `.env`. |
| `config/whkd/whkdrc` | Arquivo pessoal de atalhos, preservado integralmente. |
| `scripts/whkd.ps1` | Planejamento do arquivo e resolução do destino do whkd. |
| `tests/whkd.tests.ps1` | Verificações dos atalhos e da aplicação isolada e conjunta do desktop. |
| `config/fastfetch/Spider2-ascii.txt` | Logo ASCII. |
| `config/powershell/profile.ps1` | Perfil compartilhável do PowerShell. |
| `config/starship/starship.toml` | Base atual do prompt, com os módulos e estilos padrão. |
| `scripts/starship.ps1` | Resolução do destino padrão ou de `STARSHIP_CONFIG`. |
| `tests/starship.tests.ps1` | Verificações isoladas da aplicação do Starship. |
| `config/windows-terminal/settings.json.example` | Temas, fonte, transparência e atalhos do Windows Terminal. |
| `scripts/windows-terminal.ps1` | Leitura de JSON com comentários, seleção do destino e combinação das preferências. |
| `tests/windows-terminal.tests.ps1` | Verificações isoladas do componente Windows Terminal. |
| `setup.ps1` | Entrada principal com seleção de componentes, verificação de pré-requisitos, instalação opcional de programas e simulação. |
| `devices/example.json` | Modelo público sem caminhos pessoais para os ajustes por dispositivo. |
| `scripts/device.ps1` | Leitura e validação do JSON local e resolução dos caminhos relativos. |
| `tests/device.tests.ps1` | Aplicação isolada das variantes locais, prioridade, backups e preservação dos padrões. |
| `packages.psd1` | Catálogo dos programas instaláveis via WinGet. |
| `fonts.psd1` | Famílias, aliases e dependência opcional da barra alternativa. |
| `scripts/fonts.ps1` | Leitura das famílias instaladas e comparação com as dependências. |
| `scripts/check-fonts.ps1` | Relatório somente leitura da disponibilidade das fontes. |
| `tests/fonts.tests.ps1` | Verificações de aliases e instalação simulada da Nerd Font. |
| `portable-programs.psd1` | URLs e SHA-256 do matrix-rain 1.1.0 para x64 e ARM64. |
| `scripts/install-rain.ps1` | Instalação portátil do matrix-rain, com verificação e preservação de instalações existentes. |
| `tests/rain.tests.ps1` | Instalação, falhas e integração com arquivos e downloads simulados. |
| `modules.psd1` | Catálogo das dependências opcionais do perfil. |
| `scripts/install-modules.ps1` | Instalação de z e PSReadLine para o usuário atual. |
| `scripts/install-programs.ps1` | Instalação dos programas selecionados, com preservação das versões existentes. |
| `scripts/configure-startup.ps1` | Configuração opcional dos atalhos de login, com backup. |
| `scripts/startup.ps1` | Resolução dos programas e diretórios, verificação e criação dos atalhos. |
| `scripts/start-desktop.ps1` | Lançador copiado para a pasta local do setup; consulta processos e inicia os componentes no login. |
| `tests/startup.tests.ps1` | Atalhos e backups em pasta temporária, com início dos programas simulado. |
| `scripts/install.ps1` | Aplicação dos arquivos da configuração atual do terminal. |
| `scripts/configuration.ps1` | Planejamento, backups e registro das alterações dos arquivos. |
| `scripts/restore.ps1` | Validação dos manifestos, integridade dos originais e planejamento da restauração. |
| `scripts/restore-backup.ps1` | Restauração explícita com simulação e novo backup do estado atual. |
| `tests/restore.tests.ps1` | Recuperação isolada de arquivos, remoções, conflitos, corrupção e aplicações parciais. |
| `tests/configuration.tests.ps1` | Verificações isoladas da aplicação e dos backups. |
| `assets/screenshots/terminal-preview.png` | Prévia exibida no README. |
| `assets/wallpapers/` | Coleção pessoal de 18 wallpapers, sem conversão. |
| `assets/icons/terminal.ico` | Ícone Gengar do perfil do Windows PowerShell. |
| `assets/manifest.json` | Arquivos de mídia selecionados e seus SHA-256. |
| `scripts/visual-assets.ps1` | Verificação e planejamento da aplicação dos recursos. |
| `tests/visual-assets.tests.ps1` | Verificações de cópia, backup, reaplicação e integração do ícone. |

## Compatibilidade do instalador atual

A entrada recomendada é `setup.ps1`; as opções estão em [Uso do setup](setup.md). O comando anterior continua disponível:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

O instalador lê o perfil de `config/powershell/profile.ps1` e os arquivos de `config/fastfetch/`. Os destinos permanecem:

- `$HOME/.config/fastfetch/config-purple.jsonc`;
- `$HOME/.config/fastfetch/Spider2-ascii.txt`;
- `$HOME/.config/fastfetch/custom-windows-terminal-profile.ps1`.

O nome do perfil instalado e os marcadores de integração ainda usam `custom-windows-terminal`. Eles foram mantidos para reconhecer instalações existentes e evitar adicionar a mesma integração novamente.

Os conteúdos anteriores dos arquivos alterados e o registro de cada execução ficam em `$HOME/.winux-setup/backups/`. O funcionamento está descrito em [Backups das configurações](backups.md). Os backups antigos do perfil não são removidos.

O perfil encontra o Fastfetch na pasta vizinha quando carregado a partir do repositório e na própria pasta depois de instalado.

O componente opcional `WindowsTerminal` aplica suas preferências no `settings.json` da edição selecionada, com backup e preservação dos perfis locais. Veja [Windows Terminal](windows-terminal.md). A instalação opcional dos programas está descrita em [Instalação dos programas](programas.md). A importação das configurações locais dos demais componentes continua nas etapas correspondentes.

## Recursos e arquivos locais

As capturas públicas ficam em `assets/screenshots/`. O `.gitignore` mantém a exceção para a prévia do terminal já publicada; novas capturas precisam ser adicionadas de forma explícita. A coleção pessoal de wallpapers e o ícone ficam em `assets/wallpapers/` e `assets/icons/`, com seleção registrada em `assets/manifest.json`. A aplicação usa `$HOME/Pictures/wallpaper` e `$HOME/Pictures/winux-setup/terminal.ico`; veja [Recursos visuais](recursos-visuais.md).

Backups, logs, credenciais, binários e arquivos específicos de um dispositivo não fazem parte das configurações compartilhadas. A opção `-DeviceConfig` seleciona variantes locais para cada máquina; veja [Ajustes por dispositivo](dispositivos.md). Novos arquivos em `devices/` são ignorados pelo Git, exceto o exemplo público.

