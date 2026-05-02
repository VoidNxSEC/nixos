{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.security.hardening.apparmor.edr;
in
{
  options.security.hardening.apparmor.edr = {
    enable = mkEnableOption "EDR AppArmor Profiles";
  };

  config = mkIf cfg.enable {
    security.apparmor.enable = true;
    # AppArmor profiles for EDR components
  };
}
