# Guia Rápido: Configurar Desktop como Build Server

> **Objetivo**: Configurar desktop (192.168.15.7) para servir builds ao laptop, economizando espaço em disco (apenas 1GB livre no laptop)

## Status Atual

✅ Desktop acessível via rede (192.168.15.7)  
✅ Módulos de offload existem no repositório  
⚠️ Precisa configurar autenticação SSH sem senha  
⚠️ Precisa habilitar offload-server no desktop  
⚠️ Precisa habilitar offload-client no laptop  

---

## Configuração Rápida (3 Passos)

### Passo 1: Executar Script de Setup (Laptop)

```bash
cd /etc/nixos
./scripts/setup-desktop-offload.sh
```

O script vai:
- Copiar sua chave SSH para o desktop (vai pedir senha UMA VEZ)
- Configurar autenticação sem senha
- Preparar configuração no desktop

---

### Passo 2: Configurar Desktop como Build Server

**No Desktop (192.168.15.7):**

```bash
# 1. Conectar via SSH (agora sem senha!)
ssh kernelcore@192.168.15.7

# 2. Editar configuração
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix

# 3. Adicionar (se ainda não existir):
services.offload-server = {
  enable = true;
  cachePort = 5000;
  builderUser = "nix-builder";
};

# 4. Aplicar configuração
sudo nixos-rebuild switch

# 5. Gerar chaves do cache
offload-generate-cache-keys

# 6. Verificar status
offload-server-status

# 7. Copiar chave pública (vai aparecer no output acima)
# Exemplo: cache.local:abc123...xyz789=
```

---

### Passo 3: Configurar Laptop como Build Client

**No Laptop (aqui):**

```bash
# 1. Editar flake.nix
sudo nano /etc/nixos/flake.nix

# 2. Descomentar linha 75 (remover # no início):
# DE:
#   # ./modules/services/laptop-offload-client.nix  # DISABLED
# PARA:
    ./modules/services/laptop-offload-client.nix

# 3. Editar laptop-offload-client.nix para atualizar IP
sudo nano /etc/nixos/modules/services/laptop-offload-client.nix

# 4. Verificar/alterar linha 13:
desktopIP = "192.168.15.7";  # Deve ser 192.168.15.7

# 5. Adicionar chave pública do desktop (obtida no passo 2.7)
# Localizar linha ~39 e adicionar:
trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "cache.local:COLE_AQUI_A_CHAVE_DO_DESKTOP"
];

# 6. Aplicar configuração
sudo nixos-rebuild switch

# 7. Verificar status
offload-status

# 8. Testar build remoto
offload-test-build
```

---

## Verificação Pós-Setup

### No Desktop
```bash
offload-server-status
# Deve mostrar:
# ✅ nix-serve: Running
# ✅ sshd: Running
# ✅ Cache signing key: Present
```

### No Laptop
```bash
offload-status
# Deve mostrar:
# ✅ Desktop reachable
# ✅ SSH builder access working
# ✅ Desktop cache accessible
```

---

## Benefícios Esperados

📊 **Economia de Espaço:**
- Laptop não precisa manter todos os pacotes compilados
- Builds são feitos no desktop com mais espaço
- Cache compartilhado via rede

⚡ **Performance:**
- Desktop mais poderoso faz builds pesados
- Laptop apenas baixa binários prontos
- Rebuild 2-5x mais rápido

💾 **Uso de Disco no Laptop:**
- Antes: ~30-50GB para `/nix/store` completo
- Depois: ~5-10GB (apenas essenciais)
- Acesso a packages do desktop via NFS

---

## Comandos Úteis

### Laptop
```bash
offload-status              # Status geral da conexão
offload-test-build          # Testar build remoto
offload-mount              # Montar NFS manualmente
offload-unmount            # Desmontar NFS
cache-status               # Status do cache binário
```

### Desktop
```bash
offload-server-status      # Status do servidor
offload-server-test        # Testar capacidade de build
offload-generate-cache-keys # Gerar chaves do cache (uma vez)
```

---

## Troubleshooting

### Desktop não responde
```bash
# Verificar conectividade
timeout 3 bash -c "echo > /dev/tcp/192.168.15.7/22"

# Verificar SSH
ssh kernelcore@192.168.15.7 'echo OK'
```

### Build falha no desktop
```bash
# No laptop, verificar configuração
nix show-config | grep -E "^builders|^max-jobs"

# Deve mostrar:
# builders = ssh://nix-builder@192.168.15.7 ...
# max-jobs = 4
```

### Cache não funciona
```bash
# Testar acesso ao cache
curl http://192.168.15.7:5000/nix-cache-info

# Deve retornar informações do cache
```

### SSH pede senha
```bash
# Reconfigurar chave SSH
ssh-copy-id -i ~/.ssh/id_ed25519.pub kernelcore@192.168.15.7

# Testar sem senha
ssh -o BatchMode=yes kernelcore@192.168.15.7 'echo OK'
```

---

## Modo Emergência (Desktop Offline)

Se o desktop ficar offline e você precisar fazer rebuild:

```bash
# Override temporário para builds locais
sudo nixos-rebuild switch --option max-jobs auto --option builders ""

# Ou editar flake.nix e comentar:
# ./modules/services/laptop-offload-client.nix
```

---

## Arquitetura Final

```
┌─────────────────────────────────────────────────┐
│                  LAPTOP (1GB livre)              │
│  ┌────────────────────────────────────────┐     │
│  │  Builds → Desktop (SSH)                │     │
│  │  Cache → Desktop:5000 (priority 1)     │     │
│  │  Cache → cache.nixos.org (fallback)    │     │
│  │  Store → /nix/store (minimal, ~5GB)    │     │
│  │  Remote→ /nix/store-remote (NFS,RO)    │     │
│  └────────────────────────────────────────┘     │
└─────────────────────────────────────────────────┘
                      │
                      │ SSH + NFS
                      ▼
┌─────────────────────────────────────────────────┐
│           DESKTOP (192.168.15.7)                │
│  ┌────────────────────────────────────────┐     │
│  │  nix-serve → :5000 (cache binário)     │     │
│  │  sshd → :22 (remote builds)            │     │
│  │  NFS → /nix/store (shared read-only)   │     │
│  │  User → nix-builder (trusted)          │     │
│  │  Store → /nix/store (full, ~850GB)     │     │
│  └────────────────────────────────────────┘     │
└─────────────────────────────────────────────────┘
```

---

## Referências

- [`REMOTE-BUILDER-CACHE-GUIDE.md`](./REMOTE-BUILDER-CACHE-GUIDE.md) - Guia completo
- [`BINARY-CACHE-SETUP.md`](./BINARY-CACHE-SETUP.md) - Setup de cache
- [`modules/services/offload-server.nix`](../modules/services/offload-server.nix) - Servidor
- [`modules/services/laptop-offload-client.nix`](../modules/services/laptop-offload-client.nix) - Cliente

---

**Data**: 2025-11-22  
**Status**: Pronto para execução  
**Tempo Estimado**: 15-20 minutos (incluindo rebuilds)