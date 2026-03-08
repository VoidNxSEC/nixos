# ═══════════════════════════════════════════════════════════════
# CHAINSCOPE — Crypto Intelligence Pipeline
# ═══════════════════════════════════════════════════════════════
# NixOS module para o pipeline de pesquisa de criptomoedas.
# Inference LLM na B300. Coleta exclusivamente dados públicos.
#
# Opções:
#   kernelcore.blockchain.chainscope.enable          = true/false
#   kernelcore.blockchain.chainscope.enableCollector = true/false
#   kernelcore.blockchain.chainscope.enableApi       = true/false
#   kernelcore.blockchain.chainscope.inferenceUrl    = "http://..."
# ═══════════════════════════════════════════════════════════════

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.blockchain.chainscope;

  # Python environment com todas as deps do CHAINSCOPE
  chainscopePython = pkgs.python313.withPackages (
    ps: with ps; [
      httpx
      aiohttp
      pydantic
      structlog
      asyncpg
      redis
      neo4j
      numpy
      pandas
      scipy
      scikit-learn
      fastapi
      uvicorn
      feedparser
      lxml
      beautifulsoup4
      orjson
      prometheus-client
    ]
  );

in
{
  # ══════════════════════════════════════════════════════════════
  # OPTIONS
  # ══════════════════════════════════════════════════════════════
  options.kernelcore.blockchain.chainscope = {

    enable = mkEnableOption "CHAINSCOPE crypto intelligence pipeline";

    enableCollector = mkOption {
      type = types.bool;
      default = false;
      description = "Habilita o serviço de coleta contínua (systemd).";
    };

    enableApi = mkOption {
      type = types.bool;
      default = false;
      description = "Habilita a API FastAPI de entrega de inteligência.";
    };

    inferenceUrl = mkOption {
      type = types.str;
      default = "http://localhost:9000";
      description = "URL do inference service (LLM na B300).";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/chainscope";
      description = "Diretório de dados persistentes do pipeline.";
    };

    apiPort = mkOption {
      type = types.port;
      default = 8420;
      description = "Porta da API FastAPI.";
    };

    # Storage overrides (defaults apontam para docker-compose local)
    timescaleUrl = mkOption {
      type = types.str;
      default = "postgresql://chainscope:chainscope@localhost:5432/chainscope";
    };
    redisUrl = mkOption {
      type = types.str;
      default = "redis://localhost:6379/0";
    };
    neo4jUrl = mkOption {
      type = types.str;
      default = "bolt://localhost:7687";
    };
    qdrantUrl = mkOption {
      type = types.str;
      default = "http://localhost:6333";
    };
  };

  # ══════════════════════════════════════════════════════════════
  # CONFIG
  # ══════════════════════════════════════════════════════════════
  config = mkIf cfg.enable {

    # ── Pacotes disponíveis no sistema ───────────────────────────
    environment.systemPackages = [
      chainscopePython
      pkgs.chainscope # CLI entry points do projeto
      pkgs.docker-compose # para `chainscope-infra up`
    ];

    # ── Variáveis de ambiente globais ────────────────────────────
    environment.sessionVariables = {
      CHAINSCOPE_DATA_DIR = cfg.dataDir;
      TIMESCALE_URL = cfg.timescaleUrl;
      REDIS_URL = cfg.redisUrl;
      NEO4J_URL = cfg.neo4jUrl;
      QDRANT_URL = cfg.qdrantUrl;
      INFERENCE_URL = cfg.inferenceUrl;
      CHAINSCOPE_API_PORT = toString cfg.apiPort;
    };

    # ── Shell aliases ─────────────────────────────────────────────
    environment.shellAliases = {
      # Infra
      chainscope-infra-up = "docker compose -f ${cfg.dataDir}/docker-compose.foundation.yml up -d";
      chainscope-infra-down = "docker compose -f ${cfg.dataDir}/docker-compose.foundation.yml down";
      chainscope-infra-logs = "docker compose -f ${cfg.dataDir}/docker-compose.foundation.yml logs -f";

      # Pipeline control
      chainscope-status = "systemctl status chainscope-collector chainscope-api 2>/dev/null || echo 'Services not enabled'";
      chainscope-logs = "journalctl -u chainscope-collector -u chainscope-api -f";
    };

    # ── Diretório de dados ────────────────────────────────────────
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}           0750 root root -"
      "d ${cfg.dataDir}/state     0750 root root -"
      "d ${cfg.dataDir}/logs      0750 root root -"
    ];

    # ── Collector Service (coleta contínua) ───────────────────────
    systemd.services.chainscope-collector = mkIf cfg.enableCollector {
      description = "CHAINSCOPE — Collector Pipeline";
      after = [
        "network.target"
        "docker.service"
      ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;

      environment = {
        CHAINSCOPE_ENV = "production";
        TIMESCALE_URL = cfg.timescaleUrl;
        REDIS_URL = cfg.redisUrl;
        NEO4J_URL = cfg.neo4jUrl;
        QDRANT_URL = cfg.qdrantUrl;
        INFERENCE_URL = cfg.inferenceUrl;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${chainscopePython}/bin/python -m services.collector.engine";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "30s";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "chainscope-collector";
      };
    };

    # ── API Service (FastAPI delivery layer) ─────────────────────
    systemd.services.chainscope-api = mkIf cfg.enableApi {
      description = "CHAINSCOPE — Intelligence API";
      after = [
        "network.target"
        "chainscope-collector.service"
      ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;

      environment = {
        CHAINSCOPE_ENV = "production";
        TIMESCALE_URL = cfg.timescaleUrl;
        REDIS_URL = cfg.redisUrl;
        NEO4J_URL = cfg.neo4jUrl;
        QDRANT_URL = cfg.qdrantUrl;
        INFERENCE_URL = cfg.inferenceUrl;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${chainscopePython}/bin/uvicorn services.delivery.api.app:app --host 0.0.0.0 --port ${toString cfg.apiPort}";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "chainscope-api";
      };
    };

    # ── Firewall: abrir porta da API (se enableApi) ───────────────
    networking.firewall.allowedTCPPorts = mkIf cfg.enableApi [ cfg.apiPort ];
  };
}
