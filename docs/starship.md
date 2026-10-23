# Starship

O ambiente inventariado inicializa o Starship pelo perfil do PowerShell, sem um `starship.toml` personalizado. A configuração em `config/starship/starship.toml` registra essa base: formato padrão dos módulos e uma linha em branco entre prompts. Os demais módulos, símbolos e estilos usam os padrões do Starship instalado, conforme a [documentação oficial](https://starship.rs/config/).

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components Starship -Check
.\setup.ps1 -Components Starship -WhatIf
.\setup.ps1 -Components Starship
```

O componente é opcional e dispensa Fastfetch e o executável do Starship. Para instalar também o programa, acrescente `-InstallPrograms -Programs Starship`; os aceites de termos usam `-AcceptAgreements`. O arquivo só terá efeito quando o Starship estiver instalado e inicializado no shell.

O perfil do projeto já executa `starship init powershell` quando encontra o programa. Para aplicar também esse perfil e os demais componentes, execute dentro do PowerShell:

```powershell
.\setup.ps1 -Components PowerShell, WindowsTerminal, Starship
```

PowerShell inclui a dependência do Fastfetch. Sem `-Components`, o setup continua selecionando somente Fastfetch e PowerShell.

## Destino e backup

O destino padrão é `$HOME/.config/starship.toml`. Se `STARSHIP_CONFIG` estiver definida na sessão que executa o setup, o componente usa esse caminho. Informe um caminho absoluto e mantenha o mesmo valor nas sessões que usarão o prompt:

```powershell
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
.\setup.ps1 -Components Starship -Check
```

O setup exibe o destino e não altera variáveis persistentes nem edita o perfil apenas para aplicar esse componente. Uma variável definida dentro de outro perfil só será considerada se esse perfil já tiver sido carregado na sessão do setup.

Ao selecionar Starship, o arquivo de destino é substituído pela configuração versionada, com [backup completo do conteúdo anterior](backups.md). As opções de um arquivo personalizado existente não são combinadas com a base do projeto. Confira o destino e mantenha suas personalizações no arquivo do repositório antes de aplicar. Arquivos idênticos não são regravados e não geram outro backup.

O visual padrão acompanha a versão instalada do Starship. Esta base não fixa todas as opções de cada módulo nem acrescenta uma paleta própria. A aparência pode variar com a versão, a fonte e o tema do terminal.

## Verificação isolada

```powershell
.\tests\starship.tests.ps1 -TestRoot "$env:TEMP\winux-starship-tests"
```

Os testes usam destinos temporários e verificam seleção isolada, caminho personalizado, simulações, backup e reaplicação. Eles não instalam o Starship nem alteram a configuração real do prompt.
