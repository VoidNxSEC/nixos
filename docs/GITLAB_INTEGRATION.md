# 🔐 GitLab Integration - Quick Reference

## 📋 Chaves Geradas

### SSH Key para GitLab

**Adicione esta chave no GitLab (https://gitlab.com/-/profile/keys):**

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyAHCfElZid7pLtp8lk9H5n8MTEpUfvSAVxxE6fFr5V sec@voidnxlabs.com
```

### GPG Key (Já configurada)

Sua chave GPG existente já está configurada:
- **Key ID:** `5606AB430E95F5AD`
- **Email:** sec@voidnxlabs.com
- **Expira:** 2026-09-29

**Exporte para o GitLab:**
```bash
gpg --armor --export 5606AB430E95F5AD
```

Adicione em: https://gitlab.com/-/profile/gpg_keys

---

## ✅ Integração NixOS

### 1. Importar módulo SSH

Adicione ao `/etc/nixos/hosts/kernelcore/home/home.nix`:

```nix
imports = [
  # ... suas importações existentes
  /home/kernelcore/arch/cerebro/nix/ssh-gitlab-config.nix
];
```

### 2. Git config já está atualizado

O arquivo `/etc/nixos/hosts/kernelcore/home/git.nix` foi atualizado com:
- ✅ `url."git@gitlab.com:".insteadOf = "https://gitlab.com/"`
- ✅ `push.autoSetupRemote = true`
- ✅ `push.default = "current"`
- ✅ GPG signing habilitado

### 3. Rebuild do sistema

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 8 --cores 8
```

---

## 🧪 Teste a Integração

### 1. Teste SSH

```bash
ssh -T git@gitlab.com
# Esperado: Welcome to GitLab, @yourusername!
```

### 2. Clone um repo

```bash
git clone git@gitlab.com:yourusername/test-repo.git
```

### 3. Commit com GPG

```bash
cd test-repo
echo "test" > file.txt
git add file.txt
git commit -m "test: GPG signing"
git log --show-signature -1
# Esperado: gpg: Good signature from "marcos (gh) <sec@voidnxlabs.com>"
```

---

## 🚀 Push do Cerebro para GitLab

Se quiser hospedar o Cerebro também no GitLab:

```bash
cd /home/kernelcore/arch/cerebro

# Adicionar remote GitLab
git remote add gitlab git@gitlab.com:yourusername/cerebro.git

# Push com commits assinados
git push gitlab main

# Ou configurar como mirror
git remote set-url --add --push origin git@gitlab.com:yourusername/cerebro.git
git push origin main  # Pushará para GitHub E GitLab
```

---

## 📝 Resumo das Mudanças

### Arquivos Criados
- ✅ `~/.ssh/id_ed25519_gitlab` - Chave privada GitLab
- ✅ `~/.ssh/id_ed25519_gitlab.pub` - Chave pública GitLab
- ✅ `/home/kernelcore/arch/cerebro/nix/ssh-gitlab-config.nix` - Config SSH
- ✅ `/home/kernelcore/arch/cerebro/nix/gpg-gitlab-config.nix` - Config GPG (opcional)

### Arquivos Modificados
- ✅ `/etc/nixos/hosts/kernelcore/home/git.nix` - Adicionado GitLab config

### Próximos Passos
1. [ ] Adicionar SSH key no GitLab
2. [ ] Adicionar GPG key no GitLab
3. [ ] Importar `ssh-gitlab-config.nix` no home.nix
4. [ ] Rebuild NixOS
5. [ ] Testar conexão SSH
6. [ ] Push Cerebro para GitLab (opcional)

---

**Gerado em:** 2026-01-15
**Autor:** kernelcore
**Projeto:** Cerebro Knowledge Extraction Platform
