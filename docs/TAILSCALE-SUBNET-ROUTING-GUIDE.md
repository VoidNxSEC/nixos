# 🌐 Guia: Compartilhar Rede Local via Tailscale (Subnet Routing)

## 🎯 O Problema

Você tem dispositivos na mesma rede local (ex: 192.168.1.0/24):
- 🖥️ Desktop: 192.168.1.10
- 💻 Laptop: 192.168.1.20
- 🖨️ Impressora: 192.168.1.50
- 📦 NAS: 192.168.1.100

**Quando está em casa:** Tudo funciona ✅  
**Quando está fora:** Só acessa via Tailscale, não alcança outros dispositivos locais ❌

## ✨ A Solução: Subnet Router

**Subnet Router** = Um dispositivo Tailscale que compartilha sua rede local com outros dispositivos Tailscale.

```
Internet
   │
   ├── Laptop (remoto) ──────> Tailscale VPN
   │                               │
   └─────────────────────> Desktop (subnet router)
                                   │
                          ┌────────┴────────┐
                          │  Rede Local     │
                          │  192.168.1.0/24 │
                          ├─────────────────┤
                          │ Impressora      │
                          │ NAS             │
                          │ Smart TV        │
                          │ IoT devices     │
                          └─────────────────┘
```

## 🚀 Setup Rápido

### Passo 1: Descobrir sua Subnet Local

```bash
# Ver suas redes locais
ip route | grep "scope link"

# Exemplo de output:
# 192.168.1.0/24 dev wlan0 proto kernel scope link src 192.168.1.10
```

Anote a subnet: `192.168.1.0/24` (mude conforme seu caso)

### Passo 2: Configurar Desktop como Subnet Router

**No dispositivo que fica sempre em casa (Desktop):**

```bash
# Anunciar a subnet local via Tailscale
sudo tailscale up --advertise-routes=192.168.1.0/24 --ssh --accept-dns

# Se tiver múltiplas subnets
sudo tailscale up --advertise-routes=192.168.1.0/24,192.168.2.0/24
```

### Passo 3: Aprovar no Dashboard

1. Acesse: https://login.tailscale.com/admin/machines
2. Encontre o Desktop
3. Clique nos "..." → **Edit route settings**
4. Marque a checkbox da subnet `192.168.1.0/24`
5. Clique em **Save**

### Passo 4: Conectar Laptop

**No laptop (ou qualquer outro dispositivo):**

```bash
# Conectar aceitando rotas do subnet router
sudo tailscale up --accept-routes --ssh --accept-dns

# Verificar rotas instaladas
tailscale status
ip route | grep 100.64
```

## ✅ Testar

```bash
# Do laptop (mesmo remoto), acessar dispositivos locais:

# Pingar impressora na rede local do desktop
ping 192.168.1.50

# SSH para outro device na rede local
ssh usuario@192.168.1.100

# Acessar NAS web interface
curl http://192.168.1.100:8080

# Acessar impressora
lpstat -p -h 192.168.1.50
```

**Agora você acessa a rede local do desktop de qualquer lugar!** 🎉

## 📋 Configuração NixOS Automática

Para tornar isso permanente no seu NixOS, adicione ao [`modules/network/vpn/tailscale.nix`](../modules/network/vpn/tailscale.nix):

```nix
# Descobrir subnet automaticamente
services.tailscale = {
  enable = true;
  
  # Anunciar rotas automaticamente no boot
  extraUpFlags = [
    "--advertise-routes=192.168.1.0/24"  # Mude para sua subnet
    "--ssh"
    "--accept-dns"
    "--accept-routes"  # Se este também vai usar rotas de outros
  ];
};

# Habilitar IP forwarding (necessário para subnet router)
boot.kernel.sysctl = {
  "net.ipv4.ip_forward" = 1;
  "net.ipv6.conf.all.forwarding" = 1;
};
```

Depois rebuildar:
```bash
sudo nixos-rebuild switch --flake .#nx
```

## 🔧 Casos de Uso Avançados

### 1. Múltiplas Redes

```bash
# Desktop com acesso a várias VLANs
sudo tailscale up --advertise-routes=192.168.1.0/24,10.0.0.0/24,172.16.0.0/16
```

### 2. Subnet Router + Exit Node

```bash
# Desktop serve como gateway completo
sudo tailscale up \
  --advertise-routes=192.168.1.0/24 \
  --advertise-exit-node \
  --ssh --accept-dns
```

Agora o laptop pode:
- Acessar rede local via subnet routing
- Usar desktop como gateway de internet (exit node)

### 3. Alta Disponibilidade

**Setup com 2 subnet routers (failover automático):**

```bash
# Desktop principal
sudo tailscale up --advertise-routes=192.168.1.0/24

# Raspberry Pi backup (mesma rede)
sudo tailscale up --advertise-routes=192.168.1.0/24
```

Tailscale usa o mais rápido automaticamente!

### 4. Subnet Router Específico

```bash
# Forçar uso de um subnet router específico
tailscale up --exit-node=desktop-nome
```

## 🛡️ Segurança

### ACLs (Access Control Lists)

Controle quem pode acessar quais subnets:

**No dashboard** (https://login.tailscale.com/admin/acls):

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["laptop", "tablet"],
      "dst": ["192.168.1.0/24:*"]
    },
    {
      "action": "accept",
      "src": ["workstation"],
      "dst": ["192.168.1.100:22", "192.168.1.100:80"]
    }
  ]
}
```

### Firewall Local

O subnet router precisa permitir forwarding:

```bash
# NixOS já configura automaticamente com:
# boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

# Mas se precisar manualmente:
networking.firewall = {
  enable = true;
  # Permitir forwarding entre Tailscale e rede local
  trustedInterfaces = [ "tailscale0" ];
  # Ou regras específicas:
  extraCommands = ''
    iptables -A FORWARD -i tailscale0 -o wlan0 -j ACCEPT
    iptables -A FORWARD -i wlan0 -o tailscale0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  '';
};
```

## 📊 Monitoramento

```bash
# Ver rotas anunciadas
tailscale status | grep relay

# Ver rotas aceitas
ip route show | grep 100

# Testar conectividade
tailscale ping desktop-nome

# Ver uso de bandwidth
iftop -i tailscale0

# Logs do subnet routing
journalctl -u tailscaled -f | grep subnet
```

## 🚨 Troubleshooting

### Subnet não aparece no dashboard

```bash
# Verificar anúncio
tailscale status --json | grep -i routes

# Re-anunciar
sudo tailscale down
sudo tailscale up --advertise-routes=192.168.1.0/24 --reset
```

### IP Forwarding não funciona

```bash
# Verificar se está habilitado
sysctl net.ipv4.ip_forward
# Deve retornar: net.ipv4.ip_forward = 1

# Se retornar 0, habilitar:
sudo sysctl -w net.ipv4.ip_forward=1

# No NixOS, adicionar ao configuration.nix:
boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
```

### Não alcança dispositivos locais

```bash
# 1. Verificar rota está instalada no cliente
ip route | grep 192.168.1

# 2. Verificar cliente aceitou rotas
tailscale status | grep routes

# 3. Testar do subnet router
ping 192.168.1.50  # Deve funcionar

# 4. Ver se firewall não está bloqueando
sudo iptables -L -n -v
```

### Latência alta

```bash
# Verificar se está usando conexão direta
tailscale status
# Procure por "relay" vs "direct"

# Forçar direct connection
tailscale up --advertise-routes=192.168.1.0/24 --force-reauth
```

## 💡 Dicas e Boas Práticas

1. **Use Desktop fixo como subnet router** - Dispositivo que fica sempre em casa
2. **Habilite MagicDNS** - `--accept-dns` para resolver nomes
3. **Configure ACLs** - Limite acesso por segurança
4. **Monitor performance** - Use `ts-monitor-logs` (já configurado)
5. **Backup subnet router** - Dois dispositivos anunciando mesma subnet = failover automático
6. **Documente IPs** - Mantenha lista de dispositivos importantes
7. **Use exit node ocasionalmente** - Para navegar "de casa" quando estiver fora

## 📚 Exemplos Práticos

### Home Lab completo acessível remotamente

```bash
# Desktop anuncia tudo
sudo tailscale up --advertise-routes=192.168.1.0/24 --ssh

# Agora de qualquer lugar:
ssh nas@192.168.1.100          # Acessar NAS
http://192.168.1.10:8080       # Jellyfin
http://192.168.1.20:9091       # Transmission
ssh pi@192.168.1.30            # Raspberry Pi
```

### Desenvolvimento remoto

```bash
# Desktop expõe serviços de desenvolvimento
sudo tailscale up --advertise-routes=192.168.1.0/24

# Do laptop remoto:
psql -h 192.168.1.100 -U dev    # PostgreSQL local
redis-cli -h 192.168.1.101      # Redis local
curl http://192.168.1.102:3000  # Backend dev server
```

### Smart Home remoto

```bash
# Controlar IoT de qualquer lugar
curl http://192.168.1.200/api   # Home Assistant
curl http://192.168.1.201       # Lights controller
ssh root@192.168.1.202          # OpenWRT router
```

## 🎓 Resumo

| Comando | Descrição |
|---------|-----------|
| `tailscale up --advertise-routes=X.X.X.X/X` | Anunciar subnet |
| `tailscale up --accept-routes` | Aceitar rotas de outros |
| `sysctl net.ipv4.ip_forward=1` | Habilitar forwarding |
| `tailscale status` | Ver rotas ativas |
| `ip route | grep 100` | Ver rotas Tailscale |

---

**Com isso configurado, todos os seus dispositivos Tailscale compartilham a mesma rede local, não importa onde você esteja!** 🌍✨