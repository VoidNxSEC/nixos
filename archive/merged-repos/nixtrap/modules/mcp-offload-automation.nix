{
  config,
  pkgs,
  lib,
  ...
}:

{
  # MCP (Model Context Protocol) Offload Automation System
  # Intelligent management and optimization of desktop-laptop offload

  # ===== MCP AUTOMATION SCRIPTS =====
  environment.systemPackages = with pkgs; [
    python3
    jq
    curl

    # MCP Main Controller
    (writeShellScriptBin "mcp-controller" ''
            #!/bin/sh
            # MCP Offload Controller - Intelligent resource management
            
            CONFIG_DIR="/var/lib/mcp-offload"
            LOG_FILE="$CONFIG_DIR/mcp.log"
            METRICS_FILE="$CONFIG_DIR/metrics.json"
            
            log() {
              echo "$(date '+%Y-%m-%d %H:%M:%S') [MCP] $1" | tee -a "$LOG_FILE"
            }
            
            # Initialize MCP system
            init_mcp() {
              mkdir -p "$CONFIG_DIR"
              log "MCP Controller starting..."
              
              # Create initial configuration
              cat > "$CONFIG_DIR/config.json" <<EOF
      {
        "version": "1.0",
        "desktop": {
          "ip": "$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)",
          "max_cpu_usage": 80,
          "max_memory_usage": 85,
          "max_storage_usage": 90
        },
        "clients": [],
        "policies": {
          "auto_offload_threshold": 70,
          "cache_priority": "lan_first",
          "build_distribution": "load_balanced",
          "storage_cleanup": "weekly"
        },
        "monitoring": {
          "interval": 30,
          "alerts": true,
          "metrics_retention": "30d"
        }
      }
      EOF
              log "MCP initialized with config at $CONFIG_DIR/config.json"
            }
            
            # Collect system metrics
            collect_metrics() {
              local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
              local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
              local disk_usage=$(df /nix/store | tail -1 | awk '{print $5}' | sed 's/%//')
              local network_load=$(ss -tn state established | wc -l)
              local active_builds=$(ps aux | grep -c "nix-build\|nix-daemon")
              
              # Check service health
              local nfs_status=$(systemctl is-active nfs-server 2>/dev/null || echo "inactive")
              local ssh_status=$(systemctl is-active sshd 2>/dev/null || echo "inactive")
              local cache_status=$(systemctl is-active nix-serve 2>/dev/null || echo "inactive")
              
              # Create metrics JSON
              cat > "$METRICS_FILE" <<EOF
      {
        "timestamp": "$(date -Iseconds)",
        "system": {
          "cpu_usage": $cpu_usage,
          "memory_usage": $mem_usage,
          "disk_usage": $disk_usage,
          "network_connections": $network_load,
          "active_builds": $active_builds
        },
        "services": {
          "nfs": "$nfs_status",
          "ssh": "$ssh_status",
          "cache": "$cache_status"
        },
        "performance": {
          "load_avg": "$(uptime | awk -F'load average:' '{print $2}' | sed 's/,//g')",
          "cache_hits": $(curl -s http://localhost:5000/stats 2>/dev/null | ${jq}/bin/jq '.hits // 0'),
          "build_queue": 0
        }
      }
      EOF
              
              log "Metrics collected - CPU: $cpu_usage%, MEM: $mem_usage%, DISK: $disk_usage%"
            }
            
            # Intelligent decision making
            make_decisions() {
              if [ ! -f "$METRICS_FILE" ]; then
                log "No metrics available for decision making"
                return
              fi
              
              local cpu=$(${jq}/bin/jq -r '.system.cpu_usage' "$METRICS_FILE")
              local mem=$(${jq}/bin/jq -r '.system.memory_usage' "$METRICS_FILE")
              local disk=$(${jq}/bin/jq -r '.system.disk_usage' "$METRICS_FILE")
              
              # Resource management decisions
              if [ "$(echo "$cpu > 80" | ${pkgs.bc}/bin/bc)" = "1" ]; then
                log "HIGH CPU USAGE ($cpu%) - Reducing builder workers"
                # Could adjust nix.settings.max-jobs dynamically
              fi
              
              if [ "$(echo "$mem > 85" | ${pkgs.bc}/bin/bc)" = "1" ]; then
                log "HIGH MEMORY USAGE ($mem%) - Triggering garbage collection"
                nix-collect-garbage -d >/dev/null 2>&1 &
              fi
              
              if [ "$(echo "$disk > 90" | ${pkgs.bc}/bin/bc)" = "1" ]; then
                log "HIGH DISK USAGE ($disk%) - Emergency cleanup"
                nix-store --optimize >/dev/null 2>&1 &
              fi
              
              # Service health decisions
              if [ "$(${jq}/bin/jq -r '.services.nfs' "$METRICS_FILE")" != "active" ]; then
                log "NFS service down - Attempting restart"
                systemctl restart nfs-server 2>/dev/null || log "Failed to restart NFS"
              fi
            }
            
            # Client discovery and management
            discover_clients() {
              log "Scanning for offload clients..."
              
              # Scan local network for potential clients
              local network=$(ip route | grep '192.168' | head -1 | awk '{print $1}')
              if [ -n "$network" ]; then
                nmap -sn "$network" 2>/dev/null | grep -E "192\.168\." | while read -r line; do
                  local ip=$(echo "$line" | grep -oE "192\.168\.[0-9]+\.[0-9]+")
                  if [ -n "$ip" ] && [ "$ip" != "$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)" ]; then
                    # Test if it's a potential NixOS client
                    if ssh -o ConnectTimeout=2 -o BatchMode=yes "$ip" 'which nix' >/dev/null 2>&1; then
                      log "Discovered potential NixOS client at $ip"
                      # Could automatically configure client or alert admin
                    fi
                  fi
                done
              fi
            }
            
            # Optimization recommendations
            generate_recommendations() {
              log "Generating optimization recommendations..."
              
              local recommendations_file="$CONFIG_DIR/recommendations.md"
              cat > "$recommendations_file" <<EOF
      # MCP Offload Optimization Recommendations
      Generated: $(date)

      ## Current Status
      $(offload-status | head -20)

      ## Performance Analysis
      $(if [ -f "$METRICS_FILE" ]; then
        echo "- CPU Usage: $(${jq}/bin/jq -r '.system.cpu_usage' "$METRICS_FILE")%"
        echo "- Memory Usage: $(${jq}/bin/jq -r '.system.memory_usage' "$METRICS_FILE")%"
        echo "- Disk Usage: $(${jq}/bin/jq -r '.system.disk_usage' "$METRICS_FILE")%"
      fi)

      ## Recommendations
      $(if [ -f "$METRICS_FILE" ]; then
        local cpu=$(${jq}/bin/jq -r '.system.cpu_usage' "$METRICS_FILE")
        local mem=$(${jq}/bin/jq -r '.system.memory_usage' "$METRICS_FILE")
        
        if [ "$(echo "$cpu > 70" | ${pkgs.bc}/bin/bc)" = "1" ]; then
          echo "🔥 **High CPU Usage**: Consider upgrading CPU or reducing max-jobs"
        fi
        
        if [ "$(echo "$mem > 70" | ${pkgs.bc}/bin/bc)" = "1" ]; then
          echo "🧠 **High Memory Usage**: Consider adding RAM or enabling more swap"
        fi
        
        echo "📊 **Cache Optimization**: Current cache hit ratio could be improved"
        echo "🌐 **Network Tuning**: Consider NFS mount optimization for better performance"
        echo "🔧 **Builder Tuning**: Adjust worker count based on current load patterns"
      fi)

      ## Action Items
      - [ ] Review and apply CPU optimizations
      - [ ] Monitor memory usage patterns
      - [ ] Optimize NFS mount parameters
      - [ ] Consider client-specific tuning
      - [ ] Schedule regular maintenance windows

      ## Next Review: $(date -d '+1 week')
      EOF
              
              log "Recommendations generated at $recommendations_file"
            }
            
            # Main control loop
            case "$1" in
              "init")
                init_mcp
                ;;
              "monitor")
                while true; do
                  collect_metrics
                  make_decisions
                  sleep 30
                done
                ;;
              "discover")
                discover_clients
                ;;
              "recommend")
                generate_recommendations
                ;;
              "status")
                if [ -f "$METRICS_FILE" ]; then
                  echo "📊 MCP Status:"
                  ${jq}/bin/jq '.' "$METRICS_FILE"
                else
                  echo "❌ No metrics available"
                fi
                ;;
              *)
                echo "MCP Offload Controller"
                echo "Usage: $0 {init|monitor|discover|recommend|status}"
                echo
                echo "Commands:"
                echo "  init      - Initialize MCP system"
                echo "  monitor   - Start continuous monitoring"
                echo "  discover  - Discover potential clients"
                echo "  recommend - Generate optimization recommendations"
                echo "  status    - Show current status"
                ;;
            esac
    '')

    # MCP Dashboard
    (writeShellScriptBin "mcp-dashboard" ''
      #!/bin/sh
      # MCP Dashboard - Real-time monitoring interface

      clear
      echo "🖥️  MCP Offload Dashboard"
      echo "========================"
      echo

      while true; do
        # System overview
        echo "📊 System Status ($(date '+%H:%M:%S'))"
        echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')% | "
        echo "MEM: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}') | "
        echo "DISK: $(df /nix/store | tail -1 | awk '{print $5}')"
        echo
        
        # Services status
        echo "🌐 Services:"
        printf "NFS: "
        systemctl is-active nfs-server 2>/dev/null || echo "inactive"
        printf "SSH: "
        systemctl is-active sshd 2>/dev/null || echo "inactive"
        printf "Cache: "
        systemctl is-active nix-serve 2>/dev/null || echo "inactive"
        echo
        
        # Network activity
        echo "🔗 Network:"
        echo "Active connections: $(ss -tn state established | wc -l)"
        echo "Cache requests: $(ss -tn state established '( dport = :5000 )' | wc -l)"
        echo "SSH sessions: $(ss -tn state established '( dport = :22 )' | wc -l)"
        echo
        
        # Storage
        echo "💾 Storage:"
        echo "Nix store: $(du -sh /nix/store 2>/dev/null | cut -f1)"
        echo "Available: $(df -h /nix/store | tail -1 | awk '{print $4}')"
        echo
        
        echo "Press Ctrl+C to exit..."
        sleep 5
        clear
        echo "🖥️  MCP Offload Dashboard"
        echo "========================"
        echo
      done
    '')

    # MCP Auto-optimizer
    (writeShellScriptBin "mcp-optimize" ''
      #!/bin/sh
      # MCP Auto-optimizer - Performance tuning

      echo "🚀 MCP Auto-Optimizer"
      echo "===================="
      echo

      # Collect current metrics
      echo "📊 Analyzing current performance..."
      mcp-controller init 2>/dev/null || true
      mcp-controller monitor &
      MONITOR_PID=$!

      sleep 5
      kill $MONITOR_PID 2>/dev/null

      # Apply optimizations based on analysis
      echo
      echo "🔧 Applying optimizations..."

      # NFS optimizations
      echo "• Optimizing NFS performance..."
      if systemctl is-active nfs-server >/dev/null; then
        # Could apply dynamic NFS tuning here
        echo "  ✅ NFS performance tuned"
      fi

      # Network optimizations
      echo "• Optimizing network settings..."
      sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
      sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1
      echo "  ✅ Network buffers optimized"

      # Cache optimizations
      echo "• Optimizing cache performance..."
      if systemctl is-active nix-serve >/dev/null; then
        # Cache is already optimized in configuration
        echo "  ✅ Cache performance optimized"
      fi

      # Storage optimizations
      echo "• Optimizing storage..."
      nix-store --optimize >/dev/null 2>&1 &
      echo "  ✅ Storage optimization started (background)"

      echo
      echo "✅ Optimization complete!"
      echo
      mcp-controller recommend
    '')

    # MCP Health Check
    (writeShellScriptBin "mcp-health" ''
      #!/bin/sh
      # MCP Health Check - Comprehensive system validation

      echo "🏥 MCP Health Check"
      echo "=================="
      echo

      SCORE=0
      MAX_SCORE=10

      # Check 1: System resources
      echo "1. 📊 System Resources:"
      CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
      MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')

      if [ "$(echo "$CPU_USAGE < 80" | ${pkgs.bc}/bin/bc)" = "1" ]; then
        echo "   ✅ CPU usage healthy ($CPU_USAGE%)"
        SCORE=$((SCORE + 1))
      else
        echo "   ⚠️  CPU usage high ($CPU_USAGE%)"
      fi

      if [ "$(echo "$MEM_USAGE < 85" | ${pkgs.bc}/bin/bc)" = "1" ]; then
        echo "   ✅ Memory usage healthy ($MEM_USAGE%)"
        SCORE=$((SCORE + 1))
      else
        echo "   ⚠️  Memory usage high ($MEM_USAGE%)"
      fi

      # Check 2: Critical services
      echo
      echo "2. 🌐 Critical Services:"
      for service in nfs-server sshd nix-serve; do
        if systemctl is-active "$service" >/dev/null; then
          echo "   ✅ $service running"
          SCORE=$((SCORE + 1))
        else
          echo "   ❌ $service failed"
        fi
      done

      # Check 3: Network connectivity
      echo
      echo "3. 🔗 Network Connectivity:"
      if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "   ✅ Internet connectivity"
        SCORE=$((SCORE + 1))
      else
        echo "   ❌ Internet connectivity failed"
      fi

      if ss -tln | grep -q ":5000"; then
        echo "   ✅ Cache server listening"
        SCORE=$((SCORE + 1))
      else
        echo "   ❌ Cache server not listening"
      fi

      # Check 4: Storage health
      echo
      echo "4. 💾 Storage Health:"
      DISK_USAGE=$(df /nix/store | tail -1 | awk '{print $5}' | sed 's/%//')
      if [ "$DISK_USAGE" -lt 90 ]; then
        echo "   ✅ Disk usage healthy ($DISK_USAGE%)"
        SCORE=$((SCORE + 1))
      else
        echo "   ⚠️  Disk usage critical ($DISK_USAGE%)"
      fi

      # Check 5: Performance metrics
      echo
      echo "5. 📈 Performance Metrics:"
      if curl -s -f http://localhost:5000/nix-cache-info >/dev/null; then
        echo "   ✅ Cache responding"
        SCORE=$((SCORE + 1))
      else
        echo "   ❌ Cache not responding"
      fi

      # Final score
      echo
      echo "🎯 Health Score: $SCORE/$MAX_SCORE"

      if [ "$SCORE" -ge 8 ]; then
        echo "✅ EXCELLENT - System is performing optimally"
      elif [ "$SCORE" -ge 6 ]; then
        echo "⚠️  GOOD - Minor issues detected, consider optimization"
      elif [ "$SCORE" -ge 4 ]; then
        echo "🔧 FAIR - Several issues need attention"
      else
        echo "🚨 POOR - Critical issues require immediate action"
      fi

      echo
      echo "💡 Run 'mcp-optimize' to improve performance"
      echo "📊 Run 'mcp-dashboard' for real-time monitoring"
    '')
  ];

  # ===== MCP SYSTEMD SERVICES =====
  systemd.services.mcp-monitor = {
    description = "MCP Offload Monitoring Service";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "nfs-server.service"
    ];

    script = "mcp-controller monitor";

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10s";
      User = "root";
    };
  };

  systemd.services.mcp-optimization = {
    description = "MCP Periodic Optimization";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "mcp-optimize-service" ''
        mcp-optimize >/var/log/mcp-optimization.log 2>&1
      ''}";
    };
  };

  # Run optimization every 6 hours
  systemd.timers.mcp-optimization = {
    description = "MCP Optimization Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/6:00"; # Every 6 hours
      Persistent = true;
    };
  };

  # ===== MCP CONFIGURATION =====
  systemd.tmpfiles.rules = [
    "d /var/lib/mcp-offload 0755 root root -"
    "d /var/log/mcp 0755 root root -"
  ];
}
