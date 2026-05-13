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
      # Buildbot worker password — kept for backwards compat, root-owned
      "ci/buildbot-worker-password" = {
        sopsFile = cfg.secretsFile;
        key = "buildbot_worker_password";
        mode = "0400";
      };

      # GitHub webhook secret — used by CI ingress / buildbot webhook handler
      "ci/github-webhook-secret" = {
        sopsFile = cfg.secretsFile;
        key = "github_webhook_secret";
        mode = "0400";
      };
    };

    warnings = optional (
      !pathExists cfg.secretsFile
    ) "kernelcore.secrets.ci.enable is true but ${cfg.secretsFile} does not exist yet.";
  };
}
