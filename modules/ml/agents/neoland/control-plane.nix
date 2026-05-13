# Neoland Control Plane — Rust binary (systemd service)
# Kubernetes equivalent: Deployment + Service + liveness/readiness probes
#
# Ciclo 1 additions:
#   - shmPath    — mmap IPC com o pipeline Python (Fase A)
#   - natsUrl    — NATS publisher via spectre-events (Fase B)
#   - RuntimeDirectory = "neoland" — cria /run/neoland/ para o shm

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neoland-control-plane;
  eco = config.ai.ecosystem;
in
{
  options.services.neoland-control-plane = {
    enable = lib.mkEnableOption "Neoland Rust control plane";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The neoland binary package";
    };

    grpcPort = lib.mkOption {
      type = lib.types.port;
      default = 50051;
    };

    restPort = lib.mkOption {
      type = lib.types.port;
      default = 3001;
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      description = "PostgreSQL connection string (via sops-nix)";
    };

    # ── Ciclo 1 — Fase A: mmap IPC ────────────────────────────────────────
    shmPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/neoland/agent-flags.shm";
      description = "Path do arquivo mmap IPC com o pipeline Python.";
    };

    # ── Ciclo 1 — Fase B: NATS publisher ──────────────────────────────────
    natsUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "NATS server URL. Vazio = NATS desabilitado.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "neoland";
    };

    # ── Resource limits (maps to k8s requests/limits) ─────────────────────
    resources = {
      memoryMb = lib.mkOption {
        type = lib.types.int;
        default = 512;
        description = "Memory limit in MB (k8s: resources.limits.memory)";
      };
      cpuPercent = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "CPU quota percent (k8s: resources.limits.cpu)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.neoland-control-plane = {
      description = "Neoland AI Control Plane (Rust)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
        "neoland-dspy-pipeline.service"
      ];

      environment = lib.filterAttrs (_: v: v != "") {
        NEOLAND_GRPC_PORT = toString cfg.grpcPort;
        NEOLAND_REST_PORT = toString cfg.restPort;
        DATABASE_URL = cfg.databaseUrl;
        NEOLAND_SHM_PATH = cfg.shmPath;
        NEOLAND_NATS_URL = cfg.natsUrl;
        # Service discovery from ecosystem registry
        NEOLAND_AGENTS_DSPY_URL = eco.services.neoland.pipelineUrl;
        AI_NEOTRON_URL = eco.services.neotron.url;
        AI_MLOPS_URL = eco.services.mlOpsApi.url;
        AI_CEREBRO_URL = eco.services.cerebro.url;
        AI_PHANTOM_URL = eco.services.phantom.url;
        AI_NEOTRON_GUARDRAILS = lib.boolToString eco.services.neotron.guardrailsEnabled;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/neoland server";
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "neoland";
        RuntimeDirectory = "neoland"; # cria /run/neoland/ — necessário para o shm
        LogsDirectory = "neoland";

        # Resource limits (mirrors k8s limits)
        MemoryMax = "${toString cfg.resources.memoryMb}M";
        CPUQuota = "${toString cfg.resources.cpuPercent}%";

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          "/var/lib/neoland"
          "/var/log/neoland"
          "/run/neoland"
        ];
      };
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };
  };
}
