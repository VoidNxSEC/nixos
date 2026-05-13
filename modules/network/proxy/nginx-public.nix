{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.proxy.nginx-public;

  serviceType = types.submodule {
    options = {
      enable = mkEnableOption "Enable this public reverse proxy upstream";

      host = mkOption {
        type = types.str;
        description = "Public hostname served by NGINX.";
      };

      upstreamHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Local upstream host.";
      };

      upstreamPort = mkOption {
        type = types.port;
        description = "Local upstream port.";
      };

      useACMEHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional ACME host override. Defaults to the virtual host name.";
      };

      enableWebSocket = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WebSocket proxying.";
      };

      maxBodySize = mkOption {
        type = types.str;
        default = "100M";
        description = "Maximum client body size accepted by the proxy.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra NGINX location config for this upstream.";
      };
    };
  };
in
{
  options.kernelcore.network.proxy.nginx-public = {
    enable = mkEnableOption "Enable NGINX public reverse proxy with central ACME certificates";

    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Public hostnames exposed through NGINX.";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts = mapAttrs' (
        _: service:
        nameValuePair service.host {
          forceSSL = true;
          useACMEHost = if service.useACMEHost != null then service.useACMEHost else service.host;

          locations."/" = {
            proxyPass = "http://${service.upstreamHost}:${toString service.upstreamPort}";
            proxyWebsockets = service.enableWebSocket;

            extraConfig = ''
              client_max_body_size ${service.maxBodySize};
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Port $server_port;
              ${service.extraConfig}
            '';
          };
        }
      ) (filterAttrs (_: service: service.enable) cfg.services);
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
