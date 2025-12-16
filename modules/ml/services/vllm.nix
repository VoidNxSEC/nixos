{
  config,
  lib,
  pkgs,
  ...
}:

# vLLM Inference Server
#
# High-performance LLM inference with:
# - PagedAttention: Efficient KV cache memory management
# - Continuous batching: Dynamic request handling
# - Tensor parallelism: Multi-GPU support
# - OpenAI-compatible API
#
# Usage:
#   services.vllm.enable = true;
#   services.vllm.model = "meta-llama/Llama-3.1-8B-Instruct";

let
  cfg = config.services.vllm;
in
{
  options.services.vllm = {
    enable = lib.mkEnableOption "vLLM high-performance inference server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python311Packages.vllm or pkgs.vllm;
      defaultText = lib.literalExpression "pkgs.vllm";
      description = "The vLLM package to use.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      example = "meta-llama/Llama-3.1-8B-Instruct";
      description = ''
        Model identifier - can be:
        - HuggingFace model ID (e.g., "meta-llama/Llama-3.1-8B-Instruct")
        - Local path to model directory
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "IP address the server listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Listen port for the vLLM OpenAI-compatible API.";
    };

    # =====================
    # GPU CONFIGURATION
    # =====================

    tensorParallelSize = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = ''
        Number of GPUs to use for tensor parallelism.
        Set to the number of available GPUs for multi-GPU inference.
      '';
    };

    gpuMemoryUtilization = lib.mkOption {
      type = lib.types.float;
      default = 0.90;
      description = ''
        Fraction of GPU memory to use (0.0 to 1.0).
        Lower values leave room for other GPU processes.
      '';
    };

    # =====================
    # CONTEXT & BATCHING
    # =====================

    maxModelLen = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 8192;
      description = ''
        Maximum context length. If null, uses model's default.
        Common values: 4096, 8192, 16384, 32768.
      '';
    };

    maxNumSeqs = lib.mkOption {
      type = lib.types.int;
      default = 256;
      description = ''
        Maximum number of sequences per iteration.
        Higher = more throughput, but more memory.
      '';
    };

    maxNumBatchedTokens = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Maximum number of batched tokens per iteration.
        If null, uses model's default.
      '';
    };

    # =====================
    # QUANTIZATION
    # =====================

    quantization = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "awq"
          "gptq"
          "squeezellm"
          "fp8"
          "bitsandbytes"
        ]
      );
      default = null;
      example = "awq";
      description = ''
        Quantization method for the model.
        Options: awq, gptq, squeezellm, fp8, bitsandbytes.
      '';
    };

    dtype = lib.mkOption {
      type = lib.types.enum [
        "auto"
        "half"
        "float16"
        "bfloat16"
        "float"
        "float32"
      ];
      default = "auto";
      description = "Data type for model weights and activations.";
    };

    # =====================
    # API CONFIGURATION
    # =====================

    apiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional API key for authentication.
        Clients must provide this in Authorization header.
      '';
    };

    servedModelName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "llama3";
      description = ''
        Name to use for the model in API responses.
        If null, uses the model path/ID.
      '';
    };

    chatTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to custom chat template file.
        If null, uses model's built-in template.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--enable-prefix-caching"
        "--disable-log-requests"
      ];
      description = "Additional arguments passed to vllm serve.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for the server port.";
    };

    # =====================
    # HUGGINGFACE
    # =====================

    huggingfaceToken = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        HuggingFace token for private/gated models.
        Recommended: use environment file instead of plaintext.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/vllm-env";
      description = ''
        Environment file with secrets (e.g., HF_TOKEN).
        Format: KEY=value, one per line.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.vllm = {
      description = "vLLM OpenAI-Compatible Inference Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        CUDA_VISIBLE_DEVICES = "0";
        # HuggingFace cache
        HF_HOME = config.environment.variables.HF_HOME or "/var/lib/ml-models/huggingface";
        TRANSFORMERS_CACHE =
          config.environment.variables.TRANSFORMERS_CACHE or "/var/lib/ml-models/huggingface/hub";
        # Prevent OOM from memory fragmentation
        PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True";
      }
      // lib.optionalAttrs (cfg.huggingfaceToken != null) {
        HF_TOKEN = cfg.huggingfaceToken;
      };

      serviceConfig = {
        Type = "exec";
        ExecStart = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/vllm"
            "serve"
            "${cfg.model}"
            "--host ${cfg.host}"
            "--port ${toString cfg.port}"
            "--tensor-parallel-size ${toString cfg.tensorParallelSize}"
            "--gpu-memory-utilization ${toString cfg.gpuMemoryUtilization}"
            "--max-num-seqs ${toString cfg.maxNumSeqs}"
            "--dtype ${cfg.dtype}"
          ]
          ++ lib.optionals (cfg.maxModelLen != null) [
            "--max-model-len ${toString cfg.maxModelLen}"
          ]
          ++ lib.optionals (cfg.maxNumBatchedTokens != null) [
            "--max-num-batched-tokens ${toString cfg.maxNumBatchedTokens}"
          ]
          ++ lib.optionals (cfg.quantization != null) [
            "--quantization ${cfg.quantization}"
          ]
          ++ lib.optionals (cfg.apiKey != null) [
            "--api-key ${cfg.apiKey}"
          ]
          ++ lib.optionals (cfg.servedModelName != null) [
            "--served-model-name ${cfg.servedModelName}"
          ]
          ++ lib.optionals (cfg.chatTemplate != null) [
            "--chat-template ${cfg.chatTemplate}"
          ]
          ++ cfg.extraArgs
        );

        Restart = "always";
        RestartSec = 10;

        # Use dedicated user
        DynamicUser = lib.mkForce false;
        User = "vllm";
        Group = "vllm";

        # Environment file for secrets
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Graceful shutdown with GPU memory release
        TimeoutStopSec = "60s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";

        # GPU device access
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidia1 rw"
          "/dev/nvidia2 rw"
          "/dev/nvidia3 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
        ];

        # Required for GPU
        PrivateDevices = false;

        # Security hardening
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        NoNewPrivileges = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        MemoryDenyWriteExecute = false; # Required for PyTorch JIT
        LockPersonality = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        ProtectHostname = true;

        # Read-only bindings for model storage
        ReadOnlyPaths = [
          "/var/lib/ml-models"
        ];
        ReadWritePaths = [
          "/var/lib/ml-models/huggingface"
          "/var/lib/ml-models/cache"
        ];
      };
    };

    # Create vllm user
    users.users.vllm = {
      isSystemUser = true;
      group = "vllm";
      home = "/var/lib/vllm";
      description = "vLLM inference server user";
    };

    users.groups.vllm = { };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ kernelcore ];
}
