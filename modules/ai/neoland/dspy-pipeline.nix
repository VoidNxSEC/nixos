# Neoland DSPy Pipeline — Python/FastAPI (systemd service)
# Kubernetes equivalent: Deployment + Service, no GPU (CPU inference via LLM API)

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neoland-dspy-pipeline;
  eco = config.ai.ecosystem;

  pythonEnv = pkgs.python311.withPackages (
    ps: with ps; [
      uvicorn
      fastapi
      pydantic
      asyncpg
      httpx
      # dspy installed via pip in workdir venv (not in nixpkgs yet)
    ]
  );
in
{
  options.services.neoland-dspy-pipeline = {
    enable = lib.mkEnableOption "Neoland DSPy multi-agent pipeline";

    workdir = lib.mkOption {
      type = lib.types.path;
      description = "Path to the agents/ directory (neoland repo)";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8001;
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      description = "PostgreSQL connection string";
    };

    llmProvider = lib.mkOption {
      type = lib.types.str;
      default = "openai";
    };

    llmModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-4o-mini";
    };

    llmApiKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the LLM API key (sops-nix decrypted path)";
    };

    checkpointDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/neoland/checkpoints/adr";
    };

    # ── Ciclo 1 — Fase A: mmap IPC ────────────────────────────────────────
    shmPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/neoland/agent-flags.shm";
      description = "Path do arquivo mmap IPC com o control plane Rust.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "neoland";
    };

    resources = {
      memoryMb = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Memory limit in MB";
      };
      cpuPercent = lib.mkOption {
        type = lib.types.int;
        default = 100;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.neoland-dspy-pipeline = {
      description = "Neoland DSPy Multi-Agent Pipeline (Python/FastAPI)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];

      environment = {
        DATABASE_URL = cfg.databaseUrl;
        NEOLAND_LLM_PROVIDER = cfg.llmProvider;
        NEOLAND_LLM_MODEL = cfg.llmModel;
        NEOLAND_CHECKPOINT_DIR = cfg.checkpointDir;
        NEOLAND_PIPELINE_PORT = toString cfg.port;
        NEOLAND_RAG_TOP_K = "5";
        NEOLAND_SHM_PATH = cfg.shmPath;
        # Ecosystem service URLs available to the pipeline
        AI_CEREBRO_URL = eco.services.cerebro.url;
        AI_CEREBRO_ENABLED = lib.boolToString eco.services.cerebro.enabled;
        AI_PHANTOM_URL = eco.services.phantom.url;
        AI_PHANTOM_ENABLED = lib.boolToString eco.services.phantom.enabled;
        AI_NEOTRON_URL = eco.services.neotron.url;
        AI_NEOTRON_GUARDRAILS = lib.boolToString eco.services.neotron.guardrailsEnabled;
      };

      serviceConfig = {
        # Load LLM API key from sops-decrypted file
        ExecStartPre = [
          "${pkgs.bash}/bin/bash -c 'export LLM_API_KEY=$(cat ${cfg.llmApiKeyFile})'"
        ];
        ExecStart = ''
          ${pythonEnv}/bin/uvicorn neoland_agents.app:app \
            --host 127.0.0.1 \
            --port ${toString cfg.port} \
            --log-level info
        '';
        WorkingDirectory = cfg.workdir;
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "10s";

        # Resource limits
        MemoryMax = "${toString cfg.resources.memoryMb}M";
        CPUQuota = "${toString cfg.resources.cpuPercent}%";

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.checkpointDir ];
      };
    };
  };
}
