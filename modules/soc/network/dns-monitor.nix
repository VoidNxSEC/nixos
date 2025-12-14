{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
in
{
  options.kernelcore.soc.network.dnsMonitor = {
    enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable DNS query monitoring";
    };

    logQueries = mkOption {
      type = types.bool;
      default = true;
      description = "Log all DNS queries";
    };

    blockMalicious = mkOption {
      type = types.bool;
      default = true;
      description = "Block known malicious domains";
    };

    blocklists = mkOption {
      type = types.listOf types.str;
      default = [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
      ];
      description = "URL blocklists for malicious domains";
    };
  };

  config = mkIf (cfg.enable && cfg.network.dnsMonitor.enable) {
    # DNS query logging via dnsmasq or systemd-resolved
    services.dnsmasq = mkIf cfg.network.dnsMonitor.logQueries {
      enable = true;
      settings = {
        log-queries = true;
        log-facility = "/var/log/soc/dns-queries.log";
        cache-size = 10000;
      };
    };

    # DNS blocklist update service
    systemd.services.dns-blocklist-update = mkIf cfg.network.dnsMonitor.blockMalicious {
      description = "Update DNS blocklists";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "update-dns-blocklist" ''
          BLOCKLIST_DIR="/var/lib/soc/dns-blocklists"
          mkdir -p "$BLOCKLIST_DIR"

          ${concatMapStringsSep "\n" (url: ''
            ${pkgs.curl}/bin/curl -sfL "${url}" >> "$BLOCKLIST_DIR/combined.txt" || true
          '') cfg.network.dnsMonitor.blocklists}

          # Extract domains and deduplicate
          grep -v "^#" "$BLOCKLIST_DIR/combined.txt" | \
            awk '{print $2}' | \
            grep -v "^$" | \
            sort -u > "$BLOCKLIST_DIR/domains.txt"

          echo "Updated: $(wc -l < "$BLOCKLIST_DIR/domains.txt") domains blocked"
        ''}";
      };
    };

    systemd.timers.dns-blocklist-update = mkIf cfg.network.dnsMonitor.blockMalicious {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # DNS log rotation
    services.logrotate.settings.dns-queries = mkIf cfg.network.dnsMonitor.logQueries {
      files = "/var/log/soc/dns-queries.log";
      frequency = "daily";
      rotate = 7;
      compress = true;
    };

    environment.shellAliases = {
      dns-top = "cat /var/log/soc/dns-queries.log | grep 'query\\[' | awk '{print $6}' | sort | uniq -c | sort -rn | head -20";
      dns-suspicious = "grep -E '(tor|onion|i2p)' /var/log/soc/dns-queries.log | tail -50";
    };
  };
}
