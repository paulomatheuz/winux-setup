# btop4win

O componente `Btop` aplica `btop.conf`, `themes/NeutralPurple.theme` e a licença da base btop4win, com backup. A configuração pessoal foi preservada, adaptando somente `color_theme` para o nome portátil `NeutralPurple`; o tema foi importado integralmente.

Permanecem o fundo do tema desativado, truecolor, gráficos `tty`, caixas `cpu mem proc`, atualização de 1500 ms, processos ordenados por memória e as demais opções do arquivo local. `force_tty = True` também foi mantido: nesse modo, o btop4win usa as cores TTY em vez da paleta personalizada. Para usar NeutralPurple visualmente, essa opção precisa ser desativada por escolha do usuário.

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components Btop -Check
.\setup.ps1 -Components Btop -WhatIf
.\setup.ps1 -Components Btop
```

Sem seleção explícita, o setup continua aplicando somente Fastfetch e PowerShell. A seleção isolada de Btop dispensa Fastfetch e pode preparar os arquivos antes de o programa estar instalado.

## Instalação opcional

O catálogo inclui btop4win 1.0.5, versão confirmada no executável do ambiente e no [manifesto oficial do WinGet](https://github.com/microsoft/winget-pkgs/blob/master/manifests/a/aristocratos/btop4win/1.0.5/aristocratos.btop4win.installer.yaml):

```powershell
.\setup.ps1 -Components Btop -InstallPrograms -Programs Btop -AcceptAgreements
```

Os aceites de termos são explícitos; `--no-upgrade` preserva instalações existentes. O pacote é portátil, tem dependência do Visual C++ Redistributable x64 e publica o comando `btop`. O perfil do projeto reconhece `btop4win` e `btop` no PATH antes de procurar a pasta portátil pessoal. Para atualizar também o perfil instalado, selecione `-Components PowerShell, Btop` dentro do PowerShell.

## Destino

O [btop4win](https://github.com/aristocratos/btop4win) lê `btop.conf` e a pasta `themes` ao lado do próprio executável. O setup procura:

1. `btop4win` ou `btop` no PATH, resolvendo links simbólicos para localizar `btop4win.exe`;
2. `$HOME/Tools/btop4win/btop4win/btop4win.exe`;
3. `$HOME/Tools/btop4win/btop4win.exe` e depois outras subpastas de `$HOME/Tools/btop4win`.

Sem um executável encontrado, prepara a pasta `$HOME/Tools/btop4win/btop4win`. A instalação pelo WinGet pode revelar outro destino depois de atualizar o PATH da sessão; o instalador confere novamente o executável após essa instalação e exibe a pasta usada.

Para escolher a pasta que contém seu executável, use um caminho absoluto:

```powershell
.\setup.ps1 -Components Btop -BtopDirectory 'D:\Ferramentas\btop4win' -Check
.\setup.ps1 -Components Btop -BtopDirectory 'D:\Ferramentas\btop4win'
```

`-BtopDirectory` determina apenas onde aplicar os arquivos; não move o programa, não altera o PATH e não muda a busca do comando `btop` no perfil. A pasta precisa permitir escrita. Ao usar outro executável ou múltiplas cópias, confirme o destino exibido antes de aplicar.

Arquivos existentes são substituídos após [backup completo](backups.md), sem combinar opções com a versão do projeto. Arquivos idênticos não são regravados nem geram outro backup. Binários, DLLs, logs e arquivos `.bak` locais não fazem parte da importação. A licença Apache 2.0 da base acompanha `BTOP.LICENSE`.

Feche o btop4win antes de aplicar e abra novamente depois, para evitar que uma sessão antiga salve opções sobre os arquivos atualizados. O setup não inicia o monitor nem instala drivers. As opções pessoais de sensores e GPU permanecem no arquivo; sua disponibilidade depende do hardware e dos componentes presentes no dispositivo.

## Verificação isolada

```powershell
.\tests\btop.tests.ps1 -TestRoot "$env:TEMP\winux-btop-tests"
.\tests\powershell.tests.ps1 -TestRoot "$env:TEMP\winux-profile-tests"
```

Os testes verificam destinos, um link simbólico simulado do WinGet, cópia integral, backup, reaplicação e os argumentos de uma instalação simulada. Nenhum programa é instalado e o monitor não é iniciado pelos testes. A comparação com a origem confirmou somente a adaptação do caminho do tema. A aparência e os sensores em outro dispositivo ainda precisam ser conferidos.
