{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
  osCfg = cfg.siem.opensearch;
in
{
  options.kernelcore.soc.siem.opensearch = {
    enable = mkOption {
      type = types.bool;
      default = cfg.profile != "minimal";
      description = "Enable OpenSearch for log storage and analysis";
    };

    # Cluster settings
    clusterName = mkOption {
      type = types.str;
      default = "soc-cluster";
      description = "OpenSearch cluster name";
    };

    # Resource configuration
    heapSize = mkOption {
      type = types.str;
      default = "2g";
      description = "JVM heap size for OpenSearch";
    };

    # Storage settings
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/opensearch";
      description = "OpenSearch data directory";
    };

    # Index management
    indices = {
      securityPrefix = mkOption {
        type = types.str;
        default = "soc-security";
        description = "Prefix for security indices";
      };

      retentionDays = mkOption {
        type = types.int;
        default = cfg.retention.days;
        description = "Days to retain indices before deletion";
      };

      replicaCount = mkOption {
        type = types.int;
        default = 0;
        description = "Number of replicas (0 for single-node)";
      };
    };

    # Security settings
    security = {
      enableTLS = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable TLS for OpenSearch.
          Requires SSL certificates configured in dataDir/config/.
          Default: false (development mode without SSL)
        '';
      };

      adminPassword = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to admin password file (SOPS)";
      };
    };
  };

  config = mkIf (cfg.enable && osCfg.enable) {
    # OpenSearch container deployment
    virtualisation.oci-containers.containers.opensearch = {
      image = "opensearchproject/opensearch:2.11.1";
      autoStart = true;

      environment = {
        "cluster.name" = osCfg.clusterName;
        "node.name" = "soc-node-1";
        "discovery.type" = "single-node";
        "bootstrap.memory_lock" = "true";
        "OPENSEARCH_JAVA_OPTS" = "-Xms${osCfg.heapSize} -Xmx${osCfg.heapSize}";

        # Security plugin configuration
        # Para desenvolvimento: desabilitado (sem SSL)
        # Para produção: habilitar e configurar certificados SSL em osCfg.security.enableTLS
        "DISABLE_INSTALL_DEMO_CONFIG" = "true";
        "DISABLE_SECURITY_PLUGIN" = if osCfg.security.enableTLS then "false" else "true";
      };

      volumes = [
        "${toString osCfg.dataDir}:/usr/share/opensearch/data"
        "/var/lib/opensearch/config:/usr/share/opensearch/config/opensearch-security"
      ];

      ports = [
        "9200:9200" # REST API
        "9300:9300" # Node communication
      ];

      extraOptions = [
        "--ulimit=memlock=-1:-1"
        "--ulimit=nofile=65536:65536"
        "--memory=4g"
      ];
    };

    # OpenSearch Dashboards (Kibana alternative)
    virtualisation.oci-containers.containers.opensearch-dashboards = {
      image = "opensearchproject/opensearch-dashboards:2.11.1";
      autoStart = true;
      dependsOn = [ "opensearch" ];

      environment = {
        # Usa http:// sem SSL ou https:// com SSL baseado na configuração
        "OPENSEARCH_HOSTS" =
          if osCfg.security.enableTLS then "[\"https://localhost:9200\"]" else "[\"http://localhost:9200\"]";

        # Desabilita plugin de segurança quando não há SSL
        "DISABLE_SECURITY_DASHBOARDS_PLUGIN" = if osCfg.security.enableTLS then "false" else "true";
      };

      ports = [
        "5601:5601" # Dashboard UI
      ];

      extraOptions = [
        "--network=host"
      ];
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${toString osCfg.dataDir} 0750 1000 1000 -"
      "d /var/lib/opensearch/config 0750 1000 1000 -"
    ];

    # Index lifecycle management script
    environment.etc."opensearch/ilm-policy.json" = {
      mode = "0644";
      text = builtins.toJSON {
        policy = {
          description = "SOC security index lifecycle";
          default_state = "hot";
          states = [
            {
              name = "hot";
              actions = [
                {
                  rollover = {
                    min_doc_count = 1000000;
                    min_size = "10gb";
                  };
                }
              ];
              transitions = [
                {
                  state_name = "warm";
                  conditions = {
                    min_index_age = "7d";
                  };
                }
              ];
            }
            {
              name = "warm";
              actions = [
                {
                  replica_count = {
                    number_of_replicas = 0;
                  };
                }
                {
                  force_merge = {
                    max_num_segments = 1;
                  };
                }
              ];
              transitions = [
                {
                  state_name = "delete";
                  conditions = {
                    min_index_age = "${toString osCfg.indices.retentionDays}d";
                  };
                }
              ];
            }
            {
              name = "delete";
              actions = [
                {
                  delete = { };
                }
              ];
            }
          ];
        };
      };
    };

    # Index templates for SOC
    environment.etc."opensearch/soc-template.json" = {
      mode = "0644";
      text = builtins.toJSON {
        index_patterns = [ "${osCfg.indices.securityPrefix}-*" ];
        template = {
          settings = {
            number_of_shards = 1;
            number_of_replicas = osCfg.indices.replicaCount;
            "index.refresh_interval" = "5s";
            "index.codec" = "best_compression";
          };
          mappings = {
            properties = {
              "@timestamp" = {
                type = "date";
              };
              "source.ip" = {
                type = "ip";
              };
              "destination.ip" = {
                type = "ip";
              };
              "event.severity" = {
                type = "keyword";
              };
              "event.category" = {
                type = "keyword";
              };
              "rule.id" = {
                type = "keyword";
              };
              "rule.name" = {
                type = "text";
              };
              "agent.name" = {
                type = "keyword";
              };
              "host.hostname" = {
                type = "keyword";
              };
            };
          };
        };
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      9200
      5601
    ];

    # CLI aliases
    environment.shellAliases = {
      os-health = "curl -s -k https://localhost:9200/_cluster/health | jq";
      os-indices = "curl -s -k https://localhost:9200/_cat/indices?v";
      os-stats = "curl -s -k https://localhost:9200/_cluster/stats | jq";
    };
  };
}
