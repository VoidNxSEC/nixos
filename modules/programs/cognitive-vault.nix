# CognitiveVault Module (DISABLED - project moved externally)
# Re-enable when cognitive-vault is available as flake input
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.cognitive-vault;
in
{
  options.programs.cognitive-vault = {
    enable = mkEnableOption "CognitiveVault - Hybrid Secure Password Manager";
    package = mkOption {
      type = types.package;
      default = pkgs.cognitive-vault; # Placeholder until flake input available
      description = "The cognitive-vault package to install.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    environment.variables = {
      CV_VAULT_PATH = "$HOME/.vault.dat";
    };
  };
}
