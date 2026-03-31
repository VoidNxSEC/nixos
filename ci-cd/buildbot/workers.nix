# TODO: Implement the Local CI Plan
# /etc/nixos/modules/services/ci/buildbot-workers.nix
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.ci;
  hasWorker = cfg.enable && builtins.elem cfg.role [
    "worker"
    "combined"
  ];
in
mkIf hasWorker {
  services.buildbot-worker =
    {
      enable = true;
      user = cfg.worker.systemUser;
      group = cfg.worker.systemGroup;
      extraGroups = cfg.worker.extraGroups;
      workerUser = cfg.worker.name;
      masterUrl = cfg.worker.masterUrl;
      hostMessage = cfg.worker.hostMessage;
      adminMessage = cfg.worker.adminMessage;
      packages = cfg.worker.packages;
    }
    // optionalAttrs (cfg.worker.passwordFile == null) {
      workerPass = cfg.worker.password;
    }
    // optionalAttrs (cfg.worker.passwordFile != null) {
      workerPassFile = cfg.worker.passwordFile;
    };

  # Worker-specific optimizations
  nix.settings = {
    # Build optimization for CI
    max-jobs = 4;
    cores = 0; # Use all available

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
      MemoryMax = cfg.worker.memoryMax;
      CPUQuota = cfg.worker.cpuQuota;
    };
  };

  nix.settings.trusted-users = mkAfter [ cfg.worker.systemUser ];
}
