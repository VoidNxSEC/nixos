{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.dns.adguard;
in
{
  options.kernelcore.network.dns.adguard = {
    enable = mkEnableOption "AdGuard Home — self-hosted DNS-level threat protection";

    dnsBindHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address for the DNS listener. Use 0.0.0.0 to serve all LAN devices.";
    };

    dnsPort = mkOption {
      type = types.port;
      default = 53;
      description = "DNS port. Must be 53 for systemd-resolved to use as upstream.";
    };

    webPort = mkOption {
      type = types.port;
      default = 3000;
      description = "Web UI port (admin dashboard).";
    };

    openWebUI = mkOption {
      type = types.bool;
      default = false;
      description = "Open webPort in firewall — only needed if accessing the UI from another device.";
    };

    upstreamDns = mkOption {
      type = types.listOf types.str;
      default = [
        "https://dns.quad9.net/dns-query" # Quad9: malware-blocking + no logs
        "https://1.1.1.1/dns-query" # Cloudflare fallback
        "9.9.9.9#dns.quad9.net"         # Quad9 — threat-blocking nativo
        "149.112.112.112#dns.quad9.net"
      ];
      description = "Upstream DoH resolvers AdGuard forwards clean queries to.";
    };

    enableSafeBrowsing = mkOption {
      type = types.bool;
      default = true;
      description = "Enable AdGuard's built-in malware/phishing check (uses AdGuard cloud API).";
    };

    extraFilters = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption { type = types.str; };
            url = mkOption { type = types.str; };
            enabled = mkOption {
              type = types.bool;
              default = true;
            };
            id = mkOption { type = types.int; };
          };
        }
      );
      default = [ ];
      description = "Additional blocklist subscriptions to load at runtime.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        # The Go dns-proxy (dns/default.nix) also claims 127.0.0.1:53
        assertion = !(config.kernelcore.network.dns-proxy.enable or false);
        message = "kernelcore.network.dns.adguard and kernelcore.network.dns-proxy both bind to ${cfg.dnsBindHost}:${toString cfg.dnsPort} — disable one.";
      }
    ];

    services.adguardhome = {
      enable = true;

      # Allow changes made through the web UI to persist across rebuilds.
      # The Nix config is the floor; UI tweaks are allowed on top.
      mutableSettings = true;

      settings = {
        http.address = "127.0.0.1:${toString cfg.webPort}";

        dns = {
          bind_hosts = [ cfg.dnsBindHost ];
          port = cfg.dnsPort;

          upstream_dns = cfg.upstreamDns;
          # Bootstrap is plain UDP — used only to resolve the DoH hostnames above
          bootstrap_dns = [
            "9.9.9.9"
            "1.1.1.1"
          ];

          # Validate DNSSEC signatures on upstream responses
          dnssec_enabled = true;

          # AdGuard cloud-based safe browsing (malware/phishing URLs)
          safe_browsing_enabled = cfg.enableSafeBrowsing;

          # Optimistic cache: serve stale answer while refreshing in background
          cache_size = 4194304; # 4 MB
          cache_optimistic = true;
        };

        filtering = {
          enabled = true;

          filters = cfg.extraFilters;
        };

        statistics = {
          enabled = true;
          interval = "168h"; # 7 days of query history
        };

        log = {
          enabled = true;
          verbose = false;
        };
      };
    };

    # Point systemd-resolved to AdGuard Home as its upstream.
    # mkForce is intentional: this module takes ownership of the DNS resolution path.
    # If dns-resolver.nix is also enabled, its preferredServers are superseded here.
    services.resolved = mkIf config.services.resolved.enable {
      settings = {
        Resolve = mkForce {
          DNS = cfg.dnsBindHost;
          DNSOverTLS = "no";
        };
      };
    };

    networking.firewall = {
      # Open DNS port only when listening on non-loopback (LAN mode)
      # lib.optional returns [] or [value] — safe for list concatenation unlike mkIf
      allowedUDPPorts = lib.optional (cfg.dnsBindHost != "127.0.0.1") cfg.dnsPort;
      allowedTCPPorts =
        lib.optional (cfg.dnsBindHost != "127.0.0.1") cfg.dnsPort
        ++ lib.optional cfg.openWebUI cfg.webPort;
    };

    environment.systemPackages = with pkgs; [ adguardhome ];

    environment.shellAliases = {
      adg-status = "systemctl status AdGuardHome";
      adg-logs = "journalctl -u AdGuardHome -f";
      adg-reload = "sudo systemctl restart AdGuardHome";
      adg-ui = "echo 'AdGuard Home UI → http://127.0.0.1:${toString cfg.webPort}'";
      adg-stats = "curl -s http://127.0.0.1:${toString cfg.webPort}/control/stats | ${pkgs.jq}/bin/jq '{queries:.num_dns_queries,blocked:.num_blocked_filtering,blocked_pct:.blocked_filtering_ratio}'";
    };
  };
}
