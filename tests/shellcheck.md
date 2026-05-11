# ShellCheck

Validação recomendada antes de publicar:

```bash
shellcheck install.sh
bash -n install.sh
```

Teste de dry-run:

```bash
./install.sh
```

Teste de aplicação em ambiente descartável:

```bash
sudo ./install.sh --apply --system
sudo ./install.sh --apply --system
```

Critério: a segunda execução não deve duplicar o bloco gerenciado nem reinstalar pacotes já presentes.
