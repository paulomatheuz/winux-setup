# Backups das configurações

A aplicação das configurações usa `scripts/configuration.ps1` para preparar as mudanças, salvar os conteúdos anteriores e registrar o resultado.

## Local dos backups

Cada execução que muda arquivos cria uma pasta em:

```text
$HOME/.winux-setup/backups/<data-UTC-e-identificador>/
```

Essa pasta contém:

- arquivos `*.original` com o conteúdo anterior dos destinos existentes;
- `manifest.json` com os destinos, hashes SHA-256, nomes dos backups e estado da execução.

Os nomes das pastas são únicos. Uma execução posterior não substitui os backups anteriores.

## Antes de aplicar

O instalador verifica os arquivos de origem e prepara os conteúdos finais antes de substituir os destinos. Todos os originais que precisarão ser alterados são salvos e conferidos antes da primeira substituição.

Arquivos cujo conteúdo já é igual ao desejado são ignorados. Se nada mudar, nenhuma pasta de backup é criada e os arquivos não são regravados.

Um destino novo é registrado com `Existed: false`, sem uma cópia anterior. Arquivos existentes vazios também são preservados.

## Perfil do PowerShell

O bloco de integração usa os mesmos marcadores das instalações anteriores. Se o bloco já estiver presente uma única vez e na ordem correta, ele não é adicionado novamente.

Os bytes existentes do perfil são preservados. O instalador acrescenta somente o bloco necessário, respeitando os formatos UTF-8, UTF-16 e UTF-32 com BOM. Para arquivos sem BOM, o bloco acrescentado contém apenas caracteres ASCII.

Marcadores incompletos, invertidos ou repetidos interrompem o planejamento das configurações. O perfil deve ser revisado antes de repetir o setup.

`-SkipProfile` continua impedindo a edição do perfil da sessão; os demais arquivos selecionados ainda são aplicados com backup.

Os arquivos de backup antigos com o sufixo `.backup-before-custom-windows-terminal` permanecem no local onde já existiam. As novas execuções usam a pasta de backups acima.

## Registro e falhas

O manifesto registra os estados `Preparing`, `Applying`, `Complete` ou `Failed`. Cada destino tem seu estado `Pending` ou `Applied`.

Se ocorrer uma falha, a sequência é interrompida. Pode haver uma aplicação parcial: os arquivos concluídos não são desfeitos automaticamente. As cópias anteriores e o registro ficam disponíveis para recuperação.

Os destinos são conferidos novamente antes de cada substituição para detectar mudanças feitas depois do planejamento. Os arquivos são escritos primeiro em um arquivo temporário na pasta de destino e depois substituídos individualmente. A operação sobre vários arquivos não é uma transação única.

O script `scripts/restore-backup.ps1` recupera os conteúdos anteriores a partir do manifesto. Ele também pode recuperar aplicações parciais quando os originais e hashes necessários estão disponíveis. A restauração é solicitada explicitamente; uma falha no setup não dispara uma reversão automática.

## Escolher e restaurar uma execução

Liste os backups e escolha a pasta da execução desejada:

```powershell
Get-ChildItem -LiteralPath "$HOME\.winux-setup\backups" -Directory | Sort-Object Name -Descending | Select-Object Name, FullName
```

Copie o caminho escolhido para uma variável na sessão do PowerShell. Use a pasta que contém `manifest.json`, não o arquivo individual:

```powershell
$backupEscolhido = Read-Host 'Caminho completo da pasta do backup'
.\scripts\restore-backup.ps1 -BackupPath $backupEscolhido -Check
.\scripts\restore-backup.ps1 -BackupPath $backupEscolhido -WhatIf
.\scripts\restore-backup.ps1 -BackupPath $backupEscolhido
```

O script confere o formato do manifesto, os SHA-256 dos originais e o estado atual de todos os destinos antes de alterar arquivos. Manifestos antigos sem o campo `Operation` continuam sendo aceitos como gravações. Novos registros usam `Write` para gravações e `Remove` para remoções.

- Um arquivo que existia antes recebe exatamente seus bytes anteriores, inclusive se estava vazio.
- Um arquivo criado naquela execução é removido, desde que ainda tenha o conteúdo aplicado pelo setup.
- Um destino que já está no estado anterior é ignorado. Repetir a mesma restauração não cria outro backup se nada precisar mudar.
- Arquivos fora do manifesto e pastas vazias que ficaram após a remoção são preservados.

Antes das trocas ou remoções, um novo backup guarda todos os arquivos atuais que vão mudar. O caminho desse registro é exibido no fim. O backup escolhido permanece intacto. Para desfazer a restauração, selecione esse novo backup e execute o mesmo comando; ele também consegue recriar arquivos removidos na restauração anterior.

Se o setup gerou vários registros, restaure do mais recente para o mais antigo. A aplicação das configurações e a configuração da inicialização, por exemplo, geram registros separados. Não há seleção automática do último backup.

## Conflitos e recuperação parcial

Se um destino mudou depois do setup, a restauração interrompe o planejamento inteiro sem substituir os outros arquivos. Preserve suas edições e compare-as com o conteúdo anterior antes de decidir como recuperar. Não há opção para forçar a substituição desses conflitos.

Registros `Complete`, `Applying` e `Failed` são aceitos se todas as referências e cópias necessárias estiverem válidas. O conteúdo atual determina se um arquivo ainda está aplicado ou já está no estado anterior, mesmo se a execução foi interrompida antes de atualizar `Pending` para `Applied`. Backups corrompidos, arquivos originais ausentes, entradas inválidas e registros `Preparing` são recusados.

Os destinos são conferidos de novo antes da execução e de cada mudança. A restauração de vários arquivos também não é uma transação única: uma falha de acesso ou uma edição concorrente durante a aplicação pode deixar uma restauração parcial. O novo registro e as cópias do estado atual ficam disponíveis para recuperação.

Feche os aplicativos que podem gravar as configurações enquanto restaura e reabra-os depois. Restaurar atalhos não encerra processos nem modifica o controle de aplicativos de inicialização do Windows. A operação cobre os arquivos registrados: não desinstala programas, módulos ou fontes, não reverte o PATH e não troca de dispositivo os caminhos gravados no manifesto.

## Atualizar as configurações

Na pasta do clone, atualize os arquivos do projeto e execute o setup novamente com a mesma seleção de componentes e, quando usado, o mesmo `-DeviceConfig`:

```powershell
git pull --ff-only
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -Check
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -WhatIf
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json
```

Para usar as configurações compartilhadas, omita `-DeviceConfig` e mantenha sua seleção em `-Components`. Somente arquivos diferentes geram backups. Variantes locais continuam sendo lidas das pastas escolhidas e não recebem automaticamente mudanças das fontes compartilhadas. Edite ou combine essas variantes antes de reaplicar.

Esse processo atualiza configurações. A instalação opcional continua preservando programas e módulos existentes; a instalação portátil do Chuva também mantém instalações existentes. Atualizações desses programas seguem seus próprios gerenciadores. Acrescente `-EnableStartup` somente se também quiser reaplicar os atalhos de login.

## Simulação

`-Check` e `-WhatIf` continuam sem aplicar configurações e sem criar backups. A instalação opcional dos programas tem seu próprio comportamento, descrito em [Instalação dos programas](programas.md); esses backups cobrem os arquivos de configuração, não os programas instalados.

Os backups podem conter dados privados do perfil anterior. Eles permanecem na pasta do usuário e não devem ser publicados no repositório.

## Verificação

Os testes de arquivos podem ser executados sem aplicar configurações ao ambiente:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\configuration.tests.ps1 -TestRoot "$env:TEMP\winux-setup-tests"
```

Cada execução cria uma pasta própria dentro do diretório informado. Os testes cobrem integridade das cópias, arquivos novos e vazios, repetição sem mudanças, falhas, registros parciais e codificações do perfil.

Os testes de restauração usam somente arquivos temporários:

```powershell
.\tests\restore.tests.ps1 -TestRoot "$env:TEMP\winux-restore-tests"
```

Eles cobrem backups antigos, simulação, bytes binários e vazios, remoção de arquivos novos, reversão da própria restauração, conflitos, corrupção, manifestos inválidos, aplicação parcial e alterações entre planejamento e execução, no Windows PowerShell 5.1 e PowerShell 7.

