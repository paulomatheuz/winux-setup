# Fontes

O catálogo inclui `JetBrainsMonoNerdFont`, pacote `DEVCOM.JetBrainsMonoNerdFont` versão 3.3.0. O [manifesto da Microsoft](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/DEVCOM/JetBrainsMonoNerdFont/3.3.0/DEVCOM.JetBrainsMonoNerdFont.installer.yaml) aponta para o MSI mantido pela comunidade [DEVCOM](https://github.com/DevelopersCommunity/wix-JetBrainsMonoNF/tree/v3.3.0), baseado no Nerd Fonts. As fontes usam a SIL Open Font License 1.1.

## Instalar

Para instalar somente as fontes, sem aplicar configurações:

```powershell
.\scripts\install-programs.ps1 -Programs JetBrainsMonoNerdFont -Check
.\scripts\install-programs.ps1 -Programs JetBrainsMonoNerdFont -WhatIf
.\scripts\install-programs.ps1 -Programs JetBrainsMonoNerdFont -AcceptAgreements
```

Para combinar com o setup:

```powershell
.\setup.ps1 -InstallPrograms -Programs JetBrainsMonoNerdFont -AcceptAgreements
```

O setup principal continua aplicando os componentes selecionados; por padrão, Fastfetch e PowerShell, com seus pré-requisitos. Sem `-Programs`, `-InstallPrograms` seleciona todo o catálogo, incluindo essa fonte. Sem `-InstallPrograms`, nenhuma fonte é instalada.

Se as duas famílias Nerd necessárias ao Terminal e ao YASB já estiverem disponíveis, o pacote é ignorado, preservando instalações manuais. Caso contrário, instala o pacote completo com seleção exata, fonte `winget` e `--no-upgrade`. Uma instalação parcial pode receber fontes que já existiam; o tratamento desses arquivos segue o instalador MSI. Ele pode solicitar elevação de privilégios do Windows.

O pacote reconhecido pelo WinGet não é atualizado automaticamente. A instalação não modifica os nomes, tamanhos ou estilos configurados no Terminal e no CSS. Reabra os aplicativos depois de instalar; pode ser necessário iniciar uma nova sessão do Windows para que todos reconheçam as fontes.

## Verificar

```powershell
.\scripts\check-fonts.ps1
```

A verificação é somente leitura e dispensa WinGet. `Available` indica a presença da família. Os nomes curtos e longos da mesma variante são reconhecidos; `fonts.psd1` registra as dependências:

| Uso | Nome configurado | Nome alternativo |
| --- | --- | --- |
| Windows Terminal | JetBrainsMonoNL Nerd Font Propo | JetBrainsMonoNL NFP |
| YASB | JetBrainsMono NFP | JetBrainsMono Nerd Font Propo |
| Menus do YASB | Segoe UI | A própria família. |
| Ícones do YASB | Segoe Fluent Icons | A própria família. |
| Barra alternativa do Komorebi | JetBrains Mono | A própria família original. |

As variantes Mono (`NFM`) e Propo (`NFP`) não são consideradas equivalentes. A presença da família não garante cada glifo nem a renderização no mecanismo de fontes do aplicativo.

Segoe UI e Segoe Fluent Icons são verificadas separadamente; o pacote Nerd Font não as fornece. O repositório não copia fontes do Windows. Sua disponibilidade depende da instalação e da versão do sistema; ausências aparecem no relatório.

A barra alternativa do Komorebi mantém `JetBrains Mono`, diferente das variantes Nerd. O instalador desta etapa não fornece essa família original. Ela é marcada como opcional porque a barra alternativa não é iniciada pelo setup. Antes de usar a barra, instale a família pelo [projeto JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) ou escolha outra fonte conscientemente na configuração. O setup não substitui esse nome.

## Testes isolados

```powershell
.\tests\fonts.tests.ps1 -TestRoot "$env:TEMP\winux-font-tests"
```

Os testes usam listas de famílias e WinGet simulados. Verificam aliases, ausências, variantes, instalações manuais e parciais, simulação e argumentos do instalador no PowerShell 5.1 e 7. Nenhuma fonte é instalada ou removida. A aparência em outro dispositivo continua pendente.
