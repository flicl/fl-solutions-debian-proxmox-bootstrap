# FL Solutions Debian/Proxmox Bootstrap

Script Bash para preparar ambientes Debian/Proxmox com ferramentas básicas de terminal, diagnóstico e ajustes seguros de shell para uso diário.

> [!WARNING]
> Use primeiro em modo `dry-run`. Em produção, revise a saída antes de aplicar. O script não altera rede, storage, cluster, firewall, repositórios Proxmox nem executa `upgrade`.

## Objetivo

Padronizar um conjunto mínimo de ferramentas e melhorias de terminal em servidores Debian/Proxmox, mantendo idempotência, backup e rollback simples.

## Escopo do MVP

- Instalar pacotes básicos de administração e diagnóstico.
- Detectar pacotes já instalados antes de instalar.
- Configurar histórico Bash, `Ctrl+R` via `fzf`, `bash-completion`, aliases com cor e GRC.
- Editar somente blocos marcados da FL Solutions.
- Criar backup antes de alterar arquivos.
- Executar em `dry-run` por padrão.

## Uso

Dry-run, sem alterar o sistema:

```bash
./install.sh
```

Aplicar somente para o usuário atual:

```bash
./install.sh --apply
```

Aplicar para o usuário atual e também `/etc/bash.bashrc`:

```bash
sudo ./install.sh --apply --system
```

Aplicar sem confirmação interativa:

```bash
sudo ./install.sh --apply --system --yes
```

## O Que o Script Não Faz

- Não executa `apt upgrade`, `apt full-upgrade`, `apt dist-upgrade` ou `apt autoremove`.
- Não altera repositórios APT ou Proxmox.
- Não reinicia serviços.
- Não muda shell padrão.
- Não altera rede, bridge, firewall, storage, cluster ou HA.
- Não sobrescreve customizações existentes fora do bloco gerenciado.

## Bloco Gerenciado

As alterações de shell ficam entre:

```text
# BEGIN FL SOLUTIONS MANAGED BLOCK
# END FL SOLUTIONS MANAGED BLOCK
```

Se o bloco já existir, ele é substituído. Configurações manuais fora dele são preservadas.

## Pacotes Principais

```text
grc fzf bash-completion curl wget vim htop iotop iftop nload ncdu tree tmux screen rsync git jq dnsutils net-tools iproute2 tcpdump mtr-tiny traceroute lsof strace unzip zip ca-certificates apt-transport-https
```

Pacotes opcionais são detectados, mas não instalados por padrão:

```text
btop ripgrep fd-find bat lsd
```

## Validação

Após aplicar, valide:

```bash
command -v grc
command -v fzf
command -v curl
command -v git
bash -n ~/.bashrc
```

Em Proxmox:

```bash
command -v pveversion
pveversion
```

## Rollback

Consulte [docs/rollback.md](docs/rollback.md).

## Licença

MIT. Consulte [LICENSE](LICENSE).
