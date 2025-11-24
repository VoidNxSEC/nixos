{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# NixOS Build Analytics & Monitoring
# ============================================================
# Advanced analytics for rebuild history and performance
# Version: 1.0.0
# ============================================================

let
  # Build history analyzer
  buildHistory = pkgs.writeShellScriptBin "build-history" ''
    #!/usr/bin/env bash
    # NixOS Build History Analyzer

    # Colors
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GRAY='\033[0;90m'
    NC='\033[0m'

    METRICS_DIR="$HOME/.cache/nixos-rebuild"
    LOG_DIR="/var/log/nixos-rebuild"

    echo -e "''${CYAN}╔════════════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${CYAN}║''${WHITE}          NixOS Build History & Analytics              ''${CYAN}║''${NC}"
    echo -e "''${CYAN}╚════════════════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # Count builds
    TOTAL_BUILDS=$(find "$METRICS_DIR" -name "metrics_*.json" 2>/dev/null | wc -l)
    SUCCESS_BUILDS=$(grep -l '"exit_code": 0' "$METRICS_DIR"/metrics_*.json 2>/dev/null | wc -l)
    FAILED_BUILDS=$((TOTAL_BUILDS - SUCCESS_BUILDS))

    if [ $TOTAL_BUILDS -eq 0 ]; then
        echo -e "  ''${YELLOW}⚠️  No build history found.''${NC}"
        echo -e "  ''${GRAY}Run 'rebuild' to start collecting metrics.''${NC}"
        exit 0
    fi

    # Success rate
    SUCCESS_RATE=$((SUCCESS_BUILDS * 100 / TOTAL_BUILDS))

    echo -e "''${WHITE}📊 Build Statistics''${NC}"
    echo -e "''${CYAN}$(printf '─%.0s' {1..60})''${NC}"
    echo ""
    printf "  %-25s ''${WHITE}%s''${NC}\n" "Total Builds:" "$TOTAL_BUILDS"
    printf "  %-25s ''${GREEN}%s''${NC}\n" "Successful:" "$SUCCESS_BUILDS"
    printf "  %-25s ''${RED}%s''${NC}\n" "Failed:" "$FAILED_BUILDS"
    printf "  %-25s ''${CYAN}%s%%''${NC}\n" "Success Rate:" "$SUCCESS_RATE"
    echo ""

    # Average duration
    echo -e "''${WHITE}⏱️  Build Performance''${NC}"
    echo -e "''${CYAN}$(printf '─%.0s' {1..60})''${NC}"
    echo ""

    # Extract durations from JSON files
    DURATIONS=$(grep -h '"duration_seconds"' "$METRICS_DIR"/metrics_*.json 2>/dev/null | \
                awk -F': ' '{print $2}' | tr -d ',' || echo "0")

    if [ -n "$DURATIONS" ] && [ "$DURATIONS" != "0" ]; then
        TOTAL_TIME=0
        COUNT=0
        MIN_TIME=999999
        MAX_TIME=0

        while read -r duration; do
            TOTAL_TIME=$((TOTAL_TIME + duration))
            COUNT=$((COUNT + 1))
            [ $duration -lt $MIN_TIME ] && MIN_TIME=$duration
            [ $duration -gt $MAX_TIME ] && MAX_TIME=$duration
        done <<< "$DURATIONS"

        AVG_TIME=$((TOTAL_TIME / COUNT))

        format_time() {
            local seconds=$1
            local minutes=$((seconds / 60))
            local hours=$((minutes / 60))
            minutes=$((minutes % 60))
            seconds=$((seconds % 60))

            if [ $hours -gt 0 ]; then
                echo "''${hours}h ''${minutes}m ''${seconds}s"
            elif [ $minutes -gt 0 ]; then
                echo "''${minutes}m ''${seconds}s"
            else
                echo "''${seconds}s"
            fi
        }

        printf "  %-25s ''${GREEN}%s''${NC}\n" "Fastest Build:" "$(format_time $MIN_TIME)"
        printf "  %-25s ''${YELLOW}%s''${NC}\n" "Average Build:" "$(format_time $AVG_TIME)"
        printf "  %-25s ''${RED}%s''${NC}\n" "Slowest Build:" "$(format_time $MAX_TIME)"
        echo ""
    fi

    # Recent builds
    echo -e "''${WHITE}📋 Recent Builds (last 10)''${NC}"
    echo -e "''${CYAN}$(printf '─%.0s' {1..60})''${NC}"
    echo ""

    find "$METRICS_DIR" -name "metrics_*.json" 2>/dev/null | sort -r | head -10 | while read file; do
        TIMESTAMP=$(basename "$file" | sed 's/metrics_\(.*\)\.json/\1/')
        EXIT_CODE=$(grep '"exit_code"' "$file" | awk -F': ' '{print $2}' | tr -d ',' || echo "?")
        DURATION=$(grep '"duration_seconds"' "$file" | awk -F': ' '{print $2}' | tr -d ',' || echo "0")
        COMMAND=$(grep '"command"' "$file" | awk -F': ' '{print $2}' | tr -d ',"' || echo "unknown")

        # Format timestamp
        TS_FORMATTED=$(echo "$TIMESTAMP" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')

        # Status icon
        if [ "$EXIT_CODE" == "0" ]; then
            STATUS="''${GREEN}✓''${NC}"
        else
            STATUS="''${RED}✗''${NC}"
        fi

        # Duration
        DUR_MIN=$((DURATION / 60))
        DUR_SEC=$((DURATION % 60))

        printf "  %s ''${GRAY}%s''${NC} ''${WHITE}%s''${NC} ''${CYAN}(%dm%ds)''${NC}\n" \
            "$STATUS" "$TS_FORMATTED" "$COMMAND" "$DUR_MIN" "$DUR_SEC"
    done

    echo ""
    echo -e "''${GRAY}Logs: $LOG_DIR''${NC}"
    echo -e "''${GRAY}Metrics: $METRICS_DIR''${NC}"
    echo ""
  '';

  # Build log viewer
  buildLogs = pkgs.writeShellScriptBin "build-logs" ''
    #!/usr/bin/env bash
    # NixOS Build Log Viewer

    # Colors
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GRAY='\033[0;90m'
    NC='\033[0m'

    LOG_DIR="/var/log/nixos-rebuild"

    echo -e "''${CYAN}╔════════════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${CYAN}║''${WHITE}          NixOS Build Logs                             ''${CYAN}║''${NC}"
    echo -e "''${CYAN}╚════════════════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # List logs
    LOGS=$(find "$LOG_DIR" -name "rebuild_*.log" 2>/dev/null | sort -r)

    if [ -z "$LOGS" ]; then
        echo -e "  ''${GRAY}No build logs found.''${NC}"
        exit 0
    fi

    LOG_COUNT=$(echo "$LOGS" | wc -l)

    echo -e "''${WHITE}Available Logs ($LOG_COUNT):''${NC}"
    echo ""

    i=1
    echo "$LOGS" | while read log; do
        FILENAME=$(basename "$log")
        SIZE=$(du -h "$log" 2>/dev/null | cut -f1)
        TIMESTAMP=$(echo "$FILENAME" | sed 's/rebuild_\(.*\)\.log/\1/' | \
                    sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')

        printf "  ''${CYAN}%2d.''${NC} ''${WHITE}%s''${NC} ''${GRAY}(%s)''${NC}\n" "$i" "$TIMESTAMP" "$SIZE"
        i=$((i + 1))
    done

    echo ""
    echo -e "''${WHITE}Commands:''${NC}"
    echo -e "  build-logs view [N]    View log N (default: latest)"
    echo -e "  build-logs tail [N]    Tail log N (default: latest)"
    echo -e "  build-logs clean       Remove old logs (>7 days)"
    echo ""

    # Handle commands
    case "$1" in
        view)
            NUM=''${2:-1}
            LOG=$(echo "$LOGS" | sed -n "''${NUM}p")
            if [ -n "$LOG" ]; then
                less "$LOG"
            else
                echo "Invalid log number"
            fi
            ;;
        tail)
            NUM=''${2:-1}
            LOG=$(echo "$LOGS" | sed -n "''${NUM}p")
            if [ -n "$LOG" ]; then
                tail -f "$LOG"
            else
                echo "Invalid log number"
            fi
            ;;
        clean)
            echo -e "''${YELLOW}⚠️  Remove logs older than 7 days?''${NC}"
            read -p "Continue? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                find "$LOG_DIR" -name "rebuild_*.log" -mtime +7 -delete 2>/dev/null
                echo -e "''${GREEN}✓ Cleanup complete''${NC}"
            fi
            ;;
        *)
            # Default: show latest log
            LOG=$(echo "$LOGS" | head -1)
            less "$LOG"
            ;;
    esac
  '';

  # Real-time system monitor during builds
  buildMonitor = pkgs.writeShellScriptBin "build-monitor" ''
    #!/usr/bin/env bash
    # Real-time Build Monitor

    # Colors
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    GRAY='\033[0;90m'
    NC='\033[0m'

    INTERVAL=''${1:-2}

    while true; do
        clear
        echo -e "''${CYAN}╔════════════════════════════════════════════════════════════════╗''${NC}"
        echo -e "''${CYAN}║''${WHITE}          NixOS Build Monitor                          ''${CYAN}║''${NC}"
        echo -e "''${CYAN}╚════════════════════════════════════════════════════════════════╝''${NC}"
        echo ""
        echo -e "''${GRAY}Refreshing every ''${INTERVAL}s... (Ctrl+C to exit)''${NC}"
        echo ""

        # CPU
        echo -e "''${WHITE}🔬 CPU:''${NC}"
        CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
        CPU_CORES=$(nproc)
        printf "  Load Average: ''${YELLOW}%s''${NC} / %s cores\n" "$CPU_LOAD" "$CPU_CORES"
        echo ""

        # Memory
        echo -e "''${WHITE}🧠 Memory:''${NC}"
        free -h | awk 'NR==2 {printf "  Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
        echo ""

        # Disk
        echo -e "''${WHITE}💾 Disk (/nix):''${NC}"
        df -h /nix | awk 'NR==2 {printf "  Used: %s / %s (%s)\n", $3, $2, $5}'
        echo ""

        # Store size
        echo -e "''${WHITE}📦 Nix Store:''${NC}"
        STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1)
        echo "  Size: $STORE_SIZE"
        echo ""

        # Active builds
        echo -e "''${WHITE}⚙️  Active Builds:''${NC}"
        NIXOS_REBUILD=$(pgrep -f "nixos-rebuild" | wc -l)
        NIX_BUILD=$(pgrep -f "nix-build\|nix build" | wc -l)

        if [ $NIXOS_REBUILD -gt 0 ]; then
            echo -e "  ''${GREEN}●''${NC} nixos-rebuild: $NIXOS_REBUILD process(es)"
        fi
        if [ $NIX_BUILD -gt 0 ]; then
            echo -e "  ''${GREEN}●''${NC} nix build: $NIX_BUILD process(es)"
        fi
        if [ $NIXOS_REBUILD -eq 0 ] && [ $NIX_BUILD -eq 0 ]; then
            echo -e "  ''${GRAY}No active builds''${NC}"
        fi

        sleep "$INTERVAL"
    done
  '';

  # Generations analyzer
  generationsAdvanced = pkgs.writeShellScriptBin "generations" ''
    #!/usr/bin/env bash
    # Advanced Generation Manager

    # Colors
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    GRAY='\033[0;90m'
    NC='\033[0m'

    echo -e "''${CYAN}╔════════════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${CYAN}║''${WHITE}          NixOS System Generations                     ''${CYAN}║''${NC}"
    echo -e "''${CYAN}╚════════════════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # Current generation
    CURRENT=$(readlink /nix/var/nix/profiles/system | sed 's/.*-\([0-9]*\)$/\1/')

    echo -e "''${WHITE}Current Generation: ''${GREEN}#$CURRENT''${NC}"
    echo ""

    # List all generations with details
    echo -e "''${WHITE}All Generations:''${NC}"
    echo -e "''${CYAN}$(printf '─%.0s' {1..60})''${NC}"
    echo ""

    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | while read line; do
        GEN=$(echo "$line" | awk '{print $1}')

        if [ "$GEN" == "$CURRENT" ]; then
            echo -e "''${GREEN}➜ $line (current)''${NC}"
        else
            echo -e "  $line"
        fi
    done

    echo ""
    echo -e "''${CYAN}$(printf '─%.0s' {1..60})''${NC}"

    # Storage usage
    TOTAL_SIZE=$(du -sh /nix/var/nix/profiles/system-* 2>/dev/null | awk '{s+=$1}END{print s}')

    echo ""
    echo -e "''${WHITE}Storage:''${NC}"
    printf "  Total generations size: ''${YELLOW}%s''${NC}\n" "$(du -sh /nix/var/nix/profiles/ 2>/dev/null | cut -f1)"
    echo ""

    echo -e "''${WHITE}Commands:''${NC}"
    echo -e "  ''${CYAN}rollback''${NC}               Rollback to previous generation"
    echo -e "  ''${CYAN}cleanup''${NC}                Remove old generations (>7 days)"
    echo -e "  ''${CYAN}rebuild switch''${NC}         Build new generation"
    echo ""
  '';

in
{
  environment.systemPackages = [
    buildHistory
    buildLogs
    buildMonitor
    generationsAdvanced
  ];

  environment.shellAliases = {
    "build-history" = "build-history";
    "bh" = "build-history";
    "build-logs" = "build-logs";
    "bl" = "build-logs";
    "build-monitor" = "build-monitor";
    "bm" = "build-monitor";
    "generations" = "generations";
    "gens" = "generations";
  };
}
