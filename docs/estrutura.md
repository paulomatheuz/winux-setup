# Estrutura do projeto

## Organização

| Pasta | Conteúdo |
| --- | --- |
| `config/` | Configurações compartilháveis, separadas por ferramenta. |
| `scripts/` | Scripts de instalação e manutenção. |
| `assets/` | Recursos visuais usados pelo projeto. |
| `docs/` | Inventário, organização e instruções complementares. |

Cada ferramenta tem sua própria pasta em `config/` quando seus arquivos são incorporados. As configurações pessoais do Komorebi já estão incluídas. YASB e whkd continuam previstos no [inventário](inventario.md), incluindo o `styles.css` do YASB.

## Arquivos atuais

| Caminho no repositório | Uso |
| --- | --- |
| `config/fastfetch/config-purple.jsonc` | Configuração do Fastfetch. |
| `config/komorebi/komorebi.json` | Preferências pessoais, layouts e espaços de trabalho. |
| `config/komorebi/komorebi.bar.json` | Barra alternativa, sem ativação automática. |
| `config/komorebi/applications.json` | Cópia local das regras de aplicativos. |
| `config/komorebi/applications.LICENSE` | Licença da base de regras. |
| `scripts/komorebi.ps1` | Planejamento dos arquivos e adaptação do caminho das regras. |
| `tests/komorebi.tests.ps1` | Verificações isoladas do componente Komorebi. |
| `config/fastfetch/Spider2-ascii.txt` | Logo ASCII. |
| `config/powershell/profile.ps1` | Perfil compartilhável do PowerShell. |
| `config/starship/starship.toml` | Base atual do prompt, com os módulos e estilos padrão. |
| `scripts/starship.ps1` | Resolução do destino padrão ou de `STARSHIP_CONFIG`. |
| `tests/starship.tests.ps1` | Verificações isoladas da aplicação do Starship. |
| `config/windows-terminal/settings.json.example` | Temas, fonte, transparência e atalhos do Windows Terminal. |
| `scripts/windows-terminal.ps1` | Leitura de JSON com comentários, seleção do destino e combinação das preferências. |
| `tests/windows-terminal.tests.ps1` | Verificações isoladas do componente Windows Terminal. |
| `setup.ps1` | Entrada principal com seleção de componentes, verificação de pré-requisitos, instalação opcional de programas e simulação. |
| `packages.psd1` | Catálogo dos programas instaláveis via WinGet. |
| `modules.psd1` | Catálogo das dependências opcionais do perfil. |
| `scripts/install-modules.ps1` | Instalação de z e PSReadLine para o usuário atual. |
| `scripts/install-programs.ps1` | Instalação dos programas selecionados, com preservação das versões existentes. |
| `scripts/install.ps1` | Aplicação dos arquivos da configuração atual do terminal. |
| `scripts/configuration.ps1` | Planejamento, backups e registro das alterações dos arquivos. |
| `tests/configuration.tests.ps1` | Verificações isoladas da aplicação e dos backups. |
| `assets/screenshots/terminal-preview.png` | Prévia exibida no README. |

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

As imagens públicas ficam em `assets/screenshots/`. O `.gitignore` mantém a exceção para a prévia do terminal já publicada; novas capturas precisam ser adicionadas de forma explícita.

Backups, logs, credenciais, binários e arquivos específicos de um dispositivo não fazem parte das configurações compartilhadas. Os ajustes por dispositivo e a separação dos valores privados serão implementados nas etapas correspondentes.

