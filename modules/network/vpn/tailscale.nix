{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.vpn.tailscale;
in
{
  options.kernelcore.network.vpn.tailscale = {
    enable = mkEnableOption "Enable Tailscale VPN mesh network with advanced security";

    # Authentication
    authKeyFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing Tailscale auth key (SOPS encrypted)";
      example = "/run/secrets/tailscale-authkey";
    };

    useAuthKeyFile = mkOption {
      type = types.bool;
      default = true;
      description = "Use auth key file for automatic authentication";
    };

    # Network Configuration
    hostname = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Hostname for this device in the Tailscale network";
    };

    # Subnet Router Configuration
    advertiseRoutes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Subnets to advertise to the Tailscale network";
      example = [
        "192.168.15.0/24"
        "10.0.0.0/24"
      ];
    };

    enableSubnetRouter = mkOption {
      type = types.bool;
      default = false;
      description = "Enable subnet routing (advertise local networks)";
    };

    # Exit Node Configuration
    exitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Advertise this device as an exit node";
    };

    exitNodeAllowLANAccess = mkOption {
      type = types.bool;
      default = true;
      description = "Allow LAN access when using this as an exit node";
    };

    # DNS Configuration
    acceptDNS = mkOption {
      type = types.bool;
      default = true;
      description = "Accept DNS configuration from Tailscale (MagicDNS)";
    };

    enableMagicDNS = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tailscale MagicDNS for automatic hostname resolution";
    };

    extraDNSServers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional DNS servers to use alongside MagicDNS";
      example = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    # Security Options
    acceptRoutes = mkOption {
      type = types.bool;
      default = true;
      description = "Accept routes advertised by other devices";
    };

    enableSSH = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SSH over Tailscale (Tailscale SSH)";
    };

    shieldsUp = mkOption {
      type = types.bool;
      default = false;
      description = "Block incoming connections from other Tailscale devices";
    };

    # Advanced Network Settings
    port = mkOption {
      type = types.port;
      default = 41641;
      description = "UDP port for Tailscale to listen on";
    };

    interfaceName = mkOption {
      type = types.str;
      default = "tailscale0";
      description = "Name of the Tailscale network interface";
    };

    # Performance Optimization
    enableConnectionPersistence = mkOption {
      type = types.bool;
      default = true;
      description = "Enable connection persistence and automatic reconnection";
    };

    reconnectTimeout = mkOption {
      type = types.int;
      default = 30;
      description = "Timeout in seconds before attempting reconnection";
    };

    # Firewall Integration
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall ports for Tailscale";
    };

    trustedInterface = mkOption {
      type = types.bool;
      default = true;
      description = "Mark Tailscale interface as trusted in firewall";
    };

    # Device Tags
    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Tailscale ACL tags for this device";
      example = [
        "tag:server"
        "tag:prod"
      ];
    };

    # Extra Arguments
    extraUpFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional flags to pass to tailscale up";
      example = [ "--accept-risk=lose-ssh" ];
    };

    extraDaemonFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional flags for tailscaled daemon";
    };

    # Service Management
    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically start Tailscale on boot";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/tailscale";
      description = "Directory for Tailscale state files";
    };
  };

  config = mkIf cfg.enable {
    # Install Tailscale package
    environment.systemPackages = with pkgs; [
      tailscale
      curl
      jq
    ];

    # Enable IP forwarding if subnet router or exit node
    boot.kernel.sysctl = mkIf (cfg.enableSubnetRouter || cfg.exitNode) {
      "net.ipv4.ip_forward" = mkDefault 1;
      "net.ipv6.conf.all.forwarding" = mkDefault 1;
      # Optimize for routing performance (use mkDefault to allow hardening override)
      "net.ipv4.conf.all.rp_filter" = mkDefault 2;
      "net.ipv4.conf.default.rp_filter" = mkDefault 2;
    };

    # Tailscale daemon service
    services.tailscale = {
      enable = true;
      port = cfg.port;
      interfaceName = cfg.interfaceName;
      extraUpFlags =
        let
          routeFlags = optionals (cfg.enableSubnetRouter && cfg.advertiseRoutes != [ ]) [
            "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}"
          ];
          exitNodeFlags =
            optionals cfg.exitNode [
              "--advertise-exit-node"
            ]
            ++ optionals (cfg.exitNode && cfg.exitNodeAllowLANAccess) [
              "--exit-node-allow-lan-access"
            ];
          dnsFlags =
            optionals cfg.acceptDNS [
              "--accept-dns=true"
            ]
            ++ optionals (!cfg.acceptDNS) [
              "--accept-dns=false"
            ];
          routeAcceptFlags =
            optionals cfg.acceptRoutes [
              "--accept-routes=true"
            ]
            ++ optionals (!cfg.acceptRoutes) [
              "--accept-routes=false"
            ];
          sshFlags = optionals cfg.enableSSH [
            "--ssh"
          ];
          shieldsFlags = optionals cfg.shieldsUp [
            "--shields-up"
          ];
          hostnameFlags = optional (cfg.hostname != "") "--hostname=${cfg.hostname}";
          tagFlags = optionals (cfg.tags != [ ]) [
            "--advertise-tags=${concatStringsSep "," cfg.tags}"
          ];
        in
        routeFlags
        ++ exitNodeFlags
        ++ dnsFlags
        ++ routeAcceptFlags
        ++ sshFlags
        ++ shieldsFlags
        ++ hostnameFlags
        ++ tagFlags
        ++ cfg.extraUpFlags;

      # Use auth key file if configured
      authKeyFile = mkIf (cfg.useAuthKeyFile && cfg.authKeyFile != null) cfg.authKeyFile;
    };

    # Enhanced systemd service configuration
    systemd.services.tailscaled = {
      after = [ "network-pre.target" ];
      wants = [ "network-pre.target" ];
      wantedBy = mkIf cfg.autoStart [ "multi-user.target" ];

      serviceConfig = {
        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.stateDir ];

        # Resource limits
        MemoryMax = "512M";
        TasksMax = 256;

        # Restart behavior for reliability
        Restart = mkIf cfg.enableConnectionPersistence "on-failure";
        RestartSec = mkIf cfg.enableConnectionPersistence cfg.reconnectTimeout;

        # State directory
        StateDirectory = "tailscale";
      };
    };

    # Firewall configuration
    networking.firewall = mkMerge [
      (mkIf cfg.openFirewall {
        # Allow Tailscale UDP port
        allowedUDPPorts = [ cfg.port ];

        # Trust Tailscale interface
        trustedInterfaces = mkIf cfg.trustedInterface [ cfg.interfaceName ];

        # Allow forwarding for subnet router/exit node
        checkReversePath = mkIf (cfg.enableSubnetRouter || cfg.exitNode) "loose";

        # Firewall rules for subnet routing
        extraCommands = mkIf (cfg.enableSubnetRouter || cfg.exitNode) ''
          # Allow forwarding from Tailscale interface
          iptables -A FORWARD -i ${cfg.interfaceName} -j ACCEPT
          iptables -A FORWARD -o ${cfg.interfaceName} -j ACCEPT

          # NAT for exit node traffic
          ${optionalString cfg.exitNode ''
            iptables -t nat -A POSTROUTING -o ${cfg.interfaceName} -j MASQUERADE
          ''}
        '';

        extraStopCommands = mkIf (cfg.enableSubnetRouter || cfg.exitNode) ''
          # Clean up forwarding rules
          iptables -D FORWARD -i ${cfg.interfaceName} -j ACCEPT 2>/dev/null || true
          iptables -D FORWARD -o ${cfg.interfaceName} -j ACCEPT 2>/dev/null || true

          ${optionalString cfg.exitNode ''
            iptables -t nat -D POSTROUTING -o ${cfg.interfaceName} -j MASQUERADE 2>/dev/null || true
          ''}
        '';
      })
    ];

    # DNS integration with systemd-resolved
    services.resolved = mkIf (cfg.enableMagicDNS && config.services.resolved.enable) {
      extraConfig = ''
        [Resolve]
        # Allow Tailscale to manage DNS
        DNSStubListener=no
      '';
    };

    # Create state directory
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 root root -"
    ];

    # Shell aliases for management
    environment.shellAliases = {
      # Basic Tailscale commands
      ts-status = "${pkgs.tailscale}/bin/tailscale status";
      ts-ip = "${pkgs.tailscale}/bin/tailscale ip -4";
      ts-ip6 = "${pkgs.tailscale}/bin/tailscale ip -6";
      ts-ping = "${pkgs.tailscale}/bin/tailscale ping";
      ts-netcheck = "${pkgs.tailscale}/bin/tailscale netcheck";
      ts-up = "sudo systemctl start tailscaled && sleep 2 && sudo ${pkgs.tailscale}/bin/tailscale up";
      ts-down = "sudo ${pkgs.tailscale}/bin/tailscale down";
      ts-logs = "journalctl -u tailscaled -f";

      # Useful info commands
      ts-hostname = "${pkgs.tailscale}/bin/tailscale status | grep $(hostname) | awk '{print $2}'";
      ts-url = "echo http://$(${pkgs.tailscale}/bin/tailscale ip -4)";
      ts-peers = "${pkgs.tailscale}/bin/tailscale status --peers";

      # Docker + Tailscale helpers
      docker-ts-urls = ''
        echo "=== Docker Containers via Tailscale ===" && \
        TSIP=$(${pkgs.tailscale}/bin/tailscale ip -4) && \
        docker ps --format "{{.Names}}\t{{.Ports}}" | grep -v "PORTS" | while IFS=$'\t' read name ports; do
          if echo "$ports" | grep -q ":"; then
            port=$(echo "$ports" | grep -oP '0.0.0.0:\K\d+' | head -1);
            [ -n "$port" ] && echo "  $name: http://$TSIP:$port";
          fi
        done
      '';

      my-ips = ''
        echo "╔═══════════════════════════════════════╗" && \
        echo "║       Network Information              ║" && \
        echo "╚═══════════════════════════════════════╝" && \
        echo "" && \
        echo "🌐 Tailscale IPv4: $(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'Not connected')" && \
        echo "🌐 Tailscale IPv6: $(${pkgs.tailscale}/bin/tailscale ip -6 2>/dev/null || echo 'Not connected')" && \
        echo "🏠 Hostname: $(${pkgs.tailscale}/bin/tailscale status 2>/dev/null | grep $(hostname) | awk '{print $2}' || echo 'Not connected')" && \
        echo "🖥️  Local IP: $(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)" && \
        echo ""
      '';
    };

    # Health check script
    environment.etc."tailscale/health-check.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Tailscale health check script

        set -euo pipefail

        # Colors
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        NC='\033[0m'

        echo -e "''${BLUE}==================================="
        echo -e "   TAILSCALE HEALTH CHECK"
        echo -e "===================================''${NC}"
        echo ""

        # Check if tailscaled is running
        if systemctl is-active --quiet tailscaled; then
          echo -e "''${GREEN}✓ tailscaled service: Running''${NC}"
        else
          echo -e "''${RED}✗ tailscaled service: Stopped''${NC}"
          exit 1
        fi

        # Check Tailscale status
        if ${pkgs.tailscale}/bin/tailscale status &>/dev/null; then
          echo -e "''${GREEN}✓ Tailscale connection: Active''${NC}"
          
          # Show current status
          echo ""
          echo -e "''${BLUE}Current Status:''${NC}"
          ${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '
            "Host: \(.Self.HostName)",
            "Tailscale IP: \(.Self.TailscaleIPs[0])",
            "Online: \(.Self.Online)",
            "Exit Node: \(if .ExitNodeStatus then "Active" else "None" end)"
          '
          
          # Show network check
          echo ""
          echo -e "''${BLUE}Network Quality:''${NC}"
          ${pkgs.tailscale}/bin/tailscale netcheck
          
        else
          echo -e "''${YELLOW}⚠ Tailscale connection: Not authenticated''${NC}"
          echo ""
          echo -e "Run: sudo ${pkgs.tailscale}/bin/tailscale up"
        fi

        echo ""
        echo -e "''${BLUE}==================================="''${NC}
      '';
    };

    # Warnings for configuration validation
    warnings =
      (optional (
        cfg.exitNode && !cfg.enableSubnetRouter && cfg.advertiseRoutes != [ ]
      ) "Exit node is enabled but subnet router is disabled. Routes will not be advertised.")
      ++ (optional (
        cfg.enableSubnetRouter && cfg.advertiseRoutes == [ ]
      ) "Subnet router is enabled but no routes are configured in advertiseRoutes.");
  };
}
