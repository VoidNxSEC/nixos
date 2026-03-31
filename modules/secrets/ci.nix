{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.ci;
in
{
  options.kernelcore.secrets.ci = {
    enable = mkEnableOption "Enable CI secrets from SOPS-backed repository secrets";

    secretsFile = mkOption {
      type = types.path;
      default = ../../secrets/github.yaml;
      description = "Path to the SOPS-encrypted CI secrets file.";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = mkIf (pathExists cfg.secretsFile) {
      "ci/buildbot-worker-password" = {
        sopsFile = cfg.secretsFile;
        key = "buildbot_worker_password";
        mode = "0440";
        owner = "buildbot";
        group = "buildbot";
      };

      "ci/github-token" = {
        sopsFile = cfg.secretsFile;
        key = "github_token";
        mode = "0440";
        owner = "buildbot";
        group = "buildbot";
      };

      "ci/github-webhook-secret" = {
        sopsFile = cfg.secretsFile;
        key = "github_webhook_secret";
        mode = "0440";
        owner = "buildbot";
        group = "buildbot";
      };

      "ci/cachix-auth-token" = {
        sopsFile = cfg.secretsFile;
        key = "cachix_auth_token";
        mode = "0440";
        owner = "buildbot";
        group = "buildbot";
      };
    };

    warnings = optional (
      !pathExists cfg.secretsFile
    ) "kernelcore.secrets.ci.enable is true but ${cfg.secretsFile} does not exist yet.";
  };
}
