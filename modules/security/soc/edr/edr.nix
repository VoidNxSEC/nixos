{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
in
{
  options.kernelcore.soc.edr = {
    enable = mkOption {
      type = types.bool;
      default = cfg.profile == "enterprise";
      description = "Enable Endpoint Detection & Response";
    };

    # Process monitoring
    processMonitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable process execution monitoring";
      };

      suspiciousProcesses = mkOption {
        type = types.listOf types.str;
        default = [
          "nc"
          "netcat"
          "ncat"
          "socat"
          "nmap"
          "masscan"
          "zmap"
          "linpeas"
          "pspy"
          "chisel"
          "ligolo"
        ];
        description = "List of suspicious process names to alert on";
      };
    };

    # Network connection tracking
    networkTracking = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Track network connections by process";
      };

      alertOnNewListeners = mkOption {
        type = types.bool;
        default = true;
        description = "Alert when new listening ports are opened";
      };
    };

    # Behavioral analysis
    behavior = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable behavioral analysis";
      };

      detectPrivEsc = mkOption {
        type = types.bool;
        default = true;
        description = "Detect privilege escalation attempts";
      };

      detectLateralMovement = mkOption {
        type = types.bool;
        default = true;
        description = "Detect lateral movement patterns";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.edr.enable) {
    # Enhanced audit rules for EDR
    security.audit.rules = [
      # Process execution (all users)
      "-a always,exit -F arch=b64 -S execve -k edr_exec"
      "-a always,exit -F arch=b32 -S execve -k edr_exec"

      # Privilege escalation monitoring
      "-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k edr_privesc"
      "-a always,exit -F arch=b64 -S setresuid -S setresgid -k edr_privesc"

      # Network connection attempts
      "-a always,exit -F arch=b64 -S connect -k edr_network"
      "-a always,exit -F arch=b64 -S accept -S accept4 -k edr_network"
      "-a always,exit -F arch=b64 -S bind -k edr_network"

      # Kernel module loading
      "-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k edr_modules"

      # ptrace (debugging/injection)
      "-a always,exit -F arch=b64 -S ptrace -k edr_ptrace"

      # Memory mapping with execute permissions
      "-a always,exit -F arch=b64 -S mmap -F a2&0x4 -k edr_memexec"

      # File attribute changes
      "-a always,exit -F arch=b64 -S fchmod -S chmod -S fchmodat -k edr_fchmod"
      "-a always,exit -F arch=b64 -S fchown -S chown -S lchown -S fchownat -k edr_fchown"
    ];

    # EDR monitoring daemon
    systemd.services.soc-edr = {
      description = "SOC Endpoint Detection & Response";
      after = [ "auditd.service" ];
      wants = [ "auditd.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        coreutils
        gawk
        gnugrep
        procps
        iproute2
        jq
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "edr-monitor" ''
          #!/usr/bin/env bash
          set -euo pipefail

          LOG_FILE="/var/log/soc/edr.log"
          ALERT_FILE="/var/log/soc/edr-alerts.json"
          BASELINE_FILE="/var/lib/soc/edr/baseline.json"

          log_event() {
            local level=$1
            local category=$2
            local message=$3
            local details=$4

            echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"$level\",\"category\":\"$category\",\"message\":\"$message\",\"details\":$details}" >> "$ALERT_FILE"
          }

          # Initial baseline
          take_baseline() {
            echo "Taking system baseline..."
            {
              echo "{"
              echo "  \"timestamp\": \"$(date -Iseconds)\","
              echo "  \"listening_ports\": $(ss -tlnp | tail -n +2 | jq -R -s 'split("\n") | map(select(length > 0))'),"
              echo "  \"running_processes\": $(ps aux --no-headers | awk '{print $11}' | sort -u | jq -R -s 'split("\n") | map(select(length > 0))'),"
              echo "  \"kernel_modules\": $(lsmod | tail -n +2 | awk '{print $1}' | jq -R -s 'split("\n") | map(select(length > 0))')"
              echo "}"
            } > "$BASELINE_FILE"
          }

          # Check for suspicious processes
          check_suspicious_processes() {
            local suspicious="${concatStringsSep "|" cfg.edr.processMonitoring.suspiciousProcesses}"
            
            ps aux --no-headers | awk '{print $11, $2, $1}' | while read -r proc pid user; do
              if echo "$proc" | grep -qE "$suspicious"; then
                log_event "high" "suspicious_process" "Suspicious process detected: $proc" \
                  "{\"process\":\"$proc\",\"pid\":\"$pid\",\"user\":\"$user\"}"
              fi
            done
          }

          # Check for new listening ports
          check_new_listeners() {
            if [ ! -f "$BASELINE_FILE" ]; then
              return
            fi

            current_ports=$(ss -tlnp | tail -n +2 | awk '{print $4}' | sort -u)
            baseline_ports=$(jq -r '.listening_ports[]' "$BASELINE_FILE" 2>/dev/null | awk '{print $4}' | sort -u)

            for port in $current_ports; do
              if ! echo "$baseline_ports" | grep -q "^$port$"; then
                log_event "medium" "new_listener" "New listening port detected: $port" \
                  "{\"port\":\"$port\"}"
              fi
            done
          }

          # Monitor for privilege escalation
          check_privesc() {
            # Check for SUID/SGID changes
            find /usr /bin /sbin -perm /6000 -type f 2>/dev/null | while read -r file; do
              if ! grep -q "^$file$" /var/lib/soc/edr/suid_baseline.txt 2>/dev/null; then
                log_event "critical" "privilege_escalation" "New SUID/SGID binary: $file" \
                  "{\"file\":\"$file\"}"
              fi
            done
          }

          # Main monitoring loop
          mkdir -p /var/lib/soc/edr
          mkdir -p /var/log/soc

          if [ ! -f "$BASELINE_FILE" ]; then
            take_baseline
          fi

          # Create SUID baseline
          find /usr /bin /sbin -perm /6000 -type f 2>/dev/null > /var/lib/soc/edr/suid_baseline.txt || true

          echo "EDR monitoring started at $(date -Iseconds)"

          while true; do
            ${optionalString cfg.edr.processMonitoring.enable "check_suspicious_processes"}
            ${optionalString cfg.edr.networkTracking.alertOnNewListeners "check_new_listeners"}
            ${optionalString cfg.edr.behavior.detectPrivEsc "check_privesc"}
            
            sleep 30
          done
        ''}";
        Restart = "always";
        RestartSec = "10";
      };
    };

    # Process execution logger using audit
    systemd.services.soc-execlog = {
      description = "SOC Process Execution Logger";
      after = [ "auditd.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "execlog" ''
          #!/usr/bin/env bash
          ${pkgs.audit}/bin/ausearch -ts recent -m EXECVE --format text 2>/dev/null | \
          while IFS= read -r line; do
            echo "[$(date -Iseconds)] $line" >> /var/log/soc/executions.log
          done &

          # Also watch for new executions
          ${pkgs.audit}/bin/aureport -x --summary 2>/dev/null | while true; do
            ${pkgs.audit}/bin/ausearch -ts recent -m EXECVE --format text 2>/dev/null
            sleep 5
          done
        ''}";
        Restart = "always";
      };
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/soc/edr 0750 root root -"
    ];

    # CLI aliases
    environment.shellAliases = {
      edr-status = "systemctl status soc-edr";
      edr-alerts = "tail -f /var/log/soc/edr-alerts.json | jq";
      edr-baseline = "sudo systemctl restart soc-edr";
    };
  };
}
