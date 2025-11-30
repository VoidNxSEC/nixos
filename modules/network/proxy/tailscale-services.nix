{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.proxy.tailscale-services;
in
{
  options.kernelcore.network.proxy.tailscale-services = {
    enable = mkEnableOption "Enable preconfigured Tailscale service exposures";

    tailnetDomain = mkOption {
      type = types.str;
      default = "tail-scale.ts.net";
      description = "Your Tailscale tailnet domain";
    };
  };

  config = mkIf cfg.enable {
    # Enable base componentsvscode-webview://1doff4ecgmbfm85k7bsepr120ji4tl1v1jag4t944dlho61bvuij/docs/TAILSCALE-CHEATSHEET.md
    kernelcore.network.vpn.tailscale.enable = true;
    kernelcore.network.proxy.nginx-tailscale.enable = true;
    kernelcore.secrets.tailscale.enable = true;

    # Configure Tailscale with optimized settings
    kernelcore.network.vpn.tailscale = {
      # Use SOPS-encrypted auth key (if secrets file exists)
      authKeyFile =
        mkIf (pathExists "/etc/nixos/secrets/tailscale.yaml")
          config.sops.secrets."tailscale-authkey".path;
      useAuthKeyFile = pathExists "/etc/nixos/secrets/tailscale.yaml";

      # Enable subnet router for local network
      enableSubnetRouter = true;
      advertiseRoutes = [ "192.168.15.0/24" ];

      # Enable as exit node
      exitNode = true;
      exitNodeAllowLANAccess = true;

      # DNS configuration
      acceptDNS = true;
      enableMagicDNS = true;

      # Network settings
      acceptRoutes = true;
      openFirewall = true;
      trustedInterface = true;

      # Tags for ACL
      tags = [
        "tag:server"
        "tag:desktop"
      ];

      # Performance
      enableConnectionPersistence = true;
      reconnectTimeout = 30;
    };

    # Configure NGINX proxy
    kernelcore.network.proxy.nginx-tailscale = {
      tailnetDomain = cfg.tailnetDomain;
      enableHTTP3 = true;
      enableConnectionPooling = true;
      enableSecurityHeaders = true;

      # Expose services
      services = {
        # Ollama LLM
        ollama = {
          enable = mkDefault (config.services.ollama.enable or false);
          subdomain = "ollama";
          upstreamPort = 11434;
          rateLimit = "20r/s";
          maxBodySize = "500M"; # Large for model uploads
          timeout = 600; # 10 minutes for long inference
          enableWebSocket = false;
        };

        # LlamaCPP
        llamacpp = {
          enable = mkDefault (config.services.llamacpp.enable or false);
          subdomain = "llama";
          upstreamPort = 8080;
          rateLimit = "10r/s";
          maxBodySize = "100M";
          timeout = 300;
        };

        # PostgreSQL (via pg_bouncer or direct)
        postgresql = {
          enable = mkDefault false; # Explicitly enable if needed
          subdomain = "db";
          upstreamPort = 5432;
          rateLimit = "50r/s";
          maxBodySize = "10M";
          timeout = 60;
          enableAuth = true; # Require authentication
        };

        # Gitea
        gitea = {
          enable = mkDefault (config.services.gitea.enable or false);
          subdomain = "git";
          upstreamPort = 3000;
          rateLimit = "30r/s";
          maxBodySize = "200M"; # Large for repository pushes
          timeout = 180;
        };

        # Docker API (secure access)
        docker-api = {
          enable = mkDefault false; # Explicitly enable if needed
          subdomain = "docker";
          upstreamHost = "unix:/var/run/docker.sock";
          upstreamPort = 2375;
          rateLimit = "10r/s";
          enableAuth = true; # Critical: require authentication
          extraConfig = ''
            # Extra security for Docker API
            allow 100.64.0.0/10; # Tailscale IP range
            deny all;
          '';
        };
      };
    };
  };
}
