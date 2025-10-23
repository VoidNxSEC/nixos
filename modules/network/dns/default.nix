{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.dns-proxy;

  # Build the Go DNS proxy
  dns-proxy = pkgs.buildGoModule {
    pname = "dns-proxy";
    version = "1.0.0";

    src = ./.;

    vendorHash = "sha256-IfjC6xc3q9nQpsMB6ccqqBKZnU4rTL+8oeqbUN9U/tg=";

    meta = with lib; {
      description = "Fast DNS proxy with caching for improved resolution";
      homepage = "https://github.com/kernelcore/nixos";
      license = licenses.mit;
      maintainers = [ "kernelcore" ];
    };
  };

  # Generate configuration file
  configFile = pkgs.writeText "dns-proxy-config.json" (
    builtins.toJSON {
      listen_addr = cfg.listenAddress;
      upstreams = cfg.upstreams;
      cache_size = cfg.cacheSize;
      cache_ttl = cfg.cacheTTL;
      timeout = cfg.timeout;
      enable_stats = cfg.enableStats;
    }
  );

in
{
  options.kernelcore.network.dns-proxy = {
    enable = mkEnableOption "DNS proxy with caching for improved resolution";

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:53";
      description = "Address and port to listen on";
    };

    upstreams = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1:53" # Cloudflare primary
        "1.0.0.1:53" # Cloudflare secondary
        "8.8.8.8:53" # Google primary
        "8.8.4.4:53" # Google secondary
        "9.9.9.9:53" # Quad9
      ];
      description = "List of upstream DNS servers (with fallback)";
    };

    cacheSize = mkOption {
      type = types.int;
      default = 10000;
      description = "Maximum number of cached DNS responses";
    };

    cacheTTL = mkOption {
      type = types.int;
      default = 300;
      description = "Cache TTL in seconds (default: 5 minutes)";
    };

    timeout = mkOption {
      type = types.int;
      default = 5;
      description = "Timeout for upstream queries in seconds";
    };

    enableStats = mkOption {
      type = types.bool;
      default = true;
      description = "Enable periodic statistics logging";
    };

    setAsSystemResolver = mkOption {
      type = types.bool;
      default = true;
      description = "Set this proxy as the system DNS resolver";
    };
  };

  config = mkIf cfg.enable {
    # Install the DNS proxy package
    environment.systemPackages = [ dns-proxy ];

    # Create systemd service
    systemd.services.dns-proxy = {
      description = "DNS Proxy with Caching";
      after = [ "network.target" ];
      before = mkIf cfg.setAsSystemResolver [ "systemd-resolved.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${dns-proxy}/bin/dns-proxy -config ${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        PrivateDevices = true;
        ProtectClock = true;

        # Capabilities needed for binding to port 53
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      };
    };

    # Configure system to use the DNS proxy if requested
    networking.nameservers = mkIf cfg.setAsSystemResolver (mkBefore [ "127.0.0.1" ]);

    # Optional: disable systemd-resolved if we're replacing it
    # Uncomment if you want to fully replace systemd-resolved
    # services.resolved.enable = mkIf cfg.setAsSystemResolver false;
  };
}
