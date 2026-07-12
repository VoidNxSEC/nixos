{ config, ... }:

# ═══════════════════════════════════════════════════════════
# SEGURANÇA — hardening, TLS/ACME, AIDE, keyring, SOC, secrets
# ═══════════════════════════════════════════════════════════

{
  kernelcore.security = {
    hardening.enable = true;
    sandbox-fallback = true;
    audit.enable = true;
    tls = {
      enable = true;
      email = "sec@voidnxlabs.com";
      dnsProvider = "cloudflare";
      environmentFile =
        if config.sops.secrets ? "certificates/dns-provider-env" then
          config.sops.secrets."certificates/dns-provider-env".path
        else
          null;
      credentialFiles =
        if config.sops.secrets ? "certificates/cloudflare-dns-api-token" then
          {
            "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."certificates/cloudflare-dns-api-token".path;
            "CF_ZONE_API_TOKEN_FILE" = config.sops.secrets."certificates/cloudflare-dns-api-token".path;
          }
        else
          { };
      certs = {
        "gitea.voidnx.com" = {
          extraDomainNames = [ "git.voidnx.com" ];
          reloadServices = [ "nginx.service" ];
        };
      };
    };

    # HIGH PRIORITY SECURITY ENHANCEMENTS
    aide.enable = true;
    clamav.enable = false;
    ssh.enable = true;
    kernel.enable = true;
    pam.enable = true;
    packages.enable = true;

    # OS Keyring
    keyring = {
      enable = true;
      enableGUI = true;
      enableKeePassXCIntegration = true;
      autoUnlock = true;
    };
  };

  # Config declarativa de cliente SSH (ex-kernelcore.ssh)
  kernelcore.system.ssh.enable = true;

  kernelcore.soc = {
    enable = false;
    profile = "minimal";
    retention.days = 30;
    ids.suricata.enable = false;
    alerting = {
      enable = true;
      minSeverity = "medium";
    };
  };

  # ── Secrets (SOPS) ──
  kernelcore.secrets.sops = {
    enable = false; # PENDENTE: reativar após importar age key para /var/lib/sops-nix/key.txt
    secretsPath = "/etc/nixos/secrets";
    ageKeyFile = "/var/lib/sops-nix/key.txt";
  };

  # PENDENTE: reativar após restaurar venus (secrets repo) e age key SOPS
  kernelcore.secrets.github.enable = false;
  kernelcore.secrets.ci.enable = false;
  kernelcore.secrets.certificates.enable = false;
  kernelcore.secrets.gcp-ml.enable = false;
  kernelcore.secrets.aws-bedrock.enable = false;
  kernelcore.secrets.blockchain.enable = false;
  kernelcore.secrets.k8s.enable = false;
  kernelcore.secrets.grok.enable = false;
  kernelcore.secrets.gitlab.enable = false;
  kernelcore.secrets.api-keys.enable = false;
  kernelcore.secrets.forgejo.enable = false;
}
