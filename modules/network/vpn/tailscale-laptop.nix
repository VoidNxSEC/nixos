# Tailscale Configuration for Laptop (kernelcore)
# Auto-configured for mobile development workstation
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Import base Tailscale module
  imports = [ ./tailscale.nix ];

  # Laptop-specific Tailscale configuration
  kernelcore.network.vpn.tailscale = {
    enable = true;

    # Device Identity
    hostname = "laptop-kernelcore"; # Nome bonito no Tailscale

    # Network Mode: CLIENT
    # Laptop aceita rotas mas NÃO compartilha rede local
    # (Mobile device - rede muda frequentemente)
    enableSubnetRouter = lib.mkForce false; # Force: override tailscale-services
    advertiseRoutes = lib.mkForce [ ]; # Force: no routes to advertise

    # Accept routes from Desktop (home network)
    acceptRoutes = lib.mkDefault true;

    # DNS Configuration
    acceptDNS = true; # MagicDNS (usar hostnames)
    enableMagicDNS = true;

    # SSH over Tailscale
    enableSSH = true;

    # Security
    shieldsUp = false; # Allow connections from other devices

    # Performance
    enableConnectionPersistence = true;
    reconnectTimeout = 30;

    # Firewall
    openFirewall = true;
    trustedInterface = true;

    # Auto-start on boot
    autoStart = true;

    # Optional: Add tags for ACL management
    tags = [
      "tag:laptop"
      "tag:dev"
    ];

    # Extra flags if needed
    extraUpFlags = [
      # Add any extra flags here
      # Example: "--operator=kernelcore"
    ];
  };

  # Laptop-specific environment
  environment.shellAliases = {
    # Quick access to desktop via Tailscale
    ssh-desktop = lib.mkForce "ssh desktop-home"; # Prefer Tailscale host over LAN alias

    # Check if desktop is reachable
    ping-desktop = "${pkgs.tailscale}/bin/tailscale ping desktop-home";

    # Show all Tailscale devices
    ts-devices = "${pkgs.tailscale}/bin/tailscale status --peers";

    # Quick connect check
    ts-check = ''
      echo "🔍 Checking Tailscale connectivity..." && \
      echo "" && \
      echo "📱 This laptop:" && \
      ${pkgs.tailscale}/bin/tailscale status | grep $(hostname) && \
      echo "" && \
      echo "🖥️  Available devices:" && \
      ${pkgs.tailscale}/bin/tailscale status --peers | head -5
    '';
  };

  # Helpful reminder on login
  environment.interactiveShellInit = ''
    # Show Tailscale status on shell start (only if connected)
    if systemctl is-active --quiet tailscaled 2>/dev/null; then
      TSIP=$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null || echo "")
      if [ -n "$TSIP" ]; then
        echo "🌐 Tailscale connected: $TSIP"
      fi
    fi
  '';
}
