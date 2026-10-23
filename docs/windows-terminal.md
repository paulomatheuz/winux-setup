# Windows Terminal

O componente `WindowsTerminal` aplica as preferências de `config/windows-terminal/settings.json.example`: fonte JetBrainsMonoNL Nerd Font Propo, tamanho 12, tema escuro, esquemas Hurtado, Spider Purple e catppuccin-mocha, transparência e atalhos pessoais. O perfil integrado do Windows PowerShell recebe o nome e o título `paulomatheuz`, opacidade 40 e cursor em barra; o Prompt de Comando recebe opacidade 22.

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components WindowsTerminal -Check
.\setup.ps1 -Components WindowsTerminal -WhatIf
.\setup.ps1 -Components WindowsTerminal
```

Para combinar com o perfil e o Fastfetch, execute dentro de uma sessão do PowerShell:

```powershell
.\setup.ps1 -Components Fastfetch, PowerShell, WindowsTerminal
```

O componente é opcional: sem `-Components`, o setup continua aplicando Fastfetch e PowerShell. A seleção isolada de `WindowsTerminal` dispensa o Fastfetch. Para também instalar o aplicativo pelo catálogo, acrescente `-InstallPrograms -Programs WindowsTerminal`; os aceites de termos usam `-AcceptAgreements`.

## Destino

O setup procura configurações existentes das edições Stable, Preview, Canary e da instalação sem pacote. Os caminhos seguem a [documentação do Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/faq). Se encontrar mais de uma configuração, interrompe a execução para exigir uma seleção explícita:

```powershell
.\setup.ps1 -Components WindowsTerminal -TerminalSettingsPath 'C:\caminho\settings.json' -Check
.\setup.ps1 -Components WindowsTerminal -TerminalSettingsPath 'C:\caminho\settings.json'
```

Sem configuração existente, prepara o arquivo da edição Stable em `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`. Um caminho explícito também pode apontar para um arquivo novo. Confirme o destino exibido por `-Check` antes de aplicar.

## Preservação e backups

O setup mantém o perfil padrão, comandos, ícones, visibilidade e perfis próprios do computador. As preferências visuais dos dois perfis integrados são reconhecidas pelos GUIDs padrão do Windows Terminal; os perfis dinâmicos do PowerShell 7 e do WSL continuam com suas configurações, herdando apenas os padrões visuais quando não os sobrescrevem. Os esquemas são atualizados pelo nome, sem remover outros temas de cores.

Os quatro atalhos compartilhados substituem associações existentes das mesmas teclas; os demais atalhos e as definições de ações são preservados. Teclas alternativas em uma mesma associação são mantidas. Menus de nova aba e temas de interface locais permanecem no arquivo.

Configurações com comentários e vírgulas finais são aceitas. Quando há alterações, o resultado é JSON formatado em UTF-8, sem comentários. O arquivo original completo, incluindo comentários e codificação, fica no [backup da execução](backups.md). Sem alterações nas preferências, o arquivo não é regravado e nenhum backup novo é criado. Mudanças detectadas no destino durante o planejamento ou a aplicação interrompem a execução.

A fonte precisa estar instalada no dispositivo; sua instalação e a inclusão do ícone pessoal ficam para a etapa de recursos visuais. Feche e abra o Terminal depois da aplicação. Esta etapa valida os arquivos e a integração do setup; a aparência final em outro dispositivo ainda precisa ser conferida.

## Verificação isolada

```powershell
.\tests\windows-terminal.tests.ps1 -TestRoot "$env:TEMP\winux-terminal-tests"
```

Os testes usam arquivos temporários e verificam a combinação das preferências, os backups, a reaplicação, a detecção de edições e as simulações. Nenhuma configuração real do Terminal é alterada pelos testes.
