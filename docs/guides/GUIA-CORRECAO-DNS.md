# 🚨 GUIA DE CORREÇÃO DNS - NIXOS

## PROBLEMA IDENTIFICADO

Seu sistema tem **3 conflitos principais**:

1. **systemd-resolved vs dnscrypt-proxy2**: Ambos tentando usar porta 53
2. **VPN sobrescrevendo DNS**: NordVPN mudando configurações de DNS
3. **Dependências incorretas**: `dns-health-monitor` sem `wants` no `network-online.target`

---

## ⚡ SOLUÇÃO RÁPIDA (SE INTERNET ESTÁ QUEBRADA)

```bash
# 1. Rodar script de emergência
sudo bash dns-emergency-fix.sh

# 2. Se não resolver, desabilitar tudo e usar DNS direto
sudo systemctl stop dnscrypt-proxy2 nordvpn-manager dns-health-monitor
sudo systemctl restart systemd-resolved

# 3. Testar
dig @1.1.1.1 google.com
```

---

## 🔧 CORREÇÃO PERMANENTE

### Passo 1: Backup dos arquivos originais

```bash
cd /etc/nixos
sudo cp modules/network/dns-resolver.nix modules/network/dns-resolver.nix.backup
sudo cp modules/network/vpn/nordvpn.nix modules/network/vpn/nordvpn.nix.backup
```

### Passo 2: Substituir pelos arquivos corrigidos

**Localização dos arquivos corrigidos**:
- DNS: `/etc/nixos/modules/network/dns-resolver-fixed.nix`
- VPN: `/etc/nixos/modules/network/vpn/vpn-fixed.nix`

```bash
# Copiar arquivos corrigidos (executar de /etc/nixos)
sudo cp modules/network/dns-resolver-fixed.nix modules/network/dns-resolver.nix
sudo cp modules/network/vpn/vpn-fixed.nix modules/network/vpn/nordvpn.nix
```

### Passo 3: Verificar imports no flake.nix

Os módulos DNS e VPN são importados no `/etc/nixos/flake.nix` nas linhas 108-109:

```nix
# Network
./modules/network/dns-resolver.nix
./modules/network/vpn/nordvpn.nix
```

**Nota**: Após copiar os arquivos corrigidos, esses imports no flake.nix continuam apontando para os mesmos caminhos. Os arquivos `-fixed.nix` substituirão os originais.

### Passo 4: Escolher configuração

Edite seu `hosts/kernelcore/configuration.nix` onde você habilita os módulos (linhas 42-56):

#### OPÇÃO A: Apenas systemd-resolved (RECOMENDADO - mais simples)

```nix
kernelcore.network = {
  dns-resolver = {
    enable = true;
    enableDNSCrypt = false;  # ← DESABILITAR
    enableDNSSEC = true;
    preferredServers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
  
  vpn.nordvpn = {
    enable = true;  # ou false se não usar
    autoConnect = false;
    overrideDNS = false;  # ← NOVO: não sobrescrever DNS
  };
};
```

#### OPÇÃO B: Com DNSCrypt (mais complexo, mas criptografado)

```nix
kernelcore.network = {
  dns-resolver = {
    enable = true;
    enableDNSCrypt = true;  # ← HABILITADO
    enableDNSSEC = true;
    preferredServers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
  
  vpn.nordvpn = {
    enable = false;  # ← DESABILITAR ou configurar overrideDNS=false
    # Se habilitar VPN com DNSCrypt, conflitos podem ocorrer
    overrideDNS = false;
  };
};
```

### Passo 5: Rebuild do sistema

```bash
# Verificar erros antes de aplicar
sudo nixos-rebuild dry-build --show-trace

# Se não tiver erros, aplicar
sudo nixos-rebuild switch
```

### Passo 6: Verificar funcionamento

```bash
# Testar DNS
dns-test
dns-status

# Ou rodar diagnóstico completo
dns-diag

# Ver logs
journalctl -u systemd-resolved -f
```

---

## 🎯 HIERARQUIA DNS CORRIGIDA

### Sem DNSCrypt:
```
Aplicações
    ↓
systemd-resolved (127.0.0.53)
    ↓
Cloudflare/Google DNS (1.1.1.1, 8.8.8.8)
    ↓
Internet
```

### Com DNSCrypt:
```
Aplicações
    ↓
systemd-resolved (127.0.0.53)
    ↓
dnscrypt-proxy2 (127.0.0.2:53)
    ↓
Cloudflare/Google DNS criptografado
    ↓
Internet
```

### Com VPN (overrideDNS=false):
```
Aplicações
    ↓
systemd-resolved (127.0.0.53)
    ↓
Cloudflare/Google DNS
    ↓
Interface VPN (wgnord)
    ↓
Internet
```

---

## 🐛 DEBUGGING

### Comandos úteis instalados:

```bash
# Status geral
dns-status

# Teste rápido
dns-test

# Diagnóstico completo
dns-diag

# Benchmark de servidores
dns-bench

# Flush cache
dns-flush

# Ver estatísticas
dns-stats
```

### Verificar conflitos de porta:

```bash
# Ver quem está usando porta 53
sudo ss -tulpn | grep :53

# Deve mostrar algo como:
# udp   UNCONN  0  0  127.0.0.53:53   *:*   users:(("systemd-resolve",pid=XXX))
```

### Ver ordem de inicialização dos serviços:

```bash
systemctl list-dependencies multi-user.target | grep -E "(resolved|dns-health|nordvpn)"
```

---

## ⚠️ NOTAS IMPORTANTES

1. **DNSCrypt + VPN**: Pode causar conflitos. Use apenas um ou configure manualmente.

2. **VPN overrideDNS**: Se `true`, a VPN vai sobrescrever o DNS do systemd-resolved. 
   Recomendado: deixar `false` e deixar systemd-resolved gerenciar.

3. **dns-health-monitor**: Agora vai iniciar DEPOIS da VPN (se habilitada) para não 
   testar DNS antes da VPN estar pronta.

4. **Pacotes instalados**: `dig`, `dog`, `drill`, `kdig` estão todos disponíveis agora.

---

## 📊 VERIFICAÇÃO PÓS-INSTALAÇÃO

Checklist:

- [ ] `sudo nixos-rebuild switch` sem erros
- [ ] `dns-test` retorna IPs
- [ ] `dns-status` mostra DNS servers corretos
- [ ] `dns-diag` mostra tudo verde (✅)
- [ ] `ping google.com` funciona
- [ ] `curl https://google.com` funciona
- [ ] Sem warnings no `nixos-rebuild`

---

## 🆘 SE NADA FUNCIONAR

```bash
# Reset completo
sudo systemctl stop dnscrypt-proxy2 nordvpn-manager dns-health-monitor
sudo systemctl restart systemd-resolved

# Configuração manual temporária
sudo rm /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Testar
dig @1.1.1.1 google.com

# Se funcionar, problema é na configuração NixOS
# Volte ao backup:
cd /etc/nixos
sudo cp modules/network/dns-resolver.nix.backup modules/network/dns-resolver.nix
sudo nixos-rebuild switch
```

---

## 📞 CONTATO

Se continuar com problemas:
1. Rode `dns-diag` e copie a saída
2. Rode `journalctl -u systemd-resolved -n 100` e copie erros
3. Verifique `/var/log/` por mensagens de erro

Boa sorte! 🚀
