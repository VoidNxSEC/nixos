# Stack Server/Client - Guia Completo de Setup
## NFS + NAS + Remote Cache + Remote Builder

> **Criado:** 2025-11-26  
> **Objetivo:** Configuração completa da infraestrutura distribuída Laptop ↔ Desktop  
> **Status:** 🚧 Em Progresso

---

## 📋 Índice

1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
2. [Pré-requisitos](#pré-requisitos)
3. [Configuração do Desktop (Servidor)](#configuração-do-desktop-servidor)
4. [Configuração do Laptop (Cliente)](#configuração-do-laptop-cliente)
5. [Testes e Validação](#testes-e-validação)
6. [Troubleshooting](#troubleshooting)
7. [Manutenção e Monitoramento](#manutenção-e-monitoramento)

---

## 🏗️ Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                   INFRAESTRUTURA DISTRIBUÍDA                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐                    ┌──────────────────┐   │
│  │  LAPTOP (Client) │◄───────────────────┤ DESKTOP (Server) │   │
│  │  kernelcore      │                    │ cypher@192.168.15.7  │
│  │  192.168.15.9    │                    │                  │   │
│  └──────────────────┘                    └──────────────────┘   │
│         │                                          │             │
│         │                                          │             │
│         │  ┌────────────────────────────────────┐ │             │
│         ├──┤ 1. SSH Remote Builds               │◄┤             │
│         │  │    ssh://nix-builder@desktop       │ │             │
│         │  │    Port: 22                        │ │             │
│         │  └────────────────────────────────────┘ │             │
│         │                                          │             │
│         │  ┌────────────────────────────────────┐ │             │
│         ├──┤ 2. Binary Cache (HTTP)             │◄┤             │
│         │  │    http://192.168.15.7:5000        │ │             │
│         │  │    nix-serve                       │ │             │
│         │  └────────────────────────────────────┘ │             │
│         │                                          │             │
│         │  ┌────────────────────────────────────┐ │             │
│         └──┤ 3. NFS Storage Share               │◄┤             │
│            │    /nix/store (ro)                 │ │             │
│            │    /var/lib/nix-offload (rw)       │ │             │
│            │    Ports: 2049, 111                │ │             │
│            └────────────────────────────────────┘ │             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Componentes da Stack

| Componente | Função | Porta | Protocolo |
|------------|--------|-------|-----------|
| **SSH Remote Builder** | Executa builds pesados no desktop | 22 | SSH |
| **nix-serve (Cache)** | Serve pacotes pré-compilados | 5000 | HTTP |
| **NFS Server** | Compartilha /nix/store | 2049, 111 | NFS |
| **RPC Portmapper** | Gerencia serviços NFS | 111 | RPC |

### Benefícios

- ✅ **Performance:** Builds 2-5x mais rápidos via desktop
- ✅ **Storage:** Acesso a todo /nix/store do desktop (>850GB)
- ✅ **Cache:** 90% de cache hits antes de baixar da internet
- ✅ **Escalabilidade:** Adiciona mais máquinas facilmente
- ✅ **Resiliência:** Fallback automático para builds locais

---

## 📦 Pré-requisitos

### Desktop (192.168.15.7 - cypher)

- [x] NixOS instalado e funcionando
- [x] Acesso SSH ativo
- [ ] IP estático configurado (192.168.15.7)
- [ ] Firewall configurado (portas 22, 5000, 2049, 111)
- [ ] Storage suficiente (/nix/store com espaço)

### Laptop (192.168.15.9 - kernelcore)

- [x] NixOS instalado e funcionando
- [x] Configuração flake em `/etc/nixos`
- [x] Acesso à rede local do desktop
- [x] Cliente SSH configurado

### Rede

- [x] Desktop e laptop na mesma rede (192.168.15.0/24)
- [x] Conectividade entre máquinas (ping funcionando)
- [ ] Firewall do roteador permitindo tráfego local

---

## 🖥️ Configuração do Desktop (Servidor)

O desktop já tem o módulo `offload-server.nix` configurado. Vamos ativá-lo.

### Passo 1: Habilitar offload-server

**Arquivo:** `/etc/nixos/hosts/kernelcore/configuration.nix` (ou equivalente no desktop)

```nix
{
  # ... existing config ...
  
  services.offload-server = {
    enable = true;              # ← ATIVAR ISTO
    cachePort = 5000;           # Porta do nix-serve
    builderUser = "nix-builder"; # Usuário para SSH
    cacheKeyPath = "/var/cache-priv-key.pem";
    enableNFS = true;           # ← ATIVAR NFS se quiser compartilhar /nix/store
  };
}
```

### Passo 2: Configurar sudo passwordless (opcional mas recomendado)

```nix
{
  # Permitir sudo sem senha para cypher (usuário do desktop)
  security.sudo.extraRules = [{
    users = [ "cypher" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
```

### Passo 3: Rebuild do Desktop

```bash
# No desktop (via SSH ou localmente)
sudo nixos-rebuild switch --flake /etc/nixos#<hostname-desktop>
```

### Passo 4: Gerar Chaves de Cache

```bash
# No desktop, após rebuild
offload-generate-cache-keys
```

**Output esperado:**
```
🔑 Generating cache signing keys...
✅ Keys generated successfully!

📋 Public key (add to laptop's trusted-public-keys):
   cache.local:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=

🔒 Private key location: /var/cache-priv-key.pem
   Keep this secure! Do not share!
```

**⚠️ IMPORTANTE:** Copie a chave pública (`cache.local:xxx...`) - você vai precisar no laptop!

### Passo 5: Verificar Status do Servidor

```bash
offload-server-status
```

**Output esperado:**
```
🖥️  NixOS Offload Server Status
================================

📊 Services:
✅ nix-serve: Running (port 5000)
✅ sshd: Running
✅ NFS: Running

🔑 Cache Configuration:
✅ Cache signing key: Present
   Public key: /var/cache-pub-key.pem
   Key content: cache.local:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=

🌐 Network:
Server IP: 192.168.15.7
Cache URL: http://192.168.15.7:5000

🧪 Cache Test:
✅ Cache accessible
StoreDir: /nix/store
WantMassQuery: 1
Priority: 40

👤 Builder User (nix-builder):
✅ User exists
   Home: /var/lib/nix-builder
   Authorized keys: 0

💾 Storage:
Nix store: 850G
Available: 150G
```

### Passo 6: Configurar Chave SSH do Laptop

**Você vai precisar da chave pública do laptop.** O laptop vai gerar isso no próximo passo, mas por enquanto vamos preparar:

```bash
# No desktop, como root ou cypher
sudo mkdir -p /var/lib/nix-builder/.ssh
sudo chmod 700 /var/lib/nix-builder/.ssh
sudo touch /var/lib/nix-builder/.ssh/authorized_keys
sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /var/lib/nix-builder/.ssh
```

**Aguarde o laptop gerar a chave pública antes de adicioná-la aqui.**

---

## 💻 Configuração do Laptop (Cliente)

### Passo 1: Atualizar IP do Desktop

**Arquivo:** `/etc/nixos/modules/services/laptop-offload-client.nix`

```nix
let
  # CONFIGURE THESE VALUES FOR YOUR SETUP
  desktopIP = "192.168.15.7"; # ← CONFIRMAR/ATUALIZAR
  laptopIP = "192.168.15.9";  # ← CONFIRMAR IP ATUAL DO LAPTOP

  # SSH key path for builder authentication
  builderKeyPath = "/etc/nix/builder_key";
in
{
  # ... resto da configuração ...
}
```

### Passo 2: Gerar Chave SSH para Builds

```bash
# No laptop
sudo mkdir -p /etc/nix
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N "" -C "nix-builder@laptop-to-desktop"
```

**Output:**
```
Generating public/private ed25519 key pair.
Your identification has been saved in /etc/nix/builder_key
Your public key has been saved in /etc/nix/builder_key.pub
The key fingerprint is:
SHA256:xxx... nix-builder@laptop-to-desktop
```

### Passo 3: Copiar Chave Pública para o Desktop

```bash
# No laptop, mostrar a chave pública
cat /etc/nix/builder_key.pub
```

**Copie o output (começa com `ssh-ed25519 AAAA...`)**

**No desktop, adicionar ao authorized_keys:**

```bash
# No desktop
echo "ssh-ed25519 AAAA... nix-builder@laptop-to-desktop" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys
```

### Passo 4: Adicionar Chave Pública do Cache do Desktop

**Arquivo:** `/etc/nixos/modules/services/laptop-offload-client.nix`

Localize a seção `trusted-public-keys` e adicione a chave do desktop:

```nix
trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "cache.local:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE="  # ← ADICIONAR CHAVE DO DESKTOP
];
```

### Passo 5: Verificar que laptop-offload-client está HABILITADO

**Arquivo:** `/etc/nixos/flake.nix` (linha 87)

```nix
./modules/services/laptop-offload-client.nix # ENABLED: NFS + Binary Cache + Remote Builds
```

**✅ Já está habilitado!** Apenas confirme que a linha NÃO está comentada.

### Passo 6: Rebuild do Laptop

```bash
# No laptop
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Passo 7: Testar Conectividade

```bash
# No laptop, após rebuild
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
   Priority: http://192.168.15.7:5000 https://cache.nixos.org

🔨 Build Statistics:
Local builds: 1234
Remote store items: 5678

💾 Storage Usage:
Local /nix/store: 45G
Remote store: 850G
Available: 100G
```

---

## 🧪 Testes e Validação

### Teste 1: Conectividade Básica

```bash
# No laptop
ping -c 3 192.168.15.7
```

**Esperado:** 3 pacotes enviados e recebidos com sucesso.

### Teste 2: SSH Builder

```bash
# No laptop
ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 'echo "SSH OK"'
```

**Esperado:** `SSH OK`

### Teste 3: Cache HTTP

```bash
# No laptop
curl -sf http://192.168.15.7:5000/nix-cache-info
```

**Esperado:**
```
StoreDir: /nix/store
WantMassQuery: 1
Priority: 40
```

### Teste 4: NFS Mounts

```bash
# No laptop
mountpoint -q /nix/store-remote && echo "✅ NFS OK" || echo "❌ NFS FAIL"
```

**Esperado:** `✅ NFS OK`

### Teste 5: Build Remoto Simples

```bash
# No laptop
offload-test-build
```

**Ou manualmente:**

```bash
# Força build remoto (sem cache)
nix-build --builders "ssh://nix-builder@192.168.15.7 x86_64-linux /etc/nix/builder_key 2 1" \
          --option substitute false \
          '<nixpkgs>' -A hello --no-out-link
```

**Esperado:**
```
building '/nix/store/xxx-hello.drv' on 'ssh://nix-builder@192.168.15.7'...
copying path '/nix/store/yyy-hello' from 'ssh://nix-builder@192.168.15.7'...
/nix/store/yyy-hello
```

### Teste 6: Build com Cache

```bash
# No laptop - deve pegar do cache do desktop
nix-build '<nixpkgs>' -A hello --no-out-link
```

**Esperado:**
```
copying path '/nix/store/xxx-hello' from 'http://192.168.15.7:5000'...
/nix/store/xxx-hello
```

---

## 🔧 Troubleshooting

### Problema: Desktop Inacessível

**Sintoma:**
```
❌ Desktop unreachable at 192.168.15.7
```

**Diagnóstico:**
```bash
# No laptop
ping 192.168.15.7
```

**Soluções:**
1. Verificar se desktop está ligado
2. Verificar IP correto: `ip addr show` no desktop
3. Verificar firewall do roteador
4. Verificar cabos de rede

### Problema: SSH Refused

**Sintoma:**
```
❌ SSH builder access failed
ssh: connect to host 192.168.15.7 port 22: Connection refused
```

**Diagnóstico:**
```bash
# No desktop
systemctl status sshd
```

**Soluções:**
```bash
# No desktop
sudo systemctl start sshd
sudo systemctl enable sshd

# Verificar firewall
sudo iptables -L -n | grep 22
```

### Problema: Permission Denied (SSH)

**Sintoma:**
```
Permission denied (publickey)
```

**Diagnóstico:**
```bash
# No laptop - testar com verbose
ssh -vvv -i /etc/nix/builder_key nix-builder@192.168.15.7
```

**Soluções:**
1. Verificar chave pública no desktop:
   ```bash
   # No desktop
   sudo cat /var/lib/nix-builder/.ssh/authorized_keys
   ```

2. Verificar permissões:
   ```bash
   # No desktop
   sudo chmod 700 /var/lib/nix-builder/.ssh
   sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
   sudo chown -R nix-builder:nix-builder /var/lib/nix-builder/.ssh
   ```

3. Regerar chaves se necessário:
   ```bash
   # No laptop
   sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N ""
   cat /etc/nix/builder_key.pub
   # Copiar novamente para o desktop
   ```

### Problema: Cache HTTP 500

**Sintoma:**
```
warning: error: unable to download 'http://192.168.15.7:5000/xxx.narinfo': HTTP error 500
```

**Diagnóstico:**
```bash
# No desktop
systemctl status nix-serve
journalctl -u nix-serve -n 50
```

**Soluções:**
```bash
# No desktop - reiniciar nix-serve
sudo systemctl restart nix-serve

# Verificar chaves de cache
ls -la /var/cache-priv-key.pem /var/cache-pub-key.pem

# Regerar se necessário
offload-generate-cache-keys
sudo systemctl restart nix-serve
```

### Problema: NFS Mount Failed

**Sintoma:**
```
❌ /nix/store-remote not mounted
mount.nfs: Connection refused
```

**Diagnóstico:**
```bash
# No desktop
systemctl status nfs-server
showmount -e localhost
```

**Soluções:**
```bash
# No desktop - iniciar NFS
sudo systemctl start nfs-server
sudo systemctl enable nfs-server

# Verificar exports
sudo exportfs -v

# Verificar firewall
sudo iptables -L -n | grep -E '2049|111'

# No laptop - tentar montar manualmente
sudo mount -t nfs 192.168.15.7:/nix/store /nix/store-remote
```

### Problema: Build Falha com "Failed to find machine"

**Sintoma:**
```
Failed to find a machine for remote build!
derivation: xyz.drv
required (system, features): (x86_64-linux, [])
```

**Diagnóstico:**
```bash
# No laptop
nix show-config | grep -E "^max-jobs|^builders"
```

**Solução:**
```bash
# Emergency rebuild (força local)
sudo nixos-rebuild switch --option max-jobs auto --option builders ""

# Verificar conectividade do builder
ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 'nix-build --version'
```

---

## 🔄 Manutenção e Monitoramento

### Comandos Úteis - Desktop

```bash
# Status geral
offload-server-status

# Testar componentes
offload-server-test

# Regenerar chaves de cache
offload-generate-cache-keys

# Logs do nix-serve
journalctl -u nix-serve -f

# Logs do NFS
journalctl -u nfs-server -f

# Verificar conexões SSH
sudo tail -f /var/log/auth.log | grep nix-builder
```

### Comandos Úteis - Laptop

```bash
# Status do cliente
offload-status

# Testar build remoto
offload-test-build

# Montar NFS manualmente
offload-mount

# Desmontar NFS
offload-unmount

# Verificar cache
cache-status

# Ver configuração Nix
nix show-config | grep -E "^(max-jobs|builders|substituters)"
```

### Monitoramento Contínuo

```bash
# No laptop - watch status
watch -n 5 offload-status

# No desktop - watch services
watch -n 5 'systemctl is-active nix-serve sshd nfs-server'
```

### Limpeza Periódica

```bash
# No desktop - limpar builds antigos
sudo nix-collect-garbage -d
nix-store --optimise

# No laptop - limpar cache local
nix-collect-garbage -d
nix-store --optimise
```

---

## 📊 Checklist de Setup

### Desktop (Servidor)

- [ ] `offload-server.enable = true` em configuration.nix
- [ ] `enableNFS = true` se quiser NFS
- [ ] Sudo passwordless configurado (opcional)
- [ ] Rebuild executado com sucesso
- [ ] Chaves de cache geradas (`offload-generate-cache-keys`)
- [ ] Chave pública do cache copiada
- [ ] Chave pública do laptop adicionada ao `authorized_keys`
- [ ] Firewall configurado (portas 22, 5000, 2049, 111)
- [ ] `offload-server-status` mostra tudo ✅
- [ ] Cache acessível: `curl http://localhost:5000/nix-cache-info`

### Laptop (Cliente)

- [ ] IP do desktop atualizado (192.168.15.7) em `laptop-offload-client.nix`
- [ ] Chave SSH gerada (`/etc/nix/builder_key`)
- [ ] Chave pública copiada para o desktop
- [ ] Chave pública do cache do desktop adicionada em `trusted-public-keys`
- [ ] `laptop-offload-client.nix` habilitado no flake.nix
- [ ] Rebuild executado com sucesso
- [ ] `offload-status` mostra conectividade ✅
- [ ] SSH funciona: `ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 echo OK`
- [ ] Cache funciona: `curl http://192.168.15.7:5000/nix-cache-info`
- [ ] NFS montado (se habilitado)

### Testes Finais

- [ ] Build remoto simples: `offload-test-build`
- [ ] Build com cache: `nix-build '<nixpkgs>' -A hello`
- [ ] NFS read: `ls /nix/store-remote`
- [ ] Performance: Build remoto mais rápido que local

---

## 🎯 Próximos Passos

1. **Otimizar Performance:**
   - Aumentar `n_parallel` no desktop se tiver CPU/RAM sobrando
   - Ajustar `http-connections` para sua rede
   - Configurar cache de segundo nível (Cachix)

2. **Adicionar Mais Clientes:**
   - Replicar configuração do laptop em outras máquinas
   - Usar NFS para compartilhar /nix/store entre todos

3. **Monitoramento Avançado:**
   - Configurar Prometheus + Grafana
   - Alertas para desktop offline
   - Métricas de cache hit rate

4. **Backup e Recuperação:**
   - Backup das chaves de cache
   - Backup da configuração
   - Plano de recuperação de desastres

---

## 📚 Referências

- [REMOTE-BUILDER-CACHE-GUIDE.md](docs/REMOTE-BUILDER-CACHE-GUIDE.md)
- [BINARY-CACHE-SETUP.md](docs/BINARY-CACHE-SETUP.md)
- [DESKTOP-BUILDER-SETUP.md](archive/merged-repos/nixtrap/DebugLand/DESKTOP-BUILDER-SETUP.md)
- [MULTI-HOST-SETUP.md](docs/guides/MULTI-HOST-SETUP.md)

---

**Versão:** 1.0  
**Última Atualização:** 2025-11-26  
**Mantido por:** kernelcore  
**Status:** 🚧 Em Progresso - Aguardando execução no desktop