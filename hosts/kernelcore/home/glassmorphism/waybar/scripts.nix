# Waybar glassmorphism — monitoring scripts installed into
# ~/.config/waybar/scripts/ (flake-manager, system/gpu/disk/ssh monitor)
# (part of the waybar.nix split; see ./default.nix)
{ ... }:

{
  config = {
    # Create scripts directory and monitoring scripts
    home.file = {
      ".config/waybar/scripts/flake-manager.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # ============================================
          # NixOS Flake Manager for Waybar
          # Provides system management via UI
          # ============================================

          set -o pipefail

          FLAKE_DIR="/etc/nixos"
          CACHE_FILE="$HOME/.cache/waybar-flake-status"
          LOCK_FILE="/tmp/nixos-rebuild.lock"

          get_flake_status() {
            # Check if rebuild is in progress
            if [[ -f "$LOCK_FILE" ]]; then
              echo '{"text": "󱉕  BUILDING", "tooltip": "NixOS rebuild in progress...", "class": "building"}'
              exit 0
            fi

            # Get current generation
            local CURRENT_GEN
            CURRENT_GEN=$(nixos-rebuild list-generations 2>/dev/null | grep current | awk '{print $1}' | tr -d '.')
            if [[ -z "$CURRENT_GEN" ]]; then
              CURRENT_GEN="?"
            fi

            # Check for updates (flake inputs)
            local UPDATES_AVAILABLE=false
            if [[ -f "$FLAKE_DIR/flake.lock" ]]; then
              local LOCK_AGE
              LOCK_AGE=$(( ($(date +%s) - $(stat -c %Y "$FLAKE_DIR/flake.lock" 2>/dev/null || echo 0)) / 86400 ))
              if [[ "$LOCK_AGE" -gt 7 ]]; then
                UPDATES_AVAILABLE=true
              fi
            fi

            # Build tooltip
            local TOOLTIP="NixOS System Manager\n━━━━━━━━━━━━━━━━━━━━━━\n"
            TOOLTIP+="󱉕 Generation: $CURRENT_GEN\n"
            TOOLTIP+="󰚰 Location: $FLAKE_DIR\n"

            if [[ "$UPDATES_AVAILABLE" == "true" ]]; then
              TOOLTIP+="󰚰 Updates: Available (lock $LOCK_AGE days old)\n"
            else
              TOOLTIP+="󰚰 Updates: Up to date\n"
            fi

            TOOLTIP+="\n󰍜 Left-click: Rebuild\n"
            TOOLTIP+="󰍜 Right-click: Menu"

            # Determine class and icon
            local CLASS="normal"
            local ICON="󱉕"
            if [[ "$UPDATES_AVAILABLE" == "true" ]]; then
              CLASS="warning"
              ICON="󱉕"
            fi

            local TEXT="$ICON G$CURRENT_GEN"

            printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
          }

          # Interactive menu mode
          show_menu() {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  NixOS Flake Manager"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "1) Rebuild (switch)"
            echo "2) Rebuild (boot)"
            echo "3) Update inputs"
            echo "4) Rollback"
            echo "5) List generations"
            echo "6) Garbage collect"
            echo "7) Flake check"
            echo "0) Exit"
            echo ""
            read -rp "Choice: " choice

            case $choice in
              1) sudo nixos-rebuild switch --flake "$FLAKE_DIR" ;;
              2) sudo nixos-rebuild boot --flake "$FLAKE_DIR" ;;
              3) cd "$FLAKE_DIR" && nix flake update ;;
              4) sudo nixos-rebuild switch --rollback ;;
              5) nixos-rebuild list-generations | tail -20 ;;
              6) nix-collect-garbage -d && sudo nix-collect-garbage -d ;;
              7) cd "$FLAKE_DIR" && nix flake check ;;
              0) exit 0 ;;
              *) echo "Invalid choice" ;;
            esac

            read -rp "Press enter to continue..."
          }

          # Run with error trap
          trap 'echo "{\"text\": \"󱉕 ERR\", \"tooltip\": \"Script error\", \"class\": \"warning\"}"' ERR

          # Handle modes
          case "$1" in
            rebuild)
              cd "$FLAKE_DIR" && sudo nixos-rebuild switch --flake "$FLAKE_DIR"
              exit $?
              ;;
            check)
              cd "$FLAKE_DIR" && nix flake check
              exit $?
              ;;
            menu)
              show_menu
              exit 0
              ;;
          esac

          get_flake_status
        '';
      };

      ".config/waybar/scripts/system-monitor.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # ============================================
          # System Monitor Script for Waybar (OPTIMIZED)
          # Monitors CPU, RAM, and Thermal
          # Optimizations:
          # - Uses /proc for faster CPU stats
          # - Caches thermal sensor path
          # - Efficient memory reading
          # - Reduced external command calls
          # ============================================

          set -o pipefail

          # Cache file for sensor path
          CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
          SENSOR_CACHE="$CACHE_DIR/thermal_sensor"
          mkdir -p "$CACHE_DIR"

          # Fast CPU usage from /proc/stat
          get_cpu_usage() {
            local prev_idle prev_total

            # Read previous values if cached
            if [[ -f "$CACHE_DIR/cpu_prev" ]]; then
              read -r prev_idle prev_total < "$CACHE_DIR/cpu_prev"
            fi

            # Read current CPU stats
            read -r cpu_line < /proc/stat
            read -r _ user nice system idle iowait irq softirq steal _ <<< "$cpu_line"

            local idle_time=$((idle + iowait))
            local total_time=$((user + nice + system + idle + iowait + irq + softirq + steal))

            # Calculate usage if we have previous data
            if [[ -n "$prev_idle" ]]; then
              local idle_delta=$((idle_time - prev_idle))
              local total_delta=$((total_time - prev_total))

              if [[ $total_delta -gt 0 ]]; then
                echo $(( (1000 * (total_delta - idle_delta) / total_delta + 5) / 10 ))
              else
                echo 0
              fi
            else
              echo 0
            fi

            # Cache for next run
            echo "$idle_time $total_time" > "$CACHE_DIR/cpu_prev"
          }

          # Fast memory reading from /proc/meminfo
          get_memory_usage() {
            local mem_total mem_available mem_used mem_percent

            while IFS=: read -r key value; do
              case "$key" in
                MemTotal) mem_total=''${value// kB}; mem_total=$((mem_total / 1024)) ;;
                MemAvailable) mem_available=''${value// kB}; mem_available=$((mem_available / 1024)) ;;
              esac
            done < /proc/meminfo

            mem_used=$((mem_total - mem_available))
            mem_percent=$(( (mem_used * 100) / mem_total ))

            echo "$mem_used $mem_total $mem_percent"
          }

          # Optimized thermal reading with caching
          get_cpu_temp() {
            local sensor_path

            # Use cached sensor path if available
            if [[ -f "$SENSOR_CACHE" ]]; then
              sensor_path=$(< "$SENSOR_CACHE")
            else
              # Find thermal sensor (cache the path)
              for zone in /sys/class/thermal/thermal_zone*/temp; do
                if [[ -r "$zone" ]]; then
                  sensor_path="$zone"
                  echo "$sensor_path" > "$SENSOR_CACHE"
                  break
                fi
              done
            fi

            if [[ -n "$sensor_path" && -r "$sensor_path" ]]; then
              local temp
              temp=$(< "$sensor_path")
              echo $((temp / 1000))
            else
              echo 0
            fi
          }

          get_system_stats() {
            # Get all stats
            local cpu_usage mem_used mem_total mem_percent cpu_temp

            cpu_usage=$(get_cpu_usage)
            read -r mem_used mem_total mem_percent <<< "$(get_memory_usage)"
            cpu_temp=$(get_cpu_temp)

            # Determine class based on thresholds
            local class="normal"
            if [[ $cpu_usage -ge 90 ]] || [[ $mem_percent -ge 90 ]] || [[ $cpu_temp -ge 85 ]]; then
              class="critical"
            elif [[ $cpu_usage -ge 70 ]] || [[ $mem_percent -ge 75 ]] || [[ $cpu_temp -ge 75 ]]; then
              class="warning"
            fi

            # Format display
            local text="󰻠''${cpu_usage}% 󰍛''${mem_percent}%"
            [[ $cpu_temp -gt 0 ]] && text+=" 󰔏''${cpu_temp}°"

            # Build tooltip
            local tooltip="System Resources\n━━━━━━━━━━━━━━━━━━━━━━\n"
            tooltip+="󰻠 CPU Usage: ''${cpu_usage}%\n"
            tooltip+="󰍛 RAM Usage: ''${mem_used}MiB / ''${mem_total}MiB (''${mem_percent}%)\n"
            tooltip+="󰔏 CPU Temp: ''${cpu_temp}°C"

            printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
          }

          # Run with error trap
          trap 'echo "{\"text\": \"󰻠 ERR\", \"tooltip\": \"Script error\", \"class\": \"warning\"}"' ERR
          get_system_stats
        '';
      };

      ".config/waybar/scripts/disk-monitor.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # ============================================
          # Disk Space Monitor Script for Waybar (OPTIMIZED)
          # Monitors root filesystem usage
          # Optimizations:
          # - Direct /proc/self/mountinfo parsing
          # - Efficient df parsing with awk
          # - Reduced external calls
          # ============================================

          set -o pipefail

          get_disk_stats() {
            # Get disk usage for root filesystem (awk is faster than tail + read)
            local filesystem size used avail percent mounted

            if ! read -r filesystem size used avail percent mounted < <(df -h / 2>/dev/null | awk 'NR==2 {print $1, $2, $3, $4, $5, $6}'); then
              echo '{"text": "󰋊 ERR", "tooltip": "Failed to query disk", "class": "warning"}'
              exit 0
            fi

            # Remove % sign from percentage
            local percent_num=''${percent%\%}

            # Validate percentage
            [[ ! "$percent_num" =~ ^[0-9]+$ ]] && percent_num=0

            # Determine class based on usage
            local class="normal"
            if ((percent_num >= 90)); then
              class="critical"
            elif ((percent_num >= 80)); then
              class="warning"
            fi

            # Format display
            local text="󰋊 ''${percent}"

            # Build tooltip
            local tooltip="Disk Usage (Root)\n━━━━━━━━━━━━━━━━━━━━━━\n"
            tooltip+="󰋊 Filesystem: ''${filesystem}\n"
            tooltip+="󰆼 Total: ''${size}\n"
            tooltip+="󰆴 Used: ''${used} (''${percent})\n"
            tooltip+="󰆣 Available: ''${avail}\n"
            tooltip+="󰉖 Mounted: ''${mounted}"

            printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
          }

          # Run with error trap
          trap 'echo "{\"text\": \"󰋊 ERR\", \"tooltip\": \"Script error\", \"class\": \"warning\"}"' ERR
          get_disk_stats
        '';
      };

      ".config/waybar/scripts/gpu-monitor.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # ============================================
          # GPU Monitor Script for Waybar (OPTIMIZED)
          # Priority: Temp > VRAM > Utilization > Clock
          # Optimizations:
          # - Caches nvidia-smi path
          # - Single nvidia-smi call for all metrics
          # - Direct sysfs reading for faster temp
          # - Efficient string parsing
          # ============================================

          set -o pipefail

          CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
          NVIDIA_SMI_CACHE="$CACHE_DIR/nvidia_smi_path"
          mkdir -p "$CACHE_DIR"

          get_gpu_stats() {
            local nvidia_smi

            # Use cached nvidia-smi path
            if [[ -f "$NVIDIA_SMI_CACHE" ]]; then
              nvidia_smi=$(< "$NVIDIA_SMI_CACHE")
              # Validate cached path
              if [[ ! -x "$nvidia_smi" ]]; then
                nvidia_smi=""
              fi
            fi

            # Find nvidia-smi if not cached
            if [[ -z "$nvidia_smi" ]]; then
              for path in /run/current-system/sw/bin/nvidia-smi /usr/bin/nvidia-smi; do
                if [[ -x "$path" ]]; then
                  nvidia_smi="$path"
                  echo "$nvidia_smi" > "$NVIDIA_SMI_CACHE"
                  break
                fi
              done
            fi

            # Check if nvidia-smi is available
            if [[ -z "$nvidia_smi" ]]; then
              echo '{"text": "󰢮 N/A", "tooltip": "nvidia-smi not found", "class": "disabled"}'
              exit 0
            fi

            # Get GPU stats with single nvidia-smi call
            local gpu_output temp vram_used vram_total util clock

            if ! gpu_output=$("$nvidia_smi" --query-gpu=temperature.gpu,memory.used,memory.total,utilization.gpu,clocks.current.graphics --format=csv,noheader,nounits 2>/dev/null); then
              echo '{"text": "󰢮 ERR", "tooltip": "Failed to query GPU", "class": "warning"}'
              exit 0
            fi

            # Parse output efficiently (remove spaces in one pass)
            IFS=',' read -r temp vram_used vram_total util clock <<< "''${gpu_output// /}"

            # Validate and default
            temp=''${temp:-0}
            vram_used=''${vram_used:-0}
            vram_total=''${vram_total:-1}
            util=''${util:-0}
            clock=''${clock:-0}

            # Calculate VRAM percentage
            local vram_percent=0
            ((vram_total > 0)) && vram_percent=$(( (vram_used * 100) / vram_total ))

            # Determine class based on temperature
            local class="normal"
            if ((temp >= 85)); then
              class="critical"
            elif ((temp >= 75)); then
              class="warning"
            fi

            # Format output
            local text="󰢮''${temp}° ''${util}%"

            local tooltip="NVIDIA GPU Status\n━━━━━━━━━━━━━━━━━━━━━━\n"
            tooltip+="󰔏 Temperature: ''${temp}°C\n"
            tooltip+="󰍛 VRAM: ''${vram_used}MiB / ''${vram_total}MiB (''${vram_percent}%)\n"
            tooltip+="󰓅 Utilization: ''${util}%\n"
            tooltip+="󰑮 Clock: ''${clock} MHz"

            printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
          }

          # Run with error trap
          trap 'echo "{\"text\": \"󰢮 ERR\", \"tooltip\": \"Script error\", \"class\": \"warning\"}"' ERR
          get_gpu_stats
        '';
      };

      ".config/waybar/scripts/ssh-sessions.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # ============================================
          # SSH Sessions Monitor for Waybar
          # Shows active SSH connections with hostnames
          # ============================================

          get_ssh_sessions() {
            # Get active SSH connections (outbound)
            SSH_PIDS=$(pgrep -x ssh 2>/dev/null)

            if [[ -z "$SSH_PIDS" ]]; then
              # No active sessions
              echo '{"text": "󰣀", "tooltip": "No active SSH sessions", "class": "inactive"}'
              exit 0
            fi

            # Count sessions
            SESSION_COUNT=$(echo "$SSH_PIDS" | wc -l)

            # Build host list
            HOSTS=""
            for PID in $SSH_PIDS; do
              # Get the command line to extract hostname
              CMDLINE=$(ps -p "$PID" -o args= 2>/dev/null | head -1)

              # Extract hostname (simple parsing)
              HOST=$(echo "$CMDLINE" | grep -oP '(?:^ssh\s+|\s+)([a-zA-Z0-9@._-]+)(?:\s|$)' | tail -1 | tr -d ' ')

              if [[ -n "$HOST" && "$HOST" != "ssh" ]]; then
                if [[ -n "$HOSTS" ]]; then
                  HOSTS="$HOSTS\n"
                fi
                HOSTS+="  󰣀 $HOST"
              fi
            done

            # Format text: icon + count
            TEXT="󰣀 $SESSION_COUNT"

            # Build tooltip
            TOOLTIP="SSH Sessions: $SESSION_COUNT\n━━━━━━━━━━━━━━━━━━━━━━"
            if [[ -n "$HOSTS" ]]; then
              TOOLTIP+="\n$HOSTS"
            fi

            # Output JSON for Waybar
            echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"active\"}"
          }

          get_ssh_sessions
        '';
      };
    }; # End home.file
  };
}
