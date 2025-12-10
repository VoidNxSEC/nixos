# Hybrid Configuration
# Desktop + Cache Server + Distributed Builds
# Best of both nixtrap1 and nixtrap2

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Import your hardware configuration
    ./hardware-configuration.nix

    # Note: Unified modules are imported via nixosModules.hybrid-full in flake.nix
    # No need to import them again here
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel tuning for performance
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };

  # Networking
  networking.hostName = "nixos-hybrid";
  networking.networkmanager.enable = true;

  # Time and locale
  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Nix configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    cores = 0; # Use all cores
    sandbox = true;
    builders-use-substitutes = true;
    max-jobs = "auto";
  };

  # ZRAM for memory optimization
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # X11 and i3
  services.xserver = {
    enable = true;
    displayManager.lightdm = {
      enable = true;
      greeters.gtk.enable = true;
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
        rofi
        alacritty
      ];
    };
  };

  # Essential desktop packages
  environment.systemPackages = with pkgs; [
    # Terminal and editors
    alacritty
    neovim
    git

    # Browsers
    firefox
    vivaldi

    # File management
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-archive-plugin

    # System utilities
    wget
    curl
    htop
    btop
    ncdu
    tree
    jq
    rsync

    # Development
    cmake
    ninja
    gcc
    python3

    # Cache management
    openssl

    # Monitoring
    iftop
    nethogs
  ];

  # User configuration
  users.users.voidnx = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.bash;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Services
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
      5000
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Auto-upgrade (optional)
  # system.autoUpgrade = {
  #   enable = true;
  #   dates = "weekly";
  #   allowReboot = false;
  # };

  system.stateVersion = "25.05";
}
