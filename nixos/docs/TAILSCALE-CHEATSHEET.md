# 🚀 Tailscale Cheatsheet Completo - Tudo que Você Precisa

## 📋 Status Rápido

```bash
# Ver tudo de uma vez
my-ips

# Status Tailscale
ts-status

# IP Tailscale
ts-ip

# Hostname
ts-hostname

# Check completo
ts-check
```

---

## 🔐 Autenticação

```bash
# Primeira vez (abre navegador)
sudo tailscale up

# Com todas as opções
sudo tailscale up --ssh --accept-dns --accept-routes

# Re-autenticar
sudo tailscale up --reset

# Logout
sudo tailscale logout

# Ver status de auth
tailscale status
```

---

## 🌐 Rede & Conectividade

### Ver IPs
```bash
ts-ip              # IPv4 Tailscale
ts-ip6             # IPv6 Tailscale
ts-hostname        # Hostname completo
ts-url             # URL HTTP base
```

### Testar Conectividade
```bash
# Ping outro device
ts-ping laptop-nome
ts-ping desktop-nome

# Check qualidade da rede
ts-netcheck

# Ver todos os peers
ts-peers
ts-status --peers
```

### SSH via Tailscale
```bash
# SSH direto (se Tailscale SSH ativo)
ssh desktop-nome
ssh laptop-kernelcore

# SSH tradicional via Tailscale IP
ssh user@100.64.1.10
```

---

## 🐳 Docker + Tailscale

### Ver URLs de Containers
```bash
# Listar todos os containers com URLs Tailscale
docker-ts-urls

# Output exemplo:
# === Docker Containers via Tailscale ===
#   vscode-server: http://100.64.1.10:8080
#   postgres: http://100.64.1.10:5432
```

### Rodar Container e Acessar
```bash
# 1. Rodar container
docker run -d -p 8080:8080 codercom/code-server

# 2. Ver URL
ts-url
# Output: http://100.64.1.10
# Acesso: http://100.64.1.10:8080

# 3. Ou usar hostname
# http://laptop-kernelcore:8080
```

### Docker Compose
```bash
# Ver IP antes
TSIP=$(ts-ip)

# Usar na config
docker-compose up -d

# Acessar
echo "Acesse em: http://$TSIP:8080"
```

---

## 🏠 Subnet Router (Desktop)

### Ver Status do Router
```bash
# No desktop
ts-router-status

# Mostra:
# - IP Tailscale
# - Rotas anunciadas
# - Peers conectados
# - Status IP forwarding
```

### Ver Devices Locais
```bash
# Scan rede local
local-devices

# Ping device na rede local (do laptop remoto)
ping 192.168.1.100
ssh user@192.168.1.50
```

### Testar Subnet
```bash
# Do laptop, testar acesso à rede do desktop
ping 192.168.1.1          # Gateway
ping 192.168.1.100        # NAS
curl http://192.168.1.50  # Dispositivo local
```

---

## 📱 Celular (App Tailscale)

### Setup Inicial
1. Instalar app Tailscale
2. Login (mesma conta)
3. Settings → **Accept routes** ✅ (IMPORTANTE!)
4. Conectar

### Acessar do Celular
```
# Container no laptop
http://laptop-kernelcore:8080

# Device na rede do desktop
http://192.168.1.100

# Ollama no desktop (se tiver nginx proxy)
http://ollama.tailb3b82e.ts.net
```

---

## 🔧 Troubleshooting

### Service Não Inicia
```bash
# Ver logs
ts-logs
journalctl -u tailscaled -n 50

# Restart
sudo systemctl restart tailscaled
sudo tailscale up

# Check status
systemctl status tailscaled
```

### Não Conecta
```bash
# Re-autenticar
sudo tailscale down
sudo tailscale up --reset

# Ver erro específico
tailscale status --json | jq
```

### Subnet Não Funciona
```bash
# No desktop, verificar IP forwarding
sysctl net.ipv4.ip_forward
# Deve ser: net.ipv4.ip_forward = 1

# Verificar rotas anunciadas
ts-router-status

# CRÍTICO: Aprovar no dashboard!
# https://login.tailscale.com/admin/machines
# → Desktop → Edit route settings → Enable subnet
```

### Hostname Não Resolve (MagicDNS)
```bash
# Forçar DNS
sudo tailscale up --accept-dns --reset

# Verificar DNS
tailscale status --json | jq '.MagicDNSSuffix'

# Ativar no dashboard
# https://login.tailscale.com/admin/dns
```

### Container Não Acessível
```bash
# 1. Testar local
curl http://localhost:8080

# 2. Ver porta mapeada
docker port nome-container

# 3. Ver IP correto
ts-ip

# 4. Testar via Tailscale
curl http://$(ts-ip):8080
```

---

## 🎯 Casos de Uso Comuns

### 1. Desenvolvimento Remoto
```bash
# Laptop rodando VSCode Server
docker run -d -p 8080:8080 coderium/code-server

# Acesso de qualquer lugar
# http://laptop-kernelcore:8080
```

### 2. Acessar NAS de Casa
```bash
# Do laptop remoto
ssh nas@192.168.1.100
scp file.txt nas@192.168.1.100:/backup/
```

### 3. Banco de Dados Remoto
```bash
# PostgreSQL no desktop (via subnet)
psql -h 192.168.1.100 -U user -d database

# Ou via proxy Tailscale (se configurado)
psql -h db.tailb3b82e.ts.net -U user -d database
```

### 4. Transfer Files
```bash
# SCP via Tailscale
scp file.txt desktop-nome:/path/

# Rsync
rsync -avz /local/dir/ desktop-nome:/remote/dir/

# Tailscale file sharing (built-in)
tailscale file cp file.txt desktop-nome:
tailscale file get
```

### 5. Offload de Builds
```bash
# Já configurado! Nix usa desktop automaticamente
nix build .#hello

# Ver onde buildou
nix-store -q --tree result
```

---

## 📊 Monitoramento

### Monitor Service
```bash
# Status do monitor
ts-monitor-status
systemctl status tailscale-monitor

# Logs do monitor
ts-monitor-logs
ts-monitor-logs-file

# Restart monitor
ts-monitor-restart
```

### Performance
```bash
# Quality check
ts-netcheck

# Ping test
ts-ping desktop-nome

# Benchmark completo (se instalado)
ts-benchmark
```

---

## 🔑 Comandos Úteis Avançados

### Rotas
```bash
# Ver rotas
tailscale status --json | jq '.Peer[].PrimaryRoutes'

# Forçar rota específica
tailscale up --advertise-routes=192.168.1.0/24

# Ver rotas aceitas
ip route | grep 100.
```

### Exit Node
```bash
# Usar desktop como gateway de internet
tailscale up --exit-node=desktop-nome

# Desativar exit node
tailscale up --exit-node=

# Manter acesso LAN local
tailscale up --exit-node=desktop-nome --exit-node-allow-lan-access
```

### ACLs & Security
```bash
# Ver configuração
tailscale status --json | jq '.Self'

# Shields up (bloquear tudo)
tailscale up --shields-up

# Shields down (permitir)
tailscale up
```

### Debugging
```bash
# Ver todas as conexões
tailscale status --json | jq

# Netcheck verbose
tailscale netcheck --verbose

# Ver daemon status
tailscale debug daemon
```

---

## 🌐 Dashboard Web

### Links Importantes
```bash
# Machines
https://login.tailscale.com/admin/machines

# DNS Settings
https://login.tailscale.com/admin/dns

# ACLs
https://login.tailscale.com/admin/acls

# Settings
https://login.tailscale.com/admin/settings
```

### O Que Fazer no Dashboard

1. **Aprovar Subnet Routes** (CRÍTICO!)
   - Machines → Desktop → ⋮ → Edit route settings
   - Enable: ✅ 192.168.1.0/24

2. **Habilitar MagicDNS**
   - DNS → Enable MagicDNS

3. **Configurar ACLs** (opcional)
   - ACLs → Edit
   - Controlar quem acessa o quê

4. **Rename Machines**
   - Machines → Device → ⋮ → Rename

---

## 📱 Quick Reference Cards

### Laptop Commands
```bash
my-ips              # Info completa
ts-status           # Status
docker-ts-urls      # URLs containers
ssh-desktop         # SSH pro desktop
ping-desktop        # Ping desktop
ts-check            # Connectivity check
```

### Desktop Commands
```bash
ts-router-status    # Status subnet router
local-devices       # Devices na rede local
ping-laptop         # Ping laptop
test-offload        # Test build remoto
```

### Universal Commands
```bash
ts-ip               # Tailscale IP
ts-hostname         # Hostname
ts-logs             # Logs
ts-netcheck         # Network quality
ts-peers            # Ver peers
```

---

## 🎓 One-Liners Úteis

```bash
# Ver latência pra todos os peers
tailscale status | grep -v "^$" | while read line; do echo "$line"; done

# Descobrir quem está usando mais banda
nethogs tailscale0

# Monitor conexões Tailscale
watch -n 1 'tailscale status | head -20'

# Quick health check
tailscale netcheck && echo "✅ Tudo OK" || echo "❌ Problemas"

# Ver todos os IPs da rede
tailscale status --peers | awk '{print $2,$4}'

# Backup de peers
tailscale status --json > ~/tailscale-peers-backup.json

# Test all peers
tailscale status --peers | awk '{print $1}' | xargs -I {} tailscale ping {}
```

---

## 🚨 Emergency Commands

```bash
# Service crashando? Restart forçado
sudo systemctl stop tailscaled
sudo killall tailscaled
sudo systemctl start tailscaled
sudo tailscale up

# DNS quebrou? Reset total
sudo tailscale down
sudo systemctl restart tailscaled
sudo tailscale up --accept-dns --reset

# Subnet router parou? Forçar
sudo sysctl -w net.ipv4.ip_forward=1
sudo tailscale up --advertise-routes=192.168.1.0/24 --reset

# Monitor crashando? Rebuild
sudo systemctl stop tailscale-monitor
sudo nixos-rebuild switch
sudo systemctl start tailscale-monitor
```

---

## 📚 Documentação Completa

- **Setup Guide**: [`docs/TAILSCALE-COMPLETE-SETUP.md`](TAILSCALE-COMPLETE-SETUP.md)
- **Quick Start**: [`docs/TAILSCALE-QUICKSTART-GUIDE.md`](TAILSCALE-QUICKSTART-GUIDE.md)
- **Subnet Routing**: [`docs/TAILSCALE-SUBNET-ROUTING-GUIDE.md`](TAILSCALE-SUBNET-ROUTING-GUIDE.md)
- **Official Docs**: https://tailscale.com/kb/

---

## 🎯 Workflow Diário

### Manhã (Começar o Dia)
```bash
# Quick check
my-ips
ts-check

# Ver o que tá rodando
docker-ts-urls
```

### Durante Desenvolvimento
```bash
# Rodar container
docker run -d -p 8080:8080 sua-imagem

# Acessar de qualquer device
# http://laptop-kernelcore:8080
```

### Precisar de Arquivos do NAS
```bash
# Via subnet router
scp nas@192.168.1.100:/files/doc.pdf ~/
```

### Build Pesado
```bash
# Automático! Desktop assume build
nix build .#pacote-pesado
```

### Fim do Dia
```bash
# Tudo continua rodando!
# Tailscale mantém conectado 24/7
```

---

**Salva esse cheatsheet! É tudo que você precisa! 🎉**