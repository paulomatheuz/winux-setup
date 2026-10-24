# Recursos visuais

O componente `VisualAssets` aplica a coleção pessoal versionada em `assets/wallpapers/` e o ícone Gengar em `assets/icons/terminal.ico`. São 18 wallpapers e um ícone, preservados integralmente. `assets/manifest.json` registra os arquivos selecionados e seus SHA-256.

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components VisualAssets -Check
.\setup.ps1 -Components VisualAssets -WhatIf
.\setup.ps1 -Components VisualAssets
```

O componente é opcional e dispensa Fastfetch. Sem `-Components`, o setup continua aplicando apenas Fastfetch e PowerShell. Os destinos são:

- wallpapers: `$HOME/Pictures/wallpaper`, a mesma pasta usada pela configuração do YASB;
- ícone: `$HOME/Pictures/winux-setup/terminal.ico`.

Os arquivos existentes de mesmo nome são substituídos após [backup completo](backups.md). Arquivos locais extras não são apagados. Uma reaplicação sem mudanças não regrava arquivos nem cria outro backup. Os conteúdos são conferidos pelo manifesto antes da aplicação.

O componente prepara a galeria; não escolhe um wallpaper do Windows nem altera a imagem atual. O YASB continua usando sua configuração e seus controles para abrir a galeria ou trocar o wallpaper. Os aplicativos não são iniciados pelo setup.

## Ícone do Terminal

Para aplicar também a referência do ícone, combine os dois componentes dentro do PowerShell:

```powershell
.\setup.ps1 -Components VisualAssets, WindowsTerminal -Check
.\setup.ps1 -Components VisualAssets, WindowsTerminal -WhatIf
.\setup.ps1 -Components VisualAssets, WindowsTerminal
```

As imagens e o `settings.json` participam do mesmo planejamento e registro de backup. O caminho do ícone é gerado no dispositivo e aplicado ao perfil integrado do Windows PowerShell, reconhecido pelo GUID padrão. O perfil padrão, seus comandos e os demais perfis do dispositivo são preservados.

`-TerminalSettingsPath` continua disponível para escolher a edição do Terminal. A seleção isolada de `VisualAssets` apenas copia o ícone, sem editar o Terminal. A seleção isolada de `WindowsTerminal` preserva o ícone já configurado. Reabra o Terminal para conferir a aparência.

## Coleção versionada

Os 18 wallpapers e o ícone foram importados da coleção pessoal usada no ambiente. Os nomes dos wallpapers foram mantidos. A versão pública do repositório inclui os próprios arquivos; nenhum download adicional de imagens é necessário depois do clone.

Para mudar a coleção, atualize os arquivos e seus hashes no manifesto. Somente as entradas desse manifesto são aplicadas. A origem das imagens não é modificada e não há redimensionamento ou conversão durante a aplicação.

## Verificação isolada

```powershell
.\tests\visual-assets.tests.ps1 -TestRoot "$env:TEMP\winux-visual-tests"
```

Os testes verificam hashes, cópia integral, simulação, backup, ícone do Terminal, arquivos locais extras, reaplicação e origens inválidas em pastas temporárias. Não alteram a galeria real, o wallpaper atual nem o Terminal em uso. A conferência visual em outro dispositivo continua pendente.
