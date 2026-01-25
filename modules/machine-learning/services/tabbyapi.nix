{
  config,
  lib,
  pkgs,
  ...
}:

# TabbyAPI - OpenAI-compatible Inference Server
#
# High-performance inference server for GGUF/ExLlamaV2 models.
# Features:
# - OpenAI-compatible API (/v1/chat/completions, /v1/completions)
# - CUDA acceleration with Flash Attention
# - Dynamic model loading via API
# - Continuous batching for multi-request handling
# - Speculative decoding support
#
# Port: 5000 (default)
# API: http://localhost:5000/v1

let
  cfg = config.services.tabbyapi;
in
{
  options.services.tabbyapi = {
    enable = lib.mkEnableOption "TabbyAPI - OpenAI-compatible inference server";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/tabbyapi";
      description = "Data directory for TabbyAPI configuration and cache.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/ml-models";
      description = "Directory containing GGUF models.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "IP address the server listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      description = "Listen port for the inference server.";
    };

    # =====================
    # GPU CONFIGURATION
    # =====================

    gpuSplitAuto = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically split model across available GPUs.";
    };

    maxSeqLen = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Maximum sequence length (context window).";
    };

    # =====================
    # PERFORMANCE
    # =====================

    chunkSize = lib.mkOption {
      type = lib.types.int;
      default = 2048;
      description = "Prompt processing chunk size.";
    };

    cacheSize = lib.mkOption {
      type = lib.types.int;
      default = 4096;
      description = "KV cache size in tokens.";
    };

    cacheMode = lib.mkOption {
      type = lib.types.enum [
        "FP16"
        "Q8"
        "Q6"
        "Q4"
      ];
      default = "FP16";
      description = "KV cache quantization mode (FP16 = full precision, Q4 = 4-bit).";
    };

    # =====================
    # API & AUTH
    # =====================

    apiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional API key for authentication (X-API-Key header).";
    };

    disableAuth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable API key authentication (localhost only recommended).";
    };

    # =====================
    # LOGGING
    # =====================

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "DEBUG"
        "INFO"
        "WARNING"
        "ERROR"
      ];
      default = "INFO";
      description = "Logging verbosity level.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for the server port.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create dedicated user for tabbyapi
    users.users.tabbyapi = {
      isSystemUser = true;
      group = "tabbyapi";
      home = cfg.dataDir;
      description = "TabbyAPI service user";
    };

    users.groups.tabbyapi = { };

    # Create directory structure
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 tabbyapi tabbyapi -"
      "d ${cfg.dataDir}/config 0755 tabbyapi tabbyapi -"
      "d ${cfg.dataDir}/cache 0755 tabbyapi tabbyapi -"
    ];

    # Create TabbyAPI configuration file
    environment.etc."tabbyapi/config.yml".text = ''
      # TabbyAPI Configuration (managed by NixOS)
      network:
        host: ${cfg.host}
        port: ${toString cfg.port}

      model:
        model_dir: ${cfg.modelsDir}
        use_dummy_models: false
        gpu_split_auto: ${lib.boolToString cfg.gpuSplitAuto}
        max_seq_len: ${toString cfg.maxSeqLen}
        chunk_size: ${toString cfg.chunkSize}
        cache_size: ${toString cfg.cacheSize}
        cache_mode: ${cfg.cacheMode}

      ${lib.optionalString (!cfg.disableAuth && cfg.apiKey != null) ''
        network:
          api_key: ${cfg.apiKey}
      ''}

      logging:
        log_level: ${cfg.logLevel}
        log_prompt: false
        log_generation_params: false
    '';

    # SystemD service
    systemd.services.tabbyapi = {
      description = "TabbyAPI - OpenAI-compatible Inference Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        # CUDA optimizations
        CUDA_VISIBLE_DEVICES = "0";
        # Python unbuffered output
        PYTHONUNBUFFERED = "1";
        # Config path
        TABBY_CONFIG_PATH = "/etc/tabbyapi/config.yml";
      };

      serviceConfig = {
        Type = "exec";
        # TabbyAPI is typically run as a Docker container or Python app
        # For NixOS integration, we'd need a proper Nix package
        # This is a placeholder for Docker-based execution via systemd
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker}/bin/docker"
          "run"
          "--rm"
          "--name tabbyapi-host"
          "--nvidia.com/gpu=all"
          "--network host"
          "-v ${cfg.dataDir}:/app/data"
          "-v ${cfg.modelsDir}:/app/models:ro"
          "-v /etc/tabbyapi:/app/config:ro"
          "-e TABBY_CONFIG_PATH=/app/config/config.yml"
          "ghcr.io/theroyallab/tabbyapi:latest"
        ];

        Restart = "always";
        RestartSec = 10;

        User = "kernelcore"; # Required for Docker socket access
        Group = "docker";

        # Graceful shutdown
        TimeoutStopSec = "30s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ marcosfpina ];
}
