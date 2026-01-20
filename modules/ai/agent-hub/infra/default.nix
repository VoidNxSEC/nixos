{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.kernelcore.ai.agent-hub.infra;
in
{
  options.kernelcore.ai.agent-hub.infra = {
    enable = lib.mkEnableOption "Infraestrutura para Agent Hub 2.0";
    orchestrator = lib.mkOption {
      type = lib.types.enum [
        "nomad"
        "k3s"
      ];
      default = "nomad";
      description = "Orquestrador de agentes";
    };
  };

  config = lib.mkIf cfg.enable {
    # Orquestração Leve via Nomad
    services.nomad = lib.mkIf (cfg.orchestrator == "nomad") {
      enable = true;
      settings = {
        server = {
          enabled = true;
          bootstrap_expect = 1;
        };
        client = {
          enabled = true;
          # Suporte para driver de execução WASM (via raw_exec ou plugin)
          options = {
            "driver.raw_exec.enable" = "1";
          };
        };
      };
    };

    # Kafka-compatible Backbone (Redpanda)
    # Executado via Docker/Podman para manter o host limpo
    virtualisation.oci-containers.containers.redpanda = {
      image = "docker.redpanda.com/redpandadata/redpanda:latest";
      ports = [
        "9092:9092"
        "9644:9644"
      ];
      cmd = [
        "redpanda"
        "start"
        "--overprovisioned"
        "--smp 1"
        "--memory 1G"
        "--reserve-memory 0M"
        "--node-id 0"
        "--check=false"
      ];
    };

    # Monitoramento (Prometheus + Tempo para Tracing)
    services.prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "agent-hub-core";
          static_configs = [ { targets = [ "127.0.0.1:8081" ]; } ];
        }
      ];
    };
  };
}
