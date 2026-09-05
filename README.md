# Custom Windows Terminal

Este repositório contém a configuração que uso no meu terminal do Windows.

![Prévia do terminal](screenshots/terminal-preview.png)

Criei porque amigos sempre perguntavam como eu personalizava meu terminal. A ideia é deixar tudo organizado para quem quiser copiar e usar de forma rápida.

## O que está incluído

- tema roxo para o Windows Terminal;
- Fastfetch com logo ASCII personalizada;
- perfil do PowerShell;
- integração com Starship;
- comandos como `clear`, `cls`, `ls`, `ll`, `la` e `cd`.

## Requisitos

- Windows Terminal;
- Windows PowerShell 5.1 ou PowerShell 7;
- Fastfetch;
- uma Nerd Font.

Starship, `lsd` e o módulo `z` são opcionais.

## Como instalar

Clone o repositório:

```powershell
git clone https://github.com/paulomatheuz/custom-windows-terminal.git
cd custom-windows-terminal
```

Execute o instalador:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

O instalador copia os arquivos do Fastfetch e salva um backup do perfil atual do PowerShell antes de adicionar a configuração.

Depois, feche e abra novamente o Windows Terminal.

## Tema do Windows Terminal

O esquema de cores está em:

```text
WindowsTerminal/settings.json.example
```

Copie o esquema `Spider Purple` para o `settings.json` do seu Windows Terminal. Faça um backup antes de editar o arquivo.

## Estrutura

```text
custom-windows-terminal/
├── config/fastfetch/
├── PowerShell/
├── WindowsTerminal/
├── scripts/
└── README.md
```

## Observação

Este repositório é apenas uma cópia organizada do meu terminal para quem quiser usar ou adaptar.