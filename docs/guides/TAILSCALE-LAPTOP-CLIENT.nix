# Tailscale Laptop Client Configuration Template
# Copy this to your laptop's configuration.nix and customize

{ config, lib, pkgs, ... }:

{
  # Import Tailscale modules (adjust paths as needed)
  imports = [
    ./modules/network/vpn/tailscale.nix
    ./modules/secrets/tailscale.nix
  ];

  # Enable Tailscale with optimized laptop settings
  kernelcore.network.vpn.tailscale = {
    enable = true;
    
    # Authentication (use SOPS-encrypted key)
    authKeyFile = config.sops.secrets."tailscale-authkey".path;
    useAuthKeyFile = true;
    
    # Hostname
    hostname = "my-laptop"; # Change this to your laptop name
    
    # Client-only settings (no subnet routing or exit node)
    enableSubnetRouter = false;
    advertiseRoutes = [ ];
    exitNode = false;
    
    # Accept routes from other devices (to access home network)
    acceptRoutes = true;
    
    # DNS Configuration - optimized for mobile
    acceptDNS = true;
    enableMagicDNS = true;
    extraDNSServers = [
      "1.1.1.1"  # Cloudflare for fast fallback
      "8.8.8.8"  # Google DNS
    ];
    
    # Security
    shieldsUp = false;  # Allow connections from other Tailscale devices
    
    # Network settings
    openFirewall = true;
    trustedInterface = true;
    
    # Tags for ACL
    tags = [ "tag:client" "tag:laptop" ];
    
    # Performance - optimized for battery life
    enableConnectionPersistence = true;
    reconnectTimeout = 60;  # Longer timeout to save battery
    
    # Extra flags for laptop optimization
    extraUpFlags = [
      "--accept-routes"
      "--operator=${config.users.users.youruser.name}"  # Change to your username
    ];
  };
  
  # SOPS secrets
  kernelcore.secrets.tailscale = {
    enable = true;
    secretsFile = "/etc/nixos/secrets/tailscale.yaml";
  };
  
  # Power management optimization for Tailscale
  systemd.services.tailscaled.serviceConfig = {
    # Reduce CPU usage when on battery
    CPUQuota = "50%";
    MemoryMax = "256M";
  };
  
  # Laptop-specific aliases
  environment.shellAliases = {
    # Quick connect to home network
    ts-home = "sudo tailscale up --accept-routes --operator=$USER";
    
    # Disconnect to save battery
    ts-disconnect = "sudo tailscale down";
    
    # Use home desktop as exit node
    ts-exit-home = "sudo tailscale set --exit-node=kernelcore";  # Change to your desktop hostname
    
    # Reset exit node
    ts-exit-off = "sudo tailscale set --exit-node=";
    
    # Check battery-friendly status
    ts-status-mini = "tailscale status --json | jq -r '.Self | \"Host: \\(.HostName)\\nIP: \\(.TailscaleIPs[0])\\nOnline: \\(.Online)\"'";
  };
  
  # Firewall - minimal for laptop
  networking.firewall = {
    enable = true;
    # Only trust Tailscale interface
    trustedInterfaces = [ "tailscale0" ];
  };
  
  # Optional: Auto-connect on WiFi connection
  # Uncomment if you want automatic Tailscale connection
  # systemd.services.tailscale-auto-up = {
  #   description = "Auto-connect Tailscale on network up";
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.tailscale}/bin/tailscale up --accept-routes";
  #   };
  # };
  
  # Bandwidth optimization for metered connections
  environment.etc."tailscale/bandwidth-saver.sh" = {
    mode = "0755";
    text = ''
      #!/usr/bin/env bash
      # Bandwidth optimization for metered connections
      
      # Check if on metered connection (adjust detection as needed)
      if nmcli -t -f GENERAL.METERED dev show | grep -q yes; then
        echo "Metered connection detected - enabling bandwidth saving mode"
        
        # Reduce Tailscale MTU to save bandwidth
        sudo ip link set tailscale0 mtu 1280
        
        echo "Bandwidth saver enabled"
      else
        echo "Not on metered connection - using standard settings"
      fi
    '';
  };
}

# SETUP INSTRUCTIONS:
# ====================
# 
# 1. Copy Tailscale modules to your laptop's NixOS config directory
# 2. Set up SOPS secrets (see docs/guides/SETUP-SOPS-FINAL.md)
# 3. Add your Tailscale authkey to secrets/tailscale.yaml
# 4. Encrypt secrets: sops -e -i secrets/tailscale.yaml
# 5. Import this configuration in your configuration.nix
# 6. Rebuild: sudo nixos-rebuild switch
# 7. Check status: tailscale status
#
# ACCESSING HOME SERVICES:
# ========================
#
# Once connected, you can access your desktop services:
# - Ollama: http://ollama.kernelcore.your-tailnet.ts.net
# - LlamaCPP: http://llama.kernelcore.your-tailnet.ts.net  
# - PostgreSQL: db.kernelcore.your-tailnet.ts.net:5432
# - Gitea: https://git.kernelcore.your-tailnet.ts.net
#
# Or via Tailscale IP directly:
# - curl http://100.64.0.1:11434/api/tags  (adjust IP as needed)
#
# USING AS EXIT NODE:
# ===================
#
# Route all internet traffic through your home desktop:
# $ ts-exit-home
#
# To disable:
# $ ts-exit-off
#
# TROUBLESHOOTING:
# ================
#
# Check connection status:
# $ ts-status
#
# Test connectivity to desktop:
# $ tailscale ping kernelcore
#
# Check network quality:
# $ tailscale netcheck
#
# View logs:
# $ ts-logs