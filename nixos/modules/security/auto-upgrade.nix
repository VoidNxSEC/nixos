{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.auto-upgrade.enable = mkEnableOption "Enable automatic system updates";
  };

  config = mkIf config.kernelcore.security.auto-upgrade.enable {
    ##########################################################################
    # 🔄 Automatic System Updates
    ##########################################################################

    system.autoUpgrade = {
      enable = true;
      allowReboot = false;
      dates = "04:00";

      # Local flake-based system (not using remote flakes due to confidentiality)
      flake = "/etc/nixos#kernelcore";

      flags = [
        "--update-input"
        "nixpkgs"
        "--no-write-lock-file"
        "--print-build-logs"
        "--show-trace"
      ];
    };
  };
}
