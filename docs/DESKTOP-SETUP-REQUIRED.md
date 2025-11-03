# Desktop Offload Server Setup - Ações Necessárias

**Data**: 2025-11-02  
**Laptop IP**: 192.168.15.8  
**Desktop IP**: 192.168.15.7 (ATUALIZADO)  
**Status**: ⚠️ Requer configuração no desktop

---

## 🎯 Objetivo

Configurar o desktop (192.168.15.7) como servidor de builds remotos para o laptop, permitindo:
- Builds remotos via SSH
- Cache binário via HTTP (nix-serve)
- Compartilhamento opcional de /nix/store via NFS

---

## ✅ O Que Já Foi Feito no Laptop

1. ✅ Módulo `offload-server.nix` adicionado ao flake.nix
2. ✅ Módulo `laptop-offload-client.nix` configurado
3. ✅ IPs atualizados de .6 para .7 em todos os arquivos
4. ✅ Configuração de fallback para builds locais
5. ✅ Chaves SSH já existem em `/etc/nix/builder_key*`
6. ✅ Sistema do laptop rebuilou com sucesso

---

## 🚨 Problema Atual

**Laptop não consegue conectar ao desktop**:
```
❌ Desktop unreachable at 192.168.15.7
❌ SSH builder access failed  
❌ Cache not accessible
```

**Causa**: Desktop precisa:
1. Ter `services.offload-server` habilitado
2. Ter chave SSH pública do laptop autorizada para nix-builder
3. Ter nix-serve rodando na porta 5000
4. Ter firewall liberando portas 22 e 5000

---

## 📋 CHECKLIST DE AÇÕES NO DESKTOP

### ☑️ Passo 1: Verificar/Adicionar Import no flake.nix

**Arquivo**: `/etc/nixos/flake.nix`

Verificar se existe a linha:
```nix
./modules/services/offload-server.nix
```

**Localização**: Seção de imports dos módulos (provavelmente próximo a linha 73)

**Se NÃO existir**, adicionar:
```nix
# Services  
./modules/services/offload-server.nix  # ← ADICIONAR
./modules/services/default.nix
```

---

### ☑️ Passo 2: Habilitar offload-server no configuration.nix

**Arquivo**: `/etc/nixos/hosts/kernelcore/configuration.nix`

**Verificar se JÁ EXISTE** (linha ~242-248):
```nix
services.offload-server = {
  enable = true;
  cachePort = 5000;
  builderUser = "nix-builder";
  cacheKeyPath = "/var/cache-priv-key.pem";
  enableNFS = false;
};
```

**Se não existir**, adicionar na seção `services = { ... }`.

---

### ☑️ Passo 3: Verificar/Gerar Cache Keys

**Verificar se existem**:
```bash
ls -la /var/cache-*.pem
```

**Saída esperada**:
```
-rw------- 1 root root 100 /var/cache-priv-key.pem
-rw-r--r-- 1 root root  56 /var/cache-pub-key.pem
```

**Se NÃO existirem**, gerar:
```bash
# Gerar par de chaves
sudo nix-store --generate-binary-cache-key cache.local \
  /var/cache-priv-key.pem \
  /var/cache-pub-key.pem

# Verificar chave pública (para o laptop)
cat /var/cache-pub-key.pem
```

**Anotar a chave pública** - será necessária no laptop!

---

### ☑️ Passo 4: Configurar SSH para nix-builder

**4.1** Obter chave pública SSH do laptop:

```bash
# COPIAR do laptop para o desktop (método 1 - via SCP)
scp kernelcore@192.168.15.8:/etc/nix/builder_key.pub /tmp/laptop-builder-key.pub

# OU método 2 - copiar manualmente
# No laptop, executar: cat /etc/nix/builder_key.pub
# Copiar a saída
```

**Chave pública do laptop** (para referência):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBcvZ... nix-builder@laptop-to-desktop
```

**4.2** Adicionar chave ao nix-builder no desktop:

```bash
# Criar diretório .ssh para nix-builder (se não existir)
sudo mkdir -p /var/lib/nix-builder/.ssh
sudo chmod 700 /var/lib/nix-builder/.ssh

# Adicionar chave pública do laptop
sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys < /tmp/laptop-builder-key.pub

# OU se copiou manualmente:
echo "ssh-ed25519 AAAAC3NzaC1... nix-builder@laptop-to-desktop" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys

# Ajustar permissões
sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /var/lib/nix-builder/.ssh
```

**4.3** Verificar configuração:

```bash
# Listar chaves autorizadas
sudo cat /var/lib/nix-builder/.ssh/authorized_keys

# Verificar permissões
ls -la /var/lib/nix-builder/.ssh/
```

---

### ☑️ Passo 5: Verificar Firewall

```bash
# Listar portas abertas
sudo firewall-cmd --list-ports 2>/dev/null || \
  sudo iptables -L -n | grep -E ':(22|5000)'

# Se firewalld estiver ativo e portas não abertas:
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

**Portas necessárias**:
- 22/tcp (SSH - para builds remotos)
- 5000/tcp (HTTP - para nix-serve cache)

---

### ☑️ Passo 6: Rebuild do Desktop

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

**Aguardar build completar** (pode demorar alguns minutos).

---

### ☑️ Passo 7: Validar Serviços

```bash
# Verificar nix-serve
systemctl status nix-serve

# Verificar SSH
systemctl status sshd

# Verificar se porta 5000 está escutando
sudo ss -tlnp | grep 5000

# Testar cache localmente
curl http://localhost:5000/nix-cache-info
```

**Saídas esperadas**:
- `nix-serve.service`: **active (running)**
- `sshd.service`: **active (running)**  
- Porta 5000: **LISTEN** (processo nix-serve-4.0.0)
- curl: Retorna info do cache (StoreDir, WantMassQuery, etc)

---

## 🧪 TESTES FINAIS

### No Desktop:

```bash
# Status do servidor
systemctl status nix-serve

# Logs do nix-serve
journalctl -u nix-serve -n 20

# Verificar usuário nix-builder
id nix-builder

# Listar chaves SSH autorizadas
sudo cat /var/lib/nix-builder/.ssh/authorized_keys
```

### No Laptop (após desktop configurado):

```bash
# Testar ping
ping -c 2 192.168.15.7

# Testar cache HTTP
curl http://192.168.15.7:5000/nix-cache-info

# Testar SSH
ssh nix-builder@192.168.15.7 'echo "SSH OK"'

# Status geral
offload-status

# Teste de build remoto
offload-test-build
```

**Saídas esperadas do `offload-status`**:
```
📡 Desktop Connection:
✅ Desktop reachable at 192.168.15.7

🔑 SSH Builder Access:
✅ SSH builder access working

🗄️  Cache Access:
✅ Desktop cache accessible
```

---

## 🐛 TROUBLESHOOTING

### ❌ nix-serve não inicia

```bash
# Ver logs de erro
journalctl -u nix-serve -xe

# Verificar se chave existe
ls -la /var/cache-priv-key.pem

# Reiniciar serviço
sudo systemctl restart nix-serve
```

### ❌ SSH recusa conexão do laptop

```bash
# Ver logs SSH
journalctl -u sshd -f

# No laptop, testar com verbose
ssh -vvv nix-builder@192.168.15.7

# Verificar firewall
sudo systemctl status firewalld
```

### ❌ Cache retorna HTTP 500

```bash
# Verificar permissões da chave
ls -la /var/cache-priv-key.pem
# Deve ser: -rw------- root root

# Regenerar chaves se necessário
sudo nix-store --generate-binary-cache-key cache.local \
  /var/cache-priv-key.pem \
  /var/cache-pub-key.pem
  
# Reiniciar nix-serve
sudo systemctl restart nix-serve
```

### ❌ Build remoto falha com "permission denied"

Usuário nix-builder precisa estar em `trusted-users`:

```nix
# Em configuration.nix
nix.settings.trusted-users = [ "nix-builder" ];
```

Rebuild após adicionar.

---

## 📊 RESUMO DAS MUDANÇAS

### Arquivos Modificados no Laptop:
```
M  flake.nix (adicionado import offload-server.nix)
M  modules/services/laptop-offload-client.nix (IP .6 → .7)
M  modules/services/laptop-builder-client.nix (IP .6 → .7)
M  modules/system/ssh-config.nix (IP .6 → .7 em 2 lugares)
M  modules/system/binary-cache.nix (IP .6 → .7)
M  modules/services/offload-server.nix (removido builtins.readFile)
M  docs/LAPTOP-BUILD-SETUP.md (atualizado para .7)
A  docs/DESKTOP-SETUP-REQUIRED.md (este arquivo)
```

### Configurações Chave:

**Laptop**:
- Desktop IP: 192.168.15.7
- Builder key: /etc/nix/builder_key (ED25519)
- Fallback: Habilitado (max-jobs = 4)
- Cache priority: Desktop primeiro, depois internet

**Desktop** (precisa configurar):
- Cache port: 5000
- Builder user: nix-builder
- Cache key: /var/cache-priv-key.pem
- SSH: Aceitar chave pública do laptop

---

## 🚀 PRÓXIMOS PASSOS

1. **Imediato**: Seguir checklist acima no desktop
2. **Validação**: Executar testes finais
3. **Otimização**: Considerar habilitar NFS se quiser economizar espaço no laptop

---

## 📝 INFORMAÇÕES ADICIONAIS

### Cache Key Atual (Desktop):
```
cache.local:EWjcIcuqRTy3jGmiu3SiMRsUiUs81fyny2fksficOik=
```
*(Verificar se mudou após regeneração)*

### Builder SSH Key Fingerprint (Laptop):
```
256 SHA256:xGvhOvOcoYDd6uxP+FuGkrNwXUvLvHR5f9q0SO34iGk nix-builder@laptop-to-desktop (ED25519)
```

### Referências:
- Módulo offload-server: `/etc/nixos/modules/services/offload-server.nix`
- Módulo laptop client: `/etc/nixos/modules/services/laptop-offload-client.nix`
- Docs NixOS: https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html

---

**Gerado em**: 2025-11-02  
**Gerado por**: Claude Code no laptop (kernelcore@nx)  
**Para**: Desktop (kernelcore@desktop - 192.168.15.7)
