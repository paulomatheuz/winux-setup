# Inicialização automática

`-EnableStartup` prepara Komorebi com whkd e YASB para o próximo login do usuário. A opção é explícita: aplicar configurações ou instalar programas sem essa opção não cria inicialização automática.

## Configurar

Depois de preparar os programas e as configurações:

```powershell
.\scripts\configure-startup.ps1 -Check
.\scripts\configure-startup.ps1 -WhatIf
.\scripts\configure-startup.ps1
```

O script dedicado dispensa Fastfetch. Para aplicar as configurações do desktop e a inicialização em uma execução, use dentro do PowerShell:

```powershell
.\setup.ps1 -Components Komorebi, Yasb, Whkd -EnableStartup -Check
.\setup.ps1 -Components Komorebi, Yasb, Whkd -EnableStartup -WhatIf
.\setup.ps1 -Components Komorebi, Yasb, Whkd -EnableStartup
```

Para instalar também os programas, acrescente `-InstallPrograms -Programs Komorebi, Yasb, Whkd -AcceptAgreements`. A verificação inicial aceita esses programas e configurações como previstos; a aplicação real exige que os programas estejam disponíveis e os arquivos já tenham sido aplicados.

O setup configura a inicialização depois de aplicar os componentes. Cada aplicação tem seu próprio [registro de backup](backups.md). Se a configuração da inicialização falhar, as configurações aplicadas anteriormente permanecem; a restauração automática será tratada em sua etapa própria.

## Arquivos gerados

Na pasta de inicialização do usuário (`shell:startup`), o setup gerencia somente:

- `komorebi.lnk`;
- `yasb.lnk`.

Os atalhos usam Windows PowerShell sem carregar o perfil, em modo oculto. O processo usa `-ExecutionPolicy Bypass` apenas para aquela execução; a política persistente do sistema não é alterada. O lançador e seus dados ficam em `$HOME/.winux-setup/startup/start-desktop.ps1` e `startup.json`, independentes da pasta do clone.

Os caminhos dos executáveis e dos diretórios `KOMOREBI_CONFIG_HOME`, `WHKD_CONFIG_HOME` e `YASB_CONFIG_HOME` são resolvidos no dispositivo e guardados localmente. O lançador aplica essas variáveis e acrescenta as pastas dos programas somente ao seu próprio ambiente e aos processos filhos. Não altera o PATH persistente nem grava chaves ou valores privados do clima.

Antes de iniciar, o lançador confere os arquivos necessários e consulta processos da sessão atual. O Komorebi usa `start --whkd` quando o whkd ainda não está ativo; se o Komorebi já estiver ativo e faltar apenas whkd, inicia somente whkd. O YASB é iniciado quando não está ativo. A barra alternativa do Komorebi, btop, Chuva e Terminal não são iniciados automaticamente.

A ordem dos atalhos é controlada pelo Windows. O setup não inicia os aplicativos durante a aplicação e não cria tarefas agendadas nem serviços. A conferência de um login real em outro dispositivo continua pendente.

## Atalhos existentes e reaplicação

O atalho padrão do Komorebi com `start` ou `start --whkd` é reutilizado, com backup do conteúdo anterior. Atalhos padrão do YASB também podem ser migrados. Um atalho nesses nomes com comando personalizado é recusado antes das alterações para evitar descartar opções locais. Atalhos gerenciados pelo setup são reconhecidos pela descrição `winux-setup`.

Outros arquivos da pasta de inicialização são preservados. Métodos de inicialização configurados fora desses dois atalhos, como tarefas agendadas ou outras entradas, não são removidos; escolha um método por aplicativo para evitar entradas concorrentes. O lançador consulta processos ativos, mas não coordena outros mecanismos de inicialização.

Quando os caminhos e conteúdos permanecem iguais, a reaplicação não regrava os atalhos e não cria outro backup. Depois de mover programas ou mudar diretórios de configuração, execute a configuração novamente para atualizar os caminhos locais.

## Diagnóstico e desativação

O lançador registra resultados e falhas em `$HOME/.winux-setup/startup/desktop-startup.log`. Para verificar os arquivos sem iniciar aplicativos:

```powershell
& "$HOME\.winux-setup\startup\start-desktop.ps1" -Component Komorebi -Check
& "$HOME\.winux-setup\startup\start-desktop.ps1" -Component Yasb -Check
```

Para desativar, use as opções de aplicativos de inicialização do Windows para Komorebi e YASB. Isso não encerra processos que já estejam ativos. Se as entradas estavam desativadas anteriormente, habilite-as por esses controles depois de conferir a configuração.

## Testes isolados

```powershell
.\tests\startup.tests.ps1 -TestRoot "$env:TEMP\winux-startup-tests"
```

Os testes criam atalhos reais em uma pasta temporária, sem registrá-los na inicialização do usuário. Conferem migração, backups, reaplicação, conflitos e integração com o setup. As chamadas de início dos programas são simuladas, incluindo processos existentes e falhas. Nenhum aplicativo real é iniciado pelos testes.

As integrações seguem as opções documentadas de [Komorebi](https://lgug2z.github.io/komorebi/common-workflows/autostart.html) e [YASB](https://github.com/amnweb/yasb/wiki/CLI); os atalhos e os backups são preparados pelo próprio setup.
