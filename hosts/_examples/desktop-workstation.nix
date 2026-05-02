{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# Example: Full Desktop Workstation
# ============================================================
# Starting point for a complete desktop NixOS system.
# Covers: Hyprland/Wayland, audio, development, ML, security.
#
# Usage:
#   1. Copy hardware-configuration.nix from nixos-generate-config
#   2. Create hosts/my-machine/configuration.nix:
#
#        { ... }:
#        {
#          imports = [
#            ./hardware-configuration.nix
#            ../_examples/desktop-workstation.nix
#          ];
#          networking.hostName = "my-machine";
#          system.user.username = "myusername";
#        }
#
#   3. Add to flake.nix nixosConfigurations and rebuild.
# ============================================================

{
  imports = [
    # ── Module categories — enable/disable as needed ──────
    ../../modules/system
    ../../modules/hardware
    ../../modules/audio
    ../../modules/security
    ../../modules/network
    ../../modules/services
    ../../modules/development
    ../../modules/containers
    ../../modules/desktop
    ../../modules/applications
    ../../modules/programs
    ../../modules/tools
    ../../modules/shell
    ../../modules/secrets

    # Optional — uncomment to enable:
    # ../../modules/ml         # ML/AI services (requires GPU)
    # ../../modules/blockchain # Crypto dev tools
    # ../../modules/devops     # CI/CD tooling
    # ../../modules/virtualization
  ];

  # ── Customize these for your machine ─────────────────────
  networking.hostName = "change-me"; # <── set your hostname
  system.user.username = "change-me"; # <── set your username

  time.timeZone = "UTC"; # e.g. "America/Sao_Paulo"
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # SSH: disabled by default, enable deliberately
  services.openssh.enable = lib.mkDefault false;

  system.stateVersion = "24.11";
}
