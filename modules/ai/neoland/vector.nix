# Vector — colector de logs para o stack AI neoland/neotron
#
# Fontes:
#   1. Journal do systemd filtrado por unit (neoland-*, neotron-*)
#   2. Logger Python "neutron.audit" → stdout capturado pelo journal
#
# Pipeline:
#   journald → parse_neoland_json → loki_sink
#              parse_neotron_json ↗
#
# O Vector do SOC (soc/siem/log-aggregator.nix) cobre infra geral.
# Este Vector cobre exclusivamente o namespace AI — separação de concerns.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neoland-vector;
  lokiPort = config.services.neoland-loki.port or 3100;
in
{
  options.services.neoland-vector = {
    enable = lib.mkEnableOption "Vector log pipeline para neoland/neotron";

    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:${toString lokiPort}";
      description = "Endpoint Loki onde os logs são enviados";
    };

    # Unidades systemd a monitorar
    units = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "neoland-control-plane.service"
        "neoland-dspy-pipeline.service"
        "neoland-ledger-subscriber.service"
        "neotron.service"
      ];
      description = "Unidades systemd cujos logs são recolhidos";
    };
  };

  config = lib.mkIf cfg.enable {
    # Vector é declarado pelo módulo SOC — aqui apenas extendemos a config
    # com sources/transforms/sinks adicionais via merge de atributos.
    #
    # Se o módulo SOC não estiver activo, activamos o serviço Vector aqui.
    services.vector = {
      enable = true;

      settings = {
        sources = {
          # Journal filtrado pelas units do stack AI
          neoland_journal = {
            type = "journald";
            current_boot_only = false;
            include_units = cfg.units;
          };
        };

        transforms = {
          # Logs do control-plane Rust (structured JSON via tracing-subscriber)
          parse_neoland = {
            type = "remap";
            inputs = [ "neoland_journal" ];
            source = ''
              # Tenta parsear como JSON (structured logging do Rust/Python)
              parsed, err = parse_json(.message)
              if err == null {
                . = merge(., parsed)
              }

              # Labels para Loki
              .job = if exists(.SYSTEMD_UNIT) {
                string!(.SYSTEMD_UNIT)
              } else {
                "neoland-unknown"
              }

              # Compliance audit events têm guardrail_name
              if exists(.guardrail_name) {
                .job = "neoland-audit"
                .regulation   = .regulation  ?? "unknown"
                .passed       = to_string!(.passed ?? true)
                .severity_lvl = .severity     ?? "audit"
              }

              # Pipeline events têm swarm_id (cortex) ou decision (tech-leader)
              if exists(.swarm_id) {
                .job = "neoland-cortex"
              }

              if exists(.decision) && !exists(.guardrail_name) {
                .job = "neoland-pipeline"
              }

              # NATS subjects para routing no Grafana
              if exists(.subject) {
                .nats_subject = string!(.subject)
              }

              .host = get_hostname!()
            '';
          };
        };

        sinks = {
          # Loki — Grafana consulta daqui
          loki_neoland = {
            type = "loki";
            inputs = [ "parse_neoland" ];
            endpoint = cfg.lokiUrl;
            encoding.codec = "json";

            # Labels indexados no Loki (cardinalidade baixa)
            labels = {
              job = "{{ job }}";
              host = "{{ host }}";
              passed = "{{ passed }}";
            };

            # Batch para eficiência
            batch = {
              max_bytes = 1048576; # 1 MB
              timeout_secs = 5;
            };

            # Retry em falha
            request = {
              retry_attempts = 5;
              retry_initial_backoff_secs = 1;
            };
          };
        };
      };
    };
  };
}
