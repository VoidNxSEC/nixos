# Laptop Setup - Comandos Rápidos
## Execução no Laptop (kernelcore)

> **Objetivo:** Configurar o laptop como cliente de builds remotos  
> **Pré-requisito:** Desktop já configurado e rodando

---

## 🚀 Setup Rápido - Laptop

### Passo 1: Atualizar IP do Desktop

**Editar:** `/etc/nixos/modules/services/laptop-offload-client.nix`

```bash
sudo nano /etc/nixos/modules/services/laptop-offload-client.nix
```

**Localizar e confirmar/atualizar:**

```nix
let
  # CONFIGURE THESE VALUES FOR YOUR SETUP
  desktopIP = "192.168.15.7"; # ← CONFIRMAR/ATUALIZAR
  laptopIP = "192.168.15.9";  # ← CONFIRMAR IP ATUAL

  builderKeyPath = "/etc/nix/builder_key";
in
```

**Verificar IP atual do laptop:**

```bash
ip addr show | grep "inet 192"
# Ou
hostname -I
```

### Passo 2: Gerar Chave SSH para Builds

```bash
# Criar diretório se não existir
sudo mkdir -p /etc/nix

# Gerar chave ED25519 (mais segura e rápida)
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N "" -C "nix-builder@laptop-to-desktop"

# Verificar
ls -la /etc/nix/builder_key*
```

Deve criar:
- `/etc/nix/builder_key` (privada)
- `/etc/nix/builder_key.pub` (pública)

### Passo 3: Copiar Chave Pública para Desktop

```bash
# Ver chave pública
cat /etc/nix/builder_key.pub
```

**Copie todo o conteúdo** (começa com `ssh-ed25519 AAAA...`)

**No desktop (via SSH tunnel), execute:**

```bash
echo "COLE_AQUI_A_CHAVE_PUBLICA" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys
```

Exemplo:
```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxx...xxx nix-builder@laptop-to-desktop" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys
```

### Passo 4: Adicionar Chave Pública do Cache

**Você recebeu do desktop algo como:**
```
cache.local:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=
```

**Editar:** `/etc/nixos/modules/services/laptop-offload-client.nix`

```bash
sudo nano /etc/nixos/modules/services/laptop-offload-client.nix
```

**Localizar `trusted-public-keys` e adicionar:**

```nix
trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "cache.local:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=" # ← ADICIONAR CHAVE DO DESKTOP
];
```

### Passo 5: Verificar laptop-offload-client Habilitado

**Editar:** `/etc/nixos/flake.nix`

```bash
nano /etc/nixos/flake.nix
```

**Verificar linha ~87:**

```nix
./modules/services/laptop-offload-client.nix # ENABLED: NFS + Binary Cache + Remote Builds
```

✅ **JÁ ESTÁ HABILITADO!** Apenas confirme que não está comentada.

### Passo 6: Testar Conectividade ANTES do Rebuild

```bash
# Ping
ping -c 3 192.168.15.7

# SSH com chave nova
ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 'echo "SSH OK"'

# Cache HTTP
curl -sf http://192.168.15.7:5000/nix-cache-info
```

**Se algum falhar, NÃO prossiga.** Volte e corrija no desktop.

### Passo 7: Rebuild do Laptop

```bash
# Dry-run primeiro (verifica sem aplicar)
sudo nixos-rebuild dry-build --flake /etc/nixos#kernelcore

# Se OK, aplicar
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

**Atenção:** O rebuild pode demorar pois vai configurar NFS e testar conectividade.

### Passo 8: Verificar Status

```bash
offload-status
```

**Output esperado:**
```
🖥️  Laptop Offload Client Status
===============================

📡 Desktop Connection:
✅ Desktop reachable at 192.168.15.7

🔑 SSH Builder Access:
✅ SSH builder access working

📁 NFS Mounts:
✅ /nix/store-remote mounted
   Size: 850G
✅ /var/lib/nix-offload-remote mounted
   Size: 50G

🗄️  Cache Access:
✅ Desktop cache accessible
```

### Passo 9: Testar Build Remoto

```bash
# Teste simples automatizado
offload-test-build
```

**OU manualmente:**

```bash
# Build remoto forçado (sem cache)
nix-build --builders "ssh://nix-builder@192.168.15.7 x86_64-linux /etc/nix/builder_key 2 1" \
          --option substitute false \
          '<nixpkgs>' -A hello --no-out-link
```

**Deve mostrar:**
```
building '/nix/store/xxx-hello.drv' on 'ssh://nix-builder@192.168.15.7'...
copying path '/nix/store/yyy-hello' from 'ssh://nix-builder@192.168.15.7'...
```

### Passo 10: Testar Cache

```bash
# Build com cache (deve pegar do desktop primeiro)
nix-build '<nixpkgs>' -A hello --no-out-link
```

**Deve mostrar:**
```
copying path '/nix/store/xxx-hello' from 'http://192.168.15.7:5000'...
```

---

## 📋 Checklist Laptop

- [ ] IP do desktop atualizado (192.168.15.7)
- [ ] Chave SSH gerada (`/etc/nix/builder_key`)
- [ ] Chave pública copiada para desktop
- [ ] Chave pública do cache adicionada em `trusted-public-keys`
- [ ] Conectividade testada (ping, SSH, cache HTTP)
- [ ] `laptop-offload-client.nix` habilitado no flake
- [ ] Rebuild executado com sucesso
- [ ] `offload-status` mostra tudo ✅
- [ ] Build remoto funciona (`offload-test-build`)
- [ ] Cache funciona (download de 192.168.15.7:5000)
- [ ] NFS montado (se habilitado)

---

## 🔴 Troubleshooting

### SSH Permission Denied

```bash
# Verificar chave
ls -la /etc/nix/builder_key*
sudo chmod 600 /etc/nix/builder_key

# Testar com verbose
ssh -vvv -i /etc/nix/builder_key nix-builder@192.168.15.7

# Verificar se chave pública está no desktop
ssh cypher@192.168.15.7 "sudo cat /var/lib/nix-builder/.ssh/authorized_keys"
```

### Cache Inacessível

```bash
# Testar diretamente
curl -v http://192.168.15.7:5000/nix-cache-info

# Verificar no desktop
ssh cypher@192.168.15.7 "systemctl status nix-serve"
```

### NFS Mount Failed

```bash
# Verificar se desktop exporta
showmount -e 192.168.15.7

# Tentar montar manualmente
sudo mount -t nfs 192.168.15.7:/nix/store /nix/store-remote

# Ver logs
journalctl -u nix-store-remote.mount
```

### Build Remoto Não Funciona

```bash
# Verificar configuração Nix
nix show-config | grep -E "^(max-jobs|builders|substituters)"

# Deve mostrar:
# builders = ssh://nix-builder@192.168.15.7 x86_64-linux /etc/nix/builder_key 2 1...
# substituters = http://192.168.15.7:5000 https://cache.nixos.org

# Forçar rebuild local se necessário
sudo nixos-rebuild switch --option max-jobs auto --option builders ""
```

---

## 🎯 Comandos Úteis

```bash
# Status completo
offload-status

# Testar build remoto
offload-test-build

# Montar NFS manualmente
offload-mount

# Desmontar NFS
offload-unmount

# Ver configuração Nix ativa
nix show-config | grep -E "^(max-jobs|builders|substituters)"

# Status do cache
cache-status

# Ver builds em tempo real
watch -n 2 offload-status
```

---

## ✅ Tudo Funcionando?

Se todos os testes passaram:

1. **Builds normais** agora usam o desktop automaticamente
2. **Cache** busca do desktop antes da internet
3. **NFS** compartilha /nix/store entre máquinas
4. **Fallback** para builds locais se desktop offline

**Próximo:** Monitore performance e ajuste conforme necessário.

---

**Status:** ⏳ Aguardando execução no laptop (após desktop configurado)