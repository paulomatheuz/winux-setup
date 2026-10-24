# Ajustes por dispositivo

A opção `-DeviceConfig` lê um arquivo JSON escolhido explicitamente. Ele pode selecionar componentes, informar os destinos do Windows Terminal e do btop e escolher pastas de configurações específicas de uma máquina. Sem essa opção, o setup usa as configurações compartilhadas de `config/` e os padrões atuais.

## Criar uma configuração local

Na raiz do repositório:

```powershell
New-Item -ItemType Directory -Path .\devices\notebook -Force
Copy-Item .\devices\example.json .\devices\notebook\device.json
```

O exemplo seleciona Komorebi, YASB e whkd, inicialmente com os arquivos compartilhados. Para preparar versões locais do desktop:

```powershell
Copy-Item .\config\komorebi .\devices\notebook\komorebi -Recurse
Copy-Item .\config\yasb .\devices\notebook\yasb -Recurse
```

Edite `devices/notebook/device.json`:

```json
{
  "SchemaVersion": 1,
  "Components": ["Komorebi", "Yasb", "Whkd"],
  "ConfigDirectories": {
    "Komorebi": "komorebi",
    "Yasb": "yasb"
  }
}
```

Agora ajuste os monitores em `devices/notebook/komorebi/komorebi.json`, os widgets em `devices/notebook/yasb/config.yaml` e o visual em `devices/notebook/yasb/styles.css`. O whkd continua usando a versão compartilhada, pois não recebeu uma pasta alternativa.

Verifique, simule e aplique:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DeviceConfig .\devices\notebook\device.json -Check
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DeviceConfig .\devices\notebook\device.json -WhatIf
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DeviceConfig .\devices\notebook\device.json
```

O setup não escolhe uma máquina pelo nome do computador nem memoriza o último arquivo. Use `-DeviceConfig` novamente nas reaplicações. Executar sem essa opção volta às fontes compartilhadas para os componentes selecionados.

## Campos aceitos

| Campo | Uso |
| --- | --- |
| `SchemaVersion` | Obrigatório; número inteiro `1`. |
| `Components` | Lista não vazia com os mesmos componentes aceitos em `-Components`. Sem o campo, mantém Fastfetch e PowerShell. |
| `TerminalSettingsPath` | Caminho do arquivo `settings.json`, usado quando WindowsTerminal está selecionado. |
| `BtopDirectory` | Pasta de destino do btop, usada quando Btop está selecionado. |
| `ConfigDirectories` | Objeto com pastas de origem alternativas para Komorebi, Yasb, Whkd e Btop. Sem uma entrada, usa `config/<ferramenta>`. |

Os caminhos relativos são resolvidos a partir da pasta que contém o JSON, inclusive os destinos. Caminhos absolutos completos também são aceitos. Use caminhos literais: `~`, `%USERPROFILE%` e expressões PowerShell não são expandidos. No JSON, escreva barras de caminho como `/` ou `\\`.

Por exemplo, uma instalação portátil de btop pode usar `"BtopDirectory": "C:/Users/seu-usuario/Tools/btop4win"`. A edição desejada do Terminal pode ser selecionada com seu caminho absoluto em `TerminalSettingsPath`.

Opções digitadas no comando têm prioridade sobre `Components`, `TerminalSettingsPath` e `BtopDirectory` do arquivo. Os destinos do arquivo são considerados apenas para os componentes efetivamente selecionados:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DeviceConfig .\devices\notebook\device.json -Components Whkd -Check
```

Opções desconhecidas, valores inválidos e pastas alternativas inexistentes interrompem o setup. Os arquivos obrigatórios das ferramentas selecionadas são verificados antes das instalações opcionais e da aplicação.

## Pastas alternativas completas

Cada entrada de `ConfigDirectories` substitui a pasta de origem daquela ferramenta. Não há combinação de trechos de JSON, YAML ou CSS com a versão compartilhada. Copie a pasta completa antes de editar, mantendo os arquivos exigidos:

| Ferramenta | Arquivos |
| --- | --- |
| Komorebi | `komorebi.json`, `komorebi.bar.json`, `applications.json`, `applications.LICENSE`. |
| Yasb | `config.yaml`, `styles.css`, `YASB.LICENSE`. |
| Whkd | `whkdrc`. |
| Btop | `btop.conf`, `themes/NeutralPurple.theme`, `BTOP.LICENSE`. |

O caminho das regras do Komorebi continua sendo adaptado ao destino. O YAML e o CSS do YASB são copiados integralmente da pasta escolhida; o `.env` já instalado é preservado. As pastas alternativas não mudam os destinos padrão do desktop. Para destinos diferentes, defina `KOMOREBI_CONFIG_HOME`, `YASB_CONFIG_HOME` ou `WHKD_CONFIG_HOME` na sessão antes de executar o setup, conforme a documentação de cada ferramenta.

Os arquivos compartilhados e as pastas locais de origem permanecem intactos. A aplicação mantém os [backups e registros](backups.md), e arquivos idênticos não são regravados.

## Instalação e inicialização

O JSON contém somente preferências e caminhos. A instalação de programas e módulos, a aceitação dos termos e a inicialização no login continuam sendo opções explícitas do comando. Por exemplo:

```powershell
.\setup.ps1 -DeviceConfig .\devices\notebook\device.json -InstallPrograms -Programs Komorebi,Yasb,Whkd -AcceptAgreements -EnableStartup
```

Os atalhos de inicialização apontam para as configurações já aplicadas, sem depender da pasta local de origem. Veja [Inicialização automática](inicializacao.md).

## Arquivos locais e testes

O `.gitignore` ignora os novos arquivos dentro de `devices/`, exceto `example.json`. O exemplo público não contém caminhos pessoais. Para reproduzir uma variante em outro dispositivo, transfira também seu JSON e suas pastas alternativas. Arquivos que já estavam versionados continuam sendo acompanhados pelo Git.

As verificações em `tests/device.tests.ps1` usam configurações e destinos temporários. Elas cobrem validação, caminhos relativos, prioridade do comando, arquivos locais, backups, reaplicação e preservação dos padrões compartilhados, no Windows PowerShell 5.1 e PowerShell 7. A validação do ambiente completo em outro dispositivo continua pendente.
