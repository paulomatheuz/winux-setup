# winux-setup

Minhas configurações para Windows, reunidas em um só lugar para facilitar a instalação e a reprodução do meu ambiente em outros dispositivos.

O projeto começou como `custom-windows-terminal`, com a personalização do meu terminal. Agora, a proposta é incluir também o desktop, os atalhos e as automações que uso no dia a dia.

![Prévia do terminal](assets/screenshots/terminal-preview.png)

## Estado atual

O setup copia os arquivos do Fastfetch, integra o perfil do PowerShell e aplica opcionalmente minhas preferências do Windows Terminal, com backup. A instalação opcional dos programas está disponível via WinGet. A importação das configurações personalizadas do desktop será implementada nas próximas etapas.

## O que já está incluído

- temas, fonte, transparência e atalhos pessoais do Windows Terminal;
- Fastfetch com logo ASCII personalizada;
- perfil do PowerShell com os comandos pessoais dos dois perfis locais;
- integração com Starship;
- comandos como `clear`, `cls`, `Clear-Terminal`, `ls`, `ll`, `la`, `cd`, `btop` e `rain`;
- instalação opcional dos módulos z e PSReadLine.

## Requisitos atuais

Para aplicar as configurações sem instalar programas, tenha os requisitos abaixo. A opção `-InstallPrograms` instala os programas do catálogo via WinGet:

- Git, para clonar o repositório;
- Windows Terminal;
- Windows PowerShell 5.1 ou PowerShell 7;
- Fastfetch;
- uma Nerd Font.

Starship, `lsd`, `z` e PSReadLine são opcionais. Os módulos podem ser instalados com `-InstallModules -AcceptAgreements`. Consulte o [perfil do PowerShell e suas dependências](docs/powershell.md).

## Como instalar a configuração atual

Clone o repositório:

```powershell
git clone https://github.com/paulomatheuz/winux-setup.git
cd winux-setup
```

Verifique os pré-requisitos:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Check
```

Simule a aplicação:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -WhatIf
```

Aplique Fastfetch e PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

O instalador copia os arquivos do Fastfetch e o perfil do projeto para `$HOME\.config\fastfetch`. Antes de substituir qualquer arquivo existente, salva seu conteúdo anterior em `$HOME\.winux-setup\backups`, junto de um registro das alterações. Arquivos idênticos não são regravados. Veja os [detalhes dos backups](docs/backups.md).

Sem `-InstallPrograms`, o setup aplica apenas a configuração atual do terminal. Para instalar os programas do catálogo e depois aplicar essa configuração:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallPrograms -AcceptAgreements
```

A opção `-AcceptAgreements` aceita os termos da fonte e dos pacotes. Consulte o [catálogo e as opções de instalação](docs/programas.md) antes de usar. As configurações personalizadas do desktop serão incorporadas nas etapas próprias de cada ferramenta.

Para aplicar apenas o Fastfetch, acrescente `-Components Fastfetch`. A opção `PowerShell` inclui os arquivos do Fastfetch usados pelo perfil. Consulte as [opções do setup](docs/setup.md) para os detalhes e a compatibilidade com o instalador anterior.

Depois, feche e abra novamente o Windows Terminal.

## Tema do Windows Terminal

O esquema de cores está em:

```text
config/windows-terminal/settings.json.example
```

Para aplicar as preferências automaticamente, com backup e preservação dos perfis locais:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Components WindowsTerminal -Check
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Components WindowsTerminal
```

Esse componente é opcional e não exige Fastfetch. Veja os [destinos, a seleção da edição e as preferências preservadas](docs/windows-terminal.md). A fonte precisa estar instalada no dispositivo.

## Estrutura atual

```text
winux-setup/
├── assets/
│   └── screenshots/
├── config/
│   ├── fastfetch/
│   ├── powershell/
│   └── windows-terminal/
├── docs/
│   ├── backups.md
│   ├── estrutura.md
│   ├── inventario.md
│   ├── powershell.md
│   ├── programas.md
│   ├── setup.md
│   └── windows-terminal.md
├── scripts/
│   ├── configuration.ps1
│   ├── install-modules.ps1
│   ├── install-programs.ps1
│   ├── install.ps1
│   └── windows-terminal.ps1
├── tests/
│   ├── configuration.tests.ps1
│   ├── modules.tests.ps1
│   ├── powershell.tests.ps1
│   └── windows-terminal.tests.ps1
├── modules.psd1
├── packages.psd1
├── setup.ps1
└── README.md
```

A organização das pastas e os caminhos de instalação estão descritos em [Estrutura do projeto](docs/estrutura.md).

## Próximas etapas

As mudanças serão feitas aos poucos, em commits separados:

- [x] Inventariar as configurações e dependências do ambiente atual ([inventário](docs/inventario.md)).
- [x] Organizar as configurações e os scripts para receber os demais componentes.
- [x] Criar a entrada do setup com seleção de componentes, verificação de pré-requisitos e simulação.
- [x] Automatizar a instalação dos programas do catálogo via WinGet.
- [x] Aplicar as configurações com backup dos arquivos anteriores e registro das alterações.
- [x] Incorporar os comandos dos perfis pessoais do PowerShell e a instalação opcional dos módulos.
- [x] Incorporar as preferências pessoais do Windows Terminal e sua aplicação com backup.
- [ ] Incorporar as configurações do Starship.
- [ ] Adicionar Komorebi, YASB e whkd, com suas integrações e atalhos.
- [ ] Adicionar btop e Chuva.
- [ ] Incluir fontes, temas e os recursos visuais necessários.
- [ ] Configurar a inicialização automática dos componentes.
- [ ] Permitir ajustes específicos por dispositivo.
- [ ] Permitir atualizar o ambiente executando o setup novamente e restaurar backups.
- [ ] Validar o setup em outro dispositivo e documentar o processo.

## Personalização

As configurações refletem meu uso pessoal. Você pode usá-las como base e adaptar temas, atalhos e ferramentas ao seu ambiente.

