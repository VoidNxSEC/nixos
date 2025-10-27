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
  };

  config = mkIf config.kernelcore.security.nix.enable {
    ##########################################################################
    # 🔒 Nix Daemon Security Hardening
    ##########################################################################

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

      substituters = [
        "https://cache.nixos.org/"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://pre-commit-hooks.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgBv/esm1uaNOQx3cUeBiPApBCNGLQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
      ];

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
      ];

      # Store optimization
      auto-optimise-store = true;
      warn-dirty = true;
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
  };
}
