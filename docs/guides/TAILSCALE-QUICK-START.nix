# Tailscale VPN Stack - Quick Start Configuration
# Add this to your hosts/kernelcore/configuration.nix

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Import all Tailscale modules (add to your flake.nix imports)
  imports = [
    ../../modules/network/vpn/tailscale.nix
    ../../modules/network/proxy/nginx-tailscale.nix
    ../../modules/network/proxy/tailscale-services.nix
    ../../modules/network/security/firewall-zones.nix
    ../../modules/network/monitoring/tailscale-monitor.nix
    ../../modules/secrets/tailscale.nix
  ];

  # ============================================
  # OPTION 1: Simple Setup (Everything Enabled)
  # ============================================

  # Enable complete Tailscale stack with all services
  kernelcore.network.proxy.tailscale-services = {
    enable = true;
    tailnetDomain = "your-tailnet-name.ts.net"; # CHANGE THIS
  };

  # Enable monitoring with auto-failover
  kernelcore.network.monitoring.tailscale = {
    enable = true;
    checkInterval = 30;
    maxLatency = 200;
    maxPacketLoss = 5;
    enableAutoFailover = true;
  };

  # Enable advanced firewall zones
  kernelcore.network.security.firewall-zones = {
    enable = true;
    defaultPolicy = "drop";
    enableLogging = true;
  };

  # ============================================
  # OPTION 2: Granular Control (Manual Setup)
  # ============================================

  # Uncomment and customize if you want more control:

  # # Tailscale VPN
  # kernelcore.network.vpn.tailscale = {
  #   enable = true;
  #   authKeyFile = config.sops.secrets."tailscale-authkey".path;
  #
  #   # Subnet router
  #   enableSubnetRouter = true;
  #   advertiseRoutes = [ "192.168.15.0/24" ];
  #
  #   # Exit node
  #   exitNode = true;
  #   exitNodeAllowLANAccess = true;
  #
  #   # DNS
  #   acceptDNS = true;
  #   enableMagicDNS = true;
  #
  #   # Tags
  #   tags = [ "tag:server" "tag:desktop" ];
  # };

  # # NGINX Proxy
  # kernelcore.network.proxy.nginx-tailscale = {
  #   enable = true;
  #   enableHTTP3 = true;
  #
  #   services = {
  #     ollama.enable = true;
  #     llamacpp.enable = true;
  #     postgresql.enable = false;  # Enable as needed
  #   };
  # };

  # # Secrets
  # kernelcore.secrets.tailscale = {
  #   enable = true;
  #   secretsFile = "/etc/nixos/secrets/tailscale.yaml";
  # };
}

# ============================================
# SETUP CHECKLIST
# ============================================
#
# [ ] 1. Get Tailscale auth key from https://login.tailscale.com/admin/settings/keys
# [ ] 2. Create /etc/nixos/secrets/tailscale.yaml with your auth key
# [ ] 3. Encrypt secrets: sudo sops -e -i /etc/nixos/secrets/tailscale.yaml
# [ ] 4. Update tailnetDomain above with your actual tailnet name
# [ ] 5. Add imports to your flake.nix (see docs/guides/TAILSCALE-MESH-NETWORK.md)
# [ ] 6. Rebuild: sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
# [ ] 7. Check status: tailscale status
# [ ] 8. Test services: curl http://ollama.kernelcore.your-tailnet.ts.net/api/tags
# [ ] 9. Configure ACLs in Tailscale admin console
# [ ] 10. Set up laptop client (see docs/guides/TAILSCALE-LAPTOP-CLIENT.nix)
#
# ============================================
# QUICK COMMANDS
# ============================================
#
# Status:      tailscale status
# Check:       /etc/tailscale/health-check.sh
# Monitor:     ts-monitor-logs
# Benchmark:   ts-benchmark
# Firewall:    fw-status
# Services:    nginx-test && systemctl status nginx
#
# For full documentation, see: docs/guides/TAILSCALE-MESH-NETWORK.md
