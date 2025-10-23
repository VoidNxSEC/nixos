# Correção DNS - Resumo das Alterações

**Data**: 2025-10-22  
**Status**: ✅ Concluído

## Problemas Identificados

1. **Conflito de porta 53**: dnscrypt-proxy2 e systemd-resolved tentando usar a mesma porta
2. **Duplicação de atributo `after`**: Bug no serviço dns-health-monitor
3. **Concorrência de serviços**: dns-health-monitor causando conflitos com serviços de rede
4. **Arquivos duplicados**: -fixed.nix não consolidados

## Mudanças Aplicadas

### 1. Removido `dns-health-monitor` service
- **Arquivo**: `modules/network/dns-resolver.nix:276-351`
- **Motivo**: Causava conflitos de concorrência paralela com serviços de rede
- **Alternativa**: Usar comandos manuais `dns-diag` ou `dns-test` para monitoramento

### 2. Atualizado módulo VPN
- **Arquivo**: `modules/network/vpn/nordvpn.nix:178-181`
- **Alteração**: Removida referência ao dns-health-monitor.service
- **Antes**: `before = [ "dns-health-monitor.service" ]`
- **Depois**: Removido completamente

### 3. Arquivos Limpos
- ❌ Removido: `modules/network/dns-resolver-fixed.nix` (duplicado)
- ❌ Removido: `modules/network/vpn/vpn-fixed.nix` (duplicado)
- ❌ Removido: `modules/network/dns/dns-emergency-fix.sh` (temporário)
- 📁 Movido: `modules/network/dns/GUIA-CORRECAO-DNS.md` → `docs/GUIA-CORRECAO-DNS.md`

## Configuração Atual DNS

### Hierarquia DNS Simplificada
```
Aplicações
    ↓
systemd-resolved (127.0.0.53)
    ↓
Cloudflare/Google DNS (1.1.1.1, 8.8.8.8, etc)
    ↓
Internet
```

### Configuração Ativa
- **DNS Resolver**: ✅ Habilitado (`kernelcore.network.dns-resolver.enable = true`)
- **DNSSEC**: ✅ Habilitado (`enableDNSSEC = true`)
- **DNSCrypt**: ❌ Desabilitado (`enableDNSCrypt = false`)
- **VPN**: ❌ Desabilitado (`vpn.nordvpn.enable = false`)
- **VPN DNS Override**: ❌ Desabilitado (`overrideDNS = false`)

### Servidores DNS Configurados
```nix
preferredServers = [
  "1.1.1.1"         # Cloudflare Primary
  "1.0.0.1"         # Cloudflare Secondary
  "9.9.9.9"         # Quad9 Primary (Privacy-focused, DNSSEC)
  "149.112.112.112" # Quad9 Secondary
  "8.8.8.8"         # Google Primary
  "8.8.4.4"         # Google Secondary
];
```

## Comandos de Diagnóstico

Após rebuild, use estes comandos para verificar o DNS:

```bash
# Teste rápido
dns-test

# Status detalhado
dns-status

# Diagnóstico completo
dns-diag

# Benchmark de servidores
dns-bench

# Flush cache DNS
dns-flush

# Estatísticas
dns-stats
```

## Próximos Passos

1. **Rebuild do sistema**:
   ```bash
   sudo nixos-rebuild switch
   ```

2. **Verificar funcionamento**:
   ```bash
   dns-test
   ping google.com
   ```

3. **Verificar logs** (se houver problemas):
   ```bash
   journalctl -u systemd-resolved -f
   ```

## Rollback (se necessário)

Se houver problemas, use:
```bash
sudo nixos-rebuild switch --rollback
```

## Referências

- Guia completo: `docs/GUIA-CORRECAO-DNS.md`
- Configuração DNS: `modules/network/dns-resolver.nix`
- Configuração VPN: `modules/network/vpn/nordvpn.nix`
- Configuração host: `hosts/kernelcore/configuration.nix:42-63`
