# Uso do setup

O ponto de entrada do projeto é `setup.ps1`, na raiz do repositório.

## Componentes disponíveis

| Componente | O que aplica |
| --- | --- |
| `Fastfetch` | Configuração e logo ASCII do Fastfetch. |
| `PowerShell` | Perfil compartilhável e sua integração ao perfil da sessão. Inclui os arquivos do Fastfetch, que são uma dependência desse perfil. |

Sem `-Components`, os dois componentes são selecionados. Komorebi, YASB, whkd, btop4win e matrix-rain serão incorporados nas etapas seguintes; ainda não são opções do setup.

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

Os destinos, os marcadores e o backup do perfil continuam descritos em [Estrutura do projeto](estrutura.md). A proteção atual faz backup do perfil antes de adicionar a integração; a cópia dos arquivos do Fastfetch ainda usa substituição direta. Backups completos das configurações e restauração serão implementados em uma etapa própria.

A instalação dos programas ainda não está implementada. Se o Fastfetch estiver ausente, instale-o e abra uma nova sessão antes de repetir o comando.
