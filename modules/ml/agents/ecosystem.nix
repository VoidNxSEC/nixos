# AI Ecosystem — Service Discovery Registry
#
# Single source of truth for inter-service URLs.
# Both NixOS (systemd) and Kubernetes deployments read from here.
# No service hardcodes the URL of another — all via this registry.

{ config, lib, ... }:

let
  cfg = config.ai.ecosystem;
in
{
  options.ai.ecosystem = {
    # ── Deployment mode ────────────────────────────────────────────────────
    deploymentMode = lib.mkOption {
      type = lib.types.enum [
        "nixos"
        "kubernetes"
        "hybrid"
      ];
      default = "nixos";
      description = ''
        Target deployment mode.
        - nixos: systemd services on NixOS host
        - kubernetes: external k8s cluster (URLs point to k8s services)
        - hybrid: NixOS host + remote k8s backends (e.g. ml-ops-api on k8s)
      '';
    };

    # ── Service URLs (consumed by all services) ────────────────────────────
    services = {
      neoland = {
        controlPlaneUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:3001";
          description = "Neoland Rust control plane REST API";
        };
        pipelineUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:8001";
          description = "Neoland DSPy agent pipeline FastAPI";
        };
      };

      neotron = {
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:8010";
          description = "Neotron guardrails + agent orchestration";
        };
        guardrailsEnabled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Neotron guardrails intercepting agent pipeline decisions";
        };
      };

      mlOpsApi = {
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:8080";
          description = "ML-Ops API inference backend (local) or k8s service URL";
        };
        gpuEnabled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether the ML-Ops API backend has GPU access";
        };
        runtime = lib.mkOption {
          type = lib.types.enum [
            "fastapi"
            "triton"
            "vllm"
            "custom-rust"
          ];
          default = "fastapi";
          description = "Inference runtime behind the ML-Ops API";
        };
      };

      cerebro = {
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:8016";
          description = "Cerebro semantic reranker for RAG";
        };
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Cerebro reranker in the RAG pipeline";
        };
      };

      phantom = {
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:8008";
          description = "Phantom security scan / secret detection";
        };
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Phantom security scanning";
        };
      };
    };

    # ── Kubernetes configuration (used when deploymentMode != nixos) ───────
    kubernetes = {
      namespace = lib.mkOption {
        type = lib.types.str;
        default = "ai-ecosystem";
        description = "Kubernetes namespace for all AI services";
      };
      ingressDomain = lib.mkOption {
        type = lib.types.str;
        default = "ai.internal";
        description = "Base domain for k8s ingress (service.namespace.ingressDomain)";
      };
      nvidiaRuntimeClass = lib.mkOption {
        type = lib.types.str;
        default = "nvidia";
        description = "Kubernetes RuntimeClass for GPU workloads (NVIDIA Inception)";
      };
    };
  };

  # ── Derived environment (available to all services via env vars) ──────────
  config = lib.mkIf (cfg.deploymentMode != "kubernetes") {
    environment.variables = {
      # Service discovery — consumed by neoland, neotron, phantom, cerebro
      AI_NEOLAND_URL = cfg.services.neoland.controlPlaneUrl;
      AI_NEOLAND_PIPELINE = cfg.services.neoland.pipelineUrl;
      AI_NEOTRON_URL = cfg.services.neotron.url;
      AI_MLOPS_URL = cfg.services.mlOpsApi.url;
      AI_CEREBRO_URL = cfg.services.cerebro.url;
      AI_PHANTOM_URL = cfg.services.phantom.url;
      AI_DEPLOYMENT_MODE = cfg.deploymentMode;
    };
  };
}
