# Komorebi

O componente `Komorebi` aplica os arquivos pessoais de `config/komorebi/`, com backup. Ele preserva as preferências encontradas no computador de origem:

- um monitor com sete espaços de trabalho, I a VII;
- layouts BSP, VerticalStack, HorizontalStack, UltrawideVerticalStack, Rows, Grid e RightMainVerticalStack;
- espaçamentos de 3, bordas, cores, tema Base16 Ashes e stackbar desativada;
- transparência com alpha 220 e animações de 400 ms a 120 FPS;
- regras de aplicativos e configuração da barra própria do Komorebi.

Os arquivos foram verificados com os esquemas oficiais da versão 0.1.41, também fixada no catálogo de instalação. Durante a execução, o setup verifica a leitura dos arquivos JSON antes de aplicar; não baixa esquemas nem executa essa validação completa novamente.

## Aplicar

Na raiz do repositório:

```powershell
.\setup.ps1 -Components Komorebi -Check
.\setup.ps1 -Components Komorebi -WhatIf
.\setup.ps1 -Components Komorebi
```

O componente é opcional e não exige Fastfetch. Para instalar também o programa, acrescente `-InstallPrograms -Programs Komorebi`; os aceites de termos usam `-AcceptAgreements`. A aplicação dos arquivos pode ser feita antes da instalação do programa.

Sem `-Components`, continuam selecionados somente Fastfetch e PowerShell. Dentro do PowerShell, selecione vários componentes com uma lista, por exemplo `-Components PowerShell, WindowsTerminal, Starship, Komorebi`.

## Destinos

Sem `KOMOREBI_CONFIG_HOME`, os arquivos vão para a pasta do usuário, mantendo a organização do ambiente de origem:

- `$HOME/komorebi.json`;
- `$HOME/komorebi.bar.json`;
- `$HOME/applications.json`;
- `$HOME/applications.LICENSE`.

Se `KOMOREBI_CONFIG_HOME` estiver definida na sessão, o componente usa essa pasta. Informe um caminho absoluto e mantenha o mesmo valor nas sessões que iniciarão o Komorebi, conforme a [documentação da configuração de diretório](https://lgug2z.github.io/komorebi/common-workflows/komorebi-config-home.html):

```powershell
$env:KOMOREBI_CONFIG_HOME = "$HOME\.config\komorebi"
.\setup.ps1 -Components Komorebi -Check
.\setup.ps1 -Components Komorebi
```

O caminho de `applications.json` no arquivo instalado é adaptado para a pasta de destino. As outras preferências permanecem iguais às da configuração versionada. Variáveis persistentes não são criadas ou alteradas pelo setup.

Os arquivos existentes são substituídos após [backup completo](backups.md), sem combinar suas opções com a configuração do projeto. Uma reaplicação sem mudanças não regrava os arquivos nem cria outro backup.

## Barra, atalhos e monitores

`komorebi.bar.json` acompanha a importação para preservar a alternativa encontrada. O setup não inicia a barra, o Komorebi ou whkd, nem cria inicialização automática. A configuração principal não passa a ativar essa barra.

A inicialização no próximo login é uma opção separada, `-EnableStartup`, que prepara Komorebi com whkd e YASB, sem a barra alternativa. Veja [Inicialização automática](inicializacao.md).

O [YASB e seu CSS](yasb.md) podem ser aplicados pelo componente `Yasb`, e os [atalhos do whkd](whkd.md), pelo componente `Whkd`. A diferença entre os sete espaços de trabalho e os oito atalhos encontrados no whkd é preservada e documentada; a aplicação não cria nem remove espaços.

A configuração mantém o monitor do ambiente de origem, sem identificadores físicos. Outros dispositivos podem precisar de ajustes na lista de monitores e nos espaços de trabalho. A separação de ajustes por dispositivo continua prevista; o setup ainda não detecta nem reorganiza monitores automaticamente. A família original JetBrains Mono usada pela barra é diferente da Nerd Font do catálogo e precisa estar disponível antes de usar essa alternativa; veja [Fontes](fontes.md).

Depois de aplicar, recarregue a configuração ou reinicie o Komorebi pelos seus controles habituais. A conferência visual em outro dispositivo continua pendente.

## Regras de aplicativos

`applications.json` preserva a cópia local da base [komorebi-application-specific-configuration](https://github.com/LGUG2Z/komorebi-application-specific-configuration). A licença MIT é mantida ao lado das regras no repositório e no destino. O setup não baixa uma versão nova nem substitui essas regras pela versão atual da origem.

## Verificação isolada

```powershell
.\tests\komorebi.tests.ps1 -TestRoot "$env:TEMP\winux-komorebi-tests"
```

Os testes usam diretórios temporários e verificam preservação das preferências, regras e barra, destinos, simulação, backups e reaplicação. Eles não iniciam o gerenciador de janelas nem alteram a configuração real do desktop.
