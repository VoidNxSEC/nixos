# ============================================
# nix-ops: Unified NixOS System Operations Tool
# ============================================
# Replaces 7+ scattered scripts with a single
# writeShellScriptBin package. Commands:
#   status, audit, gc, kill, cooldown, monitor
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.shell.nix-ops;
in
{
  options.kernelcore.shell.nix-ops = {
    enable = mkEnableOption "nix-ops unified system operations tool";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nix-ops" ''
        set -uo pipefail

        # ================================================================
        # COLORS & LOGGING (defined once)
        # ================================================================
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        NC='\033[0m'

        LOG_FILE="/var/log/nix-ops.log"

        log()         { printf "%b[%s]%b %s\n" "$CYAN" "$(date +'%H:%M:%S')" "$NC" "$*" | tee -a "$LOG_FILE" 2>/dev/null; }
        log_ok()      { printf "%b[OK]%b %s\n" "$GREEN" "$NC" "$*" | tee -a "$LOG_FILE" 2>/dev/null; }
        log_warn()    { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$*" | tee -a "$LOG_FILE" 2>/dev/null; }
        log_err()     { printf "%b[ERR]%b %s\n" "$RED" "$NC" "$*" | tee -a "$LOG_FILE" 2>/dev/null; }
        header()      { printf "\n%b%b%s%b\n" "$BOLD" "$CYAN" "$*" "$NC"; }

        # ================================================================
        # THRESHOLDS
        # ================================================================
        TEMP_CRIT=80
        SWAP_CRIT=80
        MEM_CRIT=90

        # ================================================================
        # PROCESS WHITELIST (never kill these)
        # ================================================================
        WHITELIST="systemd|dbus|Xorg|Xwayland|gdm|sddm|sshd|NetworkManager|nix-daemon|pipewire|wireplumber|hyprland|waybar"

        # ================================================================
        # DIAGNOSTICS
        # ================================================================
        get_cpu_temp() {
          local t=0
          if command -v sensors &>/dev/null; then
            t=$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | tr -d '+°C' | cut -d'.' -f1 || echo 0)
          fi
          if [[ $t -eq 0 ]] && [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
            t=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
          fi
          echo "$t"
        }

        get_mem_pct()  { free | awk '/Mem/  {printf "%.0f", ($3/$2)*100}'; }
        get_swap_pct() { free | awk '/Swap/ {if($2==0) print 0; else printf "%.0f", ($3/$2)*100}'; }
        get_load()     { awk '{print $1}' /proc/loadavg; }

        temp_color() {
          local t=$1
          if   [[ $t -gt $TEMP_CRIT ]]; then printf "%b" "$RED"
          elif [[ $t -gt 65 ]];          then printf "%b" "$YELLOW"
          else                                 printf "%b" "$GREEN"
          fi
        }

        pct_color() {
          local p=$1 thresh=$2
          if   [[ $p -gt $thresh ]]; then printf "%b" "$RED"
          elif [[ $p -gt $((thresh - 15)) ]]; then printf "%b" "$YELLOW"
          else                                      printf "%b" "$GREEN"
          fi
        }

        disk_summary() {
          df -h / | awk 'NR==2 {printf "  Used: %s / %s (%s) Free: %s\n", $3, $2, $5, $4}'
        }

        # ================================================================
        # CMD: status
        # ================================================================
        cmd_status() {
          local temp=$(get_cpu_temp)
          local mem=$(get_mem_pct)
          local swap=$(get_swap_pct)
          local load=$(get_load)
          local tc=$(temp_color "$temp")
          local mc=$(pct_color "$mem" "$MEM_CRIT")
          local sc=$(pct_color "$swap" "$SWAP_CRIT")

          printf "%b%b" "$BOLD" "$CYAN"
          echo "+---------------------------------------------------------+"
          echo "|              nix-ops status                             |"
          echo "+---------------------------------------------------------+"
          printf "%b" "$NC"
          echo ""

          printf "  %bCPU:%b  Load %-6s Temp %b%s°C%b\n" "$CYAN" "$NC" "$load" "$tc" "$temp" "$NC"
          printf "  %bRAM:%b  %b%s%%%b used\n" "$CYAN" "$NC" "$mc" "$mem" "$NC"
          printf "  %bSWAP:%b %b%s%%%b used\n" "$CYAN" "$NC" "$sc" "$swap" "$NC"
          echo ""

          # Disk
          printf "  %bDisk:%b\n" "$CYAN" "$NC"
          disk_summary
          echo ""

          # Nix builds
          local nix_builds=$(pgrep -fc "nix.*build\|nix.*flake\|nixos-rebuild" 2>/dev/null || echo 0)
          local nixbld=$(pgrep -c nixbld 2>/dev/null || echo 0)
          printf "  %bNix:%b  %s build cmds, %s nixbld workers\n" "$CYAN" "$NC" "$nix_builds" "$nixbld"

          # Generations
          local gens=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l || echo "?")
          local gc_roots=$(nix-store --gc --print-roots 2>/dev/null | grep -vc '/proc/' || echo "?")
          printf "  %bStore:%b %s generations, %s gc roots\n" "$CYAN" "$NC" "$gens" "$gc_roots"
          echo ""

          # Alerts
          local issues=0
          if [[ $temp -gt $TEMP_CRIT ]]; then
            printf "  %b!! OVERHEAT%b (%s°C)\n" "$RED" "$NC" "$temp"
            issues=$((issues + 1))
          fi
          if [[ $mem -gt $MEM_CRIT ]]; then
            printf "  %b!! RAM CRITICAL%b (%s%%)\n" "$RED" "$NC" "$mem"
            issues=$((issues + 1))
          fi
          if [[ $swap -gt $SWAP_CRIT ]]; then
            printf "  %b!! SWAP CRITICAL%b (%s%%)\n" "$RED" "$NC" "$swap"
            issues=$((issues + 1))
          fi
          if [[ $issues -eq 0 ]]; then
            printf "  %bSystem healthy%b\n" "$GREEN" "$NC"
          fi
        }

        # ================================================================
        # CMD: audit
        # ================================================================
        cmd_audit() {
          header "nix-ops audit - Full Disk Breakdown"
          echo ""

          # General
          printf "%b1. Filesystem%b\n" "$BOLD" "$NC"
          df -h / /nix /home /var 2>/dev/null | sort -u
          echo ""

          # /nix breakdown
          printf "%b2. /nix Breakdown%b\n" "$BOLD" "$NC"
          sudo du -sh /nix 2>/dev/null
          sudo du -sh /nix/* 2>/dev/null | sort -rh
          echo ""

          # /nix/store stats
          printf "%b3. Nix Store (top 15 packages)%b\n" "$BOLD" "$NC"
          local store_count=$(ls /nix/store 2>/dev/null | wc -l)
          printf "  Items: %s\n" "$store_count"
          sudo du -sh /nix/store/* 2>/dev/null | sort -rh | head -15
          echo ""

          # /home
          printf "%b4. Home Directory (top 15)%b\n" "$BOLD" "$NC"
          du -sh ~/* 2>/dev/null | sort -rh | head -15
          echo ""

          # /var
          printf "%b5. /var (top 10)%b\n" "$BOLD" "$NC"
          sudo du -sh /var/* 2>/dev/null | sort -rh | head -10
          echo ""

          # Large logs
          printf "%b6. Large Log Files (>10MB)%b\n" "$BOLD" "$NC"
          sudo find /var/log -type f -size +10M -exec ls -lh {} \; 2>/dev/null || echo "  None"
          echo ""

          # User caches
          printf "%b7. User Caches%b\n" "$BOLD" "$NC"
          if [[ -d ~/.cache ]]; then
            du -sh ~/.cache 2>/dev/null
            du -sh ~/.cache/* 2>/dev/null | sort -rh | head -10
          fi
          echo ""

          # Build caches
          printf "%b8. Build Caches%b\n" "$BOLD" "$NC"
          for d in ~/.cargo ~/.npm ~/go ~/.cache/pip ~/.direnv; do
            if [[ -d "$d" ]]; then
              printf "  %-20s %s\n" "$d" "$(du -sh "$d" 2>/dev/null | cut -f1)"
            fi
          done
          echo ""

          # Docker
          printf "%b9. Docker%b\n" "$BOLD" "$NC"
          if command -v docker &>/dev/null && sudo systemctl is-active docker &>/dev/null; then
            sudo docker system df 2>/dev/null || echo "  Unavailable"
          else
            echo "  Docker not running"
          fi
          echo ""

          # Generations & GC roots
          printf "%b10. System Generations%b\n" "$BOLD" "$NC"
          sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | tail -10
          echo ""

          printf "%b11. GC Roots (non-proc, top 15)%b\n" "$BOLD" "$NC"
          local roots_count=$(nix-store --gc --print-roots 2>/dev/null | grep -vc '/proc/' || echo 0)
          printf "  Total: %s\n" "$roots_count"
          nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | head -15
          echo ""

          # Large files
          printf "%b12. Largest Files >500MB (top 20)%b\n" "$BOLD" "$NC"
          sudo find /home /var /tmp -type f -size +500M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh | head -20 || echo "  None"
          echo ""
        }

        # ================================================================
        # CMD: gc
        # ================================================================
        cmd_gc() {
          local aggressive=false
          local dry_run=false
          local yes_flag=false

          for arg in "$@"; do
            case "$arg" in
              --aggressive) aggressive=true ;;
              --dry-run)    dry_run=true ;;
              --yes|-y)     yes_flag=true ;;
            esac
          done

          header "nix-ops gc"

          if $dry_run; then
            printf "%b[DRY RUN] Showing what would be cleaned%b\n\n" "$YELLOW" "$NC"

            printf "%bDisk before:%b\n" "$BOLD" "$NC"
            disk_summary
            echo ""

            printf "%bGenerations:%b\n" "$BOLD" "$NC"
            local gen_count=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l)
            printf "  %s system generations (all old would be removed)\n" "$gen_count"

            local user_gen_count=$(nix-env --list-generations 2>/dev/null | wc -l)
            printf "  %s user generations (all old would be removed)\n" "$user_gen_count"
            echo ""

            printf "%bStore GC estimate:%b\n" "$BOLD" "$NC"
            local gc_estimate=$(nix-store --gc --print-dead 2>/dev/null | wc -l || echo "?")
            printf "  ~%s dead store paths would be removed\n" "$gc_estimate"
            echo ""

            if $aggressive; then
              printf "%bBuild caches (--aggressive):%b\n" "$BOLD" "$NC"
              for d in ~/.cargo/registry ~/.cargo/git ~/.npm ~/go/pkg/mod/cache ~/.cache/pip ~/.direnv; do
                if [[ -d "$d" ]]; then
                  printf "  Would clean: %-40s %s\n" "$d" "$(du -sh "$d" 2>/dev/null | cut -f1)"
                fi
              done
              echo ""
              printf "%bLogs:%b\n" "$BOLD" "$NC"
              local audit_size=$(sudo du -sh /var/log/audit 2>/dev/null | cut -f1 || echo "0")
              printf "  Audit logs: %s (would truncate)\n" "$audit_size"
              printf "  Journal: would vacuum to 3d/500M\n"
              echo ""
              if command -v docker &>/dev/null && sudo systemctl is-active docker &>/dev/null; then
                printf "%bDocker:%b would prune unused images/volumes\n" "$BOLD" "$NC"
              fi
            fi
            return 0
          fi

          # Actual GC
          printf "%bDisk before:%b\n" "$BOLD" "$NC"
          disk_summary
          echo ""

          # Phase 1: Delete old generations
          log "Phase 1: Deleting old generations..."
          sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system 2>/dev/null || true
          nix-env --delete-generations old 2>/dev/null || true
          log_ok "Old generations deleted"

          # Phase 2: GC
          log "Phase 2: Garbage collection (may take several minutes)..."
          nix-collect-garbage -d 2>/dev/null || true
          sudo nix-collect-garbage -d 2>/dev/null || true
          log_ok "Garbage collection done"

          # Phase 3: Optimise store
          log "Phase 3: Optimising store (deduplication)..."
          sudo nix-store --optimise 2>/dev/null || true
          log_ok "Store optimised"

          # Phase 4: Clean result symlinks
          rm -f ~/result* /tmp/result* /etc/nixos/result* 2>/dev/null || true

          if $aggressive; then
            echo ""
            log "Phase 4: Aggressive cleanup..."

            # Build caches
            log "  Cleaning cargo cache..."
            rm -rf ~/.cargo/registry/cache/* ~/.cargo/registry/index/* ~/.cargo/git/db/* 2>/dev/null || true

            log "  Cleaning npm cache..."
            ${pkgs.nodejs}/bin/npm cache clean --force 2>/dev/null || true

            log "  Cleaning Go cache..."
            rm -rf ~/go/pkg/mod/cache/* 2>/dev/null || true

            log "  Cleaning pip cache..."
            rm -rf ~/.cache/pip/* 2>/dev/null || true

            log "  Cleaning direnv cache..."
            rm -rf ~/.direnv/* 2>/dev/null || true

            # Logs
            log "  Cleaning audit logs..."
            sudo systemctl stop auditd 2>/dev/null || true
            sudo find /var/log/audit -name "audit.log.*" -delete 2>/dev/null || true
            sudo truncate -s 0 /var/log/audit/audit.log 2>/dev/null || true
            sudo systemctl start auditd 2>/dev/null || true

            log "  Vacuuming journal..."
            sudo journalctl --vacuum-time=3d --vacuum-size=500M 2>/dev/null || true

            log "  Cleaning old log files..."
            sudo find /var/log -name "*.log.*" -delete 2>/dev/null || true
            sudo find /var/log -name "*.gz" -delete 2>/dev/null || true
            sudo find /var/log -name "*.old" -delete 2>/dev/null || true

            # Temps
            log "  Cleaning temp files..."
            sudo find /tmp -type f -atime +1 -delete 2>/dev/null || true
            sudo find /var/tmp -type f -atime +1 -delete 2>/dev/null || true

            # Docker
            if command -v docker &>/dev/null && sudo systemctl is-active docker &>/dev/null; then
              log "  Pruning Docker..."
              docker system prune -f --volumes 2>/dev/null || true
            fi

            log_ok "Aggressive cleanup done"
          fi

          echo ""
          printf "%bDisk after:%b\n" "$BOLD" "$NC"
          disk_summary
        }

        # ================================================================
        # CMD: kill
        # ================================================================
        cmd_kill() {
          local heavy=false
          for arg in "$@"; do
            case "$arg" in
              --heavy) heavy=true ;;
            esac
          done

          header "nix-ops kill"
          local killed=0

          # Kill nix build commands
          for pattern in "nix flake check" "nix flake build" "nix build" "nixos-rebuild"; do
            if pgrep -f "$pattern" &>/dev/null; then
              pkill -9 -f "$pattern" 2>/dev/null && killed=$((killed + 1))
              log_ok "Killed: $pattern"
            fi
          done

          # Kill nixbld workers
          if pgrep nixbld &>/dev/null; then
            killall -9 nixbld 2>/dev/null && killed=$((killed + 1))
            log_ok "Killed nixbld workers"
          fi

          # Kill compilers
          for proc in cc1plus cc1 cudafe cicc nvcc ninja cmake g++ gcc clang rustc cargo; do
            if pgrep "$proc" &>/dev/null; then
              killall -9 "$proc" 2>/dev/null && killed=$((killed + 1))
            fi
          done
          if [[ $killed -gt 0 ]]; then
            log_ok "Killed compilers"
          fi

          # Kill npm/node builds
          if pgrep -f "npm.*build" &>/dev/null; then
            pkill -9 -f "npm.*build" 2>/dev/null && killed=$((killed + 1))
            log_ok "Killed npm builds"
          fi

          if $heavy; then
            echo ""
            log "Killing heavy processes (whitelist protected)..."

            # Get top memory consumers
            local pids
            pids=$(ps aux --sort=-%mem | awk 'NR>1 && NR<=15 {print $2}')
            for pid in $pids; do
              local pname
              pname=$(ps -p "$pid" -o comm= 2>/dev/null || continue)

              # Check whitelist
              if echo "$pname" | grep -qE "$WHITELIST"; then
                continue
              fi

              if kill -9 "$pid" 2>/dev/null; then
                log_ok "Killed: $pname (PID $pid)"
                killed=$((killed + 1))
              fi
            done
          fi

          # Clean zombies
          local zombie_pids
          zombie_pids=$(ps -ef | awk '$8 == "Z" {print $2}')
          if [[ -n "$zombie_pids" ]]; then
            local cleaned=0
            for pid in $zombie_pids; do
              local ppid
              ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
              if [[ -n "$ppid" ]] && ps -p "$ppid" &>/dev/null; then
                kill -s SIGCHLD "$ppid" 2>/dev/null && cleaned=$((cleaned + 1))
              fi
            done
            [[ $cleaned -gt 0 ]] && log_ok "Cleaned $cleaned zombie(s)"
          fi

          echo ""
          log_ok "Done. $killed processes killed."
        }

        # ================================================================
        # CMD: cooldown
        # ================================================================
        cmd_cooldown() {
          header "nix-ops cooldown"

          # Kill builds first
          log "Killing active builds..."
          cmd_kill "$@" 2>/dev/null

          # Set powersave
          if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              echo "powersave" | tee "$cpu" > /dev/null 2>&1
            done
            log_ok "CPU governor: powersave"
          else
            log_warn "cpufreq not available"
          fi

          # Drop caches
          sync
          echo 3 | tee /proc/sys/vm/drop_caches > /dev/null 2>&1 && log_ok "Page cache dropped"

          # Check if swap needs clearing
          local swap_pct=$(get_swap_pct)
          if [[ $swap_pct -gt 0 ]] && [[ $swap_pct -lt 50 ]]; then
            swapoff -a 2>/dev/null && swapon -a 2>/dev/null && log_ok "Swap recycled"
          elif [[ $swap_pct -ge 50 ]]; then
            log_warn "Swap at ''${swap_pct}%%, too full to recycle safely"
          fi

          echo ""
          local temp=$(get_cpu_temp)
          printf "  Temperature: %b%s°C%b\n" "$(temp_color "$temp")" "$temp" "$NC"
          log "Waiting 10s for cooldown..."
          sleep 10

          temp=$(get_cpu_temp)
          printf "  Temperature: %b%s°C%b\n" "$(temp_color "$temp")" "$temp" "$NC"
          log_ok "Cooldown complete"
        }

        # ================================================================
        # CMD: monitor
        # ================================================================
        cmd_monitor() {
          header "nix-ops monitor (Ctrl+C to stop)"
          echo ""

          while true; do
            clear
            cmd_status

            # Auto-intervene on critical conditions
            local swap=$(get_swap_pct)
            local temp=$(get_cpu_temp)

            if [[ $swap -gt 90 ]]; then
              echo ""
              log_err "SWAP CRITICAL ($swap%%) - auto-intervening..."
              cmd_kill 2>/dev/null
              sync
              echo 3 | tee /proc/sys/vm/drop_caches > /dev/null 2>&1
              if [[ $swap -lt 50 ]]; then
                swapoff -a 2>/dev/null && swapon -a 2>/dev/null
              fi
            fi

            if [[ $temp -gt 90 ]]; then
              echo ""
              log_err "OVERHEAT ($temp°C) - auto-cooldown..."
              cmd_kill 2>/dev/null
              if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
                for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                  echo "powersave" | tee "$cpu" > /dev/null 2>&1
                done
              fi
            fi

            echo ""
            printf "%b  Next refresh in 5s...%b\n" "$CYAN" "$NC"
            sleep 5
          done
        }

        # ================================================================
        # HELP
        # ================================================================
        show_help() {
          printf "%b%b" "$BOLD" "$CYAN"
          echo "+---------------------------------------------------------+"
          echo "|  nix-ops - Unified NixOS System Operations              |"
          echo "+---------------------------------------------------------+"
          printf "%b\n" "$NC"

          printf "%bCOMMANDS:%b\n" "$BOLD" "$NC"
          printf "  %-28s %s\n" "status"              "Quick system health (cpu, mem, swap, disk, nix)"
          printf "  %-28s %s\n" "audit"               "Full disk audit with breakdown"
          printf "  %-28s %s\n" "gc [--aggressive] [--dry-run]" "Nix GC (generations + store + optimise)"
          printf "  %-28s %s\n" "kill [--heavy]"       "Kill nix builds + compilers"
          printf "  %-28s %s\n" "cooldown"             "Kill builds + powersave + drop caches"
          printf "  %-28s %s\n" "monitor"              "Live monitor with auto-intervention"
          echo ""

          printf "%bFLAGS:%b\n" "$BOLD" "$NC"
          printf "  %-28s %s\n" "--aggressive"  "gc: also clean cargo/npm/pip/go caches, logs, docker"
          printf "  %-28s %s\n" "--dry-run"     "gc: show what would be cleaned without doing it"
          printf "  %-28s %s\n" "--heavy"       "kill: also kill top memory consumers (whitelist protected)"
          echo ""

          printf "%bEXAMPLES:%b\n" "$BOLD" "$NC"
          echo "  nix-ops status              # check system health"
          echo "  nix-ops gc --dry-run        # preview what gc would clean"
          echo "  sudo nix-ops gc             # standard gc"
          echo "  sudo nix-ops gc --aggressive # deep clean everything"
          echo "  sudo nix-ops kill           # kill nix builds"
          echo "  sudo nix-ops kill --heavy   # kill builds + heavy processes"
          echo "  sudo nix-ops cooldown       # emergency cpu cooldown"
          echo "  sudo nix-ops monitor        # live dashboard"
          echo ""

          printf "%bALIASES:%b\n" "$BOLD" "$NC"
          echo "  nops            = nix-ops"
          echo "  nops-status     = nix-ops status"
          echo "  nops-gc         = sudo nix-ops gc"
          echo "  nops-kill       = sudo nix-ops kill"
          echo "  nops-audit      = sudo nix-ops audit"
          echo ""
        }

        # ================================================================
        # MAIN
        # ================================================================
        touch "$LOG_FILE" 2>/dev/null || true

        if [[ $# -eq 0 ]]; then
          show_help
          exit 0
        fi

        CMD="$1"
        shift

        case "$CMD" in
          status)    cmd_status ;;
          audit)     cmd_audit ;;
          gc)        cmd_gc "$@" ;;
          kill)      cmd_kill "$@" ;;
          cooldown)  cmd_cooldown "$@" ;;
          monitor)   cmd_monitor ;;
          help|--help|-h) show_help ;;
          *)
            log_err "Unknown command: $CMD"
            echo ""
            show_help
            exit 1
            ;;
        esac
      '')
    ];

    environment.shellAliases = {
      nops = "nix-ops";
      nops-status = "nix-ops status";
      nops-gc = "sudo nix-ops gc";
      nops-kill = "sudo nix-ops kill";
      nops-audit = "sudo nix-ops audit";
    };
  };
}
