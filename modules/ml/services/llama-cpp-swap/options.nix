# llamacpp-swap — option declarations (part of the llama-cpp-swap/ split;
# see ./default.nix for the implementation).
{ lib, pkgs, ... }:

{
  options.kernelcore.ml.inference.llamacpp-swap = {
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
      default = 38;
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
        "--tools"
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
}
