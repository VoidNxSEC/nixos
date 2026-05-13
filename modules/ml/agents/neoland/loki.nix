# Loki — log aggregation para o stack AI (neoland + neotron)
#
# Recebe logs JSON via Vector (source: neoland-vector.nix).
# Grafana consulta Loki para:
#   - Audit trail de compliance (LGPD/GDPR/AI_ACT/SOC2)
#   - Pipeline multi-agent: duração, decisões, escalações
#   - BASTION/SENTINEL guardrail events
#
# Retenção: 30d (mínimo para ADR compliance trail).
# Soberania: self-hosted, nunca cloud — dados de orquestração são sensíveis.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neoland-loki;
in
{
  options.services.neoland-loki = {
    enable = lib.mkEnableOption "Loki log store para o stack AI neoland/neotron";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3100;
      description = "Porta HTTP do Loki";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/loki/neoland";
      description = "Diretório de armazenamento do Loki";
    };

    retentionDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Retenção em dias (mínimo 30 para compliance ADR)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      dataDir = cfg.dataDir;

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = cfg.port;
          grpc_listen_port = 9096;
          log_level = "warn";
        };

        common = {
          path_prefix = cfg.dataDir;
          storage.filesystem = {
            chunks_directory = "${cfg.dataDir}/chunks";
            rules_directory = "${cfg.dataDir}/rules";
          };
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
        };

        schema_config.configs = [
          {
            from = "2026-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "neoland_";
              period = "24h";
            };
          }
        ];

        limits_config = {
          # Retenção declarativa — dados de orquestração são sensíveis
          retention_period = "${toString cfg.retentionDays}d";
          # Neoland pipeline não é volume alto — limites generosos
          ingestion_rate_mb = 4;
          ingestion_burst_size_mb = 8;
          max_query_series = 5000;
        };

        compactor = {
          working_directory = "${cfg.dataDir}/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
          compaction_interval = "10m";
        };

        query_range.cache_results = true;

        ruler = {
          storage.type = "local";
          storage.local.directory = "${cfg.dataDir}/rules";
          rule_path = "${cfg.dataDir}/rules-temp";
          enable_api = true;
        };
      };
    };

    # Diretórios com permissões correctas
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}           0750 loki loki -"
      "d ${cfg.dataDir}/chunks    0750 loki loki -"
      "d ${cfg.dataDir}/rules     0750 loki loki -"
      "d ${cfg.dataDir}/compactor 0750 loki loki -"
    ];

    # Alias de conveniência
    environment.shellAliases = {
      loki-neoland = "curl -s 'http://localhost:${toString cfg.port}/loki/api/v1/labels' | jq";
      loki-audit = "curl -sG 'http://localhost:${toString cfg.port}/loki/api/v1/query_range' --data-urlencode 'query={job=\"neoland-audit\"}' --data-urlencode 'limit=50' | jq '.data.result[].values[][1]' -r | jq";
    };
  };
}
