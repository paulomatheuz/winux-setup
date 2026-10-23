# YASB

O componente `Yasb` aplica o `config.yaml` e o `styles.css` pessoais, preservando a barra superior de 32 px, sua distribuição de widgets, fontes, cores, menus, animações e detalhes visuais. O CSS foi importado integralmente. A base do [YASB](https://github.com/amnweb/yasb/tree/v2.0.7) acompanha a licença MIT em `config/yasb/YASB.LICENSE`, também copiada para o destino.

O YAML mantém home e taskbar à esquerda; clock e apps ao centro; media, wallpapers, wifi, microphone, volume, notifications e power_menu à direita. Os widgets do Komorebi e da janela ativa continuam comentados na seleção da barra. O clima continua definido, mas fora da barra ativa.

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components Yasb -Check
.\setup.ps1 -Components Yasb -WhatIf
.\setup.ps1 -Components Yasb
```

O componente é opcional e não exige Fastfetch nem o executável do YASB para preparar os arquivos. Para instalar também o programa, acrescente `-InstallPrograms -Programs Yasb`; os aceites de termos usam `-AcceptAgreements`. O catálogo mantém a versão 2.0.7 do ambiente inventariado.

Dentro do PowerShell, combine as configurações com `-Components Komorebi, Yasb`. Sem seleção explícita, o setup continua aplicando apenas Fastfetch e PowerShell. Esta etapa não inicia aplicativos nem cria inicialização automática.

## Destino e backup

O destino padrão é `$HOME/.config/yasb`. Se `YASB_CONFIG_HOME` estiver definida na sessão, o componente usa essa pasta; informe um caminho absoluto e mantenha a variável nas sessões que iniciarão o YASB. A [documentação oficial](https://github.com/amnweb/yasb/wiki/Configuration) descreve esse diretório e o suporte a `.env`.

```powershell
$env:YASB_CONFIG_HOME = "$HOME\.config\yasb"
.\setup.ps1 -Components Yasb -Check
```

Os arquivos existentes são substituídos após [backup completo](backups.md), sem combinar suas opções com a configuração do projeto. Arquivos idênticos não são regravados nem geram outro backup. O setup não altera variáveis persistentes, o arquivo `.env` ou outros arquivos da pasta.

`watch_config` e `watch_stylesheet` permanecem ativados: se o YASB estiver em execução, ele pode recarregar os arquivos quando forem aplicados. Os testes usam destinos temporários e não afetam a barra real.

## Clima e valores locais

A chave e a localização encontradas na origem não fazem parte da configuração pública. `api_key` e `location` usam `env`, recurso disponível no YASB 2.0.7. Para usar o clima futuramente, crie ou edite um arquivo `.env` no diretório de configuração com:

```dotenv
YASB_WEATHER_API_KEY=sua_chave
YASB_WEATHER_LOCATION=sua_localizacao
```

O modelo sem valores está em `config/yasb/.env.example`. Ele não é aplicado automaticamente; preserve um `.env` existente e mantenha os valores privados fora do repositório. O widget continua inativo até ser incluído na lista de widgets da barra.

## Wallpapers, fontes e atalhos

O caminho absoluto da origem foi substituído por `$env:USERPROFILE/Pictures/wallpaper`, expandido pelo YASB para a pasta do usuário atual. O componente não copia imagens nem cria essa pasta. Para usar a galeria, coloque suas imagens nesse local; a distribuição dos recursos visuais fica para uma etapa própria.

O CSS mantém JetBrainsMono NFP, Segoe UI e Segoe Fluent Icons. A instalação de fontes continua prevista. O visual em outro dispositivo precisa ser conferido depois que as fontes e os recursos estiverem disponíveis.

Os comandos de integração com Komorebi e whkd são preservados. O setup não os executa. Para usá-los, os programas e suas configurações precisam estar preparados; os [atalhos do whkd](whkd.md) podem ser aplicados com `-Components Whkd`.

## Verificação

```powershell
.\tests\yasb.tests.ps1 -TestRoot "$env:TEMP\winux-yasb-tests"
```

Os testes verificam cópia integral dos arquivos, preservação do `.env`, destinos, simulação, backups e reaplicação no PowerShell 5.1 e 7. Durante a importação, o YAML foi analisado e comparado com a origem: somente chave, localização do clima e caminho dos wallpapers foram adaptados. O CSS foi comparado byte a byte.

O modo `-Check` verifica os arquivos e destinos; não inicia o YASB nem executa uma validação completa de seus widgets ou da aparência.
