# Debian

## Uso Recomendado

Execute primeiro em modo `dry-run`:

```bash
./install.sh
```

Depois aplique:

```bash
./install.sh --apply
```

Para configuração global de Bash:

```bash
sudo ./install.sh --apply --system
```

## Cuidados

- Revise a lista de pacotes antes de aplicar.
- Evite executar em sessão crítica sem acesso alternativo ao servidor.
- O script valida sintaxe Bash depois de alterar arquivos.
- Backups são criados antes de qualquer alteração real.

## Arquivos Possivelmente Alterados

```text
~/.bashrc
/etc/bash.bashrc
```

`/etc/bash.bashrc` só entra no escopo com `--system`.
