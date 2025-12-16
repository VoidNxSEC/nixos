{
  config,
  lib,
  pkgs,
  ...
}:

# LLaMA.cpp TURBO - High-Performance Inference Server
#
# Optimizations enabled:
# - CUDA Graphs: Reduces kernel launch overhead (~1.2x speedup)
# - Flash Attention: Memory-efficient attention (lower VRAM, faster long context)
# - Speculative Decoding: Draft model acceleration (1.5-3x speedup)
# - Continuous Batching: Dynamic batch processing for concurrent requests
# - Memory-mapped I/O: Fast model loading with mmap/mlock
#
# Designed to replace Ollama with superior performance on NVIDIA GPUs.

let
  cfg = config.services.llamacpp-turbo;
in
{
  options.services.llamacpp-turbo = {
    enable = lib.mkEnableOption "LLaMA.cpp TURBO - high-performance inference server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp.override {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages;
      };
      defaultText = lib.literalExpression ''
        pkgs.llama-cpp.override {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages;
        }
      '';
      description = "The llama-cpp package to use (CUDA-enabled by default).";
    };

    model = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/ml-models/llama-cpp/DeepSeek-R1-8B-Q4_K_M.gguf";
      description = "Path to the main GGUF model file.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "IP address the server listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Listen port for the inference server.";
    };

    # =====================
    # THREADING & COMPUTE
    # =====================

    n_threads = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = ''
        Number of threads for generation.
        Recommended: Use physical core count only (not hyperthreads).
      '';
    };

    n_threads_batch = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = ''
        Number of threads for batch processing.
        Usually same as n_threads unless you want different parallelism.
      '';
    };

    # =====================
    # GPU CONFIGURATION
    # =====================

    n_gpu_layers = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Number of model layers to offload to GPU.
        Recommended: 30 for ~4GB VRAM (8B Q4), 40+ for 8GB+ VRAM.
        Set to 0 for CPU-only mode, 999 for full GPU offload.
      '';
    };

    mainGpu = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Main GPU index for inference (0 = first GPU).";
    };

    # =====================
    # CONTEXT & BATCHING
    # =====================

    n_parallel = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = ''
        Number of parallel sequences (concurrent requests).
        Higher = more throughput, but more VRAM usage.
      '';
    };

    n_ctx = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = ''
        Context window size in tokens.
        Common values: 4096, 8192, 16384, 32768.
        Larger = more VRAM required.
      '';
    };

    n_batch = lib.mkOption {
      type = lib.types.int;
      default = 2048;
      description = ''
        Batch size for prompt processing.
        Larger = faster prompt processing, more VRAM.
      '';
    };

    n_ubatch = lib.mkOption {
      type = lib.types.int;
      default = 512;
      description = ''
        Micro-batch size for GPU compute.
        Sweet spot is usually 256-512.
      '';
    };

    # =====================
    # PERFORMANCE FLAGS
    # =====================

    cudaGraphs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable CUDA Graphs for reduced kernel launch overhead.
        Provides ~1.2x speedup on NVIDIA GPUs.
        Default is true for batch size 1 inference.
      '';
    };

    flashAttention = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable Flash Attention for memory-efficient attention.
        Reduces VRAM usage and improves long context performance.
      '';
    };

    mmap = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use memory-mapped I/O for model loading.
        Faster startup, lower peak RAM usage.
      '';
    };

    mlock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Lock model pages in RAM (prevents swapping).
        Requires sufficient RAM for the model.
      '';
    };

    noKvOffload = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Disable KV cache offload to GPU.
        Set true if VRAM is limited.
      '';
    };

    # =====================
    # SPECULATIVE DECODING
    # =====================

    speculativeDecoding = {
      enable = lib.mkEnableOption "speculative decoding with draft model";

      draftModel = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/var/lib/ml-models/llama-cpp/Qwen2.5-0.5B-Q4_K_M.gguf";
        description = ''
          Path to the draft model for speculative decoding.
          Should be a smaller, faster model from same family.
        '';
      };

      draftGpuLayers = lib.mkOption {
        type = lib.types.int;
        default = 999;
        description = "GPU layers for draft model (999 = full offload).";
      };

      draftMax = lib.mkOption {
        type = lib.types.int;
        default = 16;
        description = "Maximum speculative tokens per iteration.";
      };

      draftMin = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Minimum speculative tokens.";
      };

      draftPMin = lib.mkOption {
        type = lib.types.float;
        default = 0.8;
        description = "Minimum probability for speculation.";
      };
    };

    # =====================
    # CONTINUOUS BATCHING
    # =====================

    continuousBatching = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable continuous batching for dynamic request handling.
        Improves throughput with multiple concurrent requests.
      '';
    };

    # =====================
    # API & SERVER
    # =====================

    chatTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "chatml";
      description = ''
        Chat template to use (e.g., chatml, llama2, mistral).
        If null, uses model's built-in template.
      '';
    };

    apiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional API key for authentication.
        Clients must provide this in Authorization header.
      '';
    };

    metricsEndpoint = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable /metrics endpoint for Prometheus.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--temp"
        "0.7"
        "--top-p"
        "0.9"
      ];
      description = "Additional flags passed to llama-server.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for the server port.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.llamacpp-turbo = {
      description = "LLaMA.cpp TURBO - High-Performance Inference Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        # CUDA optimizations
        CUDA_VISIBLE_DEVICES = "0";
        GGML_CUDA_NO_PEER_COPY = "1";
        # Enable CUDA Graphs (default in recent llama.cpp)
        GGML_CUDA_ENABLE_UNIFIED_MEMORY = "0";
        # Reduce CPU overhead
        OMP_NUM_THREADS = toString cfg.n_threads;
      };

      serviceConfig = {
        Type = "exec";
        ExecStart = lib.concatStringsSep " " (
          [
            "${lib.getExe' cfg.package "llama-server"}"
            "--host ${cfg.host}"
            "--port ${toString cfg.port}"
            "--model ${cfg.model}"
            "--threads ${toString cfg.n_threads}"
            "--threads-batch ${toString cfg.n_threads_batch}"
            "--gpu-layers ${toString cfg.n_gpu_layers}"
            "--main-gpu ${toString cfg.mainGpu}"
            "--parallel ${toString cfg.n_parallel}"
            "--ctx-size ${toString cfg.n_ctx}"
            "--batch-size ${toString cfg.n_batch}"
            "--ubatch-size ${toString cfg.n_ubatch}"
          ]
          # CUDA Graphs (no explicit flag needed in recent versions, enabled by default for bs=1)
          # Flash Attention
          ++ lib.optionals cfg.flashAttention [ "--flash-attn on" ]
          # Memory options
          ++ lib.optionals (!cfg.mmap) [ "--no-mmap" ]
          ++ lib.optionals cfg.mlock [ "--mlock" ]
          ++ lib.optionals cfg.noKvOffload [ "--no-kv-offload" ]
          # Speculative decoding
          ++ lib.optionals (cfg.speculativeDecoding.enable && cfg.speculativeDecoding.draftModel != null) [
            "--model-draft ${cfg.speculativeDecoding.draftModel}"
            "--gpu-layers-draft ${toString cfg.speculativeDecoding.draftGpuLayers}"
            "--draft-max ${toString cfg.speculativeDecoding.draftMax}"
            "--draft-min ${toString cfg.speculativeDecoding.draftMin}"
            "--draft-p-min ${toString cfg.speculativeDecoding.draftPMin}"
          ]
          # Continuous batching
          ++ lib.optionals cfg.continuousBatching [ "--cont-batching" ]
          # Chat template
          ++ lib.optionals (cfg.chatTemplate != null) [ "--chat-template ${cfg.chatTemplate}" ]
          # API key
          ++ lib.optionals (cfg.apiKey != null) [ "--api-key ${cfg.apiKey}" ]
          # Metrics
          ++ lib.optionals cfg.metricsEndpoint [ "--metrics" ]
          # Disable web UI for server-only mode
          ++ [ "--no-webui" ]
          # Extra flags
          ++ cfg.extraFlags
        );

        Restart = "always";
        RestartSec = 5;

        # Use dedicated user
        DynamicUser = lib.mkForce false;
        User = "llamacpp";
        Group = "llamacpp";

        # Graceful shutdown with GPU memory release
        TimeoutStopSec = "30s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";

        # GPU device access
        DeviceAllow = [
          "/dev/nvidia0 rw"
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
        MemoryDenyWriteExecute = false; # Required for CUDA JIT
        LockPersonality = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallErrorNumber = "EPERM";
        ProtectProc = "invisible";
        ProtectHostname = true;
        ProcSubset = "pid";

        # Read-only bindings for model storage
        ReadOnlyPaths = [
          "/var/lib/llamacpp"
        ];
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ marcosfpina ];
}
