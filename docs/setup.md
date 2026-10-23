# Uso do setup

O ponto de entrada do projeto é `setup.ps1`, na raiz do repositório.

## Componentes disponíveis

| Componente | O que aplica |
| --- | --- |
| `Fastfetch` | Configuração e logo ASCII do Fastfetch. |
| `PowerShell` | Perfil compartilhável e sua integração ao perfil da sessão. Inclui os arquivos do Fastfetch, que são uma dependência desse perfil. |

Sem `-Components`, os dois componentes são selecionados. As configurações do Komorebi, YASB, whkd, btop4win e matrix-rain serão incorporadas nas etapas seguintes; ainda não são opções de `-Components`. A instalação dos programas tem uma seleção separada, descrita em [Instalação dos programas](programas.md).

## Verificar antes de aplicar

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Check
```

O comando verifica:

- se a sessão está no Windows e usa PowerShell 5.1 ou superior;
- se o instalador e os arquivos necessários aos componentes selecionados existem;
- se o executável do Fastfetch está disponível no PATH.

A verificação não copia arquivos, não edita o perfil e não instala programas. Fontes, o tema do Windows Terminal e as dependências opcionais continuam seguindo as instruções do README.

## Simular a aplicação

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -WhatIf
```

O setup verifica os pré-requisitos e informa a operação prevista, sem aplicar as configurações.

## Aplicar os componentes disponíveis

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Somente o Fastfetch:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Components Fastfetch
```

Perfil do PowerShell com sua dependência do Fastfetch:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Components PowerShell
```

Para copiar os arquivos do perfil sem editar a integração no perfil da sessão, acrescente `-SkipProfile`. Esse comportamento mantém a opção do instalador anterior.

## Compatibilidade

O comando `powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1` continua disponível. Sem parâmetros, aplica os mesmos arquivos de antes. O script também aceita `-Components`, `-SkipProfile` e `-WhatIf`.

A entrada principal acrescenta a verificação do sistema e do executável do Fastfetch. Os dois scripts verificam a presença dos arquivos de configuração antes de copiá-los.

Os destinos, os marcadores e o backup do perfil continuam descritos em [Estrutura do projeto](estrutura.md). Todos os arquivos existentes que precisarem mudar são salvos antes das substituições, com registro por execução. Arquivos idênticos não são regravados. Consulte [Backups das configurações](backups.md). A restauração automática será implementada em uma etapa própria.

## Instalar programas antes de aplicar as configurações

Use `-InstallPrograms` para executar a instalação via WinGet antes da aplicação das configurações. A opção `-Programs` seleciona programas do catálogo, enquanto `-Components` seleciona configurações. Por exemplo, `-Programs PowerShell` instala PowerShell 7 e `-Components PowerShell` aplica o perfil na edição da sessão atual.

`-Check` e `-WhatIf` também funcionam com `-InstallPrograms`, sem executar o WinGet. Os aceites de termos são opcionais e explícitos por meio de `-AcceptAgreements`. Veja o [catálogo e os exemplos](programas.md).

Se o Fastfetch estiver ausente e não tiver sido selecionado para instalação, o setup interrompe a execução antes de alterar as configurações.
