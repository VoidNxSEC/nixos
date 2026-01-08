# ============================================
# Gitea Module - reads from gitea.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.gitea;
in
{
  options.kernelcore.secrets.gitea = {
    enable = mkEnableOption "Enable Gitea secrets from SOPS (gitea.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt Gitea secrets from /etc/nixos/secrets/gitea.yaml
    sops.secrets = {
      # Cloudflare API Token (for DNS automation)
      "cloudflare-api-token" = {
        sopsFile = ../../secrets/gitea.yaml;
        mode = "0400";
        owner = "root";
        group = "root";
      };

      # Gitea Admin Token (for repository automation)
      "gitea-admin-token" = {
        sopsFile = ../../secrets/gitea.yaml;
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };
}
