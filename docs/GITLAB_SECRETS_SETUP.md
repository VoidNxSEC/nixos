# 🔐 GitLab Secrets Setup (SOPS)

Configuração completa para adicionar o token GitLab ao SOPS de forma segura.

---

## 🚀 Quick Setup (Método Recomendado)

Execute o script automatizado:

```bash
cd /home/kernelcore/arch/cerebro
./scripts/setup-gitlab-secrets.sh
```

**O que o script faz:**
1. ✅ Adiciona regra GitLab ao `.sops.yaml` (se necessário)
2. ✅ Encripta o token GitLab com AGE
3. ✅ Salva em `/etc/nixos/secrets/gitlab.yaml` com permissões corretas
4. ✅ Verifica que a encriptação funcionou

---

## 📋 Setup Manual (Alternativa)

### 1. Adicionar Regra ao .sops.yaml

Edite `/etc/nixos/.sops.yaml` e adicione antes do "Default catch-all":

```yaml
  # GitLab secrets
  - path_regex: secrets/gitlab\.yaml$
    age: >-
      age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn,
      age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn
```

### 2. Criar Arquivo de Secrets

Crie `/tmp/gitlab-secret.yaml`:

```yaml
# GitLab Secrets

gitlab:
  token: glpat-toN0ppvu9pwemhHSeA1m
  username: marcosfpina
  email: sec@voidnxlabs.com

  api:
    url: https://gitlab.com/api/v4

  ssh:
    key_path: /home/kernelcore/.ssh/id_ed25519_gitlab

  gpg:
    key_id: 5606AB430E95F5AD

  runner:
    enabled: false
    token: ""
```

### 3. Encriptar com SOPS

```bash
cd /etc/nixos
sudo sops --encrypt /tmp/gitlab-secret.yaml > /etc/nixos/secrets/gitlab.yaml
sudo chmod 600 /etc/nixos/secrets/gitlab.yaml
sudo chown root:root /etc/nixos/secrets/gitlab.yaml
```

### 4. Verificar

```bash
sops --decrypt /etc/nixos/secrets/gitlab.yaml | head -20
```

---

## 🔧 Integração NixOS

### Opção 1: System-Wide (Recomendado)

Edite `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    /home/kernelcore/arch/cerebro/nix/ssh-gitlab-config.nix
    /home/kernelcore/arch/cerebro/nix/gitlab-secrets.nix  # ← Adicionar esta linha
  ];

  # ... resto da config
}
```

### Opção 2: Home Manager

Edite `~/.config/home-manager/home.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /home/kernelcore/arch/cerebro/nix/ssh-gitlab-config.nix
    /home/kernelcore/arch/cerebro/nix/gitlab-secrets.nix  # ← Adicionar esta linha
  ];

  # ... resto da config
}
```

### Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 8 --cores 8
```

---

## 🧪 Testes

### 1. Verificar Token Carregado

```bash
# Verificar se o secret está disponível
sudo ls -la /run/secrets/gitlab-token

# Ver o token (como root)
sudo cat /run/secrets/gitlab-token
```

### 2. Testar GitLab CLI (glab)

```bash
# Configurar glab (usa GITLAB_TOKEN automaticamente)
glab auth status

# Listar seus projetos
glab repo list

# Clonar um repo
glab repo clone yourusername/test-repo
```

### 3. Testar Git com Token

```bash
# Para HTTPS (usa credential helper)
git clone https://gitlab.com/yourusername/test-repo.git

# Token será usado automaticamente
```

### 4. Verificar Variáveis de Ambiente

```bash
# Em um novo shell após rebuild
echo $GITLAB_TOKEN | head -c 20
# Deve mostrar: glpat-toN0ppvu9pwemh...
```

---

## 📊 Estrutura Final de Secrets

```
/etc/nixos/
├── .sops.yaml                    # Configuração SOPS (com regra GitLab)
└── secrets/
    ├── github.yaml               # GitHub (existente)
    ├── gitlab.yaml               # GitLab (NOVO) ✅
    ├── gcp-ml.yaml              # GCP (existente)
    └── ...
```

**Conteúdo de gitlab.yaml (encriptado):**
```yaml
gitlab:
    token: ENC[AES256_GCM,data:...encrypted...]
    username: ENC[AES256_GCM,data:...encrypted...]
    # ... tudo encriptado com SOPS
```

---

## 🔐 Segurança

### Permissões Corretas

```bash
# Verificar permissões
ls -l /etc/nixos/secrets/gitlab.yaml
# Esperado: -rw------- 1 root root ... gitlab.yaml

# Secret em runtime
sudo ls -l /run/secrets/gitlab-token
# Esperado: -r-------- 1 kernelcore ... gitlab-token
```

### Quem Pode Descriptografar?

Apenas usuários com acesso às chaves AGE:
- `age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn`
- `age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn`

**Localização das chaves privadas AGE:**
```bash
ls ~/.config/sops/age/keys.txt
# ou
ls /etc/nixos/secrets/age-keys.txt
```

### Rotação de Token

Se precisar trocar o token GitLab:

```bash
# 1. Editar o secret
sudo sops /etc/nixos/secrets/gitlab.yaml

# 2. Modificar o campo 'token'
# 3. Salvar (SOPS re-encripta automaticamente)

# 4. Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

---

## 🛠️ Troubleshooting

### Erro: "no matching creation rules found"

**Causa:** `.sops.yaml` não tem regra para `secrets/gitlab.yaml`

**Solução:**
```bash
# Executar o script de setup novamente
./scripts/setup-gitlab-secrets.sh
```

### Erro: "failed to decrypt"

**Causa:** Chaves AGE não disponíveis ou corrompidas

**Solução:**
```bash
# Verificar chaves AGE
cat ~/.config/sops/age/keys.txt

# Se vazio, restaurar do backup
```

### Token não funciona no glab

**Causa:** Variável de ambiente não carregada

**Solução:**
```bash
# Abrir novo shell após rebuild
exit
# Login novamente

# Ou carregar manualmente
export GITLAB_TOKEN=$(sudo cat /run/secrets/gitlab-token)
glab auth status
```

### Permission denied ao acessar /run/secrets/

**Causa:** Secret configurado com owner errado

**Solução:** Verificar em `gitlab-secrets.nix`:
```nix
sops.secrets.gitlab-token = {
  owner = "kernelcore";  # ← Deve ser seu usuário
  mode = "0400";
};
```

---

## 🎯 Integração com CI/CD

### GitLab CI Runner (Opcional)

Para rodar pipelines localmente, descomente em `gitlab-secrets.nix`:

```nix
services.gitlab-runner = {
  enable = true;
  services = {
    cerebro-runner = {
      registrationConfigFile = config.sops.secrets.gitlab-token.path;
      dockerImage = "nixos/nix:latest";
      tagList = [ "nix" "nixos" "cerebro" ];
    };
  };
};
```

### GitHub Actions com GitLab

Se quiser usar GitHub Actions para push no GitLab:

```yaml
# .github/workflows/mirror-gitlab.yml
name: Mirror to GitLab

on:
  push:
    branches: [main]

jobs:
  mirror:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Mirror to GitLab
        run: |
          git remote add gitlab https://oauth2:${{ secrets.GITLAB_TOKEN }}@gitlab.com/yourusername/cerebro.git
          git push gitlab main --force
```

---

## ✅ Checklist de Integração Completa

- [ ] Script `setup-gitlab-secrets.sh` executado
- [ ] Arquivo `/etc/nixos/secrets/gitlab.yaml` criado
- [ ] Regra GitLab adicionada ao `.sops.yaml`
- [ ] Módulo `gitlab-secrets.nix` importado na config
- [ ] NixOS rebuild executado
- [ ] Secret `/run/secrets/gitlab-token` existe
- [ ] `glab auth status` funciona
- [ ] SSH key adicionada no GitLab
- [ ] GPG key registrada no GitLab (já estava)
- [ ] Teste de clone/push bem-sucedido

---

## 📚 Referências

- [SOPS Documentation](https://github.com/getsops/sops)
- [sops-nix Module](https://github.com/Mic92/sops-nix)
- [GitLab Personal Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
- [glab CLI Documentation](https://gitlab.com/gitlab-org/cli)

---

**Gerado em:** 2026-01-15
**Projeto:** Cerebro Knowledge Extraction Platform
**Status:** Integração GitLab 100% via SOPS
