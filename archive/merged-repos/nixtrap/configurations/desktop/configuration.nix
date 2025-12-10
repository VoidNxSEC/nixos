# Desktop Configuration (i3 + distributed builds + cache)
# Based on nixtrap2 production setup

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

    # Import unified modules
    ../../modules/cache-server.nix
    ../../modules/cache-bucket-setup.nix
    ../../modules/nginx-module.nix
    ../../modules/offload-server.nix
    ../../modules/laptop-offload-client.nix
    ../../modules/mcp-offload-automation.nix
  ];

  # Basic system settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-desktop";
  networking.networkmanager.enable = true;

  # Time and locale
  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Memory optimization
  nix.settings = {
    auto-optimise-store = true;
    cores = 0;
    sandbox = true;
    builders-use-substitutes = true;
  };

  # ZRAM configuration
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # Kernel tuning
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # X11 and i3
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.lightdm.greeters.gtk.enable = true;
  services.xserver.windowManager.i3.enable = true;
  services.xserver.windowManager.i3.extraPackages = with pkgs; [
    rofi
    i3status
    i3lock
    i3blocks
  ];

  # Essential packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    neovim
    firefox
    alacritty
    htop
  ];

  # User configuration
  users.users.voidnx = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # SSH
  services.openssh.enable = true;

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "25.05";
}
