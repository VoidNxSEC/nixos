{
  config,
  lib,
  pkgs, # ADICIONADO PKGS AQUI
  ...
}:

with lib;

let
  cfg = config.services.forgejo; # upstream (gate)
  icfg = config.kernelcore.services.forgejo; # opcoes de integracao deste repo
  publicUrl = removeSuffix "/" (
    if icfg.publicUrl != null then
      icfg.publicUrl
    else if icfg.proxy.enable || icfg.tls.enable then
      "https://${icfg.publicDomain}/"
    else
      "http://${icfg.listenAddress}:${toString icfg.listenPort}/"
  );
in
{
  options.kernelcore.services.forgejo.appName = mkOption {
    type = types.str;
    default = "Forgejo";
    description = "Application title exposed by Forgejo.";
  };

  options.kernelcore.services.forgejo.publicDomain = mkOption {
    type = types.str;
    default = "forgejo.local";
    description = "Public hostname advertised by Forgejo.";
  };

  options.kernelcore.services.forgejo.publicUrl = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Optional explicit public URL override.";
  };

  options.kernelcore.services.forgejo.listenAddress = mkOption {
    type = types.str;
    default = "127.0.0.1";
    description = "Local bind address for the Forgejo HTTP listener.";
  };

  options.kernelcore.services.forgejo.listenPort = mkOption {
    type = types.port;
    default = 3002;
    description = "Local Forgejo HTTP port.";
  };

  options.kernelcore.services.forgejo.disableRegistration = mkOption {
    type = types.bool;
    default = true;
    description = "Disable self-service account registration.";
  };

  options.kernelcore.services.forgejo.proxy.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Expose Forgejo through the central NGINX public proxy.";
  };

  options.kernelcore.services.forgejo.proxy.maxBodySize = mkOption {
    type = types.str;
    default = "200M";
    description = "Client body size limit for the public NGINX upstream.";
  };

  options.kernelcore.services.forgejo.proxy.enableWebSocket = mkOption {
    type = types.bool;
    default = true;
    description = "Enable WebSocket proxying for the public NGINX upstream.";
  };

  options.kernelcore.services.forgejo.tls.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Register the Forgejo hostname in the central TLS certificate inventory.";
  };

  options.kernelcore.services.forgejo.tls.extraDomainNames = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Additional SAN entries for the Forgejo certificate.";
  };

  options.kernelcore.services.forgejo.tls.reloadServices = mkOption {
    type = types.listOf types.str;
    default = [ "nginx.service" ];
    description = "Services reloaded after certificate renewal.";
  };

  options.kernelcore.services.forgejo.integratedSsh.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Forgejo's built-in SSH server.";
  };

  options.kernelcore.services.forgejo.integratedSsh.port = mkOption {
    type = types.port;
    default = 22;
    description = "Public SSH port advertised by Forgejo.";
  };

  options.kernelcore.services.forgejo.integratedSsh.listenPort = mkOption {
    type = types.port;
    default = 2222;
    description = "Local SSH listen port when the built-in SSH server is enabled.";
  };

  options.kernelcore.services.forgejo.database.type = mkOption {
    type = types.enum [
      "sqlite3"
      "postgres"
    ];
    default = "sqlite3";
    description = "Storage backend used by the repo-specific Forgejo integration.";
  };

  options.kernelcore.services.forgejo.database.name = mkOption {
    type = types.str;
    default = "forgejo";
    description = "Dedicated database name used by Forgejo.";
  };

  options.kernelcore.services.forgejo.database.user = mkOption {
    type = types.str;
    default = "forgejo";
    description = "Dedicated database user used by Forgejo.";
  };

  options.kernelcore.services.forgejo.database.createLocally = mkOption {
    type = types.bool;
    default = true;
    description = "Provision the Forgejo PostgreSQL database locally through the NixOS PostgreSQL module.";
  };

  options.kernelcore.services.forgejo.database.socket = mkOption {
    type = types.nullOr types.str;
    default = "/run/postgresql";
    description = "Local PostgreSQL unix socket path used by Forgejo.";
  };

  options.kernelcore.services.forgejo.database.passwordFile = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = "Optional password file for PostgreSQL auth. Leave null for local socket/peer auth.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.forgejo.settings.DEFAULT.APP_NAME = mkDefault icfg.appName;
      services.forgejo.settings.server.DOMAIN = mkDefault icfg.publicDomain;
      services.forgejo.settings.server.ROOT_URL = mkDefault "${publicUrl}/";
      services.forgejo.settings.server.HTTP_ADDR = mkDefault icfg.listenAddress;
      services.forgejo.settings.server.HTTP_PORT = mkDefault icfg.listenPort;
      services.forgejo.settings.server.PROTOCOL = mkDefault "http";
      services.forgejo.settings.server.DISABLE_SSH = mkDefault (!icfg.integratedSsh.enable);
      services.forgejo.settings.server.SSH_PORT = mkDefault icfg.integratedSsh.port;
      services.forgejo.settings.service.DISABLE_REGISTRATION =
        mkDefault icfg.disableRegistration;
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

    (mkIf (icfg.database.type == "postgres") {
      services.forgejo.database = {
        type = "postgres";
        name = icfg.database.name;
        user = icfg.database.user;
        createDatabase = icfg.database.createLocally;
        socket = icfg.database.socket;
        passwordFile = icfg.database.passwordFile;
      };

      services.postgresql.enable = mkDefault icfg.database.createLocally;
      services.postgresql.enableTCPIP = mkDefault false;
    })

    (mkIf icfg.integratedSsh.enable {
      services.forgejo.settings.server.START_SSH_SERVER = mkDefault true;
      services.forgejo.settings.server.SSH_LISTEN_PORT =
        mkDefault icfg.integratedSsh.listenPort;
    })

    (mkIf icfg.proxy.enable {
      kernelcore.network.proxy.nginx-public.services.forgejo = {
        enable = true;
        host = icfg.publicDomain;
        upstreamHost = icfg.listenAddress;
        upstreamPort = icfg.listenPort;
        maxBodySize = icfg.proxy.maxBodySize;
        enableWebSocket = icfg.proxy.enableWebSocket;
      };
    })

    (mkIf icfg.tls.enable {
      kernelcore.security.tls.certs = setAttrByPath [ icfg.publicDomain ] {
        extraDomainNames = icfg.tls.extraDomainNames;
        reloadServices = icfg.tls.reloadServices;
      };
    })

    {
      assertions = [
        {
          assertion =
            !(icfg.database.type == "postgres" && icfg.database.createLocally)
            || config.services.postgresql.enable;
          message = "Forgejo local PostgreSQL integration requires services.postgresql.enable = true.";
        }
      ];
    }
  ]);
}
