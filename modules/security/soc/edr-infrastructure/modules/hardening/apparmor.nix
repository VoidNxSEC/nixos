{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc.edr.hardening.apparmor;
in
{
  options.kernelcore.soc.edr.hardening.apparmor = {
    enable = mkEnableOption "EDR AppArmor Profiles";
  };

  config = mkIf cfg.enable {
    security.apparmor.enable = true;
    # AppArmor profiles for EDR components
  };
}
