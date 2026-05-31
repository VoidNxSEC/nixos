{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.dns-resolver;

  # Detectar se VPN está ativa
  vpnEnabled = config.kernelcore.network.vpn.nordvpn.enable or false;

  # Escolher porta para dnscrypt baseado no que está ativo
  dnscryptPort = if cfg.enableDNSCrypt then "127.0.0.2:53" else "127.0.0.1:53";
in
{
  options.kernelcore.network.dns-resolver = {
    enable = mkEnableOption "Enable DNS resolver optimization for network performance";

    preferredServers = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1" # Cloudflare Primary
        "1.0.0.1" # Cloudflare Secondary
        "8.8.8.8" # Google Primary
        "8.8.4.4" # Google Secondary
      ];
      description = "Preferred DNS servers in priority order";
    };

    enableDNSSEC = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DNSSEC validation for enhanced security";
    };

    enableDNSCrypt = mkOption {
      type = types.bool;
      default = false;
      description = "Enable DNSCrypt for encrypted DNS queries";
    };

    cacheTTL = mkOption {
      type = types.int;
      default = 3600;
      description = "DNS cache TTL in seconds";
    };
  };

  config = mkIf cfg.enable {

    # ASSERTIONS para prevenir conflitos
    assertions = [
      {
        assertion = !(cfg.enableDNSCrypt && vpnEnabled);
        message = ''
          AVISO: DNSCrypt e VPN habilitados simultaneamente podem causar conflitos.
          A VPN vai sobrescrever as configurações de DNS.
          Recomendação: Use apenas um ou configure manualmente a hierarquia.
        '';
      }
    ];

    # Use systemd-resolved para gerenciamento moderno de DNS
    services.resolved = {
      enable = true;

      settings = {
        Resolve = {
          # "allow-downgrade": valida DNSSEC quando disponível, não quebra em redes sem suporte (ex: hotspot)
          # "yes": strict, falha se servidor não suportar DNSSEC
          # "no": desabilita validação
          DNSSEC = lib.mkForce (if cfg.enableDNSSEC then "allow-downgrade" else "no");

          # "opportunistic": tenta TLS, degrada graciosamente para UDP se não suportado
          # "yes": exige TLS, falha se não disponível (não use em hotspot)
          DNSOverTLS = "opportunistic";

          # DNS global — NÃO sobrescrito pelo DHCP do hotspot/router
          DNS =
            if cfg.enableDNSCrypt then
              [ "127.0.0.2" ] # DNSCrypt rodando em porta alternativa
            else
              cfg.preferredServers;

          # Fallback caso DNS global falhe
          FallbackDNS = [
            "9.9.9.9"
            "149.112.112.112"
          ];

          # Resolver como autoritativo para todos os domínios
          Domains = "~.";
        };
      };
    };

    # DNSCrypt-proxy para DNS criptografado (opcional)
    services.dnscrypt-proxy2 = mkIf cfg.enableDNSCrypt {
      enable = true;
      settings = {
        # PORTA ALTERNATIVA para não conflitar com systemd-resolved
        listen_addresses = [ "127.0.0.2:53" ];

        server_names = [
          "cloudflare"
          "cloudflare-security"
          "google"
        ];

        ipv4_servers = true;
        ipv6_servers = true;

        dnscrypt_servers = true;
        doh_servers = true;

        require_dnssec = cfg.enableDNSSEC;
        require_nolog = true;
        require_nofilter = true;

        timeout = 5000;
        keepalive = 30;

        cache = true;
        cache_size = 4096;
        cache_min_ttl = 2400;
        cache_max_ttl = cfg.cacheTTL;
        cache_neg_ttl = 60;

        # Fallback direto para servidores públicos
        fallback_resolvers = cfg.preferredServers;
      };
    };

    # Network configuration - NÃO setar nameservers quando resolved está ativo
    networking = {
      # REMOVIDO: nameservers (conflita com systemd-resolved)
      # O systemd-resolved gerencia isso através do DNS global no resolved.conf

      # Firewall: permitir porta do dnscrypt se habilitado
      firewall.allowedUDPPorts = mkIf cfg.enableDNSCrypt [ 53 ];

      dhcpcd.extraConfig = ''
        # Permitir que systemd-resolved gerencie DNS
        nohook resolv.conf
      '';

      # Impede que o NetworkManager sobrescreva o DNS via DHCP do hotspot/router.
      # Com "systemd-resolved", o NM delega o gerenciamento de DNS inteiramente
      # ao resolved, que usa o DNS global configurado acima (ignorando DHCP DNS).
      networkmanager.dns = "systemd-resolved";
    };

    # Hardening do systemd-resolved
    systemd.services.systemd-resolved = {
      serviceConfig = {
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallFilter = "@system-service @network-io";
        SystemCallErrorNumber = "EPERM";
      };
    };

    # Ferramentas de diagnóstico DNS
    environment.systemPackages = with pkgs; [
      bind # dig, nslookup
      dnsutils
      dog # alternativa moderna ao dig
      ldns # drill
      knot-dns # kdig
    ];

    # Aliases úteis para troubleshooting
    environment.shellAliases = {
      # Testes básicos
      dns-test = "${pkgs.bind}/bin/dig @127.0.0.53 google.com +short";
      dns-test-external = "${pkgs.bind}/bin/dig @1.1.1.1 google.com +short";

      # Benchmark de servidores
      dns-bench = "${pkgs.bash}/bin/bash -c 'for srv in 127.0.0.53 1.1.1.1 8.8.8.8 9.9.9.9; do echo \"Testing \$srv:\"; ${pkgs.bind}/bin/dig @\$srv google.com +stats | grep \"Query time\"; done'";

      # Gerenciamento
      dns-flush = "sudo systemctl restart systemd-resolved";
      dns-status = "${pkgs.systemd}/bin/resolvectl status";
      dns-stats = "${pkgs.systemd}/bin/resolvectl statistics";

      # Diagnóstico completo
      dns-diag = "/etc/dns-diagnostics.sh";
    };

    # Script de diagnóstico completo
    environment.etc."dns-diagnostics.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Script de diagnóstico DNS completo

        echo "==================================="
        echo "   DNS DIAGNOSTICS TOOL"
        echo "==================================="
        echo ""

        # 0. Gateway / rota padrão
        GW=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
        IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
        echo "🔌 [0/7] Default gateway: $GW via $IFACE"
        if [ -n "$GW" ] && ${pkgs.iputils}/bin/ping -c 1 -W 2 "$GW" > /dev/null 2>&1; then
          echo "✅ Gateway reachável ($GW)"
        else
          echo "❌ Gateway INACESSÍVEL — problema de L2/L3, não DNS"
        fi
        echo ""

        # 1. Status do systemd-resolved
        echo "📡 [1/7] Systemd-resolved status:"
        systemctl status systemd-resolved --no-pager | head -n 5
        echo ""

        # 2. Configuração atual
        echo "⚙️  [2/7] Current DNS configuration:"
        ${pkgs.systemd}/bin/resolvectl status | grep -E "(DNS Servers|Current DNS|Fallback DNS)" -A 2 | head -20
        echo ""

        # 3. Testar resolução local via resolvectl (mais preciso que dig @127.0.0.53)
        echo "🔍 [3/7] Testing local resolver (resolvectl):"
        if ${pkgs.systemd}/bin/resolvectl query google.com > /dev/null 2>&1; then
          echo "✅ Local resolver OK"
          ${pkgs.systemd}/bin/resolvectl query google.com 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
        else
          echo "❌ Local resolver FAILED"
          echo "   Tip: tente 'resolvectl query google.com' para ver o erro completo"
        fi
        echo ""

        # 4. Testar Cloudflare (UDP direto, sem TLS)
        echo "☁️  [4/7] Testing Cloudflare (1.1.1.1):"
        if ${pkgs.bind}/bin/dig +short +time=5 +tries=2 +notcp @1.1.1.1 google.com > /dev/null 2>&1; then
          echo "✅ Cloudflare OK"
        else
          echo "❌ Cloudflare FAILED"
        fi
        echo ""

        # 5. Testar Google DNS
        echo "🔎 [5/7] Testing Google DNS (8.8.8.8):"
        if ${pkgs.bind}/bin/dig +short +time=5 +tries=2 +notcp @8.8.8.8 google.com > /dev/null 2>&1; then
          echo "✅ Google DNS OK"
        else
          echo "❌ Google DNS FAILED"
        fi
        echo ""

        # 6. Verificar DNSCrypt (se habilitado)
        ${optionalString cfg.enableDNSCrypt ''
          echo "🔐 [6/7] DNSCrypt-proxy status:"
          if systemctl is-active dnscrypt-proxy2 > /dev/null 2>&1; then
            echo "✅ DNSCrypt running"
            if ${pkgs.bind}/bin/dig +short +time=5 +notcp @127.0.0.2 google.com > /dev/null 2>&1; then
              echo "✅ DNSCrypt resolver OK"
            else
              echo "❌ DNSCrypt resolver FAILED"
            fi
          else
            echo "❌ DNSCrypt NOT running"
          fi
          echo ""
        ''}

        # 7. Verificar conectividade geral (HTTP, não HTTPS — evita falha de cert em IP raw)
        echo "🌐 [7/7] Internet connectivity:"
        HTTP_CODE=$(${pkgs.curl}/bin/curl -s --max-time 5 -o /dev/null -w "%{http_code}" http://1.1.1.1 2>/dev/null)
        if [ "$HTTP_CODE" -ge 200 ] 2>/dev/null && [ "$HTTP_CODE" -lt 600 ] 2>/dev/null; then
          echo "✅ Internet OK (HTTP $HTTP_CODE)"
        elif ${pkgs.iputils}/bin/ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1; then
          echo "✅ Internet OK (ping 8.8.8.8 — HTTP bloqueado)"
        else
          echo "❌ Internet connectivity FAILED"
        fi
        echo ""

        # Resumo
        echo "==================================="
        echo "   SUMMARY"
        echo "==================================="
        ${pkgs.systemd}/bin/resolvectl statistics
        echo ""

        # Logs recentes
        echo "📋 Recent DNS errors (last 10):"
        journalctl -u systemd-resolved -p err --since "10 minutes ago" --no-pager | tail -n 10
      '';
    };

    # REMOVIDO: dns-health-monitor - causava conflitos de concorrência com serviços de rede
    # Para monitoramento manual, use: dns-diag ou dns-test

    # resolv.conf é gerenciado pelo dns-proxy (networking.nameservers) quando setAsSystemResolver=true.
    # Não definir environment.etc."resolv.conf".source aqui evita conflito de definição.
  };
}
