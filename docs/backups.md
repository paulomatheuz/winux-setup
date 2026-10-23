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

A restauração automática será implementada na etapa de recuperação. Por enquanto, o manifesto permite localizar o conteúdo anterior de cada arquivo alterado.

## Simulação

`-Check` e `-WhatIf` continuam sem aplicar configurações e sem criar backups. A instalação opcional dos programas tem seu próprio comportamento, descrito em [Instalação dos programas](programas.md); esses backups cobrem os arquivos de configuração, não os programas instalados.

Os backups podem conter dados privados do perfil anterior. Eles permanecem na pasta do usuário e não devem ser publicados no repositório.

## Verificação

Os testes de arquivos podem ser executados sem aplicar configurações ao ambiente:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\configuration.tests.ps1 -TestRoot "$env:TEMP\winux-setup-tests"
```

Cada execução cria uma pasta própria dentro do diretório informado. Os testes cobrem integridade das cópias, arquivos novos e vazios, repetição sem mudanças, falhas, registros parciais e codificações do perfil.
