{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# REBUILD HOOKS - Thermal Safety Integration
# ============================================================
# Hooks executados antes/durante/depois de nixos-rebuild
# Garantem integridade térmica e evitam danos ao hardware

with lib;

{
  options.hardware.rebuildHooks = {
    enable = mkEnableOption "Rebuild safety hooks (thermal monitoring)";

    thermalCheck = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable thermal checks before rebuild";
      };

      maxStartTemp = mkOption {
        type = types.int;
        default = 75;
        description = "Maximum temperature to allow rebuild to start";
      };

      maxRunningTemp = mkOption {
        type = types.int;
        default = 90;
        description = "Maximum temperature during rebuild (abort if exceeded)";
      };

      monitorInterval = mkOption {
        type = types.int;
        default = 5;
        description = "Seconds between temperature checks during rebuild";
      };
    };

    evidenceCollection = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Collect forensic evidence on rebuild failures";
      };

      storePath = mkOption {
        type = types.str;
        default = "/var/log/rebuild-evidence";
        description = "Path to store rebuild evidence";
      };
    };
  };

  config = mkIf config.hardware.rebuildHooks.enable {

    # ========================================
    # PRE-REBUILD HOOK
    # ========================================

    system.activationScripts.pre-rebuild-thermal-check = mkIf config.hardware.rebuildHooks.thermalCheck.enable {
      text = ''
        echo "🌡️  PRE-REBUILD: Thermal safety check..."

        # Get current temperature
        MAX_TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")

        echo "   Current temperature: ''${MAX_TEMP}°C"
        echo "   Maximum allowed: ${toString config.hardware.rebuildHooks.thermalCheck.maxStartTemp}°C"

        if [ "''${MAX_TEMP:-0}" -gt ${toString config.hardware.rebuildHooks.thermalCheck.maxStartTemp} ]; then
          echo ""
          echo "❌ THERMAL SAFETY: Temperature too high (''${MAX_TEMP}°C)"
          echo ""
          echo "ABORT REASON: System temperature exceeds safe threshold"
          echo "RECOMMENDED ACTION:"
          echo "  1. Wait for system to cool down"
          echo "  2. Check fan operation (run: sensors)"
          echo "  3. Close unnecessary applications"
          echo "  4. Try again in 10 minutes"
          echo ""
          echo "To bypass (NOT RECOMMENDED):"
          echo "  hardware.rebuildHooks.thermalCheck.maxStartTemp = 90;"
          echo ""

          exit 1
        fi

        echo "   ✅ Temperature OK - proceeding with rebuild"
        echo ""
      '';
    };

    # ========================================
    # REBUILD MONITOR SERVICE
    # ========================================

    systemd.services.rebuild-thermal-monitor = mkIf config.hardware.rebuildHooks.thermalCheck.enable {
      description = "Monitor temperature during nixos-rebuild";

      # Não inicia automaticamente - será chamado por wrapper
      wantedBy = [ ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;

        ExecStart = pkgs.writeShellScript "rebuild-monitor" ''
          set -e

          REBUILD_PID="''${1:?Usage: rebuild-monitor <rebuild-pid>}"
          MAX_TEMP=${toString config.hardware.rebuildHooks.thermalCheck.maxRunningTemp}
          INTERVAL=${toString config.hardware.rebuildHooks.thermalCheck.monitorInterval}

          LOG_FILE="/var/log/rebuild-thermal.log"
          ABORT_FLAG="/tmp/rebuild-thermal-abort"

          rm -f "$ABORT_FLAG"

          echo "🌡️  Monitoring rebuild PID $REBUILD_PID (max: ''${MAX_TEMP}°C)" | tee -a "$LOG_FILE"

          while kill -0 "$REBUILD_PID" 2>/dev/null; do
            TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
            CURRENT_TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")

            echo "[$TIMESTAMP] Temp: ''${CURRENT_TEMP}°C" | tee -a "$LOG_FILE"

            if [ "''${CURRENT_TEMP:-0}" -gt "$MAX_TEMP" ]; then
              echo "" | tee -a "$LOG_FILE"
              echo "🚨 THERMAL EMERGENCY: ''${CURRENT_TEMP}°C > ''${MAX_TEMP}°C" | tee -a "$LOG_FILE"
              echo "" | tee -a "$LOG_FILE"

              # Signal abort
              touch "$ABORT_FLAG"

              # Kill rebuild gracefully
              kill -TERM "$REBUILD_PID" 2>/dev/null || true
              sleep 5
              kill -KILL "$REBUILD_PID" 2>/dev/null || true

              echo "Rebuild aborted due to thermal emergency" | tee -a "$LOG_FILE"

              # Trigger evidence collection if enabled
              ${optionalString config.hardware.rebuildHooks.evidenceCollection.enable ''
                ${pkgs.bash}/bin/bash /etc/nixos/modules/hardware/laptop-defense/collect-evidence.sh thermal-abort
              ''}

              exit 1
            fi

            sleep "$INTERVAL"
          done

          echo "Rebuild completed - final temp: ''${CURRENT_TEMP}°C" | tee -a "$LOG_FILE"
        '';
      };
    };

    # ========================================
    # REBUILD WRAPPER
    # ========================================

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "safe-nixos-rebuild" ''
        #!/usr/bin/env bash
        set -e

        # Pre-check
        echo "🔒 SAFE NIXOS REBUILD"
        echo "===================="
        echo ""

        # Thermal check
        ${optionalString config.hardware.rebuildHooks.thermalCheck.enable ''
          MAX_TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")

          if [ "''${MAX_TEMP:-0}" -gt ${toString config.hardware.rebuildHooks.thermalCheck.maxStartTemp} ]; then
            echo "❌ Pre-check failed: Temperature too high (''${MAX_TEMP}°C)"
            echo "   Maximum allowed: ${toString config.hardware.rebuildHooks.thermalCheck.maxStartTemp}°C"
            echo ""
            echo "Wait for cooling or use: sudo nixos-rebuild switch (bypass)"
            exit 1
          fi

          echo "✅ Pre-check passed (''${MAX_TEMP}°C)"
        ''}

        echo ""
        echo "🚀 Starting rebuild with thermal monitoring..."
        echo ""

        # Start rebuild in background
        sudo nixos-rebuild "$@" &
        REBUILD_PID=$!

        # Start monitor
        ${optionalString config.hardware.rebuildHooks.thermalCheck.enable ''
          ${pkgs.systemd}/bin/systemd-run \
            --unit=rebuild-thermal-monitor-$REBUILD_PID \
            --description="Thermal monitor for rebuild $REBUILD_PID" \
            ${config.systemd.package}/lib/systemd/system/rebuild-thermal-monitor.service \
            "$REBUILD_PID" &

          MONITOR_PID=$!
        ''}

        # Wait for rebuild
        wait $REBUILD_PID
        REBUILD_EXIT=$?

        # Kill monitor if still running
        ${optionalString config.hardware.rebuildHooks.thermalCheck.enable ''
          kill $MONITOR_PID 2>/dev/null || true
        ''}

        # Check if thermal abort occurred
        if [ -f /tmp/rebuild-thermal-abort ]; then
          echo ""
          echo "❌ REBUILD ABORTED: Thermal emergency"
          echo ""
          echo "Evidence: /var/log/rebuild-thermal.log"

          ${optionalString config.hardware.rebuildHooks.evidenceCollection.enable ''
            echo "Forensic evidence: ${config.hardware.rebuildHooks.evidenceCollection.storePath}"
          ''}

          rm -f /tmp/rebuild-thermal-abort
          exit 1
        fi

        # Report result
        if [ $REBUILD_EXIT -eq 0 ]; then
          echo ""
          echo "✅ Rebuild completed successfully"
        else
          echo ""
          echo "❌ Rebuild failed (exit code: $REBUILD_EXIT)"

          ${optionalString config.hardware.rebuildHooks.evidenceCollection.enable ''
            ${pkgs.bash}/bin/bash /etc/nixos/modules/hardware/laptop-defense/collect-evidence.sh rebuild-failure
          ''}
        fi

        exit $REBUILD_EXIT
      '')
    ];

    # ========================================
    # EVIDENCE COLLECTOR
    # ========================================

    environment.etc."laptop-defense/collect-evidence.sh" = mkIf config.hardware.rebuildHooks.evidenceCollection.enable {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash

        REASON="''${1:-unknown}"
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        EVIDENCE_DIR="${config.hardware.rebuildHooks.evidenceCollection.storePath}/$REASON-$TIMESTAMP"

        mkdir -p "$EVIDENCE_DIR"/{logs,thermal,system}

        echo "📦 Collecting evidence: $REASON"

        # Logs
        cp /var/log/rebuild-thermal.log "$EVIDENCE_DIR/logs/" 2>/dev/null || true
        ${pkgs.systemd}/bin/journalctl -u nixos-rebuild --since "10 minutes ago" > "$EVIDENCE_DIR/logs/nixos-rebuild.log" 2>/dev/null || true

        # Thermal data
        ${pkgs.lm_sensors}/bin/sensors > "$EVIDENCE_DIR/thermal/sensors.txt" 2>/dev/null || true
        cat /sys/class/thermal/thermal_zone*/temp > "$EVIDENCE_DIR/thermal/zones.txt" 2>/dev/null || true

        # System state
        uptime > "$EVIDENCE_DIR/system/uptime.txt"
        free -h > "$EVIDENCE_DIR/system/memory.txt"
        ps aux > "$EVIDENCE_DIR/system/processes.txt"

        # Metadata
        cat > "$EVIDENCE_DIR/METADATA.txt" <<EOF
Reason: $REASON
Timestamp: $TIMESTAMP
Hostname: $(hostname)
Kernel: $(uname -r)
EOF

        # Archive
        tar czf "$EVIDENCE_DIR.tar.gz" -C "${config.hardware.rebuildHooks.evidenceCollection.storePath}" "$(basename $EVIDENCE_DIR)"

        echo "✅ Evidence collected: $EVIDENCE_DIR.tar.gz"
      '';
    };

    # ========================================
    # LOG ROTATION
    # ========================================

    services.logrotate.settings.rebuild-thermal = {
      files = "/var/log/rebuild-thermal.log";
      rotate = 10;
      frequency = "daily";
      compress = true;
      missingok = true;
      notifempty = true;
    };

    # Create evidence directory
    systemd.tmpfiles.rules = mkIf config.hardware.rebuildHooks.evidenceCollection.enable [
      "d ${config.hardware.rebuildHooks.evidenceCollection.storePath} 0755 root root -"
    ];
  };
}
