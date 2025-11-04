{
  config,
  lib,
  pkgs,
  ...
}:

# Model Registry System
#
# Maintains a SQLite database of all available ML models with metadata:
# - Model name, path, format (GGUF, SafeTensors, Ollama)
# - Size (GB), estimated VRAM usage (GB)
# - Compatible backends (llamacpp, ollama, vllm, tgi)
# - Last used timestamp, usage count, priority
#
# Features:
# - Auto-scan: Periodic discovery of new models in /var/lib/ml-models/
# - Metadata extraction: Parse model files for size, quantization, architecture
# - VRAM estimation: Calculate expected VRAM usage based on model type/layers
# - API integration: Expose registry via ML Offload Manager API
#
# Usage:
#   kernelcore.ml.offload.modelRegistry.enable = true;
#   kernelcore.ml.offload.modelRegistry.autoScanInterval = "1h";

with lib;

let
  cfg = config.kernelcore.ml.offload.modelRegistry;
  offloadCfg = config.kernelcore.ml.offload;

  registryScript = pkgs.writeShellScript "ml-registry-scan" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Model Registry Scanner
    # Scans ${offloadCfg.modelsPath} for models and updates registry database

    MODELS_PATH="${offloadCfg.modelsPath}"
    DB_PATH="${offloadCfg.dataDir}/registry.db"
    LOG_FILE="${offloadCfg.dataDir}/logs/registry-scan.log"

    echo "[$(date -Iseconds)] Starting model registry scan..." >> "$LOG_FILE"

    # Run Python registry scanner
    ${pkgs.python311}/bin/python3 ${./api/registry.py} scan \
      --models-path "$MODELS_PATH" \
      --db-path "$DB_PATH" \
      >> "$LOG_FILE" 2>&1

    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
      echo "[$(date -Iseconds)] Model registry scan completed successfully" >> "$LOG_FILE"
    else
      echo "[$(date -Iseconds)] ERROR: Model registry scan failed with exit code $EXIT_CODE" >> "$LOG_FILE"
      exit $EXIT_CODE
    fi
  '';

in
{
  options.kernelcore.ml.offload.modelRegistry = {
    enable = mkEnableOption "ML Model Registry with auto-discovery";

    autoScanInterval = mkOption {
      type = types.str;
      default = "1h";
      example = "30m";
      description = ''
        Interval for automatic model scanning.
        Systemd timer format (e.g., "1h", "30m", "daily").
        Set to empty string to disable automatic scanning.
      '';
    };

    scanOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = "Run initial model scan on system boot";
    };

    includedPaths = mkOption {
      type = types.listOf types.path;
      default = [
        "${offloadCfg.modelsPath}/llamacpp/models"
        "${offloadCfg.modelsPath}/ollama/models"
        "${offloadCfg.modelsPath}/huggingface"
        "${offloadCfg.modelsPath}/gguf"
        "${offloadCfg.modelsPath}/custom"
      ];
      description = "List of paths to scan for models";
    };

    excludedPatterns = mkOption {
      type = types.listOf types.str;
      default = [
        "*.tmp"
        "*.part"
        ".cache/*"
        "*/cache/*"
      ];
      description = "Glob patterns to exclude from scanning";
    };
  };

  config = mkIf (offloadCfg.enable && cfg.enable) {
    # Create registry database directory
    systemd.tmpfiles.rules = [
      "f '${offloadCfg.dataDir}/registry.db' 0644 ml-offload ml-offload -"
    ];

    # Model Registry Scanner Service
    systemd.services.ml-registry-scan = {
      description = "ML Model Registry Scanner";
      documentation = [ "file:///etc/nixos/modules/ml/offload/model-registry.nix" ];

      serviceConfig = {
        Type = "oneshot";
        User = "ml-offload";
        Group = "ml-offload";
        ExecStart = "${registryScript}";

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
        ];

        # Resource limits
        CPUQuota = "50%";
        MemoryMax = "512M";
        TasksMax = 10;
      };

      # Run after models storage is mounted
      after = [ "local-fs.target" ];
      wants = [ "local-fs.target" ];
    };

    # Systemd Timer for periodic scanning
    systemd.timers.ml-registry-scan = mkIf (cfg.autoScanInterval != "") {
      description = "ML Model Registry Auto-Scan Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = if cfg.scanOnBoot then "5min" else null;
        OnUnitActiveSec = cfg.autoScanInterval;
        Unit = "ml-registry-scan.service";
        Persistent = true;
      };
    };

    # Shell alias for manual scanning
    programs.bash.shellAliases = {
      ml-registry-scan = "sudo systemctl start ml-registry-scan.service";
      ml-registry-status = "sudo systemctl status ml-registry-scan.service";
      ml-registry-log = "sudo journalctl -u ml-registry-scan.service -n 50";
    };
  };
}
