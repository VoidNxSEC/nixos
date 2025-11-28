{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# NixOS Rebuild - Professional UX
# ============================================================
# Advanced rebuild system with detailed metrics and progress
# Version: 2.0.0 - Professional Edition
# ============================================================

let
  # Advanced rebuild script with detailed UX
  nixosRebuildAdvanced = pkgs.writeShellScriptBin "rebuild" ''
        #!/usr/bin/env bash
        # NixOS Rebuild - Professional Edition
        # Advanced UX with metrics, progress tracking, and detailed reporting

        set -o pipefail

        # ============================================================
        # ANSI Color Codes & Styles
        # ============================================================

        # Colors
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        GRAY='\033[0;90m'
        NC='\033[0m'

        # Styles
        BOLD='\033[1m'
        DIM='\033[2m'
        UNDERLINE='\033[4m'
        BLINK='\033[5m'
        REVERSE='\033[7m'

        # Background colors
        BG_RED='\033[41m'
        BG_GREEN='\033[42m'
        BG_YELLOW='\033[43m'
        BG_BLUE='\033[44m'
        BG_MAGENTA='\033[45m'
        BG_CYAN='\033[46m'

        # Extended colors (256 color palette)
        ORANGE='\033[38;5;208m'
        PURPLE='\033[38;5;141m'
        PINK='\033[38;5;213m'
        TEAL='\033[38;5;51m'
        LIME='\033[38;5;190m'

        # ============================================================
        # Icons & Symbols
        # ============================================================

        ROCKET="🚀"
        CHECK="✅"
        CROSS="❌"
        WARN="⚠️ "
        INFO="ℹ️ "
        GEAR="⚙️ "
        PACKAGE="📦"
        FIRE="🔥"
        STAR="⭐"
        CLOCK="⏱️ "
        CHART="📊"
        CLEAN="🧹"
        LOCK="🔒"
        KEY="🔑"
        SHIELD="🛡️ "
        WRENCH="🔧"
        MAGNIFY="🔍"
        LIGHTNING="⚡"
        DISK="💾"
        MEMORY="🧠"
        CPU="🔬"
        NETWORK="🌐"
        ARROW_RIGHT="→"
        ARROW_UP="↑"
        ARROW_DOWN="↓"
        DOT="•"
        BULLET="▸"

        # Box drawing characters
        BOX_H="─"
        BOX_V="│"
        BOX_TL="╭"
        BOX_TR="╮"
        BOX_BL="╰"
        BOX_BR="╯"
        BOX_VR="├"
        BOX_VL="┤"
        BOX_HU="┴"
        BOX_HD="┬"
        BOX_VH="┼"

        # Progress bar characters
        PROG_FULL="█"
        PROG_EMPTY="░"
        PROG_LEFT="▐"
        PROG_RIGHT="▌"

        # ============================================================
        # Configuration
        # ============================================================

        FLAKE_PATH="/etc/nixos"
        HOST="kernelcore"
        DEFAULT_MAX_JOBS="4"
        DEFAULT_CORES="4"
        LOG_DIR="/var/log/nixos-rebuild"
        METRICS_DIR="$HOME/.cache/nixos-rebuild"

        # Create directories
        mkdir -p "$LOG_DIR" "$METRICS_DIR" 2>/dev/null || true

        # Log file with timestamp
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        LOG_FILE="$LOG_DIR/rebuild_$TIMESTAMP.log"
        METRICS_FILE="$METRICS_DIR/metrics_$TIMESTAMP.json"

        # ============================================================
        # Helper Functions
        # ============================================================

        # Print with color and icon
        print() {
            local color=$1
            local icon=$2
            local msg=$3
            echo -e "''${color}''${icon} ''${msg}''${NC}"
        }

        # Print dimmed text
        print_dim() {
            echo -e "''${DIM}''${GRAY}$1''${NC}"
        }

        # Print section header
        print_section() {
            local title=$1
            local width=60
            echo ""
            echo -e "''${CYAN}''${BOX_TL}$(printf "''${BOX_H}%.0s" $(seq 1 $width))''${BOX_TR}''${NC}"
            echo -e "''${CYAN}''${BOX_V}''${WHITE}''${BOLD} $title''${CYAN}$(printf " %.0s" $(seq 1 $((width - ''${#title} - 2))))''${BOX_V}''${NC}"
            echo -e "''${CYAN}''${BOX_BL}$(printf "''${BOX_H}%.0s" $(seq 1 $width))''${BOX_BR}''${NC}"
        }

        # Print subsection
        print_subsection() {
            local title=$1
            echo ""
            echo -e "''${BLUE}''${BULLET} ''${BOLD}$title''${NC}"
            echo -e "''${BLUE}$(printf "''${BOX_H}%.0s" $(seq 1 40))''${NC}"
        }

        # Print key-value pair
        print_kv() {
            local key=$1
            local value=$2
            local color=''${3:-$WHITE}
            printf "  ''${GRAY}%-20s''${NC} ''${color}%s''${NC}\n" "$key:" "$value"
        }

        # Progress bar
        progress_bar() {
            local current=$1
            local total=$2
            local width=40
            local percentage=$((current * 100 / total))
            local filled=$((width * current / total))
            local empty=$((width - filled))

            printf "\r  ''${CYAN}["
            printf "''${GREEN}%0.s''${PROG_FULL}" $(seq 1 $filled)
            printf "''${GRAY}%0.s''${PROG_EMPTY}" $(seq 1 $empty)
            printf "''${CYAN}]''${NC} ''${WHITE}%3d%%''${NC}" $percentage
        }

        # Spinner animation
        spinner() {
            local pid=$1
            local delay=0.1
            local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
            while ps -p $pid > /dev/null 2>&1; do
                local temp=''${spinstr#?}
                printf " ''${CYAN}%c''${NC} " "$spinstr"
                spinstr=$temp''${spinstr%"$temp"}
                sleep $delay
                printf "\b\b\b\b"
            done
            printf "    \b\b\b\b"
        }

        # Format duration
        format_duration() {
            local seconds=$1
            local minutes=$((seconds / 60))
            local hours=$((minutes / 60))
            local days=$((hours / 24))

            if [ $days -gt 0 ]; then
                echo "''${days}d ''${hours}h ''${minutes}m ''${seconds}s"
            elif [ $hours -gt 0 ]; then
                echo "''${hours}h ''${minutes}m ''${seconds}s"
            elif [ $minutes -gt 0 ]; then
                echo "''${minutes}m ''${seconds}s"
            else
                echo "''${seconds}s"
            fi
        }

        # Format bytes
        format_bytes() {
            local bytes=$1
            if [ $bytes -gt 1073741824 ]; then
                echo "$(echo "scale=2; $bytes / 1073741824" | bc)G"
            elif [ $bytes -gt 1048576 ]; then
                echo "$(echo "scale=2; $bytes / 1048576" | bc)M"
            elif [ $bytes -gt 1024 ]; then
                echo "$(echo "scale=2; $bytes / 1024" | bc)K"
            else
                echo "''${bytes}B"
            fi
        }

        # System metrics
        get_metrics() {
            # CPU
            CPU_CORES=$(nproc)
            CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

            # Memory
            MEM_TOTAL=$(free -b | awk '/^Mem:/ {print $2}')
            MEM_USED=$(free -b | awk '/^Mem:/ {print $3}')
            MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

            # Disk
            DISK_TOTAL=$(df -B1 /nix | awk 'NR==2 {print $2}')
            DISK_USED=$(df -B1 /nix | awk 'NR==2 {print $3}')
            DISK_PERCENT=$(df /nix | awk 'NR==2 {print $5}' | tr -d '%')

            # Store size
            STORE_SIZE=$(du -sb /nix/store 2>/dev/null | cut -f1)
        }

        # Print system metrics
        print_metrics() {
            get_metrics

            print_subsection "System Metrics"

            # CPU
            printf "  ''${CPU}  ''${WHITE}CPU:''${NC}\n"
            print_kv "  Cores" "$CPU_CORES cores" "$GREEN"
            print_kv "  Load Average" "$CPU_LOAD" "$YELLOW"

            # Memory
            printf "\n  ''${MEMORY}  ''${WHITE}Memory:''${NC}\n"
            print_kv "  Total" "$(format_bytes $MEM_TOTAL)" "$CYAN"
            print_kv "  Used" "$(format_bytes $MEM_USED) (''${MEM_PERCENT}%)" "$YELLOW"

            # Disk
            printf "\n  ''${DISK}  ''${WHITE}Disk (/nix):''${NC}\n"
            print_kv "  Total" "$(format_bytes $DISK_TOTAL)" "$CYAN"
            print_kv "  Used" "$(format_bytes $DISK_USED) (''${DISK_PERCENT}%)" "$YELLOW"
            print_kv "  Store Size" "$(format_bytes $STORE_SIZE)" "$MAGENTA"
        }

        # Print build header
        print_header() {
            clear
            echo ""
            echo -e "''${CYAN}╔════════════════════════════════════════════════════════════════╗''${NC}"
            echo -e "''${CYAN}║''${NC}                                                                ''${CYAN}║''${NC}"
            echo -e "''${CYAN}║''${NC}     ''${ROCKET}  ''${WHITE}''${BOLD}NixOS Rebuild''${NC} ''${GRAY}''${DIM}Professional Edition''${NC}            ''${CYAN}║''${NC}"
            echo -e "''${CYAN}║''${NC}                                                                ''${CYAN}║''${NC}"
            echo -e "''${CYAN}╚════════════════════════════════════════════════════════════════╝''${NC}"
            echo ""
            echo -e "  ''${GRAY}''${DIM}Host: ''${WHITE}$HOST''${GRAY} | Timestamp: ''${WHITE}$(date '+%Y-%m-%d %H:%M:%S')''${NC}"
        }

        # Print configuration
        print_config() {
            print_section "Build Configuration"

            print_kv "Flake Path" "$FLAKE_PATH#$HOST" "$CYAN"
            print_kv "Command" "$COMMAND" "$GREEN"
            print_kv "Mode" "$MODE" "$YELLOW"
            print_kv "Max Jobs" "$MAX_JOBS" "$BLUE"
            print_kv "Cores per Job" "$CORES" "$BLUE"
            print_kv "Keep Going" "$KEEP_GOING" "$MAGENTA"

            if [ ''${#EXTRA_ARGS[@]} -gt 0 ]; then
                print_kv "Extra Args" "''${EXTRA_ARGS[*]}" "$PURPLE"
            fi

            print_kv "Log File" "$LOG_FILE" "$GRAY"
            print_kv "Metrics File" "$METRICS_FILE" "$GRAY"
        }

        # Pre-flight checks
        preflight_checks() {
            print_section "Pre-flight Checks"

            local checks=0
            local passed=0

            # Check 1: Flake exists
            ((checks++))
            printf "  ''${MAGNIFY} Checking flake path... "
            if [ -d "$FLAKE_PATH" ]; then
                echo -e "''${GREEN}''${CHECK}''${NC}"
                ((passed++))
            else
                echo -e "''${RED}''${CROSS}''${NC}"
                print "  $RED" "$CROSS" "Flake path not found: $FLAKE_PATH"
                return 1
            fi

            # Check 2: Flake.nix exists
            ((checks++))
            printf "  ''${MAGNIFY} Checking flake.nix... "
            if [ -f "$FLAKE_PATH/flake.nix" ]; then
                echo -e "''${GREEN}''${CHECK}''${NC}"
                ((passed++))
            else
                echo -e "''${RED}''${CROSS}''${NC}"
                return 1
            fi

            # Check 3: Flake lock exists
            ((checks++))
            printf "  ''${MAGNIFY} Checking flake.lock... "
            if [ -f "$FLAKE_PATH/flake.lock" ]; then
                echo -e "''${GREEN}''${CHECK}''${NC}"
                ((passed++))
            else
                echo -e "''${YELLOW}''${WARN}''${NC}"
                print_dim "    No flake.lock found, will be created"
            fi

            # Check 4: Disk space
            ((checks++))
            printf "  ''${DISK} Checking disk space... "
            get_metrics
            if [ $DISK_PERCENT -lt 90 ]; then
                echo -e "''${GREEN}''${CHECK}''${NC} ''${GRAY}(''${DISK_PERCENT}% used)''${NC}"
                ((passed++))
            else
                echo -e "''${YELLOW}''${WARN}''${NC} ''${GRAY}(''${DISK_PERCENT}% used)''${NC}"
                print_dim "    Disk usage high, consider running cleanup"
            fi

            # Check 5: Memory available
            ((checks++))
            printf "  ''${MEMORY} Checking memory... "
            if [ $MEM_PERCENT -lt 80 ]; then
                echo -e "''${GREEN}''${CHECK}''${NC} ''${GRAY}(''${MEM_PERCENT}% used)''${NC}"
                ((passed++))
            else
                echo -e "''${YELLOW}''${WARN}''${NC} ''${GRAY}(''${MEM_PERCENT}% used)''${NC}"
                print_dim "    Memory usage high, consider using safe mode"
            fi

            # Check 6: Root access
            ((checks++))
            printf "  ''${LOCK} Checking root access... "
            if sudo -n true 2>/dev/null; then
                echo -e "''${GREEN}''${CHECK}''${NC}"
                ((passed++))
            else
                echo -e "''${YELLOW}''${WARN}''${NC}"
                print_dim "    Will prompt for sudo password"
            fi

            echo ""
            print_kv "Checks Passed" "$passed/$checks" "$GREEN"

            if [ $passed -eq $checks ]; then
                print "$GREEN" "$STAR" "All checks passed!"
            elif [ $passed -ge $((checks - 1)) ]; then
                print "$YELLOW" "$WARN" "Some checks failed, but can continue"
            else
                print "$RED" "$CROSS" "Critical checks failed, aborting"
                return 1
            fi

            return 0
        }

        # Save metrics to JSON
        save_metrics() {
            local exit_code=$1
            local duration=$2

            cat > "$METRICS_FILE" << EOF
    {
      "timestamp": "$(date -Iseconds)",
      "host": "$HOST",
      "command": "$COMMAND",
      "mode": "$MODE",
      "max_jobs": $MAX_JOBS,
      "cores": $CORES,
      "duration_seconds": $duration,
      "exit_code": $exit_code,
      "system": {
        "cpu_cores": $CPU_CORES,
        "cpu_load": $CPU_LOAD,
        "mem_total": $MEM_TOTAL,
        "mem_used": $MEM_USED,
        "mem_percent": $MEM_PERCENT,
        "disk_total": $DISK_TOTAL,
        "disk_used": $DISK_USED,
        "disk_percent": $DISK_PERCENT,
        "store_size": $STORE_SIZE
      },
      "log_file": "$LOG_FILE"
    }
    EOF
        }

        # Print build summary
        print_summary() {
            local exit_code=$1
            local duration=$2

            print_section "Build Summary"

            if [ $exit_code -eq 0 ]; then
                print "$GREEN" "$CHECK" "Build completed successfully!"
                echo ""
                print_kv "Status" "SUCCESS" "$GREEN"
            else
                print "$RED" "$CROSS" "Build failed with exit code $exit_code"
                echo ""
                print_kv "Status" "FAILED" "$RED"
            fi

            print_kv "Duration" "$(format_duration $duration)" "$CYAN"
            print_kv "Log File" "$LOG_FILE" "$GRAY"
            print_kv "Metrics" "$METRICS_FILE" "$GRAY"

            # Post-build metrics
            get_metrics
            echo ""
            print_subsection "Resource Usage"
            print_kv "CPU Load" "$CPU_LOAD" "$YELLOW"
            print_kv "Memory" "$(format_bytes $MEM_USED) / $(format_bytes $MEM_TOTAL) (''${MEM_PERCENT}%)" "$YELLOW"
            print_kv "Disk" "$(format_bytes $DISK_USED) / $(format_bytes $DISK_TOTAL) (''${DISK_PERCENT}%)" "$YELLOW"

            if [ $exit_code -eq 0 ]; then
                echo ""
                if [ "$COMMAND" == "switch" ]; then
                    print "$TEAL" "$LIGHTNING" "Configuration activated and live!"
                elif [ "$COMMAND" == "boot" ]; then
                    print "$TEAL" "$LIGHTNING" "Configuration will activate on next boot"
                elif [ "$COMMAND" == "test" ]; then
                    print "$TEAL" "$LIGHTNING" "Test configuration activated (not added to bootloader)"
                fi
            else
                echo ""
                print "$YELLOW" "$INFO" "Troubleshooting tips:"
                echo -e "  ''${BULLET} Check log file: ''${WHITE}$LOG_FILE''${NC}"
                echo -e "  ''${BULLET} Run with trace: ''${WHITE}rebuild trace''${NC}"
                echo -e "  ''${BULLET} Try safe mode: ''${WHITE}rebuild switch safe''${NC}"
            fi

            echo ""
        }

        # Show usage
        show_usage() {
            print_header
            print_section "Usage"

            echo -e "  ''${WHITE}''${BOLD}rebuild''${NC} [command] [mode] [options]"
            echo ""

            print_subsection "Commands"
            echo -e "  ''${GREEN}switch''${NC}      Build and activate (default)"
            echo -e "  ''${YELLOW}test''${NC}        Activate without bootloader entry"
            echo -e "  ''${BLUE}boot''${NC}        Add to bootloader, activate on reboot"
            echo -e "  ''${CYAN}check''${NC}       Validate flake only"
            echo -e "  ''${MAGENTA}trace''${NC}       Switch with detailed trace"
            echo ""

            print_subsection "Performance Modes"
            echo -e "  ''${GREEN}balanced''${NC}    --max-jobs 4 --cores 4 (default)"
            echo -e "  ''${YELLOW}safe''${NC}        --max-jobs 1 --cores 4 (low resource)"
            echo -e "  ''${RED}aggressive''${NC}  --max-jobs 6 --cores 2 (fast)"
            echo ""

            print_subsection "Examples"
            echo -e "  ''${GRAY}rebuild''${NC}                    # Switch with balanced mode"
            echo -e "  ''${GRAY}rebuild test''${NC}               # Test without bootloader"
            echo -e "  ''${GRAY}rebuild switch safe''${NC}        # Safe mode rebuild"
            echo -e "  ''${GRAY}rebuild trace''${NC}              # Debug with trace"
            echo ""

            exit 0
        }

        # ============================================================
        # Main Script
        # ============================================================

        # Default values
        COMMAND="switch"
        MODE="balanced"
        MAX_JOBS="$DEFAULT_MAX_JOBS"
        CORES="$DEFAULT_CORES"
        KEEP_GOING="true"
        EXTRA_ARGS=()

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case $1 in
                switch|test|boot)
                    COMMAND=$1
                    shift
                    ;;
                check)
                    COMMAND="check"
                    shift
                    ;;
                trace)
                    COMMAND="switch"
                    EXTRA_ARGS+=("--show-trace")
                    shift
                    ;;
                safe)
                    MODE="safe"
                    MAX_JOBS="1"
                    CORES="4"
                    shift
                    ;;
                balanced)
                    MODE="balanced"
                    MAX_JOBS="4"
                    CORES="4"
                    shift
                    ;;
                aggressive)
                    MODE="aggressive"
                    MAX_JOBS="6"
                    CORES="2"
                    shift
                    ;;
                -h|--help|help)
                    show_usage
                    ;;
                *)
                    EXTRA_ARGS+=("$1")
                    shift
                    ;;
            esac
        done

        # Print header
        print_header

        # Print configuration
        print_config

        # Print system metrics
        print_metrics

        # Check command
        if [ "$COMMAND" == "check" ]; then
            print_section "Flake Check"
            print "$BLUE" "$MAGNIFY" "Validating flake..."
            echo ""

            nix flake check "$FLAKE_PATH" "''${EXTRA_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"
            EXIT_CODE=''${PIPESTATUS[0]}

            echo ""
            if [ $EXIT_CODE -eq 0 ]; then
                print "$GREEN" "$CHECK" "Flake validation passed!"
            else
                print "$RED" "$CROSS" "Flake validation failed!"
            fi

            exit $EXIT_CODE
        fi

        # Pre-flight checks
        if ! preflight_checks; then
            exit 1
        fi

        # Confirmation for destructive commands
        if [ "$COMMAND" == "switch" ] || [ "$COMMAND" == "boot" ]; then
            echo ""
            print "$YELLOW" "$WARN" "This will modify your system configuration."
            printf "  Continue? [Y/n] "
            read -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
                print "$RED" "$CROSS" "Build cancelled by user"
                exit 1
            fi
        fi

        # Start build
        print_section "Building System"

        print "$ROCKET" "$BLUE" "Starting nixos-rebuild..."
        echo ""
        print_dim "  This may take several minutes. Building derivations..."
        echo ""

        # Record start time
        START_TIME=$(date +%s)

        # Build command
        BUILD_CMD="sudo nixos-rebuild $COMMAND \
            --flake $FLAKE_PATH#$HOST \
            --max-jobs $MAX_JOBS \
            --cores $CORES \
            --keep-going \
            ''${EXTRA_ARGS[*]}"

        # Execute build
        echo -e "''${GRAY}''${DIM}$ $BUILD_CMD''${NC}"
        echo ""

        eval "$BUILD_CMD" 2>&1 | tee -a "$LOG_FILE"
        EXIT_CODE=''${PIPESTATUS[0]}

        # Calculate duration
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))

        # Save metrics
        get_metrics
        save_metrics $EXIT_CODE $DURATION

        # Print summary
        print_summary $EXIT_CODE $DURATION

        # Exit with build exit code
        exit $EXIT_CODE
  '';

  # Quick alias
  rebuildQuick = pkgs.writeShellScriptBin "rb" ''
    #!/usr/bin/env bash
    ${nixosRebuildAdvanced}/bin/rebuild "$@"
  '';

in
{
  environment.systemPackages = [
    nixosRebuildAdvanced
    rebuildQuick
  ];

  # Override old rebuild command
  environment.shellAliases = {
    "rebuild" = "rebuild";
    "rb" = "rb";
  };
}
