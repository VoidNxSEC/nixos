{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
  grafanaCfg = cfg.dashboards.grafana;
in
{
  options.kernelcore.soc.dashboards.grafana = {
    enable = mkOption {
      type = types.bool;
      default = cfg.profile != "minimal";
      description = "Enable Grafana SOC dashboards";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Grafana HTTP port";
    };

    domain = mkOption {
      type = types.str;
      default = "soc.local";
      description = "Grafana domain";
    };

    adminPassword = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to admin password file";
    };
  };

  config = mkIf (cfg.enable && grafanaCfg.enable) {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = mkDefault cfg.network.listenAddress;
          http_port = mkDefault grafanaCfg.port;
          domain = mkDefault grafanaCfg.domain;
        };

        security = mkIf (grafanaCfg.adminPassword != null) {
          admin_user = "admin";
          admin_password = "$__file{${toString grafanaCfg.adminPassword}}";
        };

        analytics.reporting_enabled = mkDefault false;
      };

      # Provision data sources
      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "OpenSearch";
            type = "elasticsearch";
            url = "https://localhost:9200";
            database = "soc-security-*";
            jsonData = {
              timeField = "@timestamp";
              esVersion = "8.0.0";
              tlsSkipVerify = true;
            };
          }
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
          }
        ];

        # SOC Dashboards
        dashboards.settings.providers = [
          {
            name = "SOC";
            options.path = "/etc/grafana/dashboards";
          }
        ];
      };
    };

    # SOC Overview Dashboard
    environment.etc."grafana/dashboards/soc-overview.json" = {
      mode = "0644";
      text = builtins.toJSON {
        title = "SOC Overview";
        uid = "soc-overview";
        refresh = "30s";
        panels = [
          {
            id = 1;
            title = "Security Alerts (24h)";
            type = "stat";
            gridPos = {
              h = 4;
              w = 6;
              x = 0;
              y = 0;
            };
            targets = [
              {
                datasource = "OpenSearch";
                query = "event.severity:critical OR event.severity:high";
              }
            ];
          }
          {
            id = 2;
            title = "IDS Alerts";
            type = "stat";
            gridPos = {
              h = 4;
              w = 6;
              x = 6;
              y = 0;
            };
          }
          {
            id = 3;
            title = "Alert Timeline";
            type = "timeseries";
            gridPos = {
              h = 8;
              w = 12;
              x = 0;
              y = 4;
            };
          }
          {
            id = 4;
            title = "Top Source IPs";
            type = "table";
            gridPos = {
              h = 8;
              w = 6;
              x = 12;
              y = 0;
            };
          }
          {
            id = 5;
            title = "Alert Categories";
            type = "piechart";
            gridPos = {
              h = 8;
              w = 6;
              x = 18;
              y = 0;
            };
          }
        ];
      };
    };

    # Network Traffic Dashboard
    environment.etc."grafana/dashboards/network-traffic.json" = {
      mode = "0644";
      text = builtins.toJSON {
        title = "Network Traffic";
        uid = "network-traffic";
        refresh = "1m";
        panels = [
          {
            id = 1;
            title = "Bandwidth In/Out";
            type = "timeseries";
            gridPos = {
              h = 8;
              w = 24;
              x = 0;
              y = 0;
            };
          }
          {
            id = 2;
            title = "Top Talkers";
            type = "table";
            gridPos = {
              h = 8;
              w = 12;
              x = 0;
              y = 8;
            };
          }
          {
            id = 3;
            title = "Protocol Distribution";
            type = "piechart";
            gridPos = {
              h = 8;
              w = 12;
              x = 12;
              y = 8;
            };
          }
        ];
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ grafanaCfg.port ];

    environment.shellAliases = {
      grafana-logs = "journalctl -u grafana -f";
    };
  };
}
