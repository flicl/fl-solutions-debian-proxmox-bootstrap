# Rollback

## Remover Apenas o Bloco FL Solutions

Para remover manualmente, edite o arquivo afetado e apague tudo entre:

```text
# BEGIN FL SOLUTIONS MANAGED BLOCK
# END FL SOLUTIONS MANAGED BLOCK
```

Arquivos possíveis:

```text
~/.bashrc
/etc/bash.bashrc
```

## Restaurar Backup Completo

Backups seguem este padrão:

```text
arquivo.bak.fl-solutions-YYYYmmdd-HHMMSS
```

Exemplo:

```bash
cp -a ~/.bashrc.bak.fl-solutions-20260511-140000 ~/.bashrc
```

Para `/etc/bash.bashrc`:

```bash
sudo cp -a /etc/bash.bashrc.bak.fl-solutions-20260511-140000 /etc/bash.bashrc
```

## Validar Depois do Rollback

```bash
bash -n ~/.bashrc
```

Se restaurou `/etc/bash.bashrc`:

```bash
sudo bash -n /etc/bash.bashrc
```

Abra uma nova sessão SSH antes de encerrar a sessão atual em ambiente remoto.
