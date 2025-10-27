{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.system.nix = {
      optimizations.enable = mkEnableOption "Enable Nix daemon optimizations";
      experimental-features.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable experimental Nix features (flakes, nix-command)";
      };
    };
  };

  config = mkIf config.kernelcore.system.nix.optimizations.enable {
    nix = {
      package = pkgs.nixVersions.latest;

      # Fix NIX_PATH warning: use flake nixpkgs instead of non-existent channels
      nixPath = [ "nixpkgs=${pkgs.path}" ];

      settings = mkMerge [
        (mkIf config.kernelcore.system.nix.experimental-features.enable {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        })

        {
          max-jobs = mkDefault "auto";
          cores = mkDefault 0;

          trusted-users = [
            "root"
            "@wheel"
          ];

          keep-derivations = true;
          keep-outputs = true;

          auto-optimise-store = true;
        }
      ];

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      optimise = {
        automatic = true;
        dates = [ "03:45" ];
      };
    };
  };
}
