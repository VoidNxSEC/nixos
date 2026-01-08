# ============================================
# GitHub Module - reads from github.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.github;
in
{
  options.kernelcore.secrets.github = {
    enable = mkEnableOption "Enable GitHub secrets from SOPS (github.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt GitHub secrets from /etc/nixos/secrets/github.yaml
    sops.secrets = {
      # GitHub Personal Access Token
      "github_token" = {
        sopsFile = ../../secrets/github.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };
  };
}
