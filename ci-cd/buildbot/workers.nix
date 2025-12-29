/* TODO: Implement the Local CI Plan */
# /etc/nixos/modules/services/ci/buildbot-workers.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.kernelcore.ci;
in mkIf cfg.enable {
  # Worker-specific optimizations
  nix.settings = {
    # Build optimization for CI
    max-jobs = 4;
    cores = 0;  # Use all available
    
    # Faster builds
    keep-outputs = true;
    keep-derivations = true;
    
    # Binary caches
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://marcosfpina.cachix.org"
    ];
    
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # Add your cachix key here
    ];
  };
  
  # Resource limits for builds
  systemd.services.buildbot-worker = {
    serviceConfig = {
      MemoryMax = "8G";
      CPUQuota = "400%";  # 4 cores
    };
  };
}