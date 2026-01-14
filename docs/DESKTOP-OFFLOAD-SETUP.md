# 🖥️ Setup Desktop Offload - RESUMO EXECUTIVO

**Data**: 2025-11-22  
**Objetivo**: Configurar desktop (192.168.15.7) como build server para laptop (apenas 1GB livre)

---

## ✅ O QUE FOI PREPARADO

1. **Script Automatizado**: [`scripts/setup-desktop-offload.sh`](scripts/setup-desktop-offload.sh)
   - Configura chaves SSH sem senha
   - Prepara desktop e laptop automaticamente
   - Guia interativo passo a passo

2. **Guia Completo**: [`docs/DESKTOP-OFFLOAD-QUICKSTART.md`](docs/DESKTOP-OFFLOAD-QUICKSTART.md)
   - Instruções detalhadas
   - Troubleshooting
   - Comandos úteis

3. **Módulos Existentes** (já no repositório):
   - [`modules/services/offload-server.nix`](modules/services/offload-server.nix) - Servidor
   - [`modules/services/laptop-offload-client.nix`](modules/services/laptop-offload-client.nix) - Cliente

---

## 🚀 PRÓXIMOS PASSOS (VOCÊ PRECISA EXECUTAR)

### Passo 1: Executar Script de Setup

```bash
cd /etc/nixos
./scripts/setup-desktop-offload.sh
```

**O que o script faz:**
- Copia sua chave SSH para o desktop (vai pedir senha UMA VEZ)
- Configura autenticação sem senha
- Prepara ambos os sistemas

**Tempo**: ~5 minutos

---

### Passo 2: No Desktop (SSH: kernelcore@192.168.15.7)

```bash
# 1. Conectar (agora sem senha!)
ssh kernelcore@192.168.15.7

# 2. Editar configuração
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix

# 3. Adicionar essas linhas:
services.offload-server = {
  enable = true;
  cachePort = 5000;
  builderUser = "nix-builder";
};

# 4. Salvar e aplicar
sudo nixos-rebuild switch

# 5. Gerar chaves do cache
offload-generate-cache-keys

# 6. Copiar a chave pública que aparecer
# Formato: cache.local:abc123...xyz789=
```

**Tempo**: ~10 minutos (incluindo rebuild)

---

### Passo 3: No Laptop (Aqui)

```bash
# 1. Editar flake.nix
sudo nano /etc/nixos/flake.nix

# 2. Descomentar linha 75:
# DE:  # ./modules/services/laptop-offload-client.nix
# PARA:  ./modules/services/laptop-offload-client.nix

# 3. Editar cliente
sudo nano /etc/nixos/modules/services/laptop-offload-client.nix

# 4. Verificar linha 13 (IP deve ser 192.168.15.7):
desktopIP = "192.168.15.7";

# 5. Adicionar chave pública do desktop (linha ~39):
trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "COLE_AQUI_A_CHAVE_DO_PASSO_2"
];

# 6. Aplicar
sudo nixos-rebuild switch

# 7. Testar
offload-status
offload-test-build
```

**Tempo**: ~10 minutos (incluindo rebuild)

---

## 📊 RESULTADO ESPERADO

### Antes (Laptop Sozinho)
- `/nix/store`: 30-50GB ocupado
- Builds locais: LENTOS
- Espaço livre: 1GB ❌

### Depois (com Desktop Offload)
- `/nix/store` local: 5-10GB (apenas essenciais)
- Builds remotos: RÁPIDOS (no desktop)
- Cache via LAN: >10x mais rápido que internet
- Espaço economizado: ~40GB ✅

### Arquitetura
```
LAPTOP (1GB livre)
   ↓ SSH builds
   ↓ Cache requests
   ↓ NFS read-only store
DESKTOP (192.168.15.7)
   • Executa builds pesados
   • Serve cache binário (:5000)
   • Compartilha /nix/store via NFS
```

---

## ⚡ INÍCIO RÁPIDO (1 comando)

Se você confia no script automatizado:

```bash
cd /etc/nixos && ./scripts/setup-desktop-offload.sh
```

Depois siga as instruções na tela!

---

## 🆘 SE ALGO DER ERRADO

### Desktop não responde
```bash
# Testar conectividade
timeout 3 bash -c "echo > /dev/tcp/192.168.15.7/22"
```

### Rebuild falha (desktop offline)
```bash
# Build local temporário
sudo nixos-rebuild switch --option max-jobs auto --option builders ""
```

### Ver logs detalhados
```bash
# No laptop
offload-status
cache-status

# No desktop (via SSH)
offload-server-status
journalctl -u nix-serve -n 50
```

---

## 📚 DOCUMENTAÇÃO COMPLETA

- [`docs/DESKTOP-OFFLOAD-QUICKSTART.md`](docs/DESKTOP-OFFLOAD-QUICKSTART.md) - Guia passo a passo
- [`docs/REMOTE-BUILDER-CACHE-GUIDE.md`](docs/REMOTE-BUILDER-CACHE-GUIDE.md) - Detalhes técnicos
- [`docs/BINARY-CACHE-SETUP.md`](docs/BINARY-CACHE-SETUP.md) - Setup de cache

---

## ✨ COMANDOS ÚTEIS PÓS-SETUP

```bash
# Verificar status
offload-status              # Status geral
cache-status               # Status do cache

# Testar
offload-test-build         # Build de teste remoto

# Gerenciar NFS
offload-mount              # Montar shares manualmente
offload-unmount            # Desmontar

# Emergência (desktop offline)
sudo nixos-rebuild switch --option max-jobs auto --option builders ""
```

---

**Status**: ✅ Pronto para configuração  
**Tempo Total Estimado**: 25-30 minutos  
**Complexidade**: Média (requer edições manuais em 2 arquivos)