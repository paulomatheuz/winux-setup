# Validação do setup

O comando `scripts/validate.ps1` reúne os testes isolados do projeto. O roteiro abaixo separa esses resultados da conferência do ambiente instalado em outro dispositivo.

## Testes isolados

Na raiz do clone, execute com Windows PowerShell 5.1:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate.ps1
```

Se o PowerShell 7 estiver instalado, repita nele:

```powershell
pwsh -NoProfile -File .\scripts\validate.ps1
```

Cada comando usa a versão do PowerShell que o iniciou. As 15 verificações são executadas em processos separados, sem carregar o perfil, para que as funções e simulações de um teste não afetem os seguintes. O verificador também procura erros de sintaxe nos arquivos PowerShell de `scripts/`, `tests/` e `config/`.

Os testes usam destinos temporários e simulações de instalação, download e início de aplicativos. Os atalhos de teste são criados em pastas temporárias. O comando não instala programas nem registra a inicialização real do usuário. Ele não verifica a disponibilidade online dos pacotes e não comprova que o desktop funciona em um login real.

## Relatórios e diagnóstico

Uma pasta exclusiva é criada em `$env:TEMP/winux-validation/`. Seu caminho é exibido ao final. Dentro dela ficam:

- `summary.json`, com a versão do PowerShell, a seleção executada, erros de sintaxe, estados, códigos de saída, duração e SHA-256 dos arquivos de teste;
- uma pasta por verificação, com `stdout.log`, `stderr.log` e os arquivos temporários daquele teste.

O relatório usa `Scope: IsolatedTests`. `Selection: AllSuites` identifica a seleção completa padrão; uma execução com `-Suites` recebe `SelectedSuites`. Um resultado positivo para uma seleção parcial cobre somente os testes listados no relatório.

`Passed` indica código de saída zero. `Failed` indica erro, teste ausente ou código diferente de zero; `TimedOut` indica que o processo excedeu o limite por teste. O limite padrão é de 180 segundos e pode ser alterado com `-TimeoutSeconds`. As outras verificações continuam após uma falha. Ao final, o comando retorna código `1` se houver qualquer falha ou erro de sintaxe, e `0` se tudo passar. Se o comando for interrompido, o relatório pode permanecer em `Running` e não deve ser considerado aprovado.

Para guardar os resultados dentro de uma pasta já ignorada pelo Git:

```powershell
.\scripts\validate.ps1 -ReportRoot .\.winux-setup\validation
```

Para repetir somente verificações específicas, execute dentro do PowerShell:

```powershell
.\scripts\validate.ps1 -Suites komorebi,yasb,whkd -TimeoutSeconds 300
```

Use `-RepositoryRoot` apenas se precisar verificar outro checkout; normalmente o próprio script encontra a raiz do projeto. Os relatórios e logs contêm caminhos locais e podem conter mensagens dos arquivos testados. Revise-os antes de compartilhar. As pastas de resultados são mantidas para diagnóstico e podem ser removidas depois da revisão.

## Preparar o outro dispositivo

Clone a versão que pretende testar. No PowerShell, registre a revisão e as versões disponíveis:

```powershell
git rev-parse HEAD
$PSVersionTable.PSVersion
[Environment]::OSVersion.Version
[Environment]::Is64BitOperatingSystem
```

Execute os testes isolados e guarde os relatórios. Depois escolha os componentes desejados. Para um desktop com ajustes próprios de monitores e da barra, prepare o arquivo descrito em [Ajustes por dispositivo](dispositivos.md), incluindo as pastas locais necessárias. Para seguir os exemplos abaixo, use `devices/notebook/device.json`.

Verifique e simule a aplicação antes de instalar:

```powershell
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -Check
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -WhatIf
```

Se algum programa obrigatório ainda não estiver instalado, inclua a instalação pretendida na verificação e na simulação. A seleção dos programas é independente da seleção de configurações:

```powershell
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -InstallPrograms -Programs Komorebi,Yasb,Whkd -Check
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -InstallPrograms -Programs Komorebi,Yasb,Whkd -WhatIf
```

Os exemplos usam somente o desktop. Para incluir Terminal, PowerShell, Fastfetch, Starship, btop, fontes, Chuva ou recursos visuais, selecione as opções correspondentes de [Uso do setup](setup.md). Verifique os destinos exibidos e as dependências de [Programas](programas.md) e [Fontes](fontes.md).

## Aplicar e conferir o ambiente real

Feche os aplicativos que podem regravar os arquivos de configuração. Para instalar os três programas do exemplo, aceitar os termos e aplicar suas configurações:

```powershell
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -InstallPrograms -Programs Komorebi,Yasb,Whkd -AcceptAgreements
```

Se os programas já estiverem preparados, omita as opções de instalação. Guarde os caminhos dos backups exibidos. Abra ou recarregue os aplicativos pelos controles habituais e registre os resultados:

| Área selecionada | Conferência no dispositivo |
| --- | --- |
| Terminal e PowerShell | Fonte, cores, perfil, Fastfetch, prompt e comandos pessoais. |
| Komorebi | Quantidade e ordem dos monitores, layouts, regras e espaços de trabalho. |
| YASB | CSS, fontes, distribuição dos widgets, áudio, rede e caminhos de wallpapers. |
| whkd | Atalhos, shell e correspondência com os espaços do Komorebi. A base compartilhada mantém oito atalhos e sete espaços. |
| btop e Chuva | Comandos, configuração visual e funcionamento no terminal escolhido. |
| Recursos visuais | Coleção de wallpapers e ícone no destino selecionado. |

Cada área não selecionada deve ser registrada como não testada. Clima e outros valores privados continuam sendo configurados localmente, conforme a documentação das ferramentas.

Repita o mesmo setup para conferir que arquivos idênticos são ignorados. Se um aplicativo tiver regravado sua configuração, compare a diferença antes de reaplicar. Teste também a recuperação de uma execução escolhida, usando primeiro `-Check` e `-WhatIf`, conforme [Backups e restauração](backups.md). Confira os aplicativos após restaurar e reaplique o estado desejado ao terminar.

## Conferir o login

Somente depois de conferir os componentes, prepare os atalhos:

```powershell
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -EnableStartup -Check
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -EnableStartup -WhatIf
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -EnableStartup
```

Salve seu trabalho e faça um novo login quando for conveniente. Confira se Komorebi, whkd e YASB iniciaram, se os layouts e atalhos funcionam e se há inicializações duplicadas por outros mecanismos. Em caso de falha, consulte `$HOME/.winux-setup/startup/desktop-startup.log` e [Inicialização automática](inicializacao.md). O verificador isolado não encerra a sessão nem executa essa conferência.

## Registrar o resultado

Use um registro por revisão e dispositivo, mantendo nomes e caminhos privados fora do relatório público:

| Informação | Registro |
| --- | --- |
| Revisão do repositório | SHA obtido com `git rev-parse HEAD`. |
| Ambiente | Versão do Windows, arquitetura e versão do PowerShell. |
| Seleção | Componentes e opções usados; variante local identificada sem valores privados. |
| Testes isolados | Estado final e seleção de cada `summary.json`. |
| Aplicação real | Componentes aprovados, falhas e áreas não testadas. |
| Reaplicação e recuperação | Resultado da repetição e da restauração escolhida. |
| Novo login | Resultado da inicialização e funcionamento do desktop. |

A validação em outro dispositivo só deve ser marcada como concluída depois dessas conferências reais. Os testes executados durante o desenvolvimento foram locais e isolados; o uso completo em uma segunda máquina permanece pendente.
