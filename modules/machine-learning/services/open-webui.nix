{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.open-webui;
in
{
  options.kernelcore.open-webui = {
    enable = mkEnableOption "Open-WebUI - Self-hosted AI Chat Interface";

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host to bind the web interface to";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the web interface";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for the web interface port";
    };

    apiBackend = mkOption {
      type = types.enum [
        "tabbyapi"
        "llama-swap"
        "custom"
      ];
      default = "tabbyapi";
      description = "Which local LLM backend to use";
    };

    customApiUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "http://127.0.0.1:8081/v1";
      description = "Custom OpenAI-compatible API URL (when apiBackend = custom)";
    };

    performance = {
      enableHardcoreMode = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ML hardcore optimizations (streaming, cache, threading)";
      };

      workers = mkOption {
        type = types.int;
        default = 4;
        description = "Uvicorn worker count for high-load scenarios";
      };

      threadPoolSize = mkOption {
        type = types.int;
        default = 16;
        description = "FastAPI/AnyIO thread pool size (increase for large instances)";
      };
    };

    rag = {
      vectorDB = mkOption {
        type = types.enum [
          "chroma"
          "milvus"
          "pgvector"
          "qdrant"
        ];
        default = "chroma";
        description = "Vector database backend (milvus/pgvector recommended for production)";
      };

      embeddingModelAutoUpdate = mkOption {
        type = types.bool;
        default = true;
        description = "Auto-update Sentence-Transformer embeddings";
      };

      enableMilvusMultitenancy = mkOption {
        type = types.bool;
        default = false;
        description = "Milvus multitenancy mode (reduced RAM usage)";
      };
    };

    codeExecution = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable code execution/interpreter";
      };

      engine = mkOption {
        type = types.enum [
          "pyodide"
          "jupyter"
        ];
        default = "pyodide";
        description = "Code execution engine (jupyter for remote/advanced)";
      };

      jupyterUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://localhost:8888";
        description = "Remote Jupyter server URL (when engine = jupyter)";
      };
    };

    security = {
      enableAuditLogs = mkOption {
        type = types.bool;
        default = true;
        description = "Enable comprehensive audit logging";
      };

      auditLogLevel = mkOption {
        type = types.enum [
          "NONE"
          "METADATA"
          "REQUEST"
          "REQUEST_RESPONSE"
        ];
        default = "REQUEST";
        description = "Audit log detail level";
      };

      jwtExpiresIn = mkOption {
        type = types.str;
        default = "4w";
        description = "JWT token lifetime (e.g., 4w, 30d, 12h)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Use the upstream NixOS module
    services.open-webui = {
      enable = true;
      inherit (cfg) host port openFirewall;

      environment = {
        # ========================================
        # ANALYTICS & TELEMETRY
        # ========================================
        SCARF_NO_ANALYTICS = "true";
        DO_NOT_TRACK = "true";
        ANONYMIZED_TELEMETRY = "false";

        # ========================================
        # API BACKEND CONFIGURATION
        # ========================================
        OPENAI_API_BASE_URL =
          if cfg.apiBackend == "tabbyapi" then
            "http://127.0.0.1:7734/v1"
          else if cfg.apiBackend == "llama-swap" then
            "http://127.0.0.1:8081/v1"
          else
            cfg.customApiUrl;

        OPENAI_API_KEY = "not-needed";
        ENABLE_OLLAMA_API = "false";
        ENABLE_OPENAI_API = "true";

        # ========================================
        # PERFORMANCE OPTIMIZATIONS (ML Hardcore)
        # ========================================
      }
      // optionalAttrs cfg.performance.enableHardcoreMode {
        # Streaming optimizations
        CHAT_RESPONSE_STREAM_DELTA_CHUNK_SIZE = "4"; # Batch 4 tokens for lower latency
        ENABLE_REALTIME_CHAT_SAVE = "false"; # Disable for multi-user performance

        # Threading & workers
        THREAD_POOL_SIZE = toString cfg.performance.threadPoolSize;
        UVICORN_WORKERS = toString cfg.performance.workers;

        # Timeouts
        AIOHTTP_CLIENT_TIMEOUT = "120";
        AIOHTTP_CLIENT_TIMEOUT_MODEL_LIST = "5";

        # Caching
        ENABLE_BASE_MODELS_CACHE = "true";
        MODELS_CACHE_TTL = "300"; # 5 min cache
        ENABLE_COMPRESSION_MIDDLEWARE = "true";

        # HTTP optimizations
        ENABLE_CHAT_RESPONSE_BASE64_IMAGE_URL_CONVERSION = "true";
      }
      // {

        # ========================================
        # RAG & VECTOR DB CONFIGURATION
        # ========================================
        VECTOR_DB = cfg.rag.vectorDB;
        RAG_EMBEDDING_MODEL_AUTO_UPDATE = toString cfg.rag.embeddingModelAutoUpdate;
        RAG_RERANKING_MODEL_AUTO_UPDATE = "true";

        # Milvus advanced (if enabled)
      }
      // optionalAttrs (cfg.rag.vectorDB == "milvus") {
        MILVUS_INDEX_TYPE = "HNSW"; # Best for accuracy/speed tradeoff
        MILVUS_METRIC_TYPE = "COSINE";
        MILVUS_HNSW_M = "32"; # Higher = better recall, more memory
        MILVUS_HNSW_EFCONSTRUCTION = "200"; # Higher = better index quality
        ENABLE_MILVUS_MULTITENANCY_MODE = toString cfg.rag.enableMilvusMultitenancy;
      }
      // optionalAttrs (cfg.rag.vectorDB == "pgvector") {
        PGVECTOR_INDEX_METHOD = "hnsw";
        PGVECTOR_HNSW_M = "32";
        PGVECTOR_HNSW_EF_CONSTRUCTION = "128";
      }
      // {

        # ========================================
        # CODE EXECUTION & INTERPRETER
        # ========================================
        ENABLE_CODE_EXECUTION = toString cfg.codeExecution.enable;
        ENABLE_CODE_INTERPRETER = toString cfg.codeExecution.enable;
        CODE_EXECUTION_ENGINE = cfg.codeExecution.engine;
        CODE_INTERPRETER_ENGINE = cfg.codeExecution.engine;
      }
      // optionalAttrs (cfg.codeExecution.engine == "jupyter" && cfg.codeExecution.jupyterUrl != null) {
        CODE_EXECUTION_JUPYTER_URL = cfg.codeExecution.jupyterUrl;
        CODE_INTERPRETER_JUPYTER_URL = cfg.codeExecution.jupyterUrl;
        CODE_EXECUTION_JUPYTER_TIMEOUT = "300";
      }
      // {

        # ========================================
        # SECURITY & AUDIT
        # ========================================
        JWT_EXPIRES_IN = cfg.security.jwtExpiresIn;
        ENABLE_AUDIT_LOGS_FILE = toString cfg.security.enableAuditLogs;
        AUDIT_LOG_LEVEL = cfg.security.auditLogLevel;
        AUDIT_LOG_FILE_ROTATION_SIZE = "50MB";
        MAX_BODY_LOG_SIZE = "4096";

        # Password policy (for production)
        ENABLE_PASSWORD_VALIDATION = "true";
        PASSWORD_VALIDATION_REGEX_PATTERN = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$";

        # Session security
        WEBUI_SESSION_COOKIE_SAME_SITE = "lax";
        WEBUI_SESSION_COOKIE_SECURE = "true";

        # ========================================
        # AI TASK CUSTOMIZATION
        # ========================================
        ENABLE_TITLE_GENERATION = "true";
        ENABLE_FOLLOW_UP_GENERATION = "true";
        ENABLE_AUTOCOMPLETE_GENERATION = "true";
        ENABLE_TAGS_GENERATION = "true";

        # ========================================
        # FEATURES
        # ========================================
        ENABLE_SIGNUP = "true";
        DEFAULT_USER_ROLE = "user";
        ENABLE_COMMUNITY_SHARING = "false";
        ENABLE_IMAGE_GENERATION = "false";
        ENABLE_TTS = "false";
        ENABLE_CHANNELS = "false";
        ENABLE_FOLDERS = "true";
        ENABLE_NOTES = "true";
        ENABLE_MEMORIES = "true";
        ENABLE_USER_WEBHOOKS = "true";
        ENABLE_MESSAGE_RATING = "true";

        # ========================================
        # ADVANCED FEATURES
        # ========================================
        ENABLE_DIRECT_CONNECTIONS = "true"; # MCP/OpenAPI tool servers
        ENABLE_API_KEYS = "false"; # Enable via admin panel when needed
        SAFE_MODE = "false"; # Allow functions & advanced features

        # Logging
        GLOBAL_LOG_LEVEL = "INFO";
        ENABLE_AUDIT_STDOUT = "false";

        # ========================================
        # NETWORK & CORS
        # ========================================
        CORS_ALLOW_ORIGIN = "*"; # Restrict in production
        AIOHTTP_CLIENT_SESSION_SSL = "true";
        REQUESTS_VERIFY = "true";
      };
    };

    # ========================================
    # SYSTEMD SERVICE DEPENDENCIES
    # ========================================
    systemd.services.open-webui = mkMerge [
      (mkIf (cfg.apiBackend == "tabbyapi") {
        after = [ "tabbyapi.service" ];
        wants = [ "tabbyapi.service" ];
      })
      (mkIf (cfg.apiBackend == "llama-swap") {
        after = [ "llamacpp-swap.service" ];
        wants = [ "llamacpp-swap.service" ];
      })

      # Hardcore mode: increase limits
      (mkIf cfg.performance.enableHardcoreMode {
        serviceConfig = {
          LimitNOFILE = 65536;
          LimitNPROC = 4096;
        };
      })
    ];
  };
}
