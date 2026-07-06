# 🔧 Plano de Interoperabilidade: Laptop ↔ Desktop

**Data**: 2025-11-26
**Laptop**: kernelcore @ 192.168.15.9 (NixOS)
**Desktop**: 192.168.15.7 (Remote Builder)
**Objetivo**: Estabelecer interoperabilidade completa via Tailscale + Remote Builds

---

## 📊 DIAGNÓSTICO COMPLETO

### Estado do Laptop (kernelcore)
```
IP Local: 192.168.15.9
Hostname: nx.local
Sistema: NixOS com flake
```

**✅ Funcionando:**
- Tailscale modules criados (6 módulos)
- Documentação completa
- SSH key nix-builder gerada
- Sandboxing corrigido

**⚠️ Pendente:**
1. Secrets Tailscale em texto plano (não encriptados)
2. Módulo firewall-zones não importado no flake.nix
3. Não consegue acessar desktop via SSH (chaves não autorizadas)

### Estado do Desktop (192.168.15.7)
```
IP Local: 192.168.15.7
Status: Online (nmap confirmou)
SSH: Porta 22 aberta mas rejeita autenticação
```

**Problema de Acesso SSH:**
```
debug1: Authentications that can continue: publickey,keyboard-interactive
debug1: Offering public key: sec@voidnxlabs.com (REJEITADO)
debug1: Offering public key: /etc/nix/builder_key (REJEITADO)
Connection closed by 192.168.15.7
```

**Causa:** Chaves SSH do laptop não estão nos `authorized_keys` do desktop

---

## 🔑 SOLUÇÃO 1: ACESSO AO DESKTOP (CRÍTICO)

### Opção A: Via Console Físico (RECOMENDADO)

**Acesso direto ao desktop para adicionar SSH key:**

1. **No desktop, adicionar chave pública do laptop:**

```bash
# Editar configuração NixOS no desktop
sudo nano /etc/nixos/hosts/*/configuration.nix

# Adicionar ao usuário kernelcore:
users.users.kernelcore = {
  openssh.authorizedKeys.keys = [
    # Chave pública do laptop (id_ed25519.pub)
    "ssh-ed25519 <CHAVE_PUBLICA_DO_LAPTOP> kernelcore@nx"

    # Chave nix-builder (para remote builds)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq nix-builder@nx"
  ];
};

# Também adicionar ao usuário nix-builder:
users.users.nix-builder = {
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq nix-builder@nx"
  ];
};
```

2. **Rebuild desktop:**
```bash
sudo nixos-rebuild switch --flake /etc/nixos#<hostname-desktop>
```

3. **Verificar no desktop:**
```bash
systemctl status nix-serve
systemctl status sshd
cat ~/.ssh/authorized_keys  # Para usuário kernelcore
```

### Opção B: Via Recovery/Single User Mode

Se não houver acesso físico normal:

1. Boot no GRUB, adicionar `systemd.unit=rescue.target`
2. Login como root
3. Adicionar chaves manualmente a `/home/kernelcore/.ssh/authorized_keys`
4. Reboot normal

### Opção C: Via Another User (se existir)

Se houver outro usuário com acesso SSH no desktop:

```bash
# Do laptop, conectar com outro usuário
ssh outro-usuario@192.168.15.7

# Adicionar chave ao kernelcore
sudo -u kernelcore mkdir -p /home/kernelcore/.ssh
sudo -u kernelcore nano /home/kernelcore/.ssh/authorized_keys
# Colar chave pública
sudo chmod 700 /home/kernelcore/.ssh
sudo chmod 600 /home/kernelcore/.ssh/authorized_keys
```

---

## 🔐 SOLUÇÃO 2: ENCRIPTAR SECRETS (IMEDIATO - LAPTOP)

**Executar no laptop agora:**

```bash
# 1. Verificar que SOPS está configurado
cat /etc/nixos/.sops.yaml

# 2. Encriptar secrets Tailscale
sudo sops -e -i /etc/nixos/secrets/tailscale.yaml

# 3. Verificar encriptação
head -5 /etc/nixos/secrets/tailscale.yaml
# Deve mostrar conteúdo encriptado começando com "sops:"
```

**Status:**
- ❌ Arquivo atual: TEXTO PLANO (vulnerável)
- ✅ Após comando: ENCRIPTADO com SOPS

---

## ⚙️ SOLUÇÃO 3: ADICIONAR FIREWALL-ZONES (IMEDIATO - LAPTOP)

**Editar flake.nix:**

```bash
# Localizar as importações do Tailscale (linhas 145-150)
# Adicionar a linha faltante:

./modules/network/vpn/tailscale.nix
./modules/network/proxy/nginx-tailscale.nix
./modules/network/proxy/tailscale-services.nix
./modules/network/security/firewall-zones.nix    # ← ADICIONAR ESTA LINHA
./modules/network/monitoring/tailscale-monitor.nix
./modules/secrets/tailscale.nix
```

---

## 🚀 PLANO DE EXECUÇÃO COMPLETO

### FASE 1: Correções no Laptop (AGORA - Sem acesso desktop)

```bash
# 1. Encriptar secrets
sudo sops -e -i /etc/nixos/secrets/tailscale.yaml

# 2. Verificar chave pública que será adicionada no desktop
cat ~/.ssh/id_ed25519.pub
cat ~/.ssh/nix-builder.pub

# 3. Adicionar firewall-zones ao flake.nix
nano /etc/nixos/flake.nix
# Inserir linha: ./modules/network/security/firewall-zones.nix

# 4. Validar configuração
nix flake check --show-trace

# 5. NÃO fazer rebuild ainda (aguardar acesso desktop)
```

### FASE 2: Configuração no Desktop (COM ACESSO)

**No desktop (192.168.15.7):**

```bash
# 1. Localizar configuração
ls -la /etc/nixos/hosts/
cat /etc/nixos/flake.nix | grep nixosConfigurations

# 2. Explorar diretório server/ mencionado
ls -la /etc/nixos/server/
# Verificar configurações existentes

# 3. Editar configuração para adicionar SSH keys
sudo nano /etc/nixos/hosts/<hostname>/configuration.nix

# Adicionar:
users.users.kernelcore = {
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 <CHAVE_LAPTOP_id_ed25519.pub>"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq nix-builder@nx"
  ];
};

users.users.nix-builder = {
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq nix-builder@nx"
  ];
};

# 4. Verificar serviço offload-server
cat /etc/nixos/hosts/*/configuration.nix | grep -A 10 offload-server

# 5. Rebuild desktop
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# 6. Verificar serviços
systemctl status nix-serve
systemctl status sshd
netstat -tlnp | grep 5000
```

### FASE 3: Teste de Conectividade (LAPTOP após desktop configurado)

```bash
# 1. Testar SSH básico
ssh kernelcore@192.168.15.7 "hostname && uname -a"

# 2. Testar SSH com chave nix-builder
ssh -i ~/.ssh/nix-builder nix-builder@192.168.15.7 "echo 'SSH OK'"

# 3. Testar acesso ao binary cache
curl http://192.168.15.7:5000/nix-cache-info

# 4. Testar remote build
nix-build '<nixpkgs>' -A hello
# Verificar nos logs se offload para desktop ocorreu

# 5. Verificar logs
journalctl -u nix-daemon -n 50
```

### FASE 4: Deploy Tailscale (LAPTOP após testes SSH)

```bash
# 1. Verificar secrets encriptados
sudo sops -d /etc/nixos/secrets/tailscale.yaml | head -5

# 2. Rebuild laptop com Tailscale
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# 3. Verificar Tailscale ativo
systemctl status tailscaled
tailscale status

# 4. Testar conectividade Tailscale
tailscale ping <desktop-tailscale-hostname>

# 5. Health check completo
/etc/tailscale/health-check.sh
```

### FASE 5: Deploy Tailscale no Desktop (Opcional)

**No desktop:**

```bash
# 1. Copiar módulos Tailscale do laptop
rsync -avz kernelcore@192.168.15.9:/etc/nixos/modules/network/ /etc/nixos/modules/network/

# 2. Adicionar ao flake.nix do desktop
# (mesmas importações que no laptop)

# 3. Configurar desktop como exit node/subnet router
# Editar configuration.nix:
kernelcore.network.vpn.tailscale = {
  enable = true;
  hostname = "desktop";
  isExitNode = true;
  advertiseRoutes = [ "192.168.15.0/24" ];
};

# 4. Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

---

## 📋 CHECKLIST DE VALIDAÇÃO

### ✅ Laptop Configurado
- [ ] Secrets encriptados com SOPS
- [ ] firewall-zones adicionado ao flake.nix
- [ ] `nix flake check` passa sem erros
- [ ] Chaves SSH públicas identificadas

### ✅ Desktop Configurado
- [ ] SSH keys do laptop adicionadas (kernelcore + nix-builder)
- [ ] Serviço nix-serve rodando (porta 5000)
- [ ] SSHD aceita conexões do laptop
- [ ] Configuração offload-server ativa

### ✅ Conectividade Estabelecida
- [ ] SSH laptop → desktop funciona
- [ ] SSH nix-builder → desktop funciona
- [ ] Binary cache acessível (HTTP 200)
- [ ] Remote builds funcionam (offload confirmado)

### ✅ Tailscale Operacional
- [ ] tailscaled ativo no laptop
- [ ] Laptop conectado à mesh Tailscale
- [ ] MagicDNS funcionando
- [ ] Serviços acessíveis via Tailscale

### ✅ Integração Completa
- [ ] Builds pesados offload para desktop
- [ ] Binary cache compartilhado funciona
- [ ] Acesso remoto via Tailscale funciona
- [ ] Monitoramento ativo

---

## 🔧 COMANDOS ÚTEIS PARA DEBUG

### No Laptop

```bash
# Verificar configuração SSH
cat ~/.ssh/config

# Listar chaves SSH disponíveis
ssh-add -l

# Testar conexão verbose
ssh -vvv kernelcore@192.168.15.7

# Verificar buildMachines configurado
nix show-config | grep builders

# Forçar remote build
nix-build '<nixpkgs>' -A hello --option builders 'ssh://nix-builder@192.168.15.7 x86_64-linux'
```

### No Desktop

```bash
# Verificar usuários
cat /etc/passwd | grep -E 'kernelcore|nix-builder'

# Verificar authorized_keys
sudo cat /home/kernelcore/.ssh/authorized_keys
sudo cat /home/nix-builder/.ssh/authorized_keys

# Logs SSH
journalctl -u sshd -f

# Logs nix-serve
journalctl -u nix-serve -f

# Testar cache local
curl http://localhost:5000/nix-cache-info
```

---

## 🚨 PROBLEMAS CONHECIDOS & SOLUÇÕES

### Problema: SSH "Permission denied (publickey)"

**Causa:** Chave pública não está em authorized_keys
**Solução:** Adicionar chave ao desktop (Fase 2)

### Problema: Binary Cache HTTP 500

**Causa Real:** Falha de autenticação SSH (não é erro HTTP)
**Solução:** Configurar SSH keys corretamente

### Problema: "does not support kernel namespaces"

**Status:** ✅ JÁ CORRIGIDO
**Fix:** Linha `kernel.unprivileged_userns_clone = 0` comentada em `sec/hardening.nix:267`

### Problema: Tailscale não inicia

**Possíveis causas:**
1. Secrets não encriptados → Encriptar com SOPS
2. Módulos não importados → Verificar flake.nix
3. Auth key inválido → Regenerar no Tailscale admin

---

## 📚 REFERÊNCIAS RÁPIDAS

### Documentação Criada
- `/etc/nixos/docs/guides/TAILSCALE-MESH-NETWORK.md` - Guia completo
- `/etc/nixos/docs/INFRASTRUCTURE-FIX-SUMMARY.md` - Fixes SSH/sandbox
- `/etc/nixos/HANDOFF-TAILSCALE-E-INFRAESTRUTURA.md` - Status completo

### Chaves SSH Críticas

**Laptop para Desktop (kernelcore user):**
```
# Copiar do laptop:
cat ~/.ssh/id_ed25519.pub

# Adicionar no desktop em:
users.users.kernelcore.openssh.authorizedKeys.keys
```

**Laptop para Desktop (nix-builder user):**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq nix-builder@nx
```

### IPs & Hostnames
- **Laptop**: 192.168.15.9 (nx.local)
- **Desktop**: 192.168.15.7
- **Gateway**: 192.168.15.1
- **Tailnet**: tailb3b82e.ts.net

---

## 🎯 PRÓXIMOS PASSOS IMEDIATOS

### Agora (Sem acesso desktop):

1. ✅ Encriptar secrets: `sudo sops -e -i /etc/nixos/secrets/tailscale.yaml`
2. ✅ Adicionar firewall-zones ao flake.nix
3. ✅ Validar: `nix flake check`
4. ✅ Preparar chaves públicas para copiar ao desktop

### Com acesso ao desktop:

1. 🔑 Adicionar SSH keys do laptop
2. 🔨 Rebuild desktop
3. 🧪 Testar SSH laptop → desktop
4. 🚀 Deploy Tailscale no laptop
5. ✅ Validação completa

---

## ✅ OBJETIVO FINAL

**Sistema Completo:**
- Laptop e Desktop interconectados via SSH
- Remote builds offload para desktop
- Binary cache compartilhado
- Tailscale mesh network operacional
- Acesso remoto seguro a todos os serviços
- Monitoramento e health checks ativos

**Benefícios:**
- ⚡ Builds mais rápidos (offload para desktop 8-cores)
- 🔒 Acesso remoto seguro via Tailscale
- 💾 Cache compartilhado (menos rebuilds)
- 📊 Monitoramento de performance
- 🌐 Serviços acessíveis de qualquer lugar

---

**Este plano fornece todas as soluções necessárias para estabelecer interoperabilidade completa entre laptop e desktop!**
