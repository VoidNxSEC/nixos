{
  pkgs,
  lib,
  name,
  pkg,
  package,
}:

with lib;

let
  # Audit log directory
  logDir = "/var/log/deb-packages";

  # Log levels and their corresponding verbosity
  logLevels = {
    minimal = {
      # Only log executions
      auditRules = [
        "-w ${package}/bin/${name} -p x -k deb_exec_${name}"
      ];
      journalFields = [ "MESSAGE" ];
    };

    standard = {
      # Log executions, file access, and resource usage
      auditRules = [
        "-w ${package}/bin/${name} -p x -k deb_exec_${name}"
        "-w ${package}/lib -p r -k deb_lib_${name}"
      ];
      journalFields = [
        "MESSAGE"
        "_PID"
        "_UID"
        "_GID"
        "_CMDLINE"
      ];
    };

    verbose = {
      # Log everything including syscalls
      auditRules = [
        "-w ${package}/bin/${name} -p rwxa -k deb_exec_${name}"
        "-w ${package}/lib -p rwa -k deb_lib_${name}"
        "-a always,exit -F arch=b64 -S execve -F exe=${package}/bin/${name} -k deb_syscall_${name}"
      ];
      journalFields = [
        "MESSAGE"
        "_PID"
        "_UID"
        "_GID"
        "_CMDLINE"
        "_CAP_EFFECTIVE"
        "_SYSTEMD_CGROUP"
      ];
    };
  };

  currentLogLevel = logLevels.${pkg.audit.logLevel};

  # Create wrapper script that logs execution
  auditWrapper = pkgs.writeShellScriptBin "${name}-audited" ''
    #!/bin/bash

    # Log directory
    LOG_DIR="${logDir}"
    LOG_FILE="$LOG_DIR/${name}.log"

    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Log entry function
    log_entry() {
      local level="$1"
      local message="$2"
      echo "[$(date -Iseconds)] [$level] [PID:$$] [USER:$USER] $message" >> "$LOG_FILE"
    }

    # Start execution log
    log_entry "INFO" "Execution started: ${name} $*"
    log_entry "INFO" "Working directory: $(pwd)"
    log_entry "INFO" "Environment: $(env | grep -E '^(PATH|LD_LIBRARY_PATH|HOME)=')"

    # Log to systemd journal
    ${
      if pkg.audit.logLevel == "verbose" then
        ''
                systemd-cat -t "deb-package-${name}" -p info <<EOF
          Package: ${name}
          Method: ${pkg.method}
          Arguments: $*
          User: $USER
          PID: $$
          Working Directory: $(pwd)
          Timestamp: $(date -Iseconds)
          EOF
        ''
      else
        ''
          systemd-cat -t "deb-package-${name}" -p info echo "Executing ${name} $*"
        ''
    }

    # Resource tracking (if verbose)
    ${
      if pkg.audit.logLevel == "verbose" then
        ''
          # Start time
          START_TIME=$(date +%s)

          # Create temporary file for resource tracking
          TRACK_FILE=$(mktemp)

          # Background process to track resources
          (
            while kill -0 $$ 2>/dev/null; do
              if [ -f /proc/$$/status ]; then
                MEM=$(grep VmRSS /proc/$$/status | awk '{print $2}')
                log_entry "DEBUG" "Memory usage: $MEM kB"
              fi
              sleep 5
            done
          ) &
          TRACKER_PID=$!
        ''
      else
        ""
    }

    # Execute the actual binary
    EXIT_CODE=0
    ${package}/bin/${name} "$@" || EXIT_CODE=$?

    # Stop resource tracker
    ${
      if pkg.audit.logLevel == "verbose" then
        ''
          kill $TRACKER_PID 2>/dev/null || true
          wait $TRACKER_PID 2>/dev/null || true

          # Calculate execution time
          END_TIME=$(date +%s)
          DURATION=$((END_TIME - START_TIME))

          log_entry "INFO" "Execution duration: $DURATION seconds"

          # Log final resource usage
          if [ -f /proc/$$/status ]; then
            PEAK_MEM=$(grep VmPeak /proc/$$/status | awk '{print $2}')
            log_entry "INFO" "Peak memory usage: $PEAK_MEM kB"
          fi
        ''
      else
        ""
    }

    # Log exit status
    if [ $EXIT_CODE -eq 0 ]; then
      log_entry "INFO" "Execution completed successfully"
    else
      log_entry "ERROR" "Execution failed with exit code: $EXIT_CODE"
    fi

    # Log to systemd journal
    if [ $EXIT_CODE -eq 0 ]; then
      systemd-cat -t "deb-package-${name}" -p info echo "Execution completed successfully"
    else
      systemd-cat -t "deb-package-${name}" -p err echo "Execution failed with exit code: $EXIT_CODE"
    fi

    exit $EXIT_CODE
  '';

  # Systemd service for log rotation and management
  logRotationService = {
    description = "Log rotation for ${name} deb package";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "rotate-${name}-logs" ''
        #!/bin/bash
        LOG_FILE="${logDir}/${name}.log"

        if [ -f "$LOG_FILE" ]; then
          # Get file size in bytes
          FILE_SIZE=$(stat -f %z "$LOG_FILE" 2>/dev/null || stat -c %s "$LOG_FILE")

          # Rotate if larger than 10MB
          if [ "$FILE_SIZE" -gt 10485760 ]; then
            mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d-%H%M%S)"
            touch "$LOG_FILE"

            # Keep only last 5 rotated logs
            ls -t "${logDir}/${name}.log."* 2>/dev/null | tail -n +6 | xargs rm -f
          fi
        fi
      '';
    };
  };

  # Systemd timer for log rotation (daily)
  logRotationTimer = {
    description = "Daily log rotation for ${name}";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Monitoring service (optional - tracks resource usage)
  monitoringService = mkIf (pkg.audit.logLevel == "verbose") {
    description = "Resource monitoring for ${name}";
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeScript "monitor-${name}" ''
        #!/bin/bash

        while true; do
          # Find all running instances
          pgrep -f "${name}" | while read pid; do
            if [ -f "/proc/$pid/status" ]; then
              MEM=$(grep VmRSS /proc/$pid/status | awk '{print $2}')
              CPU=$(ps -p $pid -o %cpu= || echo "0")

              # Log to journal
              systemd-cat -t "deb-package-${name}-monitor" -p debug <<EOF
        PID: $pid
        Memory: $MEM kB
        CPU: $CPU%
        Timestamp: $(date -Iseconds)
        EOF
            fi
          done

          sleep 60
        done
      '';
      Restart = "always";
      RestartSec = "10s";
    };
    wantedBy = [ "multi-user.target" ];
  };

in
{
  # Return audited wrapper
  inherit auditWrapper;

  # Systemd services for logging and monitoring
  systemdServices = {
    "deb-package-${name}-log-rotation" = logRotationService;
  }
  // (
    if pkg.audit.logLevel == "verbose" then
      {
        "deb-package-${name}-monitor" = monitoringService;
      }
    else
      { }
  );

  # Systemd timers
  systemdTimers = {
    "deb-package-${name}-log-rotation" = logRotationTimer;
  };

  # Audit rules for Linux audit daemon
  auditRules = currentLogLevel.auditRules;

  # Log file paths
  logFiles = {
    main = "${logDir}/${name}.log";
    directory = logDir;
  };
}
