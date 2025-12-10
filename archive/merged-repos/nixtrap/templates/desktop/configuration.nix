{ config, pkgs, ... }:

{
  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "my-desktop";
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "America/New_York"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.youruser = {
    # Change to your username
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
