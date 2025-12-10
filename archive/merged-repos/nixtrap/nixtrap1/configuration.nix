# Example NixOS Configuration for Cache Server
# This is a traditional configuration.nix example (non-flake)
#
# To use the flake-based approach, see templates/ directory

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan
    ./hardware-configuration.nix

    # Import cache server modules
    ./modules/cache-server.nix
    ./modules/api-server.nix
    ./modules/monitoring.nix
  ];

  # ============================================================================
  # Cache Server Configuration
  # ============================================================================

  services.nixos-cache-server = {
    enable = true;
    hostName = "cache.local";
    port = 5000;
    priority = 40;

    enableTLS = true;
    enableMonitoring = true;

    workers = 4;

    storage = {
      maxSize = "100G";
      gcKeepOutputs = true;
      gcKeepDerivations = true;
      autoOptimise = true;
    };

    # SSL configuration (generates self-signed by default)
    ssl = {
      certificatePath = null; # Use auto-generated
      keyPath = null;
    };
  };

  # ============================================================================
  # API Server Configuration
  # ============================================================================

  services.nixos-cache-api = {
    enable = true;
    port = 8080;
    logFile = "/var/log/nixos-cache-api.log";
    openFirewall = false; # Keep internal only
  };

  # ============================================================================
  # Monitoring Configuration
  # ============================================================================

  services.nixos-cache-monitoring = {
    enable = true;

    enablePrometheus = true;
    enableNodeExporter = true;
    enableNginxExporter = true;
    enableGrafana = false; # Set to true for Grafana dashboards

    prometheus = {
      port = 9090;
      retention = "30d";
      scrapeInterval = "15s";
    };

    nodeExporter = {
      port = 9100;
      enabledCollectors = [
        "systemd"
        "cpu"
        "meminfo"
        "diskstats"
        "filesystem"
        "netdev"
        "loadavg"
      ];
    };

    openFirewall = false; # Access via SSH tunnel for security
  };

  # ============================================================================
  # Boot Configuration
  # ============================================================================

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # Change to your boot device
  };

  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = "nixos-cache";
    useDHCP = false;
    interfaces.eth0.useDHCP = true; # Adjust interface name

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        443 # HTTPS for cache
      ];
    };
  };

  # ============================================================================
  # Localization
  # ============================================================================

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================================
  # Users
  # ============================================================================

  users.users.admin = {
    isNormalUser = true;
    description = "System Administrator";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-ed25519 AAAAC3... user@host"
    ];
  };

  # ============================================================================
  # SSH Configuration
  # ============================================================================

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # ============================================================================
  # Nix Configuration
  # ============================================================================

  nix = {
    settings = {
      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Trusted users
      trusted-users = [
        "root"
        "@wheel"
      ];

      # Default substituters
      substituters = [ "https://cache.nixos.org" ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };

  # ============================================================================
  # System Packages
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    git
    curl
    wget
    htop
    tree
    jq

    # Network tools
    netcat
    nmap
    tcpdump

    # Monitoring tools
    sysstat
    iotop
    nethogs

    # Development tools
    tmux
    screen
  ];

  # ============================================================================
  # System Version
  # ============================================================================

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
