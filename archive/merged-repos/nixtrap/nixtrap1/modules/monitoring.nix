{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.nixos-cache-monitoring;

in
{
  options.services.nixos-cache-monitoring = {
    enable = mkEnableOption "NixOS Cache Monitoring Stack";

    enablePrometheus = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Prometheus monitoring";
    };

    enableNodeExporter = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Prometheus Node Exporter";
    };

    enableNginxExporter = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Prometheus Nginx Exporter";
    };

    enableGrafana = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Grafana dashboards";
    };

    prometheus = {
      port = mkOption {
        type = types.port;
        default = 9090;
        description = "Prometheus server port";
      };

      retention = mkOption {
        type = types.str;
        default = "30d";
        description = "How long to retain metrics";
      };

      scrapeInterval = mkOption {
        type = types.str;
        default = "15s";
        description = "How often to scrape metrics";
      };

      extraScrapeConfigs = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = "Extra Prometheus scrape configs";
      };
    };

    nodeExporter = {
      port = mkOption {
        type = types.port;
        default = 9100;
        description = "Node Exporter port";
      };

      enabledCollectors = mkOption {
        type = types.listOf types.str;
        default = [
          "systemd"
          "cpu"
          "meminfo"
          "diskstats"
          "filesystem"
          "netdev"
          "loadavg"
        ];
        description = "Collectors to enable";
      };
    };

    grafana = {
      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Grafana port";
      };

      domain = mkOption {
        type = types.str;
        default = "grafana.local";
        description = "Grafana domain name";
      };

      adminPassword = mkOption {
        type = types.str;
        default = "admin";
        description = "Grafana admin password (change in production!)";
      };
    };

    alertmanager = {
      enable = mkEnableOption "Alertmanager for alerts";

      port = mkOption {
        type = types.port;
        default = 9093;
        description = "Alertmanager port";
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for monitoring services";
    };
  };

  config = mkIf cfg.enable {
    # Prometheus
    services.prometheus = mkIf cfg.enablePrometheus {
      enable = true;
      port = cfg.prometheus.port;
      retentionTime = cfg.prometheus.retention;

      globalConfig = {
        scrape_interval = cfg.prometheus.scrapeInterval;
        evaluation_interval = cfg.prometheus.scrapeInterval;
      };

      scrapeConfigs = [
        # Prometheus self-monitoring
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString cfg.prometheus.port}" ];
            }
          ];
        }

        # Node Exporter
        (mkIf cfg.enableNodeExporter {
          job_name = "node";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString cfg.nodeExporter.port}" ];
            }
          ];
        })

        # Nginx Exporter
        (mkIf (cfg.enableNginxExporter && config.services.nginx.enable) {
          job_name = "nginx";
          static_configs = [
            {
              targets = [ "127.0.0.1:9113" ];
            }
          ];
        })

        # Nix-serve (if available via systemd metrics)
        {
          job_name = "nix-serve";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.nix-serve.port}" ];
            }
          ];
          metrics_path = "/metrics";
        }

        # Cache API Server
        (mkIf config.services.nixos-cache-api.enable {
          job_name = "cache-api";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.nixos-cache-api.port}" ];
            }
          ];
          metrics_path = "/api/metrics";
        })
      ]
      ++ cfg.prometheus.extraScrapeConfigs;

      # Alerting rules
      rules = [
        ''
          groups:
            - name: cache_server_alerts
              interval: 30s
              rules:
                # High disk usage
                - alert: HighDiskUsage
                  expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.15
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "High disk usage on cache server"
                    description: "Disk usage is above 85% on {{ $labels.instance }}"

                # Service down
                - alert: NixServeDown
                  expr: up{job="nix-serve"} == 0
                  for: 2m
                  labels:
                    severity: critical
                  annotations:
                    summary: "nix-serve is down"
                    description: "nix-serve has been down for more than 2 minutes"

                - alert: NginxDown
                  expr: up{job="nginx"} == 0
                  for: 2m
                  labels:
                    severity: critical
                  annotations:
                    summary: "nginx is down"
                    description: "nginx has been down for more than 2 minutes"

                # High memory usage
                - alert: HighMemoryUsage
                  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.9
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "High memory usage"
                    description: "Memory usage is above 90% on {{ $labels.instance }}"

                # High CPU usage
                - alert: HighCPUUsage
                  expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                  for: 10m
                  labels:
                    severity: warning
                  annotations:
                    summary: "High CPU usage"
                    description: "CPU usage is above 80% on {{ $labels.instance }} for 10 minutes"

                # Load average
                - alert: HighLoadAverage
                  expr: node_load5 > (count by (instance) (node_cpu_seconds_total{mode="idle"})) * 1.5
                  for: 10m
                  labels:
                    severity: warning
                  annotations:
                    summary: "High load average"
                    description: "Load average is high on {{ $labels.instance }}"
        ''
      ];
    };

    # Node Exporter
    services.prometheus.exporters.node = mkIf cfg.enableNodeExporter {
      enable = true;
      port = cfg.nodeExporter.port;
      enabledCollectors = cfg.nodeExporter.enabledCollectors;
      disabledCollectors = [ ];

      # Extra flags
      extraFlags = [
        "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
        "--collector.netclass.ignored-devices=^(veth.*|docker.*|br.*)$$"
      ];
    };

    # Nginx Exporter
    services.prometheus.exporters.nginx =
      mkIf (cfg.enableNginxExporter && config.services.nginx.enable)
        {
          enable = true;
          port = 9113;
          scrapeUri = "http://127.0.0.1/nginx-status";
        };

    # Grafana
    services.grafana = mkIf cfg.enableGrafana {
      enable = true;
      settings = {
        server = {
          http_port = cfg.grafana.port;
          domain = cfg.grafana.domain;
          root_url = "https://${cfg.grafana.domain}";
        };

        security = {
          admin_user = "admin";
          admin_password = cfg.grafana.adminPassword;
        };

        analytics.reporting_enabled = false;
      };

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString cfg.prometheus.port}";
            isDefault = true;
            jsonData = {
              timeInterval = cfg.prometheus.scrapeInterval;
            };
          }
        ];

        dashboards.settings.providers = [
          {
            name = "NixOS Cache Server";
            options.path = "/var/lib/grafana/dashboards";
          }
        ];
      };
    };

    # Alertmanager
    services.prometheus.alertmanager = mkIf cfg.alertmanager.enable {
      enable = true;
      port = cfg.alertmanager.port;

      configuration = {
        global = {
          resolve_timeout = "5m";
        };

        route = {
          group_by = [
            "alertname"
            "cluster"
            "service"
          ];
          group_wait = "10s";
          group_interval = "10s";
          repeat_interval = "12h";
          receiver = "default";
        };

        receivers = [
          {
            name = "default";
            # Add email, slack, or other notification configs here
          }
        ];
      };
    };

    # Nginx configuration for monitoring endpoints
    services.nginx = mkIf config.services.nginx.enable {
      statusPage = true; # Enable nginx status page

      virtualHosts = {
        # Prometheus endpoint
        "monitoring.${config.services.nixos-cache-server.hostName or "cache.local"}" =
          mkIf cfg.openFirewall
            {
              locations."/prometheus/" = {
                proxyPass = "http://127.0.0.1:${toString cfg.prometheus.port}/";
                extraConfig = ''
                  auth_basic "Prometheus";
                  auth_basic_user_file /etc/nginx/.htpasswd;
                '';
              };

              locations."/grafana/" = mkIf cfg.enableGrafana {
                proxyPass = "http://127.0.0.1:${toString cfg.grafana.port}/";
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                '';
              };
            };
      };
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.prometheus.port
      ]
      ++ optional cfg.enableNodeExporter cfg.nodeExporter.port
      ++ optional cfg.enableGrafana cfg.grafana.port
      ++ optional cfg.alertmanager.enable cfg.alertmanager.port;
    };

    # Create monitoring scripts
    environment.etc."nixos-cache/scripts/monitor.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Real-time monitoring script

        set -euo pipefail

        clear
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  NixOS Cache Server - Monitor em Tempo Real              ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""

        while true; do
          # System info
          echo "=== System Info ==="
          echo "Hostname: $(hostname)"
          echo "Uptime: $(uptime -p)"
          echo ""

          # CPU & Load
          echo "=== CPU & Load ==="
          echo "Load Average: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
          echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
          echo ""

          # Memory
          echo "=== Memory ==="
          free -h | grep -E "Mem|Swap"
          echo ""

          # Disk
          echo "=== Disk ==="
          df -h / /nix/store 2>/dev/null || df -h /
          echo ""

          # Services
          echo "=== Services Status ==="
          ${pkgs.systemd}/bin/systemctl is-active nix-serve && echo "✓ nix-serve: Running" || echo "✗ nix-serve: Stopped"
          ${pkgs.systemd}/bin/systemctl is-active nginx && echo "✓ nginx: Running" || echo "✗ nginx: Stopped"
          ${pkgs.systemd}/bin/systemctl is-active prometheus && echo "✓ prometheus: Running" || echo "✗ prometheus: Stopped"
          ${optionalString cfg.enableNodeExporter "${pkgs.systemd}/bin/systemctl is-active prometheus-node-exporter && echo \"✓ node-exporter: Running\" || echo \"✗ node-exporter: Stopped\""}
          echo ""

          # Network
          echo "=== Network Connections ==="
          echo "Established: $(ss -tan | grep ESTAB | wc -l)"
          echo "Listening: $(ss -tln | grep LISTEN | wc -l)"
          echo ""

          echo "Press Ctrl+C to exit. Refreshing in 5s..."
          sleep 5
          clear
        done
      '';
      mode = "0755";
    };

    # System packages for monitoring
    environment.systemPackages = with pkgs; [
      prometheus
      grafana
      htop
      iotop
      nethogs
      sysstat
    ];
  };
}
