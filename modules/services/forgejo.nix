{
  config,
  lib,
  pkgs, # ADICIONADO PKGS AQUI
  ...
}:

with lib;

let
  cfg = config.services.forgejo;
  publicUrl = removeSuffix "/" (
    if cfg.integration.publicUrl != null then
      cfg.integration.publicUrl
    else if cfg.integration.proxy.enable || cfg.integration.tls.enable then
      "https://${cfg.integration.publicDomain}/"
    else
      "http://${cfg.integration.listenAddress}:${toString cfg.integration.listenPort}/"
  );
in
{
  options.services.forgejo.integration.appName = mkOption {
    type = types.str;
    default = "Forgejo";
    description = "Application title exposed by Forgejo.";
  };

  options.services.forgejo.integration.publicDomain = mkOption {
    type = types.str;
    default = "forgejo.local";
    description = "Public hostname advertised by Forgejo.";
  };

  options.services.forgejo.integration.publicUrl = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Optional explicit public URL override.";
  };

  options.services.forgejo.integration.listenAddress = mkOption {
    type = types.str;
    default = "127.0.0.1";
    description = "Local bind address for the Forgejo HTTP listener.";
  };

  options.services.forgejo.integration.listenPort = mkOption {
    type = types.port;
    default = 3002;
    description = "Local Forgejo HTTP port.";
  };

  options.services.forgejo.integration.disableRegistration = mkOption {
    type = types.bool;
    default = true;
    description = "Disable self-service account registration.";
  };

  options.services.forgejo.integration.proxy.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Expose Forgejo through the central NGINX public proxy.";
  };

  options.services.forgejo.integration.proxy.maxBodySize = mkOption {
    type = types.str;
    default = "200M";
    description = "Client body size limit for the public NGINX upstream.";
  };

  options.services.forgejo.integration.proxy.enableWebSocket = mkOption {
    type = types.bool;
    default = true;
    description = "Enable WebSocket proxying for the public NGINX upstream.";
  };

  options.services.forgejo.integration.tls.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Register the Forgejo hostname in the central TLS certificate inventory.";
  };

  options.services.forgejo.integration.tls.extraDomainNames = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Additional SAN entries for the Forgejo certificate.";
  };

  options.services.forgejo.integration.tls.reloadServices = mkOption {
    type = types.listOf types.str;
    default = [ "nginx.service" ];
    description = "Services reloaded after certificate renewal.";
  };

  options.services.forgejo.integration.integratedSsh.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Forgejo's built-in SSH server.";
  };

  options.services.forgejo.integration.integratedSsh.port = mkOption {
    type = types.port;
    default = 22;
    description = "Public SSH port advertised by Forgejo.";
  };

  options.services.forgejo.integration.integratedSsh.listenPort = mkOption {
    type = types.port;
    default = 2222;
    description = "Local SSH listen port when the built-in SSH server is enabled.";
  };

  options.services.forgejo.integration.database.type = mkOption {
    type = types.enum [
      "sqlite3"
      "postgres"
    ];
    default = "sqlite3";
    description = "Storage backend used by the repo-specific Forgejo integration.";
  };

  options.services.forgejo.integration.database.name = mkOption {
    type = types.str;
    default = "forgejo";
    description = "Dedicated database name used by Forgejo.";
  };

  options.services.forgejo.integration.database.user = mkOption {
    type = types.str;
    default = "forgejo";
    description = "Dedicated database user used by Forgejo.";
  };

  options.services.forgejo.integration.database.createLocally = mkOption {
    type = types.bool;
    default = true;
    description = "Provision the Forgejo PostgreSQL database locally through the NixOS PostgreSQL module.";
  };

  options.services.forgejo.integration.database.socket = mkOption {
    type = types.nullOr types.str;
    default = "/run/postgresql";
    description = "Local PostgreSQL unix socket path used by Forgejo.";
  };

  options.services.forgejo.integration.database.passwordFile = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = "Optional password file for PostgreSQL auth. Leave null for local socket/peer auth.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.forgejo.settings.DEFAULT.APP_NAME = mkDefault cfg.integration.appName;
      services.forgejo.settings.server.DOMAIN = mkDefault cfg.integration.publicDomain;
      services.forgejo.settings.server.ROOT_URL = mkDefault "${publicUrl}/";
      services.forgejo.settings.server.HTTP_ADDR = mkDefault cfg.integration.listenAddress;
      services.forgejo.settings.server.HTTP_PORT = mkDefault cfg.integration.listenPort;
      services.forgejo.settings.server.PROTOCOL = mkDefault "http";
      services.forgejo.settings.server.DISABLE_SSH = mkDefault (!cfg.integration.integratedSsh.enable);
      services.forgejo.settings.server.SSH_PORT = mkDefault cfg.integration.integratedSsh.port;
      services.forgejo.settings.service.DISABLE_REGISTRATION =
        mkDefault cfg.integration.disableRegistration;
      services.forgejo.settings.service.DEFAULT_KEEP_EMAIL_PRIVATE = mkDefault true;
      services.forgejo.settings.service.DEFAULT_ORG_VISIBILITY = mkDefault "private";
      services.forgejo.settings.session.COOKIE_SECURE = mkDefault (hasPrefix "https://" publicUrl);

      # ============================================
      # CRIAÇÃO AUTOMÁTICA DO ADMIN VIA SOPS
      # ============================================
      systemd.services.forgejo.preStart =
        let
          adminCmd = "${lib.getExe config.services.forgejo.package} admin user";
          uFile = config.sops.secrets."forgejo/admin-username".path;
          pFile = config.sops.secrets."forgejo/admin-password".path;
        in
        ''
          # Lê os segredos limpando espaços do YAML
          USER=$(${pkgs.coreutils}/bin/cat ${uFile} | ${pkgs.coreutils}/bin/tr -d '\n')
          PASS=$(${pkgs.coreutils}/bin/cat ${pFile} | ${pkgs.coreutils}/bin/tr -d '\n')

          # Cria o admin se ele não existir
          ${adminCmd} create --admin --email "admin@seu.com" --username "$USER" --password "$PASS" || true
        '';
    }

    (mkIf (cfg.integration.database.type == "postgres") {
      services.forgejo.database = {
        type = "postgres";
        name = cfg.integration.database.name;
        user = cfg.integration.database.user;
        createDatabase = cfg.integration.database.createLocally;
        socket = cfg.integration.database.socket;
        passwordFile = cfg.integration.database.passwordFile;
      };

      services.postgresql.enable = mkDefault cfg.integration.database.createLocally;
      services.postgresql.enableTCPIP = mkDefault false;
    })

    (mkIf cfg.integration.integratedSsh.enable {
      services.forgejo.settings.server.START_SSH_SERVER = mkDefault true;
      services.forgejo.settings.server.SSH_LISTEN_PORT =
        mkDefault cfg.integration.integratedSsh.listenPort;
    })

    (mkIf cfg.integration.proxy.enable {
      kernelcore.network.proxy.nginx-public.services.forgejo = {
        enable = true;
        host = cfg.integration.publicDomain;
        upstreamHost = cfg.integration.listenAddress;
        upstreamPort = cfg.integration.listenPort;
        maxBodySize = cfg.integration.proxy.maxBodySize;
        enableWebSocket = cfg.integration.proxy.enableWebSocket;
      };
    })

    (mkIf cfg.integration.tls.enable {
      kernelcore.security.tls.certs = setAttrByPath [ cfg.integration.publicDomain ] {
        extraDomainNames = cfg.integration.tls.extraDomainNames;
        reloadServices = cfg.integration.tls.reloadServices;
      };
    })

    {
      assertions = [
        {
          assertion =
            !(cfg.integration.database.type == "postgres" && cfg.integration.database.createLocally)
            || config.services.postgresql.enable;
          message = "Forgejo local PostgreSQL integration requires services.postgresql.enable = true.";
        }
      ];
    }
  ]);
}
