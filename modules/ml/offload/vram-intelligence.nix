{
  config,
  lib,
  pkgs,
  ...
}:

# VRAM Intelligence System
#
# Real-time GPU memory management with:
# - Continuous monitoring (nvidia-smi polling)
# - Budget calculator (VRAM estimation per model/layers)
# - Intelligent scheduler (priority queue system)
# - Auto-scaling (unload low-priority models when >threshold)
# - Alerting (systemd notifications + webhooks)
#
# Features:
# - Sub-5-second latency monitoring
# - Predictive VRAM allocation planning
# - Priority-based model eviction (high/medium/low)
# - OOM prevention with configurable thresholds
# - Integration with ML Offload Manager API
#
# Usage:
#   kernelcore.ml.offload.vramIntelligence.enable = true;
#   kernelcore.ml.offload.vramIntelligence.monitoringInterval = 5;
#   kernelcore.ml.offload.vramIntelligence.autoScaling.threshold = 85;

with lib;

let
  cfg = config.kernelcore.ml.offload.vramIntelligence;
  offloadCfg = config.kernelcore.ml.offload;

  # Python environment with all required dependencies
  pythonEnv = pkgs.python311.withPackages (
    ps: with ps; [
      nvidia-ml-py
      requests
    ]
  );

  vramMonitorScript = pkgs.writeShellScript "vram-monitor" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # VRAM Intelligence Monitor
    # Continuously monitors NVIDIA GPU memory and triggers actions

    INTERVAL=${toString cfg.monitoringInterval}
    DB_PATH="${offloadCfg.dataDir}/registry.db"
    LOG_FILE="${offloadCfg.dataDir}/logs/vram-monitor.log"
    STATE_FILE="${offloadCfg.dataDir}/vram-state.json"

    echo "[$(date -Iseconds)] Starting VRAM Intelligence Monitor (interval: ''${INTERVAL}s)" >> "$LOG_FILE"

    # Run Python VRAM monitor
    ${pythonEnv}/bin/python3 ${./api/vram_monitor.py} monitor \
      --interval "$INTERVAL" \
      --db-path "$DB_PATH" \
      --state-file "$STATE_FILE" \
      --auto-scale ${if cfg.autoScaling.enable then "true" else "false"} \
      --threshold ${toString cfg.autoScaling.threshold} \
      --log-file "$LOG_FILE"
  '';

in
{
  options.kernelcore.ml.offload.vramIntelligence = {
    enable = mkEnableOption "VRAM Intelligence System with monitoring and scheduling";

    monitoringInterval = mkOption {
      type = types.int;
      default = 5;
      description = "VRAM monitoring interval in seconds";
    };

    autoScaling = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic model eviction when VRAM threshold exceeded";
      };

      threshold = mkOption {
        type = types.int;
        default = 85;
        description = "VRAM usage percentage threshold for auto-scaling (0-100)";
      };

      evictionPolicy = mkOption {
        type = types.enum [
          "lru"
          "priority"
          "hybrid"
        ];
        default = "priority";
        description = ''
          Model eviction policy:
          - lru: Least Recently Used (evict oldest)
          - priority: Priority-based (evict low-priority first)
          - hybrid: LRU within same priority level
        '';
      };
    };

    budgetPlanner = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable VRAM budget calculator for load predictions";
      };

      safetyMargin = mkOption {
        type = types.int;
        default = 10;
        description = "Safety margin percentage for VRAM allocation (0-50)";
      };
    };

    alerts = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable alerting for VRAM events";
      };

      highUsageThreshold = mkOption {
        type = types.int;
        default = 90;
        description = "Trigger alert when VRAM usage exceeds this percentage";
      };

      notificationMethod = mkOption {
        type = types.enum [
          "systemd"
          "webhook"
          "both"
        ];
        default = "systemd";
        description = "Alert notification method";
      };

      webhookUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://localhost:8000/alerts";
        description = "Webhook URL for alerts (if notificationMethod includes webhook)";
      };
    };

    scheduler = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable intelligent scheduling queue";
      };

      maxQueueSize = mkOption {
        type = types.int;
        default = 10;
        description = "Maximum number of pending model loads in queue";
      };

      timeoutSeconds = mkOption {
        type = types.int;
        default = 300;
        description = "Queue request timeout (auto-reject after N seconds)";
      };
    };
  };

  config = mkIf (offloadCfg.enable && cfg.enable) {
    # Ensure nvidia-smi is available
    environment.systemPackages = with pkgs; [
      linuxPackages.nvidia_x11
      python311Packages.nvidia-ml-py # Python NVIDIA Management Library
    ];

    # Create VRAM state file
    systemd.tmpfiles.rules = [
      "f '${offloadCfg.dataDir}/vram-state.json' 0644 ml-offload ml-offload -"
    ];

    # VRAM Monitor Service (continuous)
    systemd.services.ml-vram-monitor = {
      description = "ML VRAM Intelligence Monitor";
      documentation = [ "file:///etc/nixos/modules/ml/offload/vram-intelligence.nix" ];
      wantedBy = [ "multi-user.target" ];

      # Start after ML Offload Manager API
      after = [
        "network.target"
        "ml-offload-api.service"
      ];
      wants = [ "ml-offload-api.service" ];

      serviceConfig = {
        Type = "simple";
        User = "ml-offload";
        Group = "ml-offload";
        ExecStart = "${vramMonitorScript}";
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

        # Need access to NVIDIA devices for monitoring
        DeviceAllow = [
          "/dev/nvidia0 r"
          "/dev/nvidiactl r"
          "/dev/nvidia-uvm r"
        ];
        SupplementaryGroups = [
          "nvidia"
          "video"
        ];

        # Resource limits
        CPUQuota = "25%";
        MemoryMax = "256M";
        TasksMax = 10;
      };
    };

    # Shell aliases
    programs.bash.shellAliases = {
      ml-vram = "sudo systemctl status ml-vram-monitor.service";
      ml-vram-status = "${pythonEnv}/bin/python3 ${./api/vram_monitor.py} status --state-file ${offloadCfg.dataDir}/vram-state.json";
      ml-vram-log = "sudo journalctl -u ml-vram-monitor.service -n 50 -f";
      ml-vram-restart = "sudo systemctl restart ml-vram-monitor.service";
    };
  };
}
