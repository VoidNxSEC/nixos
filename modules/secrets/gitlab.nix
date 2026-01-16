# ============================================
# GitLab Module - reads from gitlab.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.gitlab;
in
{
  options.kernelcore.secrets.gitlab = {
    enable = mkEnableOption "Enable GitLab secrets from SOPS (gitlab.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt GitLab secrets from /etc/nixos/secrets/gitlab.yaml
    sops.secrets = {
      # GitLab Personal Access Token
      "gitlab_token" = {
        sopsFile = ../../secrets/gitlab.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # GitLab username (optional, for automation)
      "gitlab_username" = {
        sopsFile = ../../secrets/gitlab.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # GitLab email (optional, for automation)
      "gitlab_email" = {
        sopsFile = ../../secrets/gitlab.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };

    # Install GitLab CLI (glab)
    environment.systemPackages = with pkgs; [
      glab
    ];

    # Set GITLAB_TOKEN environment variable for the user
    # This makes the token available to glab and other tools
    # Usage: GITLAB_TOKEN=$(cat $GITLAB_TOKEN_FILE)
    environment.variables = {
      GITLAB_TOKEN_FILE = config.sops.secrets.gitlab_token.path;
    };
  };
}
