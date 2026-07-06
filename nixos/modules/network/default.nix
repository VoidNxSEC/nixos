{ ... }:

# ============================================================
# Network Module Aggregator
# ============================================================
# Purpose: Import all network configurations
# Categories: DNS, VPN, Proxy, Security, Monitoring, CNI
# ============================================================

{
  imports = [
    # DNS Configuration
    ./dns
    ./dns/adguard-home.nix
    ./dns-resolver.nix

    # VPN
    ./vpn/nordvpn.nix
    ./vpn/tailscale.nix
    ./vpn/tailscale-laptop.nix
    ./vpn/tailscale-desktop.nix
    ./vpn/wireguard.nix

    # Proxy & Reverse Proxy
    ./proxy

    # Security
    ./security/firewall-zones.nix

    # Monitoring
    ./monitoring/tailscale-monitor.nix

    # Network Infrastructure
    ./bridge.nix

    # Anti-detection proxy (disabled, kept for future use)
    # ./spider-network-proxy.nix

    # Kubernetes CNI
    ./cilium-cni.nix
  ];
}
