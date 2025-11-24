# 🚀 COMANDOS PARA EXECUTAR AGORA

**Data**: 2025-11-22
**Status**: ✅ SSH configurado | ⚠️ **DISCO 99% CHEIO - AÇÃO IMEDIATA NECESSÁRIA!**

---

## 🚨 EMERGÊNCIA: DISCO CRÍTICO

**Situação Atual**: 430GB usado / 458.7GB (99% cheio)
**Espaço Livre**: Apenas 5.3GB ⚠️

### ⚡ ANTES DE TUDO: Libere Espaço!

```bash
# EXECUTAR AGORA (10-30 minutos):
sudo nix-collect-garbage -d
sudo nix-store --optimise
df -h /  # Verificar espaço liberado
```

**Esperado**: Liberar 50-150GB
**Detalhes**: Ver [`EMERGENCIA-LIBERAR-ESPACO.md`](EMERGENCIA-LIBERAR-ESPACO.md)

⚠️ **Só continue com os passos abaixo DEPOIS de liberar espaço!**

---

## ✅ O QUE JÁ FOI FEITO

- ✅ SSH funcionando: `cypher@192.168.15.7` (sem senha)
- ✅ IP atualizado no laptop-offload-client.nix: `192.168.15.7`
- ✅ Módulos de offload prontos
- ✅ Scripts e documentação criados

---

## 📋 PASSO 1: CONFIGURAR DESKTOP (192.168.15.7)

### Conecte ao desktop e execute:

```bash
# 1. Conectar via SSH
ssh -p 22 cypher@192.168.15.7

# 2. Fazer backup da configuração
sudo cp /etc/nixos/hosts/kernelcore/configuration.nix /etc/nixos/hosts/kernelcore/configuration.nix.backup

# 3. Editar configuração
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix
```

### Adicione ANTES da última linha `}`:

```nix
  # ===== OFFLOAD SERVER CONFIGURATION =====
  # Enable this host as a remote build server for laptops
  services.offload-server = {
    enable = true;
    cachePort = 5000;
    builderUser = "nix-builder";
    enableNFS = false;  # Opcional: true para compartilhar /nix/store via NFS
  };
```

### Continue no desktop:

```bash
# 4. Salvar arquivo (Ctrl+O, Enter, Ctrl+X no nano)

# 5. Aplicar configuração (vai demorar ~5-10 min)
cd /etc/nixos
sudo nixos-rebuild switch

# 6. Gerar chaves do cache
offload-generate-cache-keys

# 7. COPIE a chave pública que aparecer
# Formato: cache.local:abc123...xyz789=

# 8. Verificar status
offload-server-status
```

**⚠️ IMPORTANTE**: Copie a chave pública (cache.local:...) que aparecerá no passo 6!

---

## 📋 PASSO 2: CONFIGURAR LAPTOP (AQUI)

### Execute no laptop:

```bash
cd /etc/nixos

# 1. Editar flake.nix
sudo nano flake.nix

# 2. Localizar linha 75 e DESCOMENTAR (remover # no início):
# DE:
#     # ./modules/services/laptop-offload-client.nix  # DISABLED
# PARA:
      ./modules/services/laptop-offload-client.nix

# 3. Salvar (Ctrl+O, Enter, Ctrl+X)

# 4. Editar laptop-offload-client.nix
sudo nano modules/services/laptop-offload-client.nix

# 5. Verificar linha 13 (já atualizado):
desktopIP = "192.168.15.7";  # ✅ Deve estar assim

# 6. Localizar linha ~39 e ADICIONAR a chave pública DO DESKTOP:
trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "COLE_AQUI_A_CHAVE_DO_PASSO_1_ITEM_7"
];

# 7. Salvar (Ctrl+O, Enter, Ctrl+X)

# 8. Criar chave SSH para builds remotos
sudo mkdir -p /etc/nix
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N ""
sudo chmod 600 /etc/nix/builder_key

# 9. Copiar chave pública para o desktop
ssh-copy-id -i /etc/nix/builder_key.pub nix-builder@192.168.15.7

# 10. Aplicar configuração (vai demorar ~5-10 min)
sudo nixos-rebuild switch

# 11. Testar offload
offload-status
offload-test-build
```

---

## 🧪 VERIFICAÇÃO

### No Desktop:
```bash
ssh cypher@192.168.15.7

# Status do servidor
offload-server-status

# Deve mostrar:
# ✅ nix-serve: Running (port 5000)
# ✅ sshd: Running
# ✅ Cache signing key: Present
```

### No Laptop:
```bash
# Status do cliente
offload-status

# Deve mostrar:
# ✅ Desktop reachable at 192.168.15.7
# ✅ SSH builder access working
# ✅ Desktop cache accessible

# Testar build remoto
offload-test-build

# Deve executar build no desktop via SSH
```

---

## 📊 RESULTADO ESPERADO

Após configuração completa:

```
LAPTOP (kernelcore - 1GB livre)
   │
   ├─→ SSH builds ──────────→ DESKTOP (192.168.15.7)
   ├─→ Cache requests ───────→ http://192.168.15.7:5000
   └─→ NFS /nix/store (RO) ─→ Desktop /nix/store
```

**Benefícios:**
- 💾 Laptop economiza ~40GB de espaço em disco
- ⚡ Builds 2-5x mais rápidos (executados no desktop)
- 🗄️ Cache LAN 10x mais rápido que internet
- 🔄 Sincronização automática entre hosts

---

## 🆘 TROUBLESHOOTING

### Desktop: nix-serve não inicia
```bash
# No desktop, verificar logs
journalctl -u nix-serve -n 50

# Verificar se porta 5000 está livre
sudo netstat -tlnp | grep 5000

# Tentar restart
sudo systemctl restart nix-serve
```

### Laptop: SSH não conecta ao nix-builder
```bash
# Testar conexão
ssh -o BatchMode=yes nix-builder@192.168.15.7 'echo OK'

# Se falhar, recriar chave
sudo rm -f /etc/nix/builder_key*
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N ""
ssh-copy-id -i /etc/nix/builder_key.pub nix-builder@192.168.15.7
```

### Cache não funciona
```bash
# Testar acesso direto
curl http://192.168.15.7:5000/nix-cache-info

# Deve retornar informações do cache
```

### Build falha (desktop offline)
```bash
# Rebuild local temporário
sudo nixos-rebuild switch --option max-jobs auto --option builders ""

# Ou desabilitar offload:
sudo nano /etc/nixos/flake.nix
# Comentar: # ./modules/services/laptop-offload-client.nix
sudo nixos-rebuild switch
```

---

## 📚 DOCUMENTAÇÃO COMPLETA

- [`DESKTOP-OFFLOAD-SETUP.md`](./DESKTOP-OFFLOAD-SETUP.md) - Visão geral
- [`docs/DESKTOP-OFFLOAD-QUICKSTART.md`](./docs/DESKTOP-OFFLOAD-QUICKSTART.md) - Guia detalhado
- [`docs/REMOTE-BUILDER-CACHE-GUIDE.md`](./docs/REMOTE-BUILDER-CACHE-GUIDE.md) - Guia técnico completo

---

## ⏱️ TEMPO ESTIMADO

- **Desktop**: 15-20 minutos (incluindo rebuild)
- **Laptop**: 15-20 minutos (incluindo rebuild)
- **Total**: ~30-40 minutos

---

**✅ COMECE PELO PASSO 1 (DESKTOP)**