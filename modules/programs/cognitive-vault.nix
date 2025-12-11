{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.cognitive-vault;
  # Dynamically import the package from local projects directory
  # We assume /etc/nixos is the root of the flake/config
  packageSource = ../../projects/cognitive-vault/default.nix;
  pkg = if builtins.pathExists packageSource 
        then pkgs.callPackage packageSource {}
        else pkgs.hello; # Fallback or error if project missing (shouldn't happen in this setup)
in {
  options.programs.cognitive-vault = {
    enable = mkEnableOption "CognitiveVault - Hybrid Secure Password Manager";

    package = mkOption {
      type = types.package;
      default = pkg;
      description = "The cognitive-vault package to install.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    
    # Add cvault to user shells
    environment.variables = {
      CV_VAULT_PATH = "$HOME/.vault.dat";
    };
  };
}
