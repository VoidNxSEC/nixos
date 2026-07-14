{ config, lib, ... }:

# ============================================================
# NixOS Specialisation Aliases
#
# Switching: activates a specialisation without reboot.
# Base:      returns to the base system config.
# ============================================================

{
  # Gate da Fase 4: config era incondicional; default true preserva o
  # sistema como está e permite desligar por host/specialisation.
  options.kernelcore.shell.aliases.specialisations.enable =
    lib.mkEnableOption "specialisation aliases"
    // {
      default = true;
    };

  config = lib.mkIf config.kernelcore.shell.aliases.specialisations.enable {
    environment.shellAliases = {
      # ── Status ────────────────────────────────────────────────────────────────
      # List available specialisations
      "nx-spec-list" =
        "ls /run/current-system/specialisation/ 2>/dev/null || echo 'No specialisations built yet'";

      # Show active specialisation (tag embedded in nixos-version)
      "nx-spec-status" = "nixos-version";

      # ── Switch to specialisation ───────────────────────────────────────────────
      "nx-spec-dev" =
        "sudo /run/current-system/specialisation/development/bin/switch-to-configuration switch";
      "nx-spec-k8s" =
        "sudo /run/current-system/specialisation/k8s-lab/bin/switch-to-configuration switch";
      "nx-spec-sec" =
        "sudo /run/current-system/specialisation/cybersecurity/bin/switch-to-configuration switch";
      "nx-spec-priv" =
        "sudo /run/current-system/specialisation/privacy-paranoia/bin/switch-to-configuration switch";
      "nx-spec-emer" =
        "sudo /run/current-system/specialisation/emergency/bin/switch-to-configuration switch";

      # ── Return to base ────────────────────────────────────────────────────────
      "nx-spec-base" = "sudo /run/current-system/bin/switch-to-configuration switch";
    };
  };
}
