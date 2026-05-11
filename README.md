# FL Solutions Debian/Proxmox Bootstrap

Bootstrap seguro e idempotente para preparar servidores Debian e Proxmox com ferramentas essenciais de operação, diagnóstico e produtividade em terminal.

Este projeto nasceu para padronizar o ambiente base usado em rotinas de administração Linux sem assumir que o servidor está vazio, sem sobrescrever customizações existentes e sem executar mudanças agressivas em produção.

> [!WARNING]
> Execute primeiro em modo `dry-run`. Em servidores de produção, revise a saída antes de usar `--apply`.
> O script não altera rede, storage, cluster, firewall, repositórios Proxmox, serviços críticos ou ciclo de upgrade do sistema.

## Visão Geral

O `install.sh` prepara um ambiente Debian/Proxmox com ferramentas comuns de terminal, diagnóstico e operação diária. Ele foi pensado para ser simples de auditar, seguro para repetir e fácil de reverter.

Principais características:

- `dry-run` por padrão.
- Instala somente pacotes ausentes.
- Detecta pacotes já instalados.
- Detecta Proxmox sem alterar configurações do Proxmox.
- Usa bloco gerenciado para ajustes de shell.
- Cria backup antes de qualquer alteração real em arquivo.
- Preserva customizações manuais fora do bloco gerenciado.
- Recusa aplicação em hosts sem APT/dpkg.

## Escopo

Incluído no MVP:

- instalação de ferramentas básicas de administração e diagnóstico;
- configuração conservadora de Bash history;
- integração com `fzf` para pesquisa no histórico via `Ctrl+R`;
- carregamento de `bash-completion` quando disponível;
- aliases seguros para cor em comandos comuns;
- integração com `grc` para melhorar leitura de saídas;
- documentação de uso, validação e rollback.

Fora do escopo:

- hardening completo de sistema;
- tuning de kernel;
- configuração de rede;
- configuração de cluster Proxmox;
- alteração de repositórios APT;
- atualização de versão do Debian ou Proxmox;
- instalação de stack de monitoramento, backup ou virtualização.

## Requisitos

- Debian ou Proxmox baseado em Debian.
- Bash.
- APT/dpkg.
- Permissão de `root` apenas quando for instalar pacotes ou alterar `/etc/bash.bashrc`.

O script pode ser executado sem `root` em modo `dry-run`.

## Instalação em Debian Novo

Use estes comandos em um Debian recém-instalado para baixar o projeto do GitHub e executar primeiro em modo seguro.

### Opção Recomendada: Git Clone

Instalar dependências mínimas para baixar o projeto:

```bash
sudo apt update
sudo apt install -y git ca-certificates
```

Baixar o repositório:

```bash
git clone https://github.com/flicl/fl-solutions-debian-proxmox-bootstrap.git
cd fl-solutions-debian-proxmox-bootstrap
```

Rodar primeiro em modo simulação:

```bash
./install.sh
```

Se a saída estiver correta, aplicar:

```bash
sudo ./install.sh --apply --system
```

### Opção Rápida: Curl

Use esta opção apenas se quiser baixar somente o script.

```bash
sudo apt update
sudo apt install -y curl ca-certificates
curl -fsSLO https://raw.githubusercontent.com/flicl/fl-solutions-debian-proxmox-bootstrap/main/install.sh
chmod +x install.sh
./install.sh
```

Depois de revisar o `dry-run`, aplicar:

```bash
sudo ./install.sh --apply --system
```

## Uso Rápido Local

Clonar ou acessar a pasta do projeto:

```bash
cd fl-solutions-debian-proxmox-bootstrap
```

Executar simulação sem alterar o sistema:

```bash
./install.sh
```

Aplicar para o usuário atual:

```bash
./install.sh --apply
```

Aplicar para o usuário atual e também para `/etc/bash.bashrc`:

```bash
sudo ./install.sh --apply --system
```

Aplicar sem confirmação interativa:

```bash
sudo ./install.sh --apply --system --yes
```

## Modos de Execução

| Comando | Efeito |
| --- | --- |
| `./install.sh` | Mostra o que seria feito, sem alterar o sistema. |
| `./install.sh --apply` | Instala pacotes ausentes e gerencia `~/.bashrc`. |
| `sudo ./install.sh --apply --system` | Também gerencia `/etc/bash.bashrc`. |
| `sudo ./install.sh --apply --system --yes` | Aplica sem prompt interativo. Use apenas em automação revisada. |

## Segurança Operacional

O script foi desenhado para não causar impacto inesperado em servidores já em uso.

Ele faz:

- verifica pacotes antes de instalar;
- mostra pacotes já instalados;
- mostra pacotes que seriam instalados;
- cria backup antes de editar arquivos;
- valida sintaxe Bash depois das alterações;
- edita apenas blocos claramente marcados.

Ele não faz:

- `apt upgrade`;
- `apt full-upgrade`;
- `apt dist-upgrade`;
- `apt autoremove`;
- alteração de repositórios APT;
- alteração de repositórios Proxmox;
- reinício de serviços;
- alteração de shell padrão;
- alteração de interfaces, bridges, VLANs ou firewall;
- alteração de storage, cluster, HA ou configurações PVE.

## Arquivos Alterados

Por padrão:

```text
~/.bashrc
```

Com `--system`:

```text
/etc/bash.bashrc
```

As alterações ficam sempre dentro do bloco:

```text
# BEGIN FL SOLUTIONS MANAGED BLOCK
# END FL SOLUTIONS MANAGED BLOCK
```

Se o bloco já existir, ele é atualizado. Conteúdo fora desse bloco é preservado.

## Backup e Rollback

Antes de alterar um arquivo, o script cria um backup com timestamp:

```text
arquivo.bak.fl-solutions-YYYYmmdd-HHMMSS
```

Exemplo:

```text
~/.bashrc.bak.fl-solutions-20260511-140000
```

Para rollback, remova o bloco gerenciado ou restaure o backup completo.

Guia detalhado:

```text
docs/rollback.md
```

## Pacotes

Pacotes principais instalados quando ausentes:

```text
apt-transport-https
bash-completion
ca-certificates
curl
dnsutils
fzf
git
grc
htop
iftop
iotop
iproute2
jq
lsof
mtr-tiny
ncdu
net-tools
nload
rsync
screen
strace
tcpdump
tmux
traceroute
tree
unzip
vim
wget
zip
```

Pacotes opcionais detectados, mas não instalados por padrão:

```text
bat
btop
fd-find
lsd
ripgrep
```

## Validação Pós-Execução

Valide os comandos principais:

```bash
command -v grc
command -v fzf
command -v curl
command -v git
```

Valide arquivos de shell:

```bash
bash -n ~/.bashrc
```

Se usou `--system`:

```bash
sudo bash -n /etc/bash.bashrc
```

Em Proxmox:

```bash
command -v pveversion
pveversion
```

## Desenvolvimento

Validação recomendada antes de publicar mudanças:

```bash
bash -n install.sh
shellcheck install.sh
./install.sh
```

Teste de idempotência em ambiente descartável:

```bash
sudo ./install.sh --apply --system
sudo ./install.sh --apply --system
```

A segunda execução não deve duplicar blocos nem reinstalar pacotes já presentes.

## Estrutura do Projeto

```text
.
├── install.sh
├── README.md
├── CHANGELOG.md
├── LICENSE
├── docs/
│   ├── debian.md
│   ├── proxmox.md
│   └── rollback.md
└── tests/
    └── shellcheck.md
```

## Status

Versão inicial: `0.1.0`

O projeto está pronto para validação em laboratório Debian/Proxmox antes de uso em produção.

## Licença

Distribuído sob licença MIT. Consulte [LICENSE](LICENSE).
