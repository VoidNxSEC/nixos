# Monitoring Stack Module - Prometheus, Grafana, and friends
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hyperlab.monitoring;
in
{
  options.hyperlab.monitoring = {
    enable = mkEnableOption "HyperLab monitoring stack";

    prometheus = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus";
      };
      port = mkOption {
        type = types.port;
        default = 9090;
      };
      retentionDays = mkOption {
        type = types.int;
        default = 15;
      };
    };

    grafana = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      port = mkOption {
        type = types.port;
        default = 3001;
      };
      adminPassword = mkOption {
        type = types.str;
        default = "admin"; # Should use agenix in production
      };
    };

    exporters = {
      node = mkOption {
        type = types.bool;
        default = true;
      };
      docker = mkOption {
        type = types.bool;
        default = true;
      };
      nvidia = mkOption {
        type = types.bool;
        default = false;
      };
    };

    loki = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Loki for log aggregation";
      };
    };
  };

  config = mkIf cfg.enable {
    # Prometheus
    services.prometheus = mkIf cfg.prometheus.enable {
      enable = true;
      port = cfg.prometheus.port;

      retentionTime = "${toString cfg.prometheus.retentionDays}d";

      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };

      scrapeConfigs = [
        # Self-monitoring
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.prometheus.port}" ];
            }
          ];
        }

        # Node exporter
        (mkIf cfg.exporters.node {
          job_name = "node";
          static_configs = [
            {
              targets = [ "localhost:9100" ];
            }
          ];
        })

        # Docker metrics
        (mkIf cfg.exporters.docker {
          job_name = "docker";
          static_configs = [
            {
              targets = [ "localhost:9323" ];
            }
          ];
        })

        # NVIDIA GPU metrics
        (mkIf cfg.exporters.nvidia {
          job_name = "nvidia";
          static_configs = [
            {
              targets = [ "localhost:9400" ];
            }
          ];
        })

        # Container metrics (cAdvisor)
        {
          job_name = "cadvisor";
          static_configs = [
            {
              targets = [ "localhost:8080" ];
            }
          ];
        }
      ];

      # Alert rules
      rules = [
        ''
          groups:
          - name: hyperlab
            rules:
            - alert: HighCPUUsage
              expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High CPU usage detected"
                
            - alert: HighMemoryUsage
              expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High memory usage detected"
                
            - alert: DiskSpaceLow
              expr: (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 < 15
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: "Disk space is running low"
                
            - alert: ContainerDown
              expr: absent(container_memory_usage_bytes{name!=""})
              for: 1m
              labels:
                severity: critical
              annotations:
                summary: "Container is down"
        ''
      ];
    };

    # Node exporter
    services.prometheus.exporters.node = mkIf cfg.exporters.node {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "time"
        "vmstat"
        "systemd"
        "processes"
      ];
    };

    # Grafana
    services.grafana = mkIf cfg.grafana.enable {
      enable = true;

      settings = {
        server = {
          http_port = cfg.grafana.port;
          http_addr = "0.0.0.0";
        };

        security = {
          admin_password = cfg.grafana.adminPassword;
          admin_user = "admin";
        };

        analytics.reporting_enabled = false;
      };

      # Datasources
      provision.datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString cfg.prometheus.port}";
          isDefault = true;
        }
      ]
      ++ (optional cfg.loki.enable {
        name = "Loki";
        type = "loki";
        url = "http://localhost:3100";
      });

      # Dashboard provisioning
      provision.dashboards.settings.providers = [
        {
          name = "HyperLab Dashboards";
          options.path = "/var/lib/grafana/dashboards";
        }
      ];
    };

    # Loki for logs
    services.loki = mkIf cfg.loki.enable {
      enable = true;
      configuration = {
        auth_enabled = false;

        server.http_listen_port = 3100;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 1048576;
          chunk_retain_period = "30s";
        };

        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";
          };
          filesystem.directory = "/var/lib/loki/chunks";
        };
      };
    };

    # Promtail for log shipping
    services.promtail = mkIf cfg.loki.enable {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        clients = [
          {
            url = "http://localhost:3100/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels.job = "systemd-journal";
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
            ];
          }
          {
            job_name = "containers";
            static_configs = [
              {
                targets = [ "localhost" ];
                labels = {
                  job = "docker";
                  __path__ = "/var/lib/docker/containers/*/*.log";
                };
              }
            ];
          }
        ];
      };
    };

    # NVIDIA GPU exporter
    systemd.services.nvidia-gpu-exporter = mkIf cfg.exporters.nvidia {
      description = "NVIDIA GPU Prometheus Exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.prometheus-nvidia-gpu-exporter}/bin/nvidia_gpu_exporter";
        Restart = "always";
      };
    };

    # Docker metrics endpoint
    virtualisation.docker.daemon.settings = mkIf cfg.exporters.docker {
      metrics-addr = "127.0.0.1:9323";
    };

    # cAdvisor for container metrics
    virtualisation.oci-containers.containers.cadvisor = {
      image = "gcr.io/cadvisor/cadvisor:latest";
      ports = [ "8080:8080" ];
      volumes = [
        "/:/rootfs:ro"
        "/var/run:/var/run:rw"
        "/sys:/sys:ro"
        "/var/lib/docker/:/var/lib/docker:ro"
      ];
      extraOptions = [ "--privileged" ];
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      cfg.prometheus.port
      cfg.grafana.port
      9100 # Node exporter
      8080 # cAdvisor
    ]
    ++ (optional cfg.loki.enable 3100);

    # Create dashboard directory
    systemd.tmpfiles.rules = [
      "d /var/lib/grafana/dashboards 0755 grafana grafana -"
    ];
  };
}
