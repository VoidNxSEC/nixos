# /etc/nixos/modules/services/ci/buildbot-master.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.ci;
in
mkIf cfg.enable {
  services.buildbot-nix.master = {
    enable = true;
    domain = cfg.domain;

    # Web UI port
    port = 8010;

    # GitHub Integration
    github = {
      tokenFile = config.sops.secrets."ci/github_token".path;
      webhookSecretFile = config.sops.secrets."ci/github_webhook_secret".path;

      # Option 1: Topic-based discovery
      topic = "nix-ci"; # Repos with this topic get CI automatically

      # Option 2: Explicit repos (uncomment to use)
      # inputs = [
      #   "github:VoidNxLabs/swissknife"
      #   "github:VoidNxLabs/securellm-mcp"
      #   "github:VoidNxLabs/nixos"
      # ];
    };

    # Worker configuration
    workers = cfg.workers;

    # Build settings
    buildRetries = 1;
    evalMaxMemorySize = 4096; # MB for flake evaluation

    # Cachix integration
    cachix = {
      name = "marcosfpina";
      signingKeyFile = config.sops.secrets."ci/cachix_signing_key".path;
    };
  };
}
