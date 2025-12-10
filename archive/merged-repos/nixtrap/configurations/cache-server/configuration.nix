# Dedicated Cache Server Configuration
# Enterprise-grade binary cache with monitoring

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Import your hardware configuration
    # ./hardware-configuration.nix
  ];

  # Enable unified cache server module
  services.nixos-cache-server = {
    enable = true;
    hostName = "cache.example.com";
    bindAddress = "0.0.0.0"; # Listen on all interfaces
    port = 5000;
    priority = 40;

    # Enable TLS
    enableTLS = true;
    ssl = {
      enableHTTP = false; # Force HTTPS only
      # certificatePath = /path/to/cert.pem; # Use Let's Encrypt in production
      # keyPath = /path/to/key.pem;
    };

    # Enable monitoring
    enableMonitoring = true;

    # Resource limits
    workers = 8;
    resources = {
      memoryMax = "4G";
      memoryHigh = "3.5G";
      cpuQuota = "400%"; # 4 cores
      tasksMax = 100;
    };

    # Storage configuration
    storage = {
      maxSize = "500G";
      gcKeepOutputs = true;
      gcKeepDerivations = true;
      autoOptimise = true;
    };
  };

  # Basic system configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "nixos-cache";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    max-jobs = "auto";
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    ncdu
    jq
  ];

  # SSH for remote management
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Firewall - only HTTPS and SSH
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      443
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "24.11";
}
