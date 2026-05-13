# GitLab Secrets Configuration via SOPS
# This module loads GitLab secrets and makes them available as environment variables
#
# Usage: Import in /etc/nixos/configuration.nix or home-manager config

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ═══════════════════════════════════════════════════════════════
  # SOPS GitLab Secrets
  # ═══════════════════════════════════════════════════════════════

  sops.secrets.gitlab-token = {
    sopsFile = /etc/nixos/secrets/gitlab.yaml;
    path = "/run/secrets/gitlab-token";
    owner = "kernelcore";
    mode = "0400";
  };

  # ═══════════════════════════════════════════════════════════════
  # Environment Variables for GitLab CLI/API
  # ═══════════════════════════════════════════════════════════════

  environment.sessionVariables = {
    # GitLab CLI (glab) uses this environment variable
    GITLAB_TOKEN = "$(cat ${config.sops.secrets.gitlab-token.path})";

    # Alternative variable names used by some tools
    GL_TOKEN = "$(cat ${config.sops.secrets.gitlab-token.path})";
  };

  # ═══════════════════════════════════════════════════════════════
  # GitLab CLI Tool (glab)
  # ═══════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    glab # GitLab CLI tool
    git # Git with GitLab integration
  ];

  # ═══════════════════════════════════════════════════════════════
  # Git Configuration with GitLab Token
  # ═══════════════════════════════════════════════════════════════

  programs.git = {
    enable = true;

    extraConfig = {
      # GitLab URL rewrite (already in git.nix, but reinforcing here)
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";

      # GitLab-specific settings
      gitlab.user = "marcosfpina";

      # Credential helper for HTTPS (uses token from environment)
      credential."https://gitlab.com".helper = "store";
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # GitLab Runner Configuration (Optional)
  # ═══════════════════════════════════════════════════════════════

  # Uncomment if you want to run GitLab CI/CD runners locally
  # services.gitlab-runner = {
  #   enable = true;
  #   services = {
  #     cerebro-runner = {
  #       registrationConfigFile = config.sops.secrets.gitlab-runner.path;
  #       dockerImage = "nixos/nix:latest";
  #       tagList = [ "nix" "nixos" "cerebro" ];
  #     };
  #   };
  # };
}
