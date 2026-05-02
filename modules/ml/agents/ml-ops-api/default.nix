# ML-Ops API — Rust inference gateway (ml-offload-api)
#
# Manages: OpenAI-compatible endpoints, priority queue orchestrator,
#          VRAM-aware backend router, Prometheus metrics, auth + rate-limiting.
#
# Secrets via sops-nix:
#   Set apiKeysSecretFile to a sops-managed EnvironmentFile containing
#   ML_OFFLOAD_API_KEYS=key1,key2,...
#   Leave unset for dev mode (no auth).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ml-ops-api;
  eco = config.ai.ecosystem;
in
{
  options.services.ml-ops-api = {
    enable = lib.mkEnableOption "ML-Ops API Rust inference gateway";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The ml-offload-api Rust binary package";
    };

    # ── Network ───────────────────────────────────────────────────────────────

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address. Use 0.0.0.0 only behind a reverse proxy.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9000;
    };

    corsEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable permissive CORS (only for local dev behind a proxy)";
    };

    # ── Storage ───────────────────────────────────────────────────────────────

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ml-offload";
    };

    modelsPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ml-models";
      description = "Directory where GGUF / safetensors model files are stored";
    };

    dbPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ml-offload/registry.db";
      description = "SQLite model registry database path";
    };

    # ── Backends ──────────────────────────────────────────────────────────────

    llamacppUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8080";
      description = "llama-server base URL";
    };

    vllmUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "vLLM server base URL. Empty = vLLM disabled.";
    };

    # ── Auth + Rate limiting ──────────────────────────────────────────────────

    apiKeysSecretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a systemd EnvironmentFile containing:
          ML_OFFLOAD_API_KEYS=key1,key2,...
        Typically a sops-nix secret path:
          config.sops.secrets."ml-ops-api/api-keys".path
        Leave null for dev mode (no auth enforced).
      '';
    };

    rateLimitRpm = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Per-API-key rate limit in requests per minute";
    };

    # ── Orchestrator ──────────────────────────────────────────────────────────

    orchestrator = {
      workers = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of worker tasks in the priority queue pool";
      };
      maxConcurrent = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "Max in-flight requests across all workers (semaphore)";
      };
      timeoutSecs = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "Per-request timeout before worker returns error";
      };
    };

    # ── NATS ──────────────────────────────────────────────────────────────────

    natsUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "NATS server URL for inference event publishing. Empty = disabled.";
    };

    # ── Resources (mirrors k8s requests/limits) ───────────────────────────────

    resources = {
      memoryMb = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Memory limit in MB";
      };
      cpuPercent = lib.mkOption {
        type = lib.types.int;
        default = 200;
        description = "CPU quota percent (200 = 2 cores)";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "ml-offload";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ml-ops-api = {
      description = "ML-Ops API — Rust inference gateway";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "llama-server.service"
      ];

      environment = lib.filterAttrs (_: v: v != "") {
        ML_OFFLOAD_HOST = cfg.host;
        ML_OFFLOAD_PORT = toString cfg.port;
        ML_OFFLOAD_DATA_DIR = cfg.dataDir;
        ML_OFFLOAD_MODELS_PATH = cfg.modelsPath;
        ML_OFFLOAD_DB_PATH = cfg.dbPath;
        ML_OFFLOAD_CORS_ENABLED = lib.boolToString cfg.corsEnabled;

        LLAMACPP_URL = cfg.llamacppUrl;
        VLLM_URL = cfg.vllmUrl;

        ML_OFFLOAD_RATE_LIMIT_RPM = toString cfg.rateLimitRpm;

        ORCHESTRATOR_WORKERS = toString cfg.orchestrator.workers;
        ORCHESTRATOR_MAX_CONCURRENT = toString cfg.orchestrator.maxConcurrent;
        ORCHESTRATOR_TIMEOUT_SECS = toString cfg.orchestrator.timeoutSecs;

        NATS_URL = cfg.natsUrl;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ml-offload-api";
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "5s";

        # Secrets injected at runtime — never in the Nix store
        EnvironmentFiles = lib.optional (cfg.apiKeysSecretFile != null) cfg.apiKeysSecretFile;

        StateDirectory = "ml-offload";
        LogsDirectory = "ml-offload";

        # Resource limits
        MemoryMax = "${toString cfg.resources.memoryMb}M";
        CPUQuota = "${toString cfg.resources.cpuPercent}%";

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          cfg.dataDir
          cfg.modelsPath
          "/var/log/ml-offload"
        ];
      };
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = cfg.dataDir;
      createHome = false;
    };
    users.groups.${cfg.user} = { };

    # Create data and models directories with correct ownership
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}   0750 ${cfg.user} ${cfg.user} -"
      "d ${cfg.modelsPath} 0750 ${cfg.user} ${cfg.user} -"
    ];
  };
}
