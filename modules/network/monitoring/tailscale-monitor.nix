{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.monitoring.tailscale;

  # Monitoring script
  monitorScript = pkgs.writeShellScript "tailscale-monitor" ''
    #!/usr/bin/env bash
    # Tailscale Connection Quality Monitor with Auto-Failover

    set -euo pipefail

    # Configuration
    CHECK_INTERVAL=''${CHECK_INTERVAL:-30}
    MAX_LATENCY=''${MAX_LATENCY:-200}  # milliseconds
    MAX_PACKET_LOSS=''${MAX_PACKET_LOSS:-5}  # percent
    ALERT_EMAIL=''${ALERT_EMAIL:-""}
    LOG_FILE="''${LOGS_DIRECTORY:-/var/log}/tailscale-monitor.log"

    # Colors for terminal output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    # Logging function
    log() {
      local level="$1"
      shift
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
    }

    # Check Tailscale connectivity
    check_tailscale() {
      local status_output
      status_output=$(${pkgs.tailscale}/bin/tailscale status 2>&1 || echo "")
      
      # Check if Tailscale needs login
      if echo "$status_output" | grep -q "Logged out"; then
        log "WARN" "Tailscale is not authenticated yet - waiting for login"
        return 2  # Special return code for "needs auth"
      fi
      
      if ! ${pkgs.tailscale}/bin/tailscale status &>/dev/null; then
        log "ERROR" "Tailscale is not connected"
        return 1
      fi
      return 0
    }

    # Wait for Tailscale authentication
    wait_for_tailscale_auth() {
      log "INFO" "Waiting for Tailscale authentication..."
      local max_wait=300  # 5 minutes
      local waited=0
      
      while [ $waited -lt $max_wait ]; do
        if check_tailscale; then
          log "INFO" "Tailscale is authenticated and ready"
          return 0
        fi
        
        local check_result=$?
        if [ $check_result -eq 2 ]; then
          # Needs auth - keep waiting
          log "INFO" "Still waiting for authentication (''${waited}s/''${max_wait}s)"
        else
          # Other error
          log "WARN" "Tailscale check failed with unexpected error"
        fi
        
        sleep 30
        waited=$((waited + 30))
      done
      
      log "ERROR" "Timeout waiting for Tailscale authentication after ''${max_wait}s"
      return 1
    }

    # Measure connection quality
    measure_quality() {
      local peer="$1"
      
      # Run netcheck for connection quality
      local netcheck_output
      netcheck_output=$(${pkgs.tailscale}/bin/tailscale netcheck 2>/dev/null || echo "")
      
      # Parse latency from netcheck
      local latency
      latency=$(echo "$netcheck_output" | grep -oP 'latency: \K[0-9.]+' | head -1 || echo "0")
      
      # Ping test for packet loss
      local ping_output
      ping_output=$(${pkgs.tailscale}/bin/tailscale ping -c 5 "$peer" 2>/dev/null || echo "")
      
      local packet_loss
      packet_loss=$(echo "$ping_output" | grep -oP '\K[0-9.]+(?=% packet loss)' || echo "100")
      
      echo "$latency:$packet_loss"
    }

    # Check service availability
    check_service() {
      local service="$1"
      local port="$2"
      
      if ${pkgs.netcat}/bin/nc -zv 127.0.0.1 "$port" 2>&1 | grep -q succeeded; then
        return 0
      else
        return 1
      fi
    }

    # Trigger failover
    trigger_failover() {
      log "WARN" "Triggering failover to local network"
      
      # Disable Tailscale temporarily
      ${pkgs.tailscale}/bin/tailscale down || true
      
      # Notify if email configured
      if [ -n "$ALERT_EMAIL" ]; then
        echo "Tailscale failover triggered at $(date)" | \
          ${pkgs.mailutils}/bin/mail -s "Tailscale Failover Alert" "$ALERT_EMAIL" || true
      fi
    }

    # Restore Tailscale connection
    restore_connection() {
      log "INFO" "Attempting to restore Tailscale connection"
      
      ${pkgs.tailscale}/bin/tailscale up || {
        log "ERROR" "Failed to restore Tailscale connection"
        return 1
      }
      
      sleep 5
      
      if check_tailscale; then
        log "INFO" "Tailscale connection restored successfully"
        return 0
      else
        log "ERROR" "Tailscale restoration failed"
        return 1
      fi
    }

    # Main monitoring loop
    monitor_loop() {
      log "INFO" "Starting Tailscale connection monitor"
      log "INFO" "Check interval: ''${CHECK_INTERVAL}s, Max latency: ''${MAX_LATENCY}ms, Max packet loss: ''${MAX_PACKET_LOSS}%"
      
      # Wait for Tailscale to be authenticated before starting monitoring
      if ! wait_for_tailscale_auth; then
        log "ERROR" "Cannot start monitoring - Tailscale authentication timeout"
        log "INFO" "Please authenticate Tailscale with: sudo tailscale up"
        exit 1
      fi
      
      local consecutive_failures=0
      local failover_active=false
      
      while true; do
        # Check basic connectivity
        check_tailscale
        local check_result=$?
        
        if [ $check_result -eq 2 ]; then
          # Needs auth - wait and retry
          log "WARN" "Tailscale lost authentication - waiting for re-auth"
          if ! wait_for_tailscale_auth; then
            log "ERROR" "Failed to re-authenticate - exiting"
            exit 1
          fi
          continue
        elif [ $check_result -ne 0 ]; then
          consecutive_failures=$((consecutive_failures + 1))
          log "WARN" "Tailscale connectivity check failed (attempt $consecutive_failures/3)"
          
          if [ $consecutive_failures -ge 3 ] && [ "$failover_active" = false ]; then
            trigger_failover
            failover_active=true
          fi
        else
          # Connectivity OK - measure quality
          local quality
          quality=$(measure_quality "" || echo "0:100")
          
          local latency
          latency=$(echo "$quality" | cut -d: -f1)
          
          local packet_loss
          packet_loss=$(echo "$quality" | cut -d: -f2)
          
          log "INFO" "Connection quality: Latency=''${latency}ms, Packet Loss=''${packet_loss}%"
          
          # Check thresholds
          if (( $(echo "$latency > $MAX_LATENCY" | ${pkgs.bc}/bin/bc -l) )) || \
             (( $(echo "$packet_loss > $MAX_PACKET_LOSS" | ${pkgs.bc}/bin/bc -l) )); then
            consecutive_failures=$((consecutive_failures + 1))
            log "WARN" "Poor connection quality detected (attempt $consecutive_failures/3)"
            
            if [ $consecutive_failures -ge 3 ] && [ "$failover_active" = false ]; then
              trigger_failover
              failover_active=true
            fi
          else
            # Quality OK
            if [ "$failover_active" = true ]; then
              log "INFO" "Connection quality improved, attempting to restore"
              if restore_connection; then
                failover_active=false
                consecutive_failures=0
              fi
            else
              consecutive_failures=0
            fi
          fi
        fi
        
        sleep "$CHECK_INTERVAL"
      done
    }

    # Handle signals
    trap 'log "INFO" "Monitor stopping"; exit 0' SIGTERM SIGINT

    # Start monitoring
    monitor_loop
  '';

  # Performance benchmark script
  benchmarkScript = pkgs.writeShellScript "tailscale-benchmark" ''
    #!/usr/bin/env bash
    # Tailscale Performance Benchmark Suite

    set -euo pipefail

    # Colors
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "''${BLUE}======================================="
    echo -e "  TAILSCALE PERFORMANCE BENCHMARK"
    echo -e "=======================================''${NC}"
    echo ""

    # 1. Connection Quality
    echo -e "''${YELLOW}1. Network Quality Check''${NC}"
    ${pkgs.tailscale}/bin/tailscale netcheck
    echo ""

    # 2. Latency Test
    echo -e "''${YELLOW}2. Latency Test (ping)''${NC}"
    local peer_ip
    peer_ip=$(${pkgs.tailscale}/bin/tailscale ip -4 | head -1)
    if [ -n "$peer_ip" ]; then
      ${pkgs.iputils}/bin/ping -c 10 "$peer_ip" | tail -1
    else
      echo "No peers available for latency test"
    fi
    echo ""

    # 3. Bandwidth Test (requires iperf3 on both ends)
    echo -e "''${YELLOW}3. Bandwidth Test''${NC}"
    echo "Note: Requires iperf3 server on remote peer"
    echo "To run: iperf3 -c <peer-ip> -t 10"
    echo ""

    # 4. Service Response Times
    echo -e "''${YELLOW}4. Service Response Times''${NC}"

    # Test Ollama
    if ${pkgs.netcat}/bin/nc -z 127.0.0.1 11434 2>/dev/null; then
      echo -n "Ollama (11434): "
      time ${pkgs.curl}/bin/curl -s http://127.0.0.1:11434/api/tags > /dev/null || echo "Failed"
    fi

    # Test LlamaCPP
    if ${pkgs.netcat}/bin/nc -z 127.0.0.1 8080 2>/dev/null; then
      echo -n "LlamaCPP (8080): "
      time ${pkgs.curl}/bin/curl -s http://127.0.0.1:8080/health > /dev/null || echo "Failed"
    fi

    echo ""
    echo -e "''${GREEN}Benchmark complete!''${NC}"
  '';
in
{
  options.kernelcore.network.monitoring.tailscale = {
    enable = mkEnableOption "Enable Tailscale connection monitoring and auto-failover";

    checkInterval = mkOption {
      type = types.int;
      default = 30;
      description = "Interval between health checks in seconds";
    };

    maxLatency = mkOption {
      type = types.int;
      default = 200;
      description = "Maximum acceptable latency in milliseconds";
    };

    maxPacketLoss = mkOption {
      type = types.int;
      default = 5;
      description = "Maximum acceptable packet loss percentage";
    };

    enableAutoFailover = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic failover to local network on poor connectivity";
    };

    alertEmail = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Email address for failover alerts";
    };

    enableBenchmarks = mkOption {
      type = types.bool;
      default = true;
      description = "Enable performance benchmarking tools";
    };
  };

  config = mkIf cfg.enable {
    # Monitoring service
    systemd.services.tailscale-monitor = {
      description = "Tailscale Connection Quality Monitor";
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        CHECK_INTERVAL = toString cfg.checkInterval;
        MAX_LATENCY = toString cfg.maxLatency;
        MAX_PACKET_LOSS = toString cfg.maxPacketLoss;
        ALERT_EMAIL = cfg.alertEmail or "";
        LOGS_DIRECTORY = "/var/log/tailscale-monitor";
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${monitorScript}";
        Restart = "always";
        RestartSec = "10s";

        # Logging directory managed by systemd
        LogsDirectory = "tailscale-monitor";

        # Security
        DynamicUser = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;

        # Resource limits
        MemoryMax = "128M";
        CPUQuota = "10%";
      };
    };

    # Log rotation for systemd logs directory
    services.logrotate = {
      enable = true;
      settings = {
        "/var/log/tailscale-monitor/tailscale-monitor.log" = {
          frequency = "daily";
          rotate = 7;
          compress = true;
          delaycompress = true;
          missingok = true;
          notifempty = true;
        };
      };
    };

    # Benchmark tools
    environment.systemPackages =
      with pkgs;
      [
        iperf3
        netcat
        bc
      ]
      ++ optional cfg.enableBenchmarks (
        pkgs.writeScriptBin "ts-benchmark" ''
          #!${pkgs.bash}/bin/bash
          ${benchmarkScript}
        ''
      );

    # Shell aliases
    environment.shellAliases = {
      ts-monitor-status = "systemctl status tailscale-monitor";
      ts-monitor-logs = "journalctl -u tailscale-monitor -f";
      ts-monitor-logs-file = "tail -f /var/log/tailscale-monitor/tailscale-monitor.log";
      ts-monitor-restart = "sudo systemctl restart tailscale-monitor";
      ts-quality = "${pkgs.tailscale}/bin/tailscale netcheck";
    };

    # Monitoring check script
    environment.etc."tailscale/monitoring-check.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Quick Tailscale monitoring status

        echo "======================================="
        echo "   TAILSCALE MONITORING STATUS"
        echo "======================================="
        echo ""

        # Monitor service status
        if systemctl is-active --quiet tailscale-monitor; then
          echo "✓ Monitor Service: Running"
        else
          echo "✗ Monitor Service: Stopped"
        fi

        # Recent log entries
        echo ""
        echo "Recent Events (last 10):"
        echo "------------------------"
        tail -n 10 /var/log/tailscale-monitor/tailscale-monitor.log 2>/dev/null || \
          journalctl -u tailscale-monitor -n 10 --no-pager || echo "No logs available"

        echo ""
        echo "======================================="
      '';
    };
  };
}
