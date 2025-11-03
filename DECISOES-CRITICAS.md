# ⚡ DECISÕES CRÍTICAS - Offload Build Setup

**Data**: 2025-11-02  
**Situação**: Desktop está em .6, não .7  
**Impacto**: Setup não funciona até decidir caminho

---

## 🎯 DECISÃO #1: Qual IP usar?

### Opção A: MANTER Desktop em .6 ✅ RECOMENDADO

**Pros**:
- Desktop JÁ funciona em .6
- Cache JÁ responde
- Menos mudanças
- Rápido (5min)

**Cons**:
- Reverte trabalho de hoje
- IP .6 pode estar "ocupado" na rede

**Ação**: Reverter laptop para .6

---

### Opção B: MUDAR Desktop para .7

**Pros**:
- Mantém mudanças de hoje
- IP .7 "livre" na rede

**Cons**:
- Requer acesso ao desktop
- Pode quebrar outras configs
- Mais complexo (30min+)

**Ação**: Configurar IP estático no desktop

---

## 🚨 DECISÃO RECOMENDADA: Opção A

**Por quê?**
1. Desktop operacional em .6
2. Menor risco
3. Implementação imediata

---

## 📋 PLANO DE EXECUÇÃO - Opção A

### Passo 1: Reverter IPs (2min)

```bash
cd /etc/nixos

# Reverter todos os arquivos
sed -i 's/192\.168\.15\.7/192.168.15.6/g' \
  modules/services/laptop-offload-client.nix \
  modules/services/laptop-builder-client.nix \
  modules/system/ssh-config.nix \
  modules/system/binary-cache.nix \
  docs/LAPTOP-BUILD-SETUP.md

# Verificar mudanças
git diff
```

### Passo 2: Rebuild (1min)

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Passo 3: Verificar (1min)

```bash
# Ver config gerada
nix config show | grep substituters
# Deve mostrar: http://192.168.15.6:5000

# Testar cache
curl http://192.168.15.6:5000/nix-cache-info
# Deve retornar: StoreDir, WantMassQuery, Priority
```

### Passo 4: Configurar SSH Desktop (10min)

**No Desktop (192.168.15.6)**:

```bash
# 1. Obter chave pública do laptop
# (do laptop) cat /etc/nix/builder_key.pub

# 2. Adicionar ao nix-builder (no desktop)
sudo mkdir -p /var/lib/nix-builder/.ssh
echo "ssh-ed25519 AAAA... nix-builder@laptop-to-desktop" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys
sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /var/lib/nix-builder/.ssh

# 3. Verificar trusted-users no desktop
# grep trusted-users /etc/nix/nix.conf
# Deve incluir: nix-builder
```

### Passo 5: Teste Final (2min)

```bash
# No laptop
offload-status
# Espera: todos ✅

offload-test-build  
# Espera: "building on ssh://nix-builder@192.168.15.6"
```

---

## 🔧 COMANDOS PRONTOS

### COPIAR E COLAR (Opção A)

```bash
# ===== NO LAPTOP =====

# 1. Reverter IPs
\
sed -i 's/192\.168\.15\.7/192.168.15.6/g' \
  modules/services/laptop-offload-client.nix \
  modules/services/laptop-builder-client.nix \
  modules/system/ssh-config.nix \
  modules/system/binary-cache.nix \
  docs/LAPTOP-BUILD-SETUP.md

# 2. Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# 3. Verificar config
nix config show | grep "192.168.15"

# 4. Obter chave SSH para o desktop
cat /etc/nix/builder_key.pub
# COPIAR A SAÍDA ↓↓↓


# ===== NO DESKTOP (192.168.15.6) =====

# 1. Criar diretório SSH
sudo mkdir -p /var/lib/nix-builder/.ssh

# 2. Adicionar chave (COLAR a chave copiada acima)
echo "SUA_CHAVE_SSH_AQUI" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys

# 3. Permissões
sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /var/lib/nix-builder/.ssh

# 4. Verificar trusted-users
grep trusted-users /etc/nix/nix.conf
# Deve incluir "nix-builder" ou "@wheel"

# 5. Se NÃO incluir, adicionar ao configuration.nix:
# nix.settings.trusted-users = [ "nix-builder" ];
# sudo nixos-rebuild switch


# ===== VOLTAR AO LAPTOP - TESTAR =====

# 1. Testar SSH
ssh nix-builder@192.168.15.6 'echo "SSH OK"'

# 2. Status completo
offload-status

# 3. Build de teste
offload-test-build
```

---

## ⏱️ TEMPO ESTIMADO

- **Opção A**: 15 minutos
- **Opção B**: 30-60 minutos

---

## ✅ CRITÉRIOS DE SUCESSO

Após implementação, verificar:

1. `nix config show | grep substituters` → mostra .6
2. `curl http://192.168.15.6:5000/nix-cache-info` → retorna dados
3. `ssh nix-builder@192.168.15.6 'echo OK'` → conecta
4. `offload-status` → todos ✅
5. `offload-test-build` → builda remotamente

---

## 🆘 SE DER ERRADO

### Reverter tudo:

```bash
# Reverter para geração anterior
sudo nixos-rebuild switch --rollback

# OU rebuild para estado conhecido
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Logs para debug:

```bash
# Rebuild
tail -100 /tmp/nixos-rebuild-*.log

# Nix daemon
journalctl -u nix-daemon -n 50

# SSH
journalctl -u sshd -f
```

---

**ESCOLHA AGORA**: Opção A ou B?

**Recomendação**: Opção A (reverter para .6)
