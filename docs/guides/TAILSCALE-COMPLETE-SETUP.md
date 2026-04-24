# 🚀 Tailscale Setup Completo - Laptop + Desktop Sincronizado

## 📦 O Que Foi Configurado

Criei 3 módulos Tailscale prontos para usar:

1. **[`modules/network/vpn/tailscale.nix`](../modules/network/vpn/tailscale.nix)** - Módulo base (já existia, melhorei)
2. **[`modules/network/vpn/tailscale-laptop.nix`](../modules/network/vpn/tailscale-laptop.nix)** - Config do Laptop (NOVO)
3. **[`modules/network/vpn/tailscale-desktop.nix`](../modules/network/vpn/tailscale-desktop.nix)** - Config do Desktop (NOVO)

## 🎯 Arquitetura

```
┌─────────────────────────────────────────────────────┐
│              TAILSCALE VPN MESH                      │
│                                                      │
│  ┌──────────────┐         ┌──────────────┐         │
│  │   LAPTOP     │◄───────►│   DESKTOP    │         │
│  │ kernelcore   │   VPN   │  home        │         │
│  │              │         │              │         │
│  │ Mode: CLIENT │         │ Mode: SUBNET │         │
│  │              │         │    ROUTER    │         │
│  │ - Accept     │         │              │         │
│  │   Routes     │         │ - Share      │         │
│  │ - SSH        │         │   192.168.x  │         │
│  │ - MagicDNS   │         │ - SSH        │         │
│  └──────────────┘         │ - MagicDNS   │         │
│                            └──────┬───────┘         │
│                                   │                 │
│                            ┌──────┴───────┐        │
│                            │ Home Network │        │
│                            │ 192.168.1.0  │        │
│                            ├──────────────┤        │
│                            │ NAS          │        │
│                            │ Printer      │        │
│                            │ IoT Devices  │        │
│                            │ Containers   │        │
│                            └──────────────┘        │
└─────────────────────────────────────────────────────┘
```

## 🔧 Setup Rápido

### 1️⃣ Laptop (Você está aqui)

Já está pronto! O arquivo foi configurado. Só precisa:

```bash
# Rebuild para ativar
sudo nixos-rebuild switch --flake .#nx

# Autenticar Tailscale (abre navegador)
sudo tailscale up

# Verificar status
ts-status
my-ips
```

### 2️⃣ Desktop (Quando tiver acesso)

No desktop, adicione ao `configuration.nix`:

```nix
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/network/vpn/tailscale-desktop.nix  # Adicionar esta linha
    # ... outros imports
  ];
}
```

Depois:

```bash
# Rebuild
sudo nixos-rebuild switch

# Autenticar
sudo tailscale up

# IMPORTANTE: Aprovar subnet routes no dashboard
# https://login.tailscale.com/admin/machines
# → Encontre o desktop → Edit route settings → Enable routes

# Verificar se virou subnet router
ts-router-status
```

## ✨ Funcionalidades Automáticas

### No Laptop (kernelcore)

**Aliases criados:**
```bash
ts-status          # Status do Tailscale
ts-ip              # Seu IP Tailscale
ts-hostname        # Seu hostname bonito
ts-url             # URL base HTTP
my-ips             # Ver todos os IPs (bonito)
docker-ts-urls     # URLs de containers Docker
ssh-desktop        # SSH pro desktop via Tailscale
ping-desktop       # Ping no desktop
ts-check           # Check rápido de conectividade
```

**Auto-configurado:**
- ✅ SSH sobre Tailscale
- ✅ MagicDNS (usar hostnames)
- ✅ Aceita rotas do desktop
- ✅ Conecta automaticamente no boot
- ✅ Mostra IP Tailscale ao abrir terminal

### No Desktop (home)

**Aliases criados:**
```bash
ts-router-status   # Status completo do subnet router
local-devices      # Ver devices na rede local
ping-laptop        # Ping no laptop
test-offload       # Testar build remoto
```

**Auto-configurado:**
- ✅ Subnet Router (compartilha rede 192.168.1.0/24)
- ✅ SSH sobre Tailscale
- ✅ MagicDNS
- ✅ IP Forwarding automático
- ✅ Firewall configurado
- ✅ Health check no boot

## 🐳 Docker + Tailscale

### Rodar Container e Acessar Remotamente

**No Laptop:**
```bash
# 1. Rodar container qualquer
docker run -d -p 8080:8080 codercom/code-server

# 2. Ver URL para acessar
docker-ts-urls
# Output: code-server: http://100.64.1.10:8080

# 3. No celular (com Tailscale app):
# Abrir: http://100.64.1.10:8080
```

**Ainda mais fácil com alias:**
```bash
# Ver seu IP Tailscale
ts-url
# Output: http://100.64.1.10

# Adicionar porta manualmente: http://100.64.1.10:8080
```

## 🌐 Acessar Rede Local do Desktop Remotamente

Depois que o desktop virar subnet router:

**Do laptop em qualquer lugar do mundo:**
```bash
# Acessar NAS na rede do desktop
ssh user@192.168.1.100

# Acessar impressora
ping 192.168.1.50

# Acessar web interface de device
curl http://192.168.1.150

# Usar Docker container no desktop
ssh desktop-home "docker ps"
```

## 📱 Setup no Celular

1. Instalar app Tailscale (Play Store/App Store)
2. Login com mesma conta
3. Ativar VPN
4. **Importante:** Settings → Accept routes (para ver rede do desktop)
5. Pronto! Acessa tudo via IP Tailscale ou hostname

**Acessar container do laptop no celular:**
```
http://laptop-kernelcore:8080
```

**Acessar rede local do desktop:**
```
http://192.168.1.100
```

## 🔍 Troubleshooting

### Laptop não conecta

```bash
# Ver logs
ts-logs

# Restart
sudo systemctl restart tailscaled
sudo tailscale up

# Re-autenticar
sudo tailscale up --reset
```

### Desktop não compartilha subnet

```bash
# 1. Verificar IP forwarding
sysctl net.ipv4.ip_forward
# Deve ser: net.ipv4.ip_forward = 1

# 2. Verificar rotas anunciadas
ts-router-status

# 3. APROVAR no dashboard (mais comum!)
# https://login.tailscale.com/admin/machines
# → Desktop → Edit route settings → Enable subnet
```

### Não resolve hostname (MagicDNS)

```bash
# Forçar DNS
sudo tailscale up --accept-dns --reset

# Verificar no dashboard se MagicDNS está ativo
# https://login.tailscale.com/admin/dns
```

### Container não acessível

```bash
# 1. Verificar porta está mapeada
docker port nome-container

# 2. Testar localmente
curl http://localhost:8080

# 3. Ver IP Tailscale correto
ts-ip

# 4. Acessar via: http://<ts-ip>:8080
```

## 🎓 Comandos Úteis

### Informações
```bash
my-ips              # Ver todos os IPs e info
ts-status           # Status Tailscale
ts-ip               # IP Tailscale
ts-hostname         # Hostname
ts-peers            # Ver outros devices
ts-check            # Check conectividade
```

### Docker
```bash
docker-ts-urls      # URLs de containers
ts-url              # URL base (adicionar :porta)
```

### Desktop (subnet router)
```bash
ts-router-status    # Status completo
local-devices       # Scan rede local
```

### Debugging
```bash
ts-logs             # Logs em tempo real
ts-netcheck         # Check qualidade rede
ts-ping hostname    # Ping outro device
```

## 📊 Checklist de Setup

### Laptop ✅
- [x] Módulo importado no configuration.nix
- [ ] Rebuild executado
- [ ] Tailscale autenticado (`sudo tailscale up`)
- [ ] Testado `ts-status` e `my-ips`

### Desktop (quando tiver acesso)
- [ ] Módulo importado no configuration.nix
- [ ] Ajustada subnet em `advertiseRoutes` (se diferente de 192.168.1.0/24)
- [ ] Rebuild executado
- [ ] Tailscale autenticado
- [ ] **APROVADO subnet no dashboard** (CRÍTICO!)
- [ ] Testado `ts-router-status`
- [ ] Laptop consegue pingar: `ping 192.168.1.1`

### Celular
- [ ] App Tailscale instalado
- [ ] Conectado
- [ ] Accept routes habilitado
- [ ] Testa acessar laptop: `http://laptop-kernelcore:8080`
- [ ] Testa acessar rede desktop: `http://192.168.1.100`

## 🎯 Próximos Passos

1. **Agora (Laptop):**
   ```bash
   sudo nixos-rebuild switch --flake .#nx
   sudo tailscale up
   my-ips
   ```

2. **Desktop (depois):**
   - Adicionar import do módulo
   - Ajustar subnet se necessário
   - Rebuild
   - Autenticar
   - **APROVAR ROUTES NO DASHBOARD**

3. **Testar:**
   ```bash
   # Do laptop
   ping-desktop
   ssh desktop-home
   
   # Depois que desktop virar subnet router
   ping 192.168.1.1  # Gateway da rede do desktop
   ```

4. **Profit! 🎉**
   - Acesse tudo de qualquer lugar
   - Docker containers acessíveis
   - Rede local do desktop disponível
   - SSH seguro entre devices
   - MagicDNS para não decorar IPs

## 📚 Documentação Adicional

- [Guia Básico Tailscale](TAILSCALE-QUICKSTART-GUIDE.md)
- [Subnet Routing Detalhado](TAILSCALE-SUBNET-ROUTING-GUIDE.md)
- Módulo base: [`modules/network/vpn/tailscale.nix`](../modules/network/vpn/tailscale.nix)

---

**Tudo configurado no Yolo mode! 🚀 Agora é só rebuildar e conectar!**