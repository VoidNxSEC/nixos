{ config, pkgs, ... }:

{
  # Choose your features from the framework
  # kernelcore.system.nix.optimizations.enable = true;
  # kernelcore.security.hardening.enable = true;

  # Basic system settings
  networking.hostName = "minimal";
  time.timeZone = "UTC";

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05";
}
