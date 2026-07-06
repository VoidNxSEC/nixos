# Configuração DNS Funcional - Geração 183

**Data de Identificação**: 2025-10-22
**Status**: ✅ ESTÁVEL E FUNCIONANDO
**Geração NixOS**: **183**

## Solução que Funcionou

A internet ficou estável após **configurar DNS manualmente apontando para Cloudflare (1.1.1.1)**.

### Configuração Aplicada

```nix
# hosts/kernelcore/configuration.nix:42-63
kernelcore.network.dns-resolver = {
  enable = true;
  enableDNSSEC = true;
  enableDNSCrypt = false;  # ← DESABILITADO - simplificação resolveu
  preferredServers = [
    "1.1.1.1"         # Cloudflare Primary ← CHAVE DA SOLUÇÃO
    "1.0.0.1"         # Cloudflare Secondary
    "9.9.9.9"         # Quad9 Primary
    "149.112.112.112" # Quad9 Secondary
    "8.8.8.8"         # Google Primary
    "8.8.4.4"         # Google Secondary
  ];
  cacheTTL = 3600;
};

kernelcore.network.vpn.nordvpn = {
  enable = false;        # ← VPN desabilitada
  autoConnect = false;
  overrideDNS = false;   # ← Não sobrescrever DNS do sistema
};
```

## O Que Foi Removido/Desabilitado

1. ❌ **dns-health-monitor service** - Causava conflitos de concorrência
2. ❌ **DNSCrypt** - Complexidade desnecessária, conflitos de porta
3. ❌ **VPN DNS override** - Deixar systemd-resolved gerenciar

## Hierarquia DNS Final (Funcional)

```
Aplicações
    ↓
systemd-resolved (127.0.0.53)
    ↓
Cloudflare DNS (1.1.1.1) ← DIRETO, SEM INTERMEDIÁRIOS
    ↓
Internet
```

## Por Que Funcionou?

**Simplicidade**: Removemos todas as camadas intermediárias (DNSCrypt, health monitor, VPN DNS) e deixamos apenas:
- `systemd-resolved` (gerenciador padrão do systemd)
- DNS direto para Cloudflare 1.1.1.1

**Sem conflitos**:
- Sem competição pela porta 53
- Sem serviços tentando reiniciar DNS automaticamente
- Sem race conditions na inicialização

## Verificação da Geração

```bash
# Ver gerações disponíveis
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Verificar geração atual
nixos-version

# Se precisar voltar para geração 183
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation 183
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

## Comandos de Teste

```bash
# Teste rápido
dns-test

# Ver qual DNS está sendo usado
resolvectl status

# Testar Cloudflare diretamente
dig @1.1.1.1 google.com

# Ping básico
ping google.com
```

## Lições Aprendidas

1. **Menos é mais**: Configuração simples e direta > camadas de abstração
2. **DNS criptografado (DNSCrypt) não era necessário** para resolver o problema
3. **Cloudflare 1.1.1.1 é rápido e confiável** - não precisa de múltiplos fallbacks complexos
4. **systemd-resolved sozinho funciona bem** - não precisa de monitoring service externo

## Manutenção Futura

Se a internet começar a falhar novamente:

1. **Primeiro check**: Verificar se ainda está na configuração simples (geração 183)
   ```bash
   nixos-version
   ```

2. **Voltar para esta configuração**:
   ```bash
   sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation 183
   sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
   ```

3. **Testar DNS**:
   ```bash
   dns-test
   resolvectl status
   ```

## Referências

- Configuração DNS: `modules/network/dns-resolver.nix`
- Configuração VPN: `modules/network/vpn/nordvpn.nix`
- Configuração host: `hosts/kernelcore/configuration.nix:42-63`
- Resumo de correções: `DNS_FIX_SUMMARY.md`
- Guia detalhado: `docs/GUIA-CORRECAO-DNS.md`

---

**⚠️ IMPORTANTE**: Não ativar DNSCrypt ou dns-health-monitor sem necessidade real. A configuração simples está funcionando.
