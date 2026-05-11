# Proxmox

## Política de Segurança

O script é conservador para Proxmox:

- Não altera repositórios APT.
- Não executa upgrades do sistema.
- Não reinicia serviços.
- Não altera rede, bridge, VLAN, firewall, storage, cluster ou HA.
- Usa `pveversion` apenas para detecção e validação.

## Execução Recomendada

```bash
./install.sh
```

Se a saída estiver correta:

```bash
sudo ./install.sh --apply --system
```

## Riscos

- Alteração incorreta de shell pode dificultar login interativo.
- Alias conflitante pode mudar a experiência do operador.
- Pacotes indisponíveis podem indicar repositório incompleto ou host sem internet.

O script mitiga isso usando `dry-run`, backup, bloco gerenciado e validação com `bash -n`.
