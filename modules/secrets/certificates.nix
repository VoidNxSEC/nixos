# ============================================
# Certificates Module - reads from certificates.yaml
# ============================================
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.certificates;
  legacyCloudflareSecretsFile = ../../secrets/gitea.yaml;
in
{
  options.kernelcore.secrets.certificates = {
    enable = mkEnableOption "Enable TLS/ACME certificate secrets from SOPS (certificates.yaml)";

    secretsFile = mkOption {
      type = types.str;
      default = "/etc/nixos/secrets/certificates.yaml";
      description = "Path to the SOPS-encrypted certificates secrets file.";
    };

    environmentSecretName = mkOption {
      type = types.str;
      default = "certificates/dns-provider-env";
      description = ''
        Secret name containing a full ACME environment file with provider-specific
        variables for DNS-01 challenge automation.
      '';
    };

    cloudflareTokenSecretName = mkOption {
      type = types.str;
      default = "certificates/cloudflare-dns-api-token";
      description = ''
        Secret name for the Cloudflare DNS API token consumed by ACME DNS-01.
      '';
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && pathExists cfg.secretsFile) {
      sops.secrets = {
        ${cfg.environmentSecretName} = {
          sopsFile = cfg.secretsFile;
          key = "dns_provider_env";
          mode = "0400";
          owner = "root";
          group = "root";
        };

        ${cfg.cloudflareTokenSecretName} = {
          sopsFile = cfg.secretsFile;
          key = "cloudflare_dns_api_token";
          mode = "0400";
          owner = "root";
          group = "root";
        };
      };
    })

    (mkIf (cfg.enable && !pathExists cfg.secretsFile && pathExists legacyCloudflareSecretsFile) {
      sops.secrets = {
        ${cfg.environmentSecretName} = {
          sopsFile = legacyCloudflareSecretsFile;
          key = "dns_provider_env";
          mode = "0400";
          owner = "root";
          group = "root";
        };

        ${cfg.cloudflareTokenSecretName} = {
          sopsFile = legacyCloudflareSecretsFile;
          key = "cloudflare-api-token";
          mode = "0400";
          owner = "root";
          group = "root";
        };
      };

      warnings = [
        "kernelcore.secrets.certificates.enable is using the legacy Cloudflare token from ${legacyCloudflareSecretsFile}; migrate it to ${cfg.secretsFile}."
      ];
    })

    (mkIf (cfg.enable && !pathExists cfg.secretsFile && !pathExists legacyCloudflareSecretsFile) {
      warnings = [
        "kernelcore.secrets.certificates.enable is true but neither ${cfg.secretsFile} nor ${legacyCloudflareSecretsFile} exists yet."
      ];
    })
  ];
}
