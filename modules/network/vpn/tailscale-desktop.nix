# Tailscale Configuration for Desktop
# Auto-configured as SUBNET ROUTER for home network
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Import base Tailscale module
  imports = [ ./tailscale.nix ];

  # Gate da Fase 4: perfil era incondicional; default true preserva o sistema.
  # Fase 5: laptop e desktop deveriam ser mutuamente exclusivos. Enquanto os
  # dois estiverem habilitados (estado herdado, coexistindo via mkForce), o
  # warning abaixo lembra de desligar um deles no host — decisão do usuário.
  options.kernelcore.network.vpn.tailscale-desktop.enable =
    lib.mkEnableOption "Tailscale desktop (subnet router) profile"
    // {
      default = true;
    };

  config = lib.mkMerge [
    {
      warnings =
        lib.optional
          (
            config.kernelcore.network.vpn.tailscale-desktop.enable
            && config.kernelcore.network.vpn.tailscale-laptop.enable
          )
          "kernelcore.network.vpn: os perfis tailscale-laptop e tailscale-desktop estao ambos habilitados; eles se sobrepoem via mkForce. Desabilite um deles no host (ex.: kernelcore.network.vpn.tailscale-desktop.enable = false;).";
    }
    (lib.mkIf config.kernelcore.network.vpn.tailscale-desktop.enable {
      # Desktop-specific Tailscale configuration
      kernelcore.network.vpn.tailscale = {
        enable = true;

        # Device Identity
        hostname = "desktop-home"; # Nome bonito no Tailscale

        # Network Mode: SUBNET ROUTER
        # Desktop compartilha rede local para devices remotos
        enableSubnetRouter = true;

        # IMPORTANTE: Ajuste estas subnets para sua rede real!
        # Descubra com: ip route | grep "scope link"
        advertiseRoutes = [
          "192.168.1.0/24" # Subnet principal (ajuste conforme sua rede)
          # "192.168.2.0/24"  # Adicione outras subnets se necessário
          # "172.17.0.0/16"   # Rede Docker (se quiser compartilhar containers)
        ];

        # Accept routes from other devices too
        acceptRoutes = true;

        # DNS Configuration
        acceptDNS = true; # MagicDNS (usar hostnames)
        enableMagicDNS = true;

        # SSH over Tailscale
        enableSSH = true;

        # Security
        shieldsUp = false; # Allow connections from laptop

        # Performance
        enableConnectionPersistence = true;
        reconnectTimeout = 30;

        # Firewall
        openFirewall = true;
        trustedInterface = true;

        # Auto-start on boot (importante para subnet router!)
        autoStart = true;

        # Optional: Add tags for ACL management
        tags = [
          "tag:desktop"
          "tag:subnet-router"
          "tag:home"
        ];

        # Extra flags if needed
        extraUpFlags = [
          # Add any extra flags here
        ];
      };

      # IP forwarding JÁ é habilitado automaticamente pelo módulo
      # quando enableSubnetRouter = true, mas você pode adicionar
      # otimizações extras aqui se quiser:
      boot.kernel.sysctl = {
        # Performance tweaks para routing (opcional)
        "net.core.netdev_max_backlog" = 5000;
        "net.ipv4.tcp_congestion_control" = "bbr";
      };

      # Desktop-specific environment
      environment.shellAliases = {
        # Check subnet router status
        ts-router-status = ''
          echo "╔═══════════════════════════════════════╗" && \
          echo "║    Subnet Router Status                ║" && \
          echo "╚═══════════════════════════════════════╝" && \
          echo "" && \
          echo "🌐 Tailscale IP: $(${pkgs.tailscale}/bin/tailscale ip -4)" && \
          echo "🏠 Hostname: $(${pkgs.tailscale}/bin/tailscale status | grep $(hostname) | awk '{print $2}')" && \
          echo "" && \
          echo "📡 Advertised Routes:" && \
          ${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '.Self.PrimaryRoutes[]?' && \
          echo "" && \
          echo "👥 Connected Peers:" && \
          ${pkgs.tailscale}/bin/tailscale status --peers | head -10 && \
          echo "" && \
          echo "💾 IP Forwarding: $(sysctl -n net.ipv4.ip_forward)"
        '';

        # Show local network devices
        local-devices = ''
          echo "🏠 Local Network Scan (via arp):" && \
          ip neigh | grep -v FAILED | awk '{print "  " $1 " - " $5}' | sort
        '';

        # Check if laptop can reach this desktop
        ping-laptop = "${pkgs.tailscale}/bin/tailscale ping laptop-kernelcore";

        # Quick offload test (if using as build server)
        test-offload = ''
          echo "🔨 Testing remote build capability..." && \
          nix-build '<nixpkgs>' -A hello --dry-run && \
          echo "✅ Build system ready"
        '';
      };

      # Services specifically for subnet router role
      systemd.services.tailscale-subnet-check = {
        description = "Check Tailscale subnet router status on boot";
        after = [
          "tailscaled.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # Add procps (sysctl) to PATH
          Environment = "PATH=${pkgs.tailscale}/bin:${pkgs.jq}/bin:${pkgs.procps}/bin:/run/current-system/sw/bin";
          ExecStart = pkgs.writeShellScript "tailscale-subnet-check" ''
            #!/usr/bin/env bash
            set -euo pipefail

            # Smart wait for Tailscale - poll every 0.5s up to 3 seconds
            MAX_WAIT=6  # 6 iterations of 0.5s = 3 seconds max
            WAIT_COUNT=0

            echo "🔍 Waiting for Tailscale to be ready..."
            while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
              if ${pkgs.tailscale}/bin/tailscale status --json >/dev/null 2>&1; then
                echo "✅ Tailscale is ready"
                break
              fi
              sleep 0.5
              WAIT_COUNT=$((WAIT_COUNT + 1))
            done

            if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
              echo "⚠️  Tailscale not ready after 3 seconds, proceeding anyway..."
            fi

            # Check if routes are advertised
            echo "🔍 Checking Tailscale subnet router configuration..."

            if ${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -e '.Self.PrimaryRoutes | length > 0' > /dev/null 2>&1; then
              echo "✅ Subnet routes are being advertised"
              ${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '.Self.PrimaryRoutes[]?' | while read route; do
                echo "  📡 $route"
              done
            else
              echo "⚠️  WARNING: No subnet routes advertised!"
              echo "   Make sure to approve routes in Tailscale dashboard:"
              echo "   https://login.tailscale.com/admin/machines"
            fi

            # Check IP forwarding
            if [ "$(sysctl -n net.ipv4.ip_forward)" = "1" ]; then
              echo "✅ IP forwarding is enabled"
            else
              echo "❌ ERROR: IP forwarding is disabled!"
            fi
          '';
        };
      };

      # Helpful info on login
      environment.interactiveShellInit = ''
        # Show subnet router status on shell start
        if systemctl is-active --quiet tailscaled 2>/dev/null; then
          TSIP=$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null || echo "")
          if [ -n "$TSIP" ]; then
            echo "🏠 Desktop Subnet Router active: $TSIP"
            echo "📡 Run 'ts-router-status' for detailed info"
          fi
        fi
      '';
    })
  ];
}
