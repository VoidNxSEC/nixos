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
          # Optimized for 8-core/12-thread laptop to prevent CPU thrashing
          # max-jobs × cores should not exceed total CPU threads
          max-jobs = mkDefault 4; # Parallel build jobs (was "auto" = 12)
          cores = mkDefault 3; # Cores per job (was 0 = use all 12)

          trusted-users = [
            "root"
            "@wheel"
          ];

          keep-derivations = true;
          keep-outputs = true;

          auto-optimise-store = true;

          # Network timeout settings - increased for slow connections
          connect-timeout = mkDefault 30; # 30 seconds for connection (up from 5)
          stalled-download-timeout = mkDefault 300; # 5 minutes for stalled downloads (up from 30)
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
