{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.nix.enable = mkEnableOption "Enable Nix daemon security hardening";

    kernelcore.security.sandbox-fallback = mkOption {
      type = types.bool;
      default = false;
      description = "Allow Nix sandbox fallback (less secure but more compatible)";
    };

    kernelcore.security.nix.primaryCache = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional primary binary cache URL that should be tried before the default caches.
        Example: "http://192.168.15.6:5000".
      '';
    };

    kernelcore.security.nix.primaryCacheKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Public signing key for the primary cache defined in primaryCache.
        Example: "cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=".
      '';
    };

    kernelcore.security.nix.extraSubstituters = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional substituters appended after the default cache list.";
    };

    kernelcore.security.nix.extraTrustedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Signing keys that correspond to entries in extraSubstituters.";
    };

    kernelcore.security.nix.connectTimeout = mkOption {
      type = types.int;
      default = 5;
      description = "Seconds to wait before falling back to the next substituter.";
    };

    kernelcore.security.nix.stalledDownloadTimeout = mkOption {
      type = types.int;
      default = 30;
      description = "Seconds before a stalled download is abandoned.";
    };
  };

  config = mkIf config.kernelcore.security.nix.enable (
    ##########################################################################
    # 🔒 Nix Daemon Security Hardening
    ##########################################################################

    let
      defaultSubstituters = [
        "https://cache.nixos.org/"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://pre-commit-hooks.cachix.org"
      ];

      defaultTrustedKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgBv/esm1uaNOQx3cUeBiPApBCNGLQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
      ];

      primaryCacheList = lib.optionals (config.kernelcore.security.nix.primaryCache != null) [
        config.kernelcore.security.nix.primaryCache
      ];

      primaryCacheKeys = lib.optionals (config.kernelcore.security.nix.primaryCacheKey != null) [
        config.kernelcore.security.nix.primaryCacheKey
      ];

      # Ensure we do not add empty strings to the allow list
      sanitizeUris = builtins.filter (uri: uri != "");
    in
    {
      nix.settings = {
        # Build isolation
        sandbox = mkForce true;
        sandbox-fallback = mkForce config.kernelcore.security.sandbox-fallback;
        restrict-eval = mkForce true;

        # Trusted users and build configuration
        trusted-users = [ "@wheel" ];
        allowed-users = [ "@users" ];
        build-users-group = "nixbld";
        max-jobs = mkDefault "auto";
        cores = mkDefault 0;

        # Binary cache security
        require-sigs = true;

        substituters =
          primaryCacheList ++ defaultSubstituters ++ config.kernelcore.security.nix.extraSubstituters;

        trusted-public-keys =
          primaryCacheKeys ++ defaultTrustedKeys ++ config.kernelcore.security.nix.extraTrustedKeys;

        # Allowed URIs for fetchers
        allowed-uris = [
          "github:"
          "git+https://github.com/"
          "git+ssh://git@github.com/"
          "https://github.com/"
          "https://gitlab.com/"
          "https://nixos.org/"
          "https://cache.nixos.org/"
          "https://developer.downloads.nvidia.com/"
          "https://cuda-maintainers.cachix.org"
          "https://nix-community.cachix.org"
        ]
        ++ sanitizeUris (primaryCacheList ++ config.kernelcore.security.nix.extraSubstituters);

        # Store optimization
        auto-optimise-store = true;
        warn-dirty = true;

        connect-timeout = mkDefault config.kernelcore.security.nix.connectTimeout;
        stalled-download-timeout = mkDefault config.kernelcore.security.nix.stalledDownloadTimeout;
      };

      # Package security policies
      nixpkgs.config = {
        allowUnfree = true;
        allowBroken = false;
        allowInsecure = false;
        permittedInsecurePackages = [
          # Add specific packages if needed
        ];
      };
    }
  );
}
