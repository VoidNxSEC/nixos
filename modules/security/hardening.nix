{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  imports = [
    ./nix-daemon.nix
    ./pam.nix
    ./ssh.nix
    ./kernel.nix
    ./audit.nix
    ./aide.nix
    ./clamav.nix
    ./packages.nix
    ./auto-upgrade.nix
  ];

  options = {
    kernelcore.security.hardening.enable = mkEnableOption "Enable security hardening (master switch)";
  };

  config = mkIf config.kernelcore.security.hardening.enable {
    # Enable all sub-modules
    kernelcore.security.nix.enable = mkDefault true;
    kernelcore.security.pam.enable = mkDefault true;
    kernelcore.security.ssh.enable = mkDefault true;
    kernelcore.security.kernel.enable = mkDefault true;
    kernelcore.security.audit.enable = mkDefault true;
    kernelcore.security.aide.enable = mkDefault true; # Optional - intrusion detection
    kernelcore.security.clamav.enable = mkDefault true; # Optional - antivirus
    kernelcore.security.packages.enable = mkDefault true;
    kernelcore.security.auto-upgrade.enable = mkDefault false; # Optional

    # Note: Removed service disabling (avahi, printing) to avoid conflicts
    # These can be disabled manually in configuration.nix if needed
  };
}
