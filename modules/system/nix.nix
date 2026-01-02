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
          # ULTRA-OPTIMIZED: Prevent CPU/RAM throttling and OOM
          # Reduced from max-jobs=4 cores=3 to prevent memory exhaustion
          # Using mkForce to override hardening.nix settings
          max-jobs = mkForce 4; # Only 2 parallel builds to prevent RAM overload
          cores = mkForce 4; # 2 cores per job (total 4 cores active)
          # Total concurrent threads: 2 jobs × 2 cores = 4 threads (was 12)

          # Kill builds that take too long (prevents zombie builds)
          # Increased to 3 hours for LLVM/Rust compilation (was 1h)
          timeout = mkDefault 10800; # 3 hours for ultra-heavy builds

          trusted-users = [
            "root"
            "@wheel"
            "kernelcore"
          ];

          # Aggressive cleanup to save disk space
          keep-derivations = mkDefault false; # Don't keep build dependencies (saves space)
          keep-outputs = mkDefault false; # Don't keep build outputs (saves space)

          # Auto-optimize store to save space via hardlinks
          auto-optimise-store = true;

          # Network timeout settings - increased for slow connections
          connect-timeout = mkDefault 30; # 30 seconds for connection (up from 5)
          stalled-download-timeout = mkDefault 300; # 5 minutes for stalled downloads (up from 30)

          # Limit parallel downloads to reduce network congestion
          http-connections = mkDefault 25; # Default is 25, but explicitly set

          # Enable aggressive substitution to avoid local builds
          substitute = true;
          builders-use-substitutes = true;

          # Allow local git+file URIs for development (avoids restricted mode errors)
          extra-allowed-uris = [
            "git+file:///home/kernelcore/dev/projects"
            "path:///home/kernelcore/dev/projects"
            "git+file:///home/kernelcore/dev/low-level"
            "path:///home/kernelcore/dev/low-level"
          ];
        }
      ];

      gc = {
        automatic = true;
        dates = "04:00"; # Run at 4 AM to avoid interfering with late night work
        options = "--delete-older-than 7d"; # Aggressive: delete after 7 days
        # Randomize GC time to avoid system load spikes
        randomizedDelaySec = "45min";
      };

      optimise = {
        automatic = true;
        dates = [ "03:45" ];
      };
    };
  };
}
