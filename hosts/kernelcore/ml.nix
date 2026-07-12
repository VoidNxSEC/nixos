{ ... }:

# ═══════════════════════════════════════════════════════════
# ML / IA — inferência llama.cpp, MCP, agent hub, storage de modelos
# ═══════════════════════════════════════════════════════════

{
  kernelcore.ml.models-storage = {
    enable = true;
    baseDirectory = "/var/lib/ml-models";
  };

  kernelcore.system.ml-gpu-users.enable = true;

  # ── Inferência ──
  kernelcore.ml.inference.llamacpp-turbo = {
    enable = false;
    model = "/var/lib/ml-models/llamacpp/models/Mixtral-4x7B-DPO-RPChat.Q4_K_M.gguf";
    host = "127.0.0.1";
    port = 8081;
    n_threads = 12;
    n_threads_batch = 12;
    n_gpu_layers = 40;
    mainGpu = 0; # CUDA backend only sees the NVIDIA GPU (Intel iGPU isn't CUDA-capable); 0 is the RTX 3050
    n_parallel = 1;
    n_ctx = 8196;
    n_batch = 2048;
    n_ubatch = 512;
    cudaGraphs = true;
    flashAttention = true;
    mmap = true;
    mlock = true;
    continuousBatching = true;
    speculativeDecoding.enable = false;
    metricsEndpoint = false;
  };

  # LlamaSwap - Hot Model Reloading
  kernelcore.ml.inference.llamacpp-swap = {
    enable = true;
    host = "127.0.0.1";
    port = 8081;
    n_threads = 12;
    n_threads_batch = 12;
    n_gpu_layers = 48;
    mainGpu = 1;
    n_parallel = 1;
    n_ctx = 8192;
    n_batch = 2048;
    n_ubatch = 512;
    cudaGraphs = true;
    flashAttention = true;
    mmap = true;
    mlock = true;
    continuousBatching = true;
    speculativeDecoding.enable = false;
    metricsEndpoint = false;
    embeddings = true;
    extraFlags = [
      "--jinja"
    ];
  };

  # LlamaSwap - perfis de hot reload (ex-kernelcore.llama-swap)
  kernelcore.ml.inference.swap-control = {
    enable = true;
    profiles = {
      coder = {
        modelPath = "/var/lib/ml-models/llamacpp/models/L3-8B-Stheno-v3.3-32K-Ultra-NEO-V1-IMATRIX-GGUF:Q4_K_M.gguf";
        displayName = "Qwen 2.5 Coder 7B (Q4)";
        gpuLayers = 999;
        contextSize = 8192;
      };

      reasoning = {
        modelPath = "/var/lib/ml-models/llamacpp/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf";
        displayName = "DeepSeek-R1 8B (Q4)";
        gpuLayers = 36;
        contextSize = 8192;
      };

      thinking = {
        modelPath = "/var/lib/ml-models/llamacpp/models/Llama3.3-8B-Instruct-Thinking-Claude-4.5-Opus-High-Reasoning.i1-Q4_K_M.gguf";
        displayName = "Llama 3.3 Thinking 8B (Q4)";
        gpuLayers = 42;
        contextSize = 8192;
      };

      fast = {
        modelPath = "/var/lib/ml-models/llamacpp/models/qwen3-vl:2b";
        displayName = "Qwen3 VL 2B (Fast)";
        gpuLayers = 999; # Full offload for small model
        contextSize = 4096;
      };
    };
    defaultProfile = "coder";
  };

  # Model Router – exposes all llama-swap profiles as /v1/models
  # Clients connect to :8080; router forwards to llamacpp-swap :8081
  kernelcore.ml.inference.router = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    backendPort = 8081;
  };

  # ── MCP ──
  kernelcore.ml.mcp = {
    enable = true;
    knowledgeDbPath = "/var/lib/mcp-knowledge/knowledge.db";
    agents = {
      roo = {
        enable = false;
        projectRoot = "/home/kernelcore/master";
        configPath = "/home/kernelcore/.roo/mcp.json";
        user = "kernelcore";
      };

      # AGENTES MCP
      # -----------------------------------------------------------
      codex = {
        enable = false;
        projectRoot = "/var/lib/codex";
        configPath = "/home/kernelcore/.codex/mcp_config.json";
        user = "kernelcore";
      };
      gemini = {
        enable = false;
        projectRoot = "/var/lib/gemini";
        configPath = "/home/kernelcore/.gemini/mcp_config.json";
        user = "kernelcore";
      };
      antigravity = {
        enable = false;
        projectRoot = "/var/lib/antigravity";
        configPath = "/home/kernelcore/.gemini/antigravity/mcp_config.json";
        user = "kernelcore";
      };

      zed-editor = {
        enable = true;
        projectRoot = "/var/lib/zed";
        configPath = "/home/kernelcore/.config/zed/mcp_config.json";
        user = "kernelcore";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/mcp-knowledge 0755 kernelcore users -"
  ];

  kernelcore.services.securellm-mcp = {
    enable = true;
    daemon.enable = true;
    daemon.logLevel = "INFO";

    # Dynamic project profiles - switch with: mcp-context profile <name>
    profiles = {
      nixos = {
        workdir = "/srv/nixos-config";
        environment = "production";
        env = {
          PROJECT_NAME = "NixOS Configuration";
          PROJECT_TYPE = "infrastructure";
        };
      };

      dev = {
        workdir = "/home/kernelcore/arch";
        environment = "development";
        env = {
          PROJECT_NAME = "Development";
          PROJECT_TYPE = "general";
        };
      };

      gemini = {
        workdir = "/var/lib/gemini";
        environment = "development";
        env = {
          PROJECT_NAME = "Gemini Agent";
          PROJECT_TYPE = "ai-agent";
        };
      };

      codex = {
        workdir = "/var/lib/codex";
        environment = "development";
        env = {
          PROJECT_NAME = "Codex";
          PROJECT_TYPE = "ai-agent";
        };
      };
    };
  };

  # ═══════════════════════════════════════════════════════════
  # AI AGENT HUB - Event-Driven Automation with Speech
  # ═══════════════════════════════════════════════════════════
  kernelcore.ai.agent-hub = {
    # Infrastructure (Nomad orchestrator + Redpanda/Kafka)
    # Disabled: eating too much RAM; re-enable when needed
    infra = {
      enable = false;
      orchestrator = "nomad";
    };
    # Speech Capabilities (F5-TTS + Whisper STT)
    capabilities.speech = {
      enable = true;
      enableTTS = false; # TODO: f5-tts wheel checa deps na instalação, falta propagatedBuildInputs completo
      enableSTT = true; # Whisper speech-to-text
      # Whisper model: tiny, base, small, medium, large
      # base = good balance between speed and accuracy
      whisperModel = "base";

      # Voice cloning reference (opcional - deixar default por enquanto)
      referenceText = "Olá, eu sou o assistente inteligente do Agent Hub.";
    };
  };

  # ── UIs / STT ──
  # Open-WebUI - upstream NixOS module (simple config)
  services.open-webui = {
    enable = false;
    host = "127.0.0.1";
    port = 3000;
    openFirewall = false;

    # Configuração via environment variables
    environment = {
      # Backend: TabbyAPI
      OPENAI_API_BASE_URL = "http://127.0.0.1:7734/v1";
      OPENAI_API_KEY = "not-needed";
      ENABLE_OPENAI_API = "true";
      ENABLE_OLLAMA_API = "false";

      # Disable analytics
      SCARF_NO_ANALYTICS = "true";
      DO_NOT_TRACK = "true";
      ANONYMIZED_TELEMETRY = "false";

      # Features
      ENABLE_SIGNUP = "false";
      DEFAULT_USER_ROLE = "user";
      ENABLE_IMAGE_GENERATION = "false";
    };
  };

  # SPOOKNIX - Privacy-first STT Engine (Docker container)
  services.spooknix = {
    enable = false;
    model = "large-v3";
    device = "cuda";
    port = 8000;
  };
}
