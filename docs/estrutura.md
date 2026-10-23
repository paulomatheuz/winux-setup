# Estrutura do projeto

## Organização

| Pasta | Conteúdo |
| --- | --- |
| `config/` | Configurações compartilháveis, separadas por ferramenta. |
| `scripts/` | Scripts de instalação e manutenção. |
| `assets/` | Recursos visuais usados pelo projeto. |
| `docs/` | Inventário, organização e instruções complementares. |

Cada ferramenta terá sua própria pasta em `config/` quando seus arquivos forem incorporados. As configurações pessoais do Komorebi, do YASB e do whkd continuam previstas no [inventário](inventario.md), incluindo o `styles.css` do YASB.

## Arquivos atuais

| Caminho no repositório | Uso |
| --- | --- |
| `config/fastfetch/config-purple.jsonc` | Configuração do Fastfetch. |
| `config/fastfetch/Spider2-ascii.txt` | Logo ASCII. |
| `config/powershell/profile.ps1` | Perfil compartilhável do PowerShell. |
| `config/windows-terminal/settings.json.example` | Tema e preferências de fonte do Windows Terminal. |
| `setup.ps1` | Entrada principal com seleção de componentes, verificação de pré-requisitos, instalação opcional de programas e simulação. |
| `packages.psd1` | Catálogo dos programas instaláveis via WinGet. |
| `scripts/install-programs.ps1` | Instalação dos programas selecionados, com preservação das versões existentes. |
| `scripts/install.ps1` | Aplicação dos arquivos da configuração atual do terminal. |
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

O nome do perfil instalado, os marcadores de integração e o nome do backup ainda usam `custom-windows-terminal`. Eles foram mantidos para reconhecer instalações existentes e evitar adicionar a mesma integração novamente.

O perfil encontra o Fastfetch na pasta vizinha quando carregado a partir do repositório e na própria pasta depois de instalado.

O tema do Windows Terminal continua sendo aplicado manualmente conforme o README. A instalação opcional dos programas está descrita em [Instalação dos programas](programas.md). A importação das configurações locais dos demais componentes continua nas etapas correspondentes.

## Recursos e arquivos locais

As imagens públicas ficam em `assets/screenshots/`. O `.gitignore` mantém a exceção para a prévia do terminal já publicada; novas capturas precisam ser adicionadas de forma explícita.

Backups, logs, credenciais, binários e arquivos específicos de um dispositivo não fazem parte das configurações compartilhadas. Os ajustes por dispositivo e a separação dos valores privados serão implementados nas etapas correspondentes.
