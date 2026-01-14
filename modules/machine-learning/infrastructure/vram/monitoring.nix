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
#   kernelcore.ml.vramIntelligence.enable = true;
#   kernelcore.ml.vramIntelligence.dataDir = "/var/lib/ml-vram";
#   kernelcore.ml.vramIntelligence.monitoringInterval = 5;
#   kernelcore.ml.vramIntelligence.autoScaling.threshold = 85;

with lib;

let
  cfg = config.kernelcore.ml.vramIntelligence;

  # Python environment with all required dependencies
  pythonEnv = pkgs.python313.withPackages (
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
    DB_PATH="${cfg.dataDir}/registry.db"
    LOG_FILE="${cfg.dataDir}/logs/vram-monitor.log"
    STATE_FILE="${cfg.dataDir}/vram-state.json"

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
  options.kernelcore.ml.vramIntelligence = {
    enable = mkEnableOption "VRAM Intelligence System with monitoring and scheduling";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/ml-vram";
      description = "Directory for VRAM monitoring data and logs";
    };

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

  config = mkIf cfg.enable {
    # Create ml-vram user and group
    users.users.ml-vram = {
      isSystemUser = true;
      group = "ml-vram";
      description = "ML VRAM monitoring service user";
    };
    users.groups.ml-vram = { };

    # Ensure nvidia-smi is available
    environment.systemPackages = with pkgs; [
      linuxPackages.nvidia_x11
      # nvidia-ml-py is already included in pythonEnv (line 36-41)
    ];

    # Create data directory and VRAM state file
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ml-vram ml-vram -"
      "d ${cfg.dataDir}/logs 0755 ml-vram ml-vram -"
      "f '${cfg.dataDir}/vram-state.json' 0644 ml-vram ml-vram -"
    ];

    # VRAM Monitor Service (continuous)
    systemd.services.ml-vram-monitor = {
      description = "ML VRAM Intelligence Monitor";
      documentation = [ "file:///etc/nixos/modules/machine-learning/infrastructure/vram/monitoring.nix" ];
      wantedBy = [ "multi-user.target" ];

      # Start after network
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "ml-vram";
        Group = "ml-vram";
        ExecStart = "${vramMonitorScript}";
        Restart = "always";
        RestartSec = "10s";

        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          cfg.dataDir
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
      ml-vram-status = "${pythonEnv}/bin/python3 ${./api/vram_monitor.py} status --state-file ${cfg.dataDir}/vram-state.json";
      ml-vram-log = "sudo journalctl -u ml-vram-monitor.service -n 50 -f";
      ml-vram-restart = "sudo systemctl restart ml-vram-monitor.service";
    };
  };
}
