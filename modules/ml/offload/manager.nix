{
  config,
  lib,
  pkgs,
  ...
}:

# ML Offload Manager - REST API Service
#
# Unified API for ML model offloading across multiple backends.
#
# API Endpoints:
#   GET  /health                    - Service health check
#   GET  /backends                  - List available backends
#   GET  /models                    - List all models from registry
#   GET  /models/:id                - Get model details
#   POST /models/scan               - Trigger registry scan
#   GET  /status                    - Real-time status (VRAM, loaded models)
#   POST /load                      - Load model on backend
#   POST /unload                    - Unload model from backend
#   POST /switch                    - Hot-switch model on backend
#   GET  /vram                      - Detailed VRAM breakdown
#   GET  /vram/budget               - Calculate VRAM budget for model
#   POST /schedule                  - Add model load to queue
#   GET  /queue                     - View scheduled loads
#
# Usage:
#   kernelcore.ml.offload.api.enable = true;
#   kernelcore.ml.offload.api.port = 9000;

with lib;

let
  cfg = config.kernelcore.ml.offload.api;
  offloadCfg = config.kernelcore.ml.offload;

  # Build Rust API server
  ml-offload-api = pkgs.rustPlatform.buildRustPackage {
    pname = "ml-offload-api";
    version = "0.1.0";

    src = ./api;

    cargoLock = {
      lockFile = ./api/Cargo.lock;
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
      sqlite
      linuxPackages.nvidia_x11
    ];

    # Set CUDA paths for nvml-wrapper
    CUDA_PATH = "${pkgs.cudatoolkit}";
    CUDA_INCLUDE_PATH = "${pkgs.cudatoolkit}/include";

    meta = with lib; {
      description = "ML Offload Manager - Unified REST API for ML model orchestration";
      license = licenses.mit;
      maintainers = [ "kernelcore" ];
    };
  };

in
{
  options.kernelcore.ml.offload.api = {
    enable = mkEnableOption "ML Offload Manager REST API";

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "API server host address";
    };

    port = mkOption {
      type = types.port;
      default = 9000;
      description = "API server port";
    };

    logLevel = mkOption {
      type = types.enum [
        "debug"
        "info"
        "warning"
        "error"
        "critical"
      ];
      default = "info";
      description = "API logging level";
    };

    workers = mkOption {
      type = types.int;
      default = 1;
      description = "Number of API worker processes (1 for single-threaded)";
    };

    corsEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CORS for API (useful for web frontends)";
    };

    corsOrigins = mkOption {
      type = types.listOf types.str;
      default = [ "http://localhost:3000" ];
      description = "Allowed CORS origins";
    };

    rateLimiting = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable rate limiting for API endpoints";
      };

      requestsPerMinute = mkOption {
        type = types.int;
        default = 60;
        description = "Maximum requests per minute per client IP";
      };
    };
  };

  config = mkIf (offloadCfg.enable && cfg.enable) {
    # Ensure registry and VRAM intelligence are enabled
    kernelcore.ml.offload.modelRegistry.enable = mkDefault true;
    kernelcore.ml.offload.vramIntelligence.enable = mkDefault true;

    # ML Offload API Service
    systemd.services.ml-offload-api = {
      description = "ML Offload Manager REST API (Rust)";
      documentation = [
        "file:///etc/nixos/modules/ml/offload/manager.nix"
        "file:///etc/nixos/modules/ml/offload/api/src/main.rs"
      ];
      wantedBy = [ "multi-user.target" ];

      after = [ "network.target" ];
      wants = [ "network.target" ];

      environment = {
        RUST_LOG =
          if cfg.logLevel == "debug" then
            "ml_offload_api=debug,axum=debug"
          else
            "ml_offload_api=info,axum=info";
        ML_OFFLOAD_DATA_DIR = offloadCfg.dataDir;
        ML_OFFLOAD_MODELS_PATH = offloadCfg.modelsPath;
        ML_OFFLOAD_DB_PATH = "${offloadCfg.dataDir}/registry.db";
        ML_OFFLOAD_STATE_FILE = "${offloadCfg.dataDir}/vram-state.json";
        ML_OFFLOAD_HOST = cfg.host;
        ML_OFFLOAD_PORT = toString cfg.port;
        ML_OFFLOAD_CORS_ENABLED = if cfg.corsEnabled then "true" else "false";
        ML_OFFLOAD_CORS_ORIGINS = lib.concatStringsSep "," cfg.corsOrigins;
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };

      serviceConfig = {
        Type = "simple";
        User = "ml-offload";
        Group = "ml-offload";
        ExecStart = "${ml-offload-api}/bin/ml-offload-api";
        Restart = "always";
        RestartSec = "10s";

        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          offloadCfg.dataDir
        ];
        ReadOnlyPaths = [
          offloadCfg.modelsPath
          "/sys/class/drm"
          "/proc/driver/nvidia"
          "/run/opengl-driver"
        ];

        # Need access to NVIDIA devices for VRAM queries
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-modeset rw"
        ];
        SupplementaryGroups = [
          "nvidia"
          "video"
        ];

        # Resource limits
        CPUQuota = "100%";
        MemoryMax = "1G";
        TasksMax = 100;

        # Networking
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };

    # Open firewall if not localhost
    networking.firewall.allowedTCPPorts = mkIf (cfg.host != "127.0.0.1") [ cfg.port ];

    # Shell aliases
    programs.bash.shellAliases = {
      ml-offload-api = "sudo systemctl status ml-offload-api.service";
      ml-offload-api-restart = "sudo systemctl restart ml-offload-api.service";
      ml-offload-api-log = "sudo journalctl -u ml-offload-api.service -n 100 -f";
      ml-offload-api-test = "${pkgs.curl}/bin/curl http://${cfg.host}:${toString cfg.port}/health";

      # Convenient API interaction aliases
      ml-offload = "${pkgs.curl}/bin/curl -s http://${cfg.host}:${toString cfg.port}";
      ml-models = "${pkgs.curl}/bin/curl -s http://${cfg.host}:${toString cfg.port}/models | ${pkgs.jq}/bin/jq";
      ml-status = "${pkgs.curl}/bin/curl -s http://${cfg.host}:${toString cfg.port}/status | ${pkgs.jq}/bin/jq";
      ml-backends = "${pkgs.curl}/bin/curl -s http://${cfg.host}:${toString cfg.port}/backends | ${pkgs.jq}/bin/jq";
    };

    # Add API binary and utilities to system packages
    environment.systemPackages = [
      ml-offload-api
      pkgs.curl
      pkgs.jq
    ];
  };
}
