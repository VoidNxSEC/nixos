{ ... }:

# ============================================================
# Network Module Aggregator
# ============================================================
# Purpose: Import all network configurations
# Categories: DNS, VPN, Proxy, Security, Monitoring
# ============================================================

{
  imports = [
    # DNS Configuration
    ./dns
    ./dns-resolver.nix

    # VPN
    ./vpn/nordvpn.nix
    ./vpn/tailscale.nix
    ./vpn/tailscale-laptop.nix
    ./vpn/tailscale-desktop.nix

    # Proxy & Reverse Proxy
    ./proxy

    # Security
    ./security/firewall-zones.nix

    # Monitoring
    ./monitoring/tailscale-monitor.nix

    # Network Infrastructure
    ./bridge.nix
  ];
}
