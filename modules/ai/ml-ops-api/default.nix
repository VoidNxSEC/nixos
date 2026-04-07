# ML-Ops API — Inference Backend
# Suporta múltiplos runtimes: local FastAPI, Triton, vLLM, custom Rust
# Target: Kubernetes GPU fleets (NVIDIA Inception Program)

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
    enable = lib.mkEnableOption "ML-Ops API inference backend";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    runtime = lib.mkOption {
      type = lib.types.enum [
        "fastapi"
        "triton"
        "vllm"
        "custom-rust"
      ];
      default = "fastapi";
      description = ''
        Inference runtime:
        - fastapi: local Python, dev/test only
        - triton: NVIDIA Triton Inference Server (k8s GPU fleet)
        - vllm: vLLM for LLM serving (k8s GPU fleet, NVIDIA Inception)
        - custom-rust: Candle-based Rust inference (neoland engine.rs)
      '';
    };

    # GPU configuration (k8s: resources.limits."nvidia.com/gpu")
    gpu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      count = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of GPUs to request (k8s GPU fleet)";
      };
      runtimeClass = lib.mkOption {
        type = lib.types.str;
        default = "nvidia";
        description = "Kubernetes RuntimeClass for GPU (NVIDIA Inception: 'nvidia')";
      };
    };

    # Kubernetes-specific (used when eco.deploymentMode != nixos)
    kubernetes = {
      serviceType = lib.mkOption {
        type = lib.types.enum [
          "ClusterIP"
          "LoadBalancer"
          "NodePort"
        ];
        default = "ClusterIP";
      };
      replicaCount = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of replicas in k8s Deployment";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "ml-ops";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optionals (cfg.runtime != "fastapi") [
      "ml-ops-api runtime '${cfg.runtime}' requires manual k8s deployment. NixOS systemd service only supports 'fastapi'."
    ];

    # Only start systemd service for local fastapi runtime
    systemd.services.ml-ops-api = lib.mkIf (cfg.runtime == "fastapi") {
      description = "ML-Ops API (FastAPI — local dev mode)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python311}/bin/python -m uvicorn ml_ops.app:app --host 127.0.0.1 --port ${toString cfg.port}";
        User = cfg.user;
        Restart = "on-failure";
        MemoryMax = "2G";
      };
    };

    users.users.${cfg.user} = lib.mkIf (cfg.runtime == "fastapi") {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = lib.mkIf (cfg.runtime == "fastapi") { };
  };
}
