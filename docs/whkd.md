# whkd

O componente `Whkd` aplica o `config/whkd/whkdrc` pessoal integralmente, com backup. Mantém o shell `powershell` e os atalhos de foco, movimentação, pilhas, redimensionamento, layouts, pausa e espaços de trabalho. A versão 0.2.10 do programa está no catálogo de instalação.

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components Whkd -Check
.\setup.ps1 -Components Whkd -WhatIf
.\setup.ps1 -Components Whkd
```

A seleção é opcional e dispensa Fastfetch e o executável do whkd para preparar o arquivo. Para instalar também o programa, acrescente `-InstallPrograms -Programs Whkd`; os aceites de termos usam `-AcceptAgreements`. Os atalhos dependem do Komorebi disponível no PATH quando forem utilizados.

Para aplicar as três configurações do desktop em uma execução, use dentro do PowerShell:

```powershell
.\setup.ps1 -Components Komorebi, Yasb, Whkd -Check
.\setup.ps1 -Components Komorebi, Yasb, Whkd -WhatIf
.\setup.ps1 -Components Komorebi, Yasb, Whkd
```

Esses comandos aplicam configurações. O setup não inicia aplicativos, não aciona atalhos e não cria inicialização automática. Sem `-Components`, continuam selecionados apenas Fastfetch e PowerShell.

## Destino e backup

O destino padrão é `$HOME/.config/whkdrc`. Se `WHKD_CONFIG_HOME` estiver definida na sessão, o destino será `whkdrc` dentro dessa pasta, conforme o [projeto whkd](https://github.com/LGUG2Z/whkd/tree/v0.2.10). Informe um caminho absoluto para a pasta e mantenha o mesmo valor nas sessões que iniciarão o programa:

```powershell
$env:WHKD_CONFIG_HOME = "$HOME\.config"
.\setup.ps1 -Components Whkd -Check
```

Uma inicialização manual com `whkd --config outro-arquivo` usa esse outro arquivo e não muda o destino escolhido pelo setup. Variáveis persistentes não são alteradas.

O arquivo existente é substituído depois de um [backup completo](backups.md), sem combinar atalhos com a versão do projeto. A reaplicação sem mudanças não regrava o arquivo nem cria outro backup. Reinicie o whkd pelos seus controles habituais para carregar o arquivo aplicado.

## Atalhos preservados

| Teclas | Ação |
| --- | --- |
| Alt + H/J/K/L | Foco à esquerda, abaixo, acima e à direita. |
| Alt + Shift + H/J/K/L | Move a janela nessas direções. |
| Alt + setas | Empilha janelas. |
| Alt + Q / Alt + M | Fecha / minimiza a janela. |
| Alt + T / Alt + Shift + F | Alterna flutuação / modo monocle. |
| Alt + P / Alt + Shift + R | Alterna pausa / reorganiza as janelas. |
| Alt + 1 a 8 | Foca os espaços de trabalho de índice 0 a 7. |
| Alt + Shift + 1 a 8 | Move a janela para esses espaços. |
| Alt + O | Encerra o whkd e o inicia novamente em uma janela oculta. |
| Alt + Shift + O | Recarrega a configuração do Komorebi. |
| Alt + I | Alterna a visualização dos atalhos do Komorebi. |

Os demais atalhos e comentários estão no arquivo versionado. As teclas `oem_*` dependem do layout do teclado; foram mantidas como na origem.

O `whkdrc` tem atalhos para oito espaços, enquanto o `komorebi.json` define sete. Alt + 8 e Alt + Shift + 8 foram preservados, mas dependem de um oitavo espaço configurado no Komorebi. Esta etapa não cria esse espaço nem remove os atalhos. A adequação de monitores e espaços por dispositivo continua prevista.

Os comandos já presentes no [YASB](yasb.md) iniciam e encerram o Komorebi com `--whkd`. Eles continuam disponíveis na configuração; o setup não os executa.

## Verificação isolada

```powershell
.\tests\whkd.tests.ps1 -TestRoot "$env:TEMP\winux-whkd-tests"
```

Os testes verificam cópia integral, destinos, backup, reaplicação, atalhos duplicados e sintaxe dos comandos PowerShell, sem executar os comandos. Também verificam a aplicação conjunta de Komorebi, YASB e whkd em pastas temporárias. A sintaxe dos comandos não garante a disponibilidade de cada recurso do Komorebi nem substitui a conferência dos atalhos em outro dispositivo.

O modo `-Check` confere arquivos e destinos; não inicia o whkd nem registra atalhos no teclado.
