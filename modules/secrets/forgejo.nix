# ============================================
# Forgejo Secrets Module - reads from forgejo.yaml
# ============================================
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.forgejo;
  secretsFile = ../../secrets/forgejo.yaml;
  secretsFileExists = pathExists secretsFile;
in
{
  options.kernelcore.secrets.forgejo = {
    enable = mkEnableOption "Enable Forgejo secrets from SOPS (forgejo.yaml)";
  };

  config = mkMerge [
    (mkIf (cfg.enable && secretsFileExists) {
      sops.secrets = {
        "forgejo/db-password" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };

        "forgejo/secret-key" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };

        "forgejo/internal-token" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };

        "forgejo/oauth2-jwt-secret" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };

        "forgejo/lfs-jwt-secret" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };

        "forgejo/runner-token" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "root";
          group = "root";
        };

        "forgejo/smtp-password" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "root";
          group = "root";
        };

        "forgejo/restic-password" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "root";
          group = "root";
        };

        "forgejo/admin-username" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };

        "forgejo/admin-password" = {
          sopsFile = secretsFile;
          mode = "0400";
          owner = "forgejo";
          group = "forgejo";
        };
      };
    })

    (mkIf (cfg.enable && !secretsFileExists) {
      warnings = [
        "kernelcore.secrets.forgejo.enable is true but /etc/nixos/secrets/forgejo.yaml does not exist yet."
      ];
    })
  ];
}
