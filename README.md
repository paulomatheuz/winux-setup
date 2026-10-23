# winux-setup

Minhas configurações para Windows, reunidas em um só lugar para facilitar a instalação e a reprodução do meu ambiente em outros dispositivos.

O projeto começou como `custom-windows-terminal`, com a personalização do meu terminal. Agora, a proposta é incluir também o desktop, os atalhos e as automações que uso no dia a dia.

![Prévia do terminal](assets/screenshots/terminal-preview.png)

## Estado atual

Por enquanto, o repositório contém as configurações do terminal e um setup com seleção de componentes, verificação de pré-requisitos e simulação. Ele copia os arquivos do Fastfetch e integra o perfil do PowerShell. A instalação dos programas e a configuração completa do desktop ainda serão implementadas.

## O que já está incluído

- tema roxo para o Windows Terminal;
- Fastfetch com logo ASCII personalizada;
- perfil do PowerShell;
- integração com Starship;
- comandos como `clear`, `cls`, `ls`, `ll`, `la` e `cd`.

## Requisitos atuais

Instale os requisitos antes de executar o script:

- Git, para clonar o repositório;
- Windows Terminal;
- Windows PowerShell 5.1 ou PowerShell 7;
- Fastfetch;
- uma Nerd Font.

Starship, `lsd` e o módulo `z` são opcionais.

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

Aplique os componentes disponíveis:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

O instalador copia os arquivos do Fastfetch e o perfil do projeto para `$HOME\.config\fastfetch`. Antes de adicionar a integração ao perfil do PowerShell, salva um backup desse perfil.

Esse script aplica a configuração atual do terminal; ele ainda não instala os programas nem configura os componentes do desktop.

Para aplicar apenas o Fastfetch, acrescente `-Components Fastfetch`. A opção `PowerShell` inclui os arquivos do Fastfetch usados pelo perfil. Consulte as [opções do setup](docs/setup.md) para os detalhes e a compatibilidade com o instalador anterior.

Depois, feche e abra novamente o Windows Terminal.

## Tema do Windows Terminal

O esquema de cores está em:

```text
config/windows-terminal/settings.json.example
```

Copie o esquema `Spider Purple` para o `settings.json` do seu Windows Terminal. Faça um backup antes de editar o arquivo.

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
│   ├── estrutura.md
│   ├── inventario.md
│   └── setup.md
├── scripts/
│   └── install.ps1
├── setup.ps1
└── README.md
```

A organização das pastas e os caminhos de instalação estão descritos em [Estrutura do projeto](docs/estrutura.md).

## Próximas etapas

As mudanças serão feitas aos poucos, em commits separados:

- [x] Inventariar as configurações e dependências do ambiente atual ([inventário](docs/inventario.md)).
- [x] Organizar as configurações e os scripts para receber os demais componentes.
- [x] Criar a entrada do setup com seleção de componentes, verificação de pré-requisitos e simulação.
- [ ] Automatizar a instalação dos programas e a aplicação das configurações com backup.
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
