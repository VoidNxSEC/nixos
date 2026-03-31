{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.security.tls;

  acmeServer =
    if cfg.useStaging then "https://acme-staging-v02.api.letsencrypt.org/directory" else cfg.server;

  certToAcme =
    _: cert:
    {
      inherit (cert) domain extraDomainNames reloadServices;
    }
    // optionalAttrs (cert.dnsProvider != null) { inherit (cert) dnsProvider; }
    // optionalAttrs (cert.environmentFile != null) { inherit (cert) environmentFile; }
    // optionalAttrs (cert.credentialFiles != { }) { inherit (cert) credentialFiles; }
    // optionalAttrs (cert.group != null) { inherit (cert) group; }
    // optionalAttrs (cert.webroot != null) { inherit (cert) webroot; };
in
{
  options.kernelcore.security.tls = {
    enable = mkEnableOption "Enable the repo-wide TLS foundation";

    mode = mkOption {
      type = types.enum [
        "public-acme"
        "internal-ca"
      ];
      default = "public-acme";
      description = ''
        TLS backend to compose around. `internal-ca` is reserved for a later
        phase and does not provision certificates yet.
      '';
    };

    email = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default ACME account email.";
    };

    dnsProvider = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "cloudflare";
      description = "Default ACME DNS challenge provider.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Optional ACME environment file carrying provider-specific credentials.
        This is the clean hand-off point from `kernelcore.secrets.certificates`.
      '';
    };

    credentialFiles = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        {
          "RFC2136_TSIG_SECRET_FILE" = config.sops.secrets."certificates/rfc2136-tsig".path;
        }
      '';
      description = ''
        Optional ACME credential files passed through systemd credentials.
        Use this when the selected DNS provider expects *_FILE variables.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "nginx";
      description = "Default group granted read access to issued certificates.";
    };

    server = mkOption {
      type = types.str;
      default = "https://acme-v02.api.letsencrypt.org/directory";
      description = "Default ACME directory endpoint.";
    };

    useStaging = mkOption {
      type = types.bool;
      default = false;
      description = "Use Let's Encrypt staging for certificate issuance tests.";
    };

    certs = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              domain = mkOption {
                type = types.str;
                default = name;
                description = "Primary domain for this certificate.";
              };

              extraDomainNames = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional SAN entries to include in this certificate.";
              };

              dnsProvider = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Per-certificate DNS challenge provider override.";
              };

              environmentFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Per-certificate ACME environment file override.";
              };

              credentialFiles = mkOption {
                type = types.attrsOf types.path;
                default = { };
                description = "Per-certificate ACME credential file overrides.";
              };

              group = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Per-certificate group override for certificate readability.";
              };

              reloadServices = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Services to reload or restart after renewal.";
              };

              webroot = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional HTTP-01 webroot override.";
              };
            };
          }
        )
      );
      default = { };
      example = literalExpression ''
        {
          "gitea.voidnx.com" = {
            extraDomainNames = [ "git.voidnx.com" ];
            reloadServices = [ "nginx.service" ];
          };
        }
      '';
      description = "Declared certificate inventory for the repo-wide TLS layer.";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.mode == "public-acme") {
      security.acme.acceptTerms = true;

      security.acme.defaults = {
        group = cfg.group;
        server = acmeServer;
      }
      // optionalAttrs (cfg.email != null) { inherit (cfg) email; }
      // optionalAttrs (cfg.dnsProvider != null) { inherit (cfg) dnsProvider; }
      // optionalAttrs (cfg.environmentFile != null) { inherit (cfg) environmentFile; }
      // optionalAttrs (cfg.credentialFiles != { }) { inherit (cfg) credentialFiles; };

      security.acme.certs = mapAttrs certToAcme cfg.certs;

      warnings =
        optional (
          cfg.email == null
        ) "kernelcore.security.tls.enable is true but no ACME account email is configured yet."
        ++ optional (
          cfg.certs == { }
        ) "kernelcore.security.tls.enable is true but no certificates are declared yet.";
    })

    (mkIf (cfg.enable && cfg.mode == "internal-ca") {
      warnings = [
        "kernelcore.security.tls.mode = \"internal-ca\" is reserved for a later phase; no internal CA wiring is active yet."
      ];
    })
  ];
}
