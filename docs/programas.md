# Instalação dos programas

A instalação é opcional. Sem `-InstallPrograms`, o setup continua aplicando somente as configurações disponíveis.

## Catálogo

O arquivo `packages.psd1` contém os identificadores dos pacotes na fonte `winget`.

| Nome usado no setup | Identificador | Versão para novas instalações |
| --- | --- | --- |
| `WindowsTerminal` | `Microsoft.WindowsTerminal` | Disponível no WinGet. |
| `PowerShell` | `Microsoft.PowerShell` | Disponível no WinGet. |
| `Fastfetch` | `Fastfetch-cli.Fastfetch` | Disponível no WinGet. |
| `Starship` | `Starship.Starship` | Disponível no WinGet. |
| `Lsd` | `lsd-rs.lsd` | Disponível no WinGet. |
| `Komorebi` | `LGUG2Z.komorebi` | 0.1.41. |
| `Whkd` | `LGUG2Z.whkd` | 0.2.10. |
| `Yasb` | `AmN.yasb` | 2.0.7. |

As versões iniciais do Komorebi, whkd e YASB correspondem ao ambiente inventariado. Elas poderão ser alteradas no catálogo após validar as configurações. O script usa `--no-upgrade`: uma instalação existente é preservada, mesmo que sua versão seja diferente da indicada.

Os identificadores foram conferidos no [catálogo da Microsoft](https://github.com/microsoft/winget-pkgs/tree/master/manifests). A seleção exata do pacote e da fonte, as opções de instalação silenciosa e `--no-upgrade` seguem a [documentação do WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install).

btop4win, matrix-rain e fontes terão seus métodos de instalação incorporados nas etapas correspondentes. A instalação opcional dos módulos do PowerShell usa `-InstallModules` e está descrita em [Perfil do PowerShell](powershell.md). Nenhum binário é armazenado neste repositório.

## Pré-requisitos

- Windows, com Windows PowerShell 5.1 ou PowerShell 7.
- WinGet disponível e funcionando, fornecido pelo Instalador de Aplicativo da Microsoft.
- Acesso à internet para obter os pacotes durante a instalação.

O setup não instala o próprio WinGet. Os instaladores de alguns pacotes podem solicitar elevação de privilégios.

## Verificar e simular

Verificar o catálogo, a seleção e a presença do comando WinGet:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallPrograms -Check
```

Simular os programas e as configurações selecionados:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallPrograms -WhatIf
```

Esses modos não executam o WinGet, não consultam a disponibilidade online dos pacotes e não modificam o PATH nem as configurações.

## Instalar e aplicar as configurações disponíveis

Após revisar as licenças dos programas e da fonte:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallPrograms -AcceptAgreements
```

`-AcceptAgreements` encaminha os aceites de termos da fonte e dos pacotes ao WinGet. Sem essa opção, esses aceites não são enviados; uma instalação que precisar deles será interrompida, pois os prompts de interação estão desativados.

Para selecionar programas, use `-Programs`. Dentro de uma sessão PowerShell, listas são separadas por vírgulas:

```powershell
.\setup.ps1 -InstallPrograms -Programs Fastfetch,Starship,Lsd -AcceptAgreements
```

Se o Fastfetch estiver ausente, a seleção precisa incluí-lo antes de aplicar as configurações atuais. Sem `-Programs`, todos os oito programas do catálogo são selecionados.

## Instalar apenas programas

Para instalar sem aplicar as configurações, use o script específico:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-programs.ps1 -AcceptAgreements
```

Ele também aceita `-Programs`, `-Check` e `-WhatIf`.

## Comportamento e falhas

- O WinGet é chamado com identificador exato, fonte `winget`, instalação silenciosa e `--no-upgrade`.
- Repetições na seleção não executam o mesmo pacote duas vezes.
- Cada resultado é conferido; falhas interrompem a sequência. O setup não aplica as configurações após uma falha de instalação.
- Uma falha não desinstala programas que já foram instalados com sucesso. A execução pode ser repetida após corrigir o problema.
- Os códigos do WinGet para pacote já instalado ou atualização não aplicável são tratados como instalação existente preservada. Os demais códigos, incluindo pedidos de reinicialização, interrompem a execução e são informados.
- Após a instalação, o PATH é atualizado somente no processo atual, mantendo suas entradas e acrescentando os caminhos registrados pelo sistema e pelo usuário. Se o Fastfetch continuar indisponível, abra uma nova sessão e repita o setup.
- Instalar PowerShell 7 não muda a edição da sessão atual. A configuração do perfil é aplicada à sessão que executa o setup.
- Instalar Komorebi, whkd e YASB ainda não importa suas configurações personalizadas nem cria a inicialização automática. Essas integrações seguem o inventário e serão adicionadas nos próximos commits.

Os códigos de resultado tratados seguem as [definições do WinGet](https://github.com/microsoft/winget-cli/blob/master/src/AppInstallerSharedLib/Public/AppInstallerErrors.h).
