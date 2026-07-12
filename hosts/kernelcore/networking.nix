{ lib, ... }:

# ═══════════════════════════════════════════════════════════
# REDE — DNS, bridge, VPNs, proxies nginx, Tailscale
# ═══════════════════════════════════════════════════════════

{
  networking.networkmanager.enable = true;
  services.tailscale.enable = true;

  kernelcore.network = {
    dns-resolver = {
      enable = true;
      enableDNSSEC = false; # Necessario mais desenvolvimento
      enableDNSCrypt = false;
      preferredServers = [
        "1.1.1.1"
        "1.0.0.1" # Cloudflare
        "9.9.9.9"
        "149.112.112.112" # Quad9
        "8.8.8.8"
        "8.8.4.4" # Google
      ];
      cacheTTL = 3600;
    };

    dns-proxy = {
      enable = true;
      setAsSystemResolver = false;
    };

    # spider-network-proxy = {
    #   enable = false;
    #   setSystemProxy = false;
    # };

    bridge = {
      enable = true;
      ipv6.enable = false;
    };

    vpn.nordvpn = {
      enable = false;
      autoConnect = false;
      overrideDNS = false;
    };

    # WireGuard VPN – fast, modern kernel-native VPN
    # To activate: populate secrets/wireguard.yaml via `sops secrets/wireguard.yaml`
    # then set enable = true and fill in address/peers below.
    vpn.wireguard = {
      enable = false; # set true after adding private key to SOPS
      interface = "wg0";
      address = [ "10.8.0.2/24" ]; # adjust to your VPN allocation
      dns = [ "10.8.0.1" ];
      # Private key must be in SOPS – run:
      #   wg genkey | sops --set '["wireguard_private_key"]' /path/to/key
      #   then set privateKeyFile = config.sops.secrets.wireguard_private_key.path
      privateKeyFile = "/run/secrets/wireguard_private_key";
      killSwitch = false;
      peers = [
        {
          # Replace with your VPN server's public key
          publicKey = "REPLACE_WITH_SERVER_PUBLIC_KEY=";
          endpoint = "vpn.example.com:51820";
          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ]; # full-tunnel; use subnet for split-tunnel
          persistentKeepalive = 25;
        }
      ];
    };

    proxy.nginx-tailscale = {
      enable = true;
      hostname = "nx";
      tailnetDomain = "tailb3b82e.ts.net";
      services.forgejo = {
        enable = true;
        subdomain = "forgejo";
        upstreamPort = 3002;
        maxBodySize = "200M";
        enableWebSocket = true;
      };
    };

    proxy.nginx-public = {
      enable = true;
      services = {
        gitea = {
          enable = true;
          host = "gitea.voidnx.com";
          upstreamPort = 3000;
          maxBodySize = "200M";
        };
      };
    };

    vpn.tailscale.hostname = lib.mkForce "nx";

    security.firewall-zones = {
      enable = false;
    };
  };
}
