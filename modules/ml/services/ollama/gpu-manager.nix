{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.ollama-gpu-manager;
in
{
  options.services.ollama-gpu-manager = {
    enable = mkEnableOption "Enable Ollama GPU automatic memory management";

    unloadOnShellExit = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically unload Ollama models from GPU on shell exit";
    };

    idleTimeout = mkOption {
      type = types.int;
      default = 300; # 5 minutes
      description = "Seconds of inactivity before auto-unloading models (0 to disable)";
    };

    monitoringInterval = mkOption {
      type = types.int;
      default = 30;
      description = "Seconds between idle checks";
    };
  };

  config = mkIf cfg.enable {
    # Shell hook script for manual unloading
    environment.interactiveShellInit = mkIf cfg.unloadOnShellExit ''
      # Ollama GPU offload function
      ollama-offload() {
        echo "Offloading Ollama models from GPU memory..."
        # Stop all running Ollama processes gracefully
        ${pkgs.curl}/bin/curl -s -X POST http://127.0.0.1:11434/api/generate \
          -d '{"model": "", "keep_alive": 0}' 2>/dev/null || true
        echo "Ollama models offloaded."
      }

      # Trap shell exit to offload models
      trap ollama-offload EXIT
    '';

    # Systemd service for automatic idle detection and offload
    systemd.services.ollama-gpu-idle-monitor = mkIf (cfg.idleTimeout > 0) {
      description = "Ollama GPU Idle Monitor - Auto-offload inactive models";
      after = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 10;
        User = "nobody";
        Group = "nobody";

        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
      };

      script = ''
        IDLE_TIMEOUT=${toString cfg.idleTimeout}
        CHECK_INTERVAL=${toString cfg.monitoringInterval}
        LAST_ACTIVE=$(date +%s)

        echo "Starting Ollama GPU idle monitor (timeout: ''${IDLE_TIMEOUT}s, check: ''${CHECK_INTERVAL}s)"

        while true; do
          sleep $CHECK_INTERVAL

          # Check if Ollama is processing requests (has active sessions)
          if ${pkgs.curl}/bin/curl -s --max-time 2 http://127.0.0.1:11434/api/tags 2>/dev/null | ${pkgs.jq}/bin/jq -e '.models | length > 0' >/dev/null 2>&1; then
            # Check for active generation processes
            ACTIVE=$(${pkgs.curl}/bin/curl -s --max-time 2 http://127.0.0.1:11434/api/ps 2>/dev/null | ${pkgs.jq}/bin/jq -e '.models | length' 2>/dev/null || echo "0")

            if [ "$ACTIVE" -gt 0 ]; then
              LAST_ACTIVE=$(date +%s)
              echo "Ollama active: $ACTIVE model(s) loaded"
            else
              CURRENT_TIME=$(date +%s)
              IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVE))

              if [ $IDLE_TIME -ge $IDLE_TIMEOUT ]; then
                echo "Idle timeout reached (''${IDLE_TIME}s). Offloading models from GPU..."
                ${pkgs.curl}/bin/curl -s -X POST http://127.0.0.1:11434/api/generate \
                  -d '{"model": "", "keep_alive": 0}' 2>/dev/null || true
                LAST_ACTIVE=$(date +%s)
                echo "Models offloaded successfully"
              else
                echo "Idle for ''${IDLE_TIME}s (threshold: ''${IDLE_TIMEOUT}s)"
              fi
            fi
          fi
        done
      '';
    };

    # User-level convenience aliases
    environment.shellAliases = {
      ollama-unload = "${pkgs.curl}/bin/curl -s -X POST http://127.0.0.1:11434/api/generate -d '{\"model\": \"\", \"keep_alive\": 0}'";
      ollama-status = "${pkgs.curl}/bin/curl -s http://127.0.0.1:11434/api/ps | ${pkgs.jq}/bin/jq";
      ollama-models = "${pkgs.curl}/bin/curl -s http://127.0.0.1:11434/api/tags | ${pkgs.jq}/bin/jq";
    };

    # Ensure jq is available for JSON parsing
    environment.systemPackages = [
      pkgs.jq
      pkgs.curl
    ];
  };
}
