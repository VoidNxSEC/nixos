# 🚀 Guia Rápido: Tailscale VPN

## 📖 O que é Tailscale?

Tailscale é uma **VPN moderna** baseada no protocolo WireGuard que cria uma rede privada segura entre seus dispositivos. Diferente de VPNs tradicionais:

- ✅ **Zero-config**: Conecta dispositivos automaticamente sem configurar IPs, portas ou firewall
- ✅ **Peer-to-peer**: Conexões diretas entre dispositivos (mais rápido)
- ✅ **Cross-platform**: Linux, Windows, Mac, iOS, Android, etc.
- ✅ **Gratuito**: Para uso pessoal (até 100 dispositivos)

## 🔐 Como Usar Tailscale

### 1️⃣ Primeira Autenticação

```bash
# Autenticar com Tailscale (abre navegador para login)
sudo tailscale up

# Se quiser habilitar SSH sobre Tailscale
sudo tailscale up --ssh

# Verificar status
tailscale status
```

**O que acontece:**
1. Comando abre navegador automaticamente
2. Faz login com Google/GitHub/Microsoft
3. Aprova o dispositivo
4. Recebe um IP Tailscale (100.x.x.x)

### 2️⃣ Verificar Conexão

```bash
# Ver seu IP Tailscale
tailscale ip -4

# Ver todos dispositivos conectados
tailscale status

# Testar qualidade da conexão
tailscale netcheck

# Ping para outro dispositivo
tailscale ping <nome-do-dispositivo>
```

### 3️⃣ Conectar Outros Dispositivos

**No Desktop/Laptop:**
1. Instalar Tailscale: https://tailscale.com/download
2. Rodar `tailscale up`
3. Fazer login com mesma conta
4. Pronto! Todos os dispositivos se enxergam

**No Celular:**
1. Instalar app Tailscale (Play Store/App Store)
2. Fazer login
3. Ativar VPN

## 🎯 O que é MagicDNS (Smart DNS)?

**MagicDNS** é o "Smart DNS" do Tailscale. Funciona assim:

### Sem MagicDNS:
```bash
# Tem que usar IP
ssh 100.64.1.2
curl http://100.64.1.3:8080
```

### Com MagicDNS:
```bash
# Usa nome do dispositivo
ssh laptop-desktop
curl http://desktop-server:8080

# Também pode usar nome completo
ssh laptop-desktop.tail-abc123.ts.net
```

**Como ativar:**
```bash
# No dispositivo
sudo tailscale up --accept-dns

# Ou no painel web: https://login.tailscale.com/admin/dns
```

## 💡 Casos de Uso Práticos

### 1. Acessar Desktop de Casa Remotamente
```bash
# No laptop em qualquer lugar do mundo
ssh desktop-casa
```

### 2. Compartilhar Serviços Locais
```bash
# Desktop rodando Ollama na porta 11434
# No laptop, acessa via Tailscale:
curl http://desktop:11434/api/tags
```

### 3. Offload de Builds (seu caso!)
```bash
# Laptop configura desktop como builder via Tailscale
# NixOS usa Tailscale IPs para builds remotos
nix build --builders 'ssh://desktop-builder' .#hello
```

### 4. Transferir Arquivos
```bash
# Usando Tailscale file sharing
tailscale file cp arquivo.txt desktop:
tailscale file get
```

### 5. Compartilhar Serviço com Amigo
```bash
# Sharing nodes (compartilha acesso temporário)
tailscale share <email-do-amigo> <nome-do-dispositivo>
```

## 🛠️ Comandos Úteis

```bash
# Ver status completo
tailscale status

# Ver logs de conexão
journalctl -u tailscaled -f

# Desconectar temporariamente
sudo tailscale down

# Reconectar
sudo tailscale up

# Logout completo
sudo tailscale logout

# Ver configuração de rotas
tailscale routes

# Monitorar qualidade da conexão
ts-monitor-logs  # (alias que configuramos)
```

## 📊 Monitoramento (já configurado!)

O sistema já tem monitor automático rodando:

```bash
# Ver status do monitor
ts-monitor-status

# Ver logs em tempo real
ts-monitor-logs

# Ver arquivo de log
ts-monitor-logs-file

# Reiniciar monitor
ts-monitor-restart

# Testar qualidade
ts-quality
```

## 🔧 Configuração Avançada

### Exit Nodes (usar outro dispositivo como gateway)
```bash
# Dispositivo A vira gateway
sudo tailscale up --advertise-exit-node

# Dispositivo B usa A como gateway
sudo tailscale up --exit-node=dispositivo-a
```

### Subnet Routing (expor rede local)
```bash
# Desktop expõe rede 192.168.1.0/24
sudo tailscale up --advertise-routes=192.168.1.0/24
```

### SSH via Tailscale
```bash
# Habilitar SSH
sudo tailscale up --ssh

# Agora pode fazer SSH sem configurar nada
ssh usuario@desktop-nome
```

## 🚨 Troubleshooting

### Tailscale não conecta
```bash
# Verificar daemon
systemctl status tailscaled

# Verificar autenticação
tailscale status

# Re-autenticar
sudo tailscale up --reset
```

### Firewall bloqueando
```bash
# Tailscale já configura firewall automaticamente
# Mas se precisar, libera portas UDP 41641
```

### Latência alta
```bash
# Ver diagnóstico completo
tailscale netcheck

# Forçar DERP relay específico
tailscale netcheck --verbose
```

## 📚 Recursos

- **Dashboard**: https://login.tailscale.com/admin/machines
- **Documentação**: https://tailscale.com/kb/
- **Status da rede**: https://status.tailscale.com/
- **Configuração NixOS**: [`modules/network/vpn/tailscale.nix`](../modules/network/vpn/tailscale.nix)

## 🎓 Próximos Passos

1. **Autenticar**: `sudo tailscale up --ssh --accept-dns`
2. **Conectar Desktop**: Instalar Tailscale no desktop e autenticar
3. **Configurar Offload**: Usar IPs Tailscale para builds remotos
4. **Habilitar MagicDNS**: Usar nomes em vez de IPs
5. **Monitorar**: O monitor já está rodando automaticamente

---

**Dica**: Tailscale funciona **através de firewalls e NATs** automaticamente. Você pode estar em rede corporativa, hotel, café - sempre funciona! 🎉