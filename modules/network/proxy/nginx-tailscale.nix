{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.proxy.nginx-tailscale;

  # Service configuration type
  serviceType = types.submodule {
    options = {
      enable = mkEnableOption "Enable this service proxy";

      subdomain = mkOption {
        type = types.str;
        description = "Subdomain for the service (e.g., 'ollama' for ollama.hostname.ts.net)";
      };

      upstreamHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Upstream service host";
      };

      upstreamPort = mkOption {
        type = types.port;
        description = "Upstream service port";
      };

      protocol = mkOption {
        type = types.enum [
          "http"
          "https"
        ];
        default = "http";
        description = "Upstream protocol";
      };

      enableSSL = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SSL/TLS in NGINX (not needed - Tailscale provides HTTPS)";
      };

      enableAuth = mkOption {
        type = types.bool;
        default = false;
        description = "Enable basic authentication";
      };

      authFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to htpasswd file for authentication";
      };

      rateLimit = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Rate limit (e.g., '10r/s' for 10 requests per second)";
        example = "10r/s";
      };

      maxBodySize = mkOption {
        type = types.str;
        default = "100M";
        description = "Maximum client body size";
      };

      timeout = mkOption {
        type = types.int;
        default = 300;
        description = "Proxy timeout in seconds";
      };

      enableWebSocket = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WebSocket support";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra NGINX configuration for this service";
      };
    };
  };
in
{
  options.kernelcore.network.proxy.nginx-tailscale = {
    enable = mkEnableOption "Enable NGINX reverse proxy for Tailscale services";

    hostname = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Base hostname for Tailscale (will be hostname.tailnet.ts.net)";
    };

    tailnetDomain = mkOption {
      type = types.str;
      default = "tail-scale.ts.net";
      description = "Tailscale tailnet domain (e.g., your-tailnet.ts.net)";
    };

    # HTTP/3 QUIC Support
    enableHTTP3 = mkOption {
      type = types.bool;
      default = false; # Disabled by default to avoid package compatibility issues
      description = "Enable HTTP/3 with QUIC for low latency (requires nginxQuic package)";
    };

    # Connection pooling
    enableConnectionPooling = mkOption {
      type = types.bool;
      default = true;
      description = "Enable upstream connection pooling for better performance";
    };

    upstreamKeepalive = mkOption {
      type = types.int;
      default = 32;
      description = "Number of keepalive connections to upstream";
    };

    # Security
    enableSecurityHeaders = mkOption {
      type = types.bool;
      default = true;
      description = "Enable security headers (HSTS, CSP, etc.)";
    };

    # Note: SSL/TLS is configured globally via recommendedTlsSettings

    # Logging
    enableAccessLog = mkOption {
      type = types.bool;
      default = true;
      description = "Enable access logging";
    };

    enableErrorLog = mkOption {
      type = types.bool;
      default = true;
      description = "Enable error logging";
    };

    # Services to expose
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Services to expose via reverse proxy";
      example = literalExpression ''
        {
          ollama = {
            enable = true;
            subdomain = "ollama";
            upstreamPort = 11434;
            rateLimit = "10r/s";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable NGINX
    services.nginx = {
      enable = true;

      # Recommended settings for performance
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # HTTP/3 support
      #package = mkIf cfg.enableHTTP3 pkgs.nginxQuic;

      # Global settings
      appendHttpConfig = ''
        # Connection pooling (Keepalive must be configured in upstream blocks, not global http)
        # Placeholder for future upstream block implementation

        # Rate limiting zones
        ${concatStringsSep "\n" (
          mapAttrsToList (
            name: service:
            optionalString (service.enable && service.rateLimit != null) ''
              limit_req_zone $binary_remote_addr zone=${name}_limit:10m rate=${service.rateLimit};
            ''
          ) cfg.services
        )}

        # Security headers
        ${optionalString cfg.enableSecurityHeaders ''
          # Security headers
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        ''}

        # Logging format
        log_format tailscale_proxy '$remote_addr - $remote_user [$time_local] '
                                   '"$request" $status $body_bytes_sent '
                                   '"$http_referer" "$http_user_agent" '
                                   'upstream: $upstream_addr '
                                   'response_time: $upstream_response_time';
      '';

      # Virtual hosts for each service
      virtualHosts = mapAttrs' (
        name: service:
        nameValuePair "${service.subdomain}.${cfg.hostname}.${cfg.tailnetDomain}" {

          # Note: Tailscale provides HTTPS, NGINX serves HTTP locally
          enableACME = false;

          # HTTP/3 support (optional, for direct access)
          http3 = mkIf cfg.enableHTTP3 true;
          quic = mkIf cfg.enableHTTP3 true;

          # Authentication
          basicAuth = mkIf service.enableAuth service.authFile;

          extraConfig = ''
            # Logging
            ${optionalString cfg.enableAccessLog "access_log /var/log/nginx/${name}_access.log tailscale_proxy;"}
            ${optionalString cfg.enableErrorLog "error_log /var/log/nginx/${name}_error.log warn;"}

            # Client body size
            client_max_body_size ${service.maxBodySize};

            # Timeouts
            proxy_connect_timeout ${toString service.timeout}s;
            proxy_send_timeout ${toString service.timeout}s;
            proxy_read_timeout ${toString service.timeout}s;

            # Rate limiting
            ${optionalString (service.rateLimit != null) ''
              limit_req zone=${name}_limit burst=20 nodelay;
            ''}

            # WebSocket support
            ${optionalString service.enableWebSocket ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            ''}

            ${service.extraConfig}
          '';

          locations."/" = {
            proxyPass = "${service.protocol}://${service.upstreamHost}:${toString service.upstreamPort}";

            extraConfig = ''
              # Proxy headers
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Port $server_port;

              # Connection pooling
              ${optionalString cfg.enableConnectionPooling ''
                proxy_http_version 1.1;
                proxy_set_header Connection "";
              ''}

              # Buffering optimization
              proxy_buffering on;
              proxy_buffer_size 4k;
              proxy_buffers 8 4k;
              proxy_busy_buffers_size 8k;
            '';
          };
        }
      ) (filterAttrs (_: service: service.enable) cfg.services);
    };

    # Firewall: Open NGINX ports
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    networking.firewall.allowedUDPPorts = mkIf cfg.enableHTTP3 [ 443 ]; # QUIC uses UDP

    # Create log directory
    systemd.tmpfiles.rules = [
      "d /var/log/nginx 0755 nginx nginx -"
    ];

    # Service dependencies
    systemd.services.nginx = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
    };

    # Shell aliases for management
    environment.shellAliases = {
      nginx-reload = "sudo systemctl reload nginx";
      nginx-test = "sudo nginx -t";
      nginx-logs = "sudo tail -f /var/log/nginx/*.log";
      nginx-access = "sudo tail -f /var/log/nginx/*_access.log";
      nginx-error = "sudo tail -f /var/log/nginx/*_error.log";
    };

    # Warnings
    warnings = (
      optional (!config.kernelcore.network.vpn.tailscale.enable or false)
        "NGINX Tailscale proxy is enabled but Tailscale VPN is not enabled. Services will not be accessible."
    );
  };
}
