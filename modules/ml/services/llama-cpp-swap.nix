{
  config,
  lib,
  pkgs,
  ...
}:

# LLaMA.cpp SWAP - Hot Model Reloading System
#
# Based on llama-cpp-turbo with hot swap capability.
# Allows quick model switching via symlink with ~5-10s downtime.
#
# Optimizations enabled (same as turbo):
# - CUDA Graphs: Reduces kernel launch overhead (~1.2x speedup)
# - Flash Attention: Memory-efficient attention (lower VRAM, faster long context)
# - Speculative Decoding: Draft model acceleration (1.5-3x speedup)
# - Continuous Batching: Dynamic batch processing for concurrent requests
# - Memory-mapped I/O: Fast model loading with mmap/mlock
#
# Model swapping:
# - Model path points to symlink: /var/lib/llamacpp-swap/current-model
# - Scripts update symlink and restart service gracefully
# - Swap time: ~5-10s total downtime

let
  cfg = config.services.llamacpp-swap;

  boolToShell = value: if value then "true" else "false";

  memoryEquilibriumScript = pkgs.writeShellScript "llamacpp-swap-memory-equilibrium" ''
    set -euo pipefail

    mem_available_kb=$(${pkgs.gawk}/bin/awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    swap_total_kb=$(${pkgs.gawk}/bin/awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    swap_free_kb=$(${pkgs.gawk}/bin/awk '/^SwapFree:/ {print $2}' /proc/meminfo)
    swap_used_kb=$((swap_total_kb - swap_free_kb))
    reserve_kb=$((${toString cfg.memoryEquilibrium.reserveMemoryMiB} * 1024))

    echo "llamacpp-swap memory equilibrium: available=$((mem_available_kb / 1024))MiB swap_used=$((swap_used_kb / 1024))MiB reserve=${toString cfg.memoryEquilibrium.reserveMemoryMiB}MiB"

    if [ "$swap_used_kb" -gt 0 ]; then
      required_kb=$((swap_used_kb + reserve_kb))

      if [ "$mem_available_kb" -gt "$required_kb" ]; then
        echo "llamacpp-swap memory equilibrium: flushing swap back to RAM before inference"
        if ${pkgs.util-linux}/bin/swapoff -a; then
          ${pkgs.util-linux}/bin/swapon -a
          echo "llamacpp-swap memory equilibrium: swap flush complete"
        else
          echo "llamacpp-swap memory equilibrium: swapoff failed, restoring swap and continuing" >&2
          ${pkgs.util-linux}/bin/swapon -a || true
        fi
      else
        echo "llamacpp-swap memory equilibrium: keeping swap online; RAM cannot safely absorb used swap plus reserve" >&2
      fi
    fi

    ${lib.optionalString cfg.memoryEquilibrium.compactMemory ''
      echo 1 > /proc/sys/vm/compact_memory || true
    ''}

    ${lib.optionalString cfg.memoryEquilibrium.dropCaches ''
      echo 3 > /proc/sys/vm/drop_caches || true
    ''}
  '';

  launchScript = pkgs.writeShellScript "llamacpp-swap-launch" ''
    set -euo pipefail

    SWAP_DIR="/var/lib/llamacpp-swap"
    PROFILES_JSON="$SWAP_DIR/profiles.json"
    CURRENT_PROFILE_FILE="$SWAP_DIR/current-profile"
    CURRENT_PROFILE="$(${pkgs.coreutils}/bin/cat "$CURRENT_PROFILE_FILE" 2>/dev/null || true)"

    profile_value() {
      local key="$1"
      if [ -z "$CURRENT_PROFILE" ] || [ ! -f "$PROFILES_JSON" ]; then
        return 0
      fi

      ${pkgs.jq}/bin/jq -r --arg profile "$CURRENT_PROFILE" --arg key "$key" '.[$profile][$key] // empty' "$PROFILES_JSON" 2>/dev/null || true
    }

    profile_int() {
      local key="$1"
      local default="$2"
      local value
      value="$(profile_value "$key")"

      if [[ "$value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$value"
      else
        printf '%s\n' "$default"
      fi
    }

    profile_bool() {
      local key="$1"
      local default="$2"
      local value
      value="$(profile_value "$key")"

      case "$value" in
        true|false) printf '%s\n' "$value" ;;
        *) printf '%s\n' "$default" ;;
      esac
    }

    MODEL_PATH="$(profile_value modelPath)"
    if [ -z "$MODEL_PATH" ]; then
      MODEL_PATH="${cfg.model}"
    fi

    if [ ! -e "$MODEL_PATH" ] && [ ! -L "$MODEL_PATH" ]; then
      echo "llamacpp-swap: model path is missing: $MODEL_PATH" >&2
      exit 1
    fi

    GPU_LAYERS="$(profile_int gpuLayers "${toString cfg.n_gpu_layers}")"
    CTX_SIZE="$(profile_int contextSize "${toString cfg.n_ctx}")"
    BATCH_SIZE="$(profile_int batchSize "${toString cfg.n_batch}")"
    UBATCH_SIZE="$(profile_int ubatchSize "${toString cfg.n_ubatch}")"
    PARALLEL="$(profile_int parallel "${toString cfg.n_parallel}")"
    THREADS="$(profile_int threads "${toString cfg.n_threads}")"
    THREADS_BATCH="$(profile_int threadsBatch "${toString cfg.n_threads_batch}")"
    NO_KV_OFFLOAD="$(profile_bool noKvOffload "${boolToShell cfg.noKvOffload}")"
    MLOCK="$(profile_bool mlock "${boolToShell cfg.mlock}")"

    echo "llamacpp-swap: launching profile=''${CURRENT_PROFILE:-none} model=$MODEL_PATH gpu_layers=$GPU_LAYERS ctx=$CTX_SIZE batch=$BATCH_SIZE ubatch=$UBATCH_SIZE parallel=$PARALLEL"

    args=(
      --host "${cfg.host}"
      --port "${toString cfg.port}"
      --model "$MODEL_PATH"
      --threads "$THREADS"
      --threads-batch "$THREADS_BATCH"
      --gpu-layers "$GPU_LAYERS"
      --main-gpu "${toString cfg.mainGpu}"
      --parallel "$PARALLEL"
      --ctx-size "$CTX_SIZE"
      --batch-size "$BATCH_SIZE"
      --ubatch-size "$UBATCH_SIZE"
    )

    ${lib.optionalString cfg.flashAttention ''
      args+=(--flash-attn on)
    ''}
    ${lib.optionalString (!cfg.mmap) ''
      args+=(--no-mmap)
    ''}

    if [ "$MLOCK" = "true" ]; then
      args+=(--mlock)
    fi

    if [ "$NO_KV_OFFLOAD" = "true" ]; then
      args+=(--no-kv-offload)
    fi

    ${lib.optionalString (cfg.speculativeDecoding.enable && cfg.speculativeDecoding.draftModel != null)
      ''
        args+=(
          --model-draft "${cfg.speculativeDecoding.draftModel}"
          --gpu-layers-draft "${toString cfg.speculativeDecoding.draftGpuLayers}"
          --draft-max "${toString cfg.speculativeDecoding.draftMax}"
          --draft-min "${toString cfg.speculativeDecoding.draftMin}"
          --draft-p-min "${toString cfg.speculativeDecoding.draftPMin}"
        )
      ''
    }
    ${lib.optionalString cfg.continuousBatching ''
      args+=(--cont-batching)
    ''}
    ${lib.optionalString (cfg.chatTemplate != null) ''
      args+=(--chat-template ${lib.escapeShellArg cfg.chatTemplate})
    ''}
    ${lib.optionalString (cfg.apiKey != null) ''
      args+=(--api-key ${lib.escapeShellArg cfg.apiKey})
    ''}
    ${lib.optionalString cfg.metricsEndpoint ''
      args+=(--metrics)
    ''}
    ${lib.optionalString cfg.embeddings ''
      args+=(--embeddings)
    ''}
    ${lib.optionalString (cfg.extraFlags != [ ]) ''
      args+=(${lib.escapeShellArgs cfg.extraFlags})
    ''}

    exec ${lib.getExe' cfg.package "llama-server"} "''${args[@]}"
  '';
in
{
  options.services.llamacpp-swap = {
    enable = lib.mkEnableOption "LLaMA.cpp SWAP - hot model reloading inference server";

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
      default = "/var/lib/llamacpp-swap/current-model";
      description = ''
        Path to the GGUF model file or symlink.
        Default points to symlink managed by llama-swap scripts.
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
      default = 8081;
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
      default = 36;
      description = ''
        Number of model layers to offload to GPU.
        Recommended: 30 for ~4GB VRAM (8B Q4), 40+ for 8GB+ VRAM.
        Set to 0 for CPU-only mode, 999 for full GPU offload.
      '';
    };

    mainGpu = lib.mkOption {
      type = lib.types.int;
      default = 1;
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
      default = 8192;
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
      default = false;
      description = ''
        Lock model pages in RAM (prevents swapping).
        Requires sufficient RAM for the model.
      '';
    };

    noKvOffload = lib.mkOption {
      type = lib.types.bool;
      default = true;
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
        example = "/var/lib/ml-models/llamacpp/models/Qwen2.5-0.5B-Q4_K_M.gguf";
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
      default = false;
      description = "Enable /metrics endpoint for Prometheus.";
    };

    embeddings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable embeddings support in llama-server via --embeddings.
      '';
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
      default = true;
      description = "Open firewall for the server port.";
    };

    memoryHigh = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional soft cgroup memory pressure point. Leave null for maximum
        throughput because memory.high can throttle llama.cpp under pressure.
      '';
    };

    memoryMax = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional hard cgroup memory ceiling. Leave null for maximum throughput.
      '';
    };

    memoryLow = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional protected memory for LlamaSwap. This improves performance under
        pressure without throttling the process.
      '';
    };

    memoryEquilibrium = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Run a startup preflight that safely flushes used swap back into RAM
          before starting llama.cpp.
        '';
      };

      reserveMemoryMiB = lib.mkOption {
        type = lib.types.int;
        default = 2048;
        description = ''
          Free RAM reserve kept after swap flushing. Swap is only recycled when
          MemAvailable can absorb used swap plus this reserve.
        '';
      };

      compactMemory = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Compact memory before launching llama.cpp.";
      };

      dropCaches = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Drop page cache before launching. Disabled by default so mmap-backed
          model pages can stay hot across restarts.
        '';
      };

      disableServiceSwap = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Set MemorySwapMax=0 for the llama.cpp service so inference pages do
          not migrate to swap after startup.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create dedicated user for llamacpp-swap
    users.users.llamacpp-swap = {
      isSystemUser = true;
      group = "llamacpp-swap";
      home = "/var/lib/llamacpp-swap";
      description = "LlamaSwap service user";
    };

    users.groups.llamacpp-swap = { };

    # Create swap directory structure
    systemd.tmpfiles.rules = [
      "d /var/lib/llamacpp-swap 0755 llamacpp-swap llamacpp-swap -"
      "d /var/lib/llamacpp-swap/profiles 0755 llamacpp-swap llamacpp-swap -"
    ];

    systemd.services.llamacpp-swap = {
      description = "LLaMA.cpp SWAP - Hot Model Reloading Inference Server";
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
        ExecStart = "${launchScript}";

        Restart = "always";
        RestartSec = 5;
        MemoryAccounting = true;
        OOMScoreAdjust = -500;
        ManagedOOMPreference = "avoid";
        Slice = "ml.slice";
        LimitMEMLOCK = "infinity";

        # Use dedicated user
        DynamicUser = lib.mkForce false;
        User = "llamacpp-swap";
        Group = "llamacpp-swap";

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
          "/var/lib/llamacpp-swap"
          "/var/lib/ml-models"
        ];

        # Writable for symlink management (needed for service startup)
        ReadWritePaths = [ ];
      }
      // lib.optionalAttrs (cfg.memoryLow != null) {
        MemoryLow = cfg.memoryLow;
      }
      // lib.optionalAttrs (cfg.memoryHigh != null) {
        MemoryHigh = cfg.memoryHigh;
      }
      // lib.optionalAttrs (cfg.memoryMax != null) {
        MemoryMax = cfg.memoryMax;
      }
      // lib.optionalAttrs cfg.memoryEquilibrium.enable {
        ExecStartPre = "+${memoryEquilibriumScript}";
      }
      // lib.optionalAttrs cfg.memoryEquilibrium.disableServiceSwap {
        MemorySwapMax = "0";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ marcosfpina ];
}
