# ============================================
# Waybar - Glassmorphism Status Bar
# ============================================
# Premium frosted glass status bar with:
# - Pill-shaped module containers
# - SSH connection indicator with hostname tooltip
# - GPU metrics (Temp > VRAM > Util > Clock)
# - Animated hover states with glow
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Script paths
  gpuMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/gpu-monitor.sh";
  sshSessions = "${config.home.homeDirectory}/.config/waybar/scripts/ssh-sessions.sh";
in
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 42;
        spacing = 8;
        margin-top = 8;
        margin-left = 16;
        margin-right = 16;
        margin-bottom = 0;

        # Module layout
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "custom/gpu"
          "custom/ssh"
          "network"
          "bluetooth"
          "pulseaudio"
          "battery"
          "custom/agent-hub"
          "tray"
        ];

        # ============================================
        # LEFT MODULES
        # ============================================
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰲠";
            "2" = "󰲢";
            "3" = "󰲤";
            "4" = "󰲦";
            "5" = "󰲨";
            "6" = "󰲪";
            "7" = "󰲬";
            "8" = "󰲮";
            "9" = "󰲰";
            "10" = "󰿬";
            urgent = "󰀨";
            active = "󰮯";
            default = "󰊠";
          };
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          all-outputs = false;
          active-only = false;
          show-special = true;
          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          format = "{class}";
          max-length = 40;
          separate-outputs = true;
          rewrite = {
            # Terminal emulators
            "Alacritty" = "󰆍 Alacritty";
            "kitty" = "󰄛 Kitty";
            "org.wezfurlong.wezterm" = "󰆍 WezTerm";
            "foot" = "󰆍 Foot";
            
            # Browsers
            "firefox" = "󰈹 Firefox";
            "brave-browser" = "󰖟 Brave";
            "chromium-browser" = " Chromium";
            "code-oss" = "󰨞 VSCode";
            "VSCodium" = "󰨞 VSCodium";
            "codium" = "󰨞 VSCodium";
            "nemo" = "󰉋 Files";
            "discord" = "󰙯 Discord";
            "obsidian" = "󰠮 Obsidian";
            "spotify" = "󰓇 Spotify";
            "" = "󰇄 Desktop";
          };
        };

        # ============================================
        # CENTER MODULES
        # ============================================
        "clock" = {
          format = "󰥔 {:%H:%M}";
          format-alt = "󰃭 {:%A, %B %d, %Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#00d4ff'><b>{}</b></span>";
              days = "<span color='#e4e4e7'>{}</span>";
              weeks = "<span color='#7c3aed'><b>W{}</b></span>";
              weekdays = "<span color='#a1a1aa'>{}</span>";
              today = "<span color='#ff00aa'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        # ============================================
        # RIGHT MODULES
        # ============================================

        # GPU Monitor - Temp > VRAM > Util > Clock
        "custom/gpu" = {
          exec = gpuMonitor;
          return-type = "json";
          interval = 3;
          format = "{}";
          tooltip = true;
          on-click = "nvidia-settings";
        };

        # SSH Sessions Indicator
        "custom/ssh" = {
          exec = sshSessions;
          return-type = "json";
          interval = 5;
          format = "{}";
          tooltip = true;
          on-click = "alacritty -e htop -p $(pgrep -d, ssh)";
        };

        "network" = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {ipaddr}";
          format-linked = "󰈀 {ifname}";
          format-disconnected = "󰤭";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format = "󰩟 {ifname}\n󰩠 {ipaddr}/{cidr}\n󰁝 {bandwidthUpBytes}\n󰁅 {bandwidthDownBytes}";
          on-click-right = "nm-connection-editor";
        };

        "bluetooth" = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-connected = "󰂱 {num_connections}";
          format-connected-battery = "󰂱 {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "󰂰 {volume}%";
          format-bluetooth-muted = "󰂲";
          format-muted = "󰝟";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
        };

        "battery" = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          tooltip-format = "{timeTo}\n{capacity}% - {health}% health";
        };

        # Agent Hub Placeholder
        "custom/agent-hub" = {
          format = "󰚩";
          tooltip = true;
          tooltip-format = "AI Agent Hub\nClick to launch agent selector";
          on-click = "notify-send 'Agent Hub' 'Coming soon: AI agent integration'";
        };

        "tray" = {
          icon-size = 18;
          spacing = 8;
          show-passive-items = true;
        };
      };
    };

    # ============================================
    # GLASSMORPHISM CSS STYLES
    # ============================================
    style = ''
      /* ============================================
       * Waybar - Glassmorphism Theme
       * Premium frosted glass with electric accents
       * ============================================ */

      /* Reset and base styles */
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", monospace;
        font-size: 13px;
        min-height: 0;
        margin: 0;
        padding: 0;
      }

      /* Main bar - frosted glass background */
      window#waybar {
        background: rgba(10, 10, 15, 0.75);
        border-radius: 16px;
        border: 1px solid rgba(255, 255, 255, 0.1);
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4),
                    0 0 40px rgba(0, 212, 255, 0.05);
      }

      window#waybar.hidden {
        opacity: 0;
      }

      /* Tooltip styling */
      tooltip {
        background: rgba(18, 18, 26, 0.95);
        border: 1px solid rgba(0, 212, 255, 0.3);
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5),
                    0 0 20px rgba(0, 212, 255, 0.1);
      }

      tooltip label {
        color: #e4e4e7;
        padding: 8px 12px;
      }

      /* Module base styles */
      #workspaces,
      #window,
      #clock,
      #custom-gpu,
      #custom-ssh,
      #network,
      #bluetooth,
      #pulseaudio,
      #battery,
      #custom-agent-hub,
      #tray {
        background: rgba(18, 18, 26, 0.8);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 20px;
        padding: 4px 16px;
        margin: 4px 4px;
        color: #e4e4e7;
        transition: all 0.3s ease;
      }

      /* Hover effects - cyan glow */
      #workspaces:hover,
      #window:hover,
      #clock:hover,
      #custom-gpu:hover,
      #custom-ssh:hover,
      #network:hover,
      #bluetooth:hover,
      #pulseaudio:hover,
      #battery:hover,
      #custom-agent-hub:hover,
      #tray:hover {
        background: rgba(0, 212, 255, 0.15);
        border-color: rgba(0, 212, 255, 0.4);
        box-shadow: 0 0 20px rgba(0, 212, 255, 0.2);
      }

      /* ============================================
       * WORKSPACES
       * ============================================ */
      #workspaces {
        padding: 2px 8px;
      }

      #workspaces button {
        background: transparent;
        color: #71717a;
        padding: 4px 8px;
        margin: 2px;
        border-radius: 12px;
        transition: all 0.3s ease;
      }

      #workspaces button:hover {
        background: rgba(0, 212, 255, 0.2);
        color: #00d4ff;
      }

      #workspaces button.active {
        background: linear-gradient(135deg, rgba(0, 212, 255, 0.3), rgba(124, 58, 237, 0.3));
        color: #00d4ff;
        border: 1px solid rgba(0, 212, 255, 0.5);
        box-shadow: 0 0 15px rgba(0, 212, 255, 0.3);
      }

      #workspaces button.urgent {
        background: rgba(255, 0, 170, 0.3);
        color: #ff00aa;
        border: 1px solid rgba(255, 0, 170, 0.5);
        animation: pulse 1s infinite;
      }

      @keyframes pulse {
        0%, 100% { box-shadow: 0 0 10px rgba(255, 0, 170, 0.3); }
        50% { box-shadow: 0 0 20px rgba(255, 0, 170, 0.5); }
      }

      /* ============================================
       * WINDOW TITLE
       * ============================================ */
      #window {
        color: #a1a1aa;
        font-weight: 500;
      }

      window#waybar.empty #window {
        background: transparent;
        border: none;
        padding: 0;
        margin: 0;
      }

      /* ============================================
       * CLOCK
       * ============================================ */
      #clock {
        background: linear-gradient(135deg, rgba(18, 18, 26, 0.9), rgba(26, 26, 36, 0.8));
        color: #ffffff;
        font-weight: 600;
        font-size: 14px;
        padding: 4px 20px;
        border: 1px solid rgba(0, 212, 255, 0.2);
      }

      #clock:hover {
        border-color: rgba(0, 212, 255, 0.5);
        box-shadow: 0 0 25px rgba(0, 212, 255, 0.25);
      }

      /* ============================================
       * GPU MODULE
       * ============================================ */
      #custom-gpu {
        background: linear-gradient(135deg, rgba(34, 197, 94, 0.15), rgba(18, 18, 26, 0.8));
        border-color: rgba(34, 197, 94, 0.2);
      }

      #custom-gpu.warning {
        background: linear-gradient(135deg, rgba(234, 179, 8, 0.2), rgba(18, 18, 26, 0.8));
        border-color: rgba(234, 179, 8, 0.4);
        color: #eab308;
      }

      #custom-gpu.critical {
        background: linear-gradient(135deg, rgba(255, 0, 170, 0.2), rgba(18, 18, 26, 0.8));
        border-color: rgba(255, 0, 170, 0.4);
        color: #ff00aa;
        animation: pulse 1s infinite;
      }

      #custom-gpu:hover {
        background: linear-gradient(135deg, rgba(34, 197, 94, 0.25), rgba(0, 212, 255, 0.15));
        border-color: rgba(0, 212, 255, 0.4);
      }

      /* ============================================
       * SSH INDICATOR
       * ============================================ */
      #custom-ssh {
        background: rgba(18, 18, 26, 0.8);
        color: #71717a;
      }

      #custom-ssh.active {
        background: linear-gradient(135deg, rgba(0, 212, 255, 0.2), rgba(124, 58, 237, 0.15));
        border-color: rgba(0, 212, 255, 0.4);
        color: #00d4ff;
      }

      #custom-ssh.active:hover {
        box-shadow: 0 0 20px rgba(0, 212, 255, 0.3);
      }

      /* ============================================
       * NETWORK
       * ============================================ */
      #network {
        color: #22c55e;
      }

      #network.disconnected {
        color: #ef4444;
        background: rgba(239, 68, 68, 0.1);
        border-color: rgba(239, 68, 68, 0.3);
      }

      #network.wifi {
        color: #00d4ff;
      }

      /* ============================================
       * BLUETOOTH
       * ============================================ */
      #bluetooth {
        color: #3b82f6;
      }

      #bluetooth.disabled {
        color: #71717a;
      }

      #bluetooth.connected {
        color: #00d4ff;
      }

      /* ============================================
       * AUDIO
       * ============================================ */
      #pulseaudio {
        color: #7c3aed;
      }

      #pulseaudio.muted {
        color: #71717a;
        background: rgba(113, 113, 122, 0.1);
      }

      /* ============================================
       * BATTERY
       * ============================================ */
      #battery {
        color: #22c55e;
      }

      #battery.charging {
        color: #00d4ff;
        background: rgba(0, 212, 255, 0.1);
        border-color: rgba(0, 212, 255, 0.3);
      }

      #battery.warning:not(.charging) {
        color: #eab308;
        background: rgba(234, 179, 8, 0.1);
        border-color: rgba(234, 179, 8, 0.3);
      }

      #battery.critical:not(.charging) {
        color: #ff00aa;
        background: rgba(255, 0, 170, 0.15);
        border-color: rgba(255, 0, 170, 0.4);
        animation: pulse 1s infinite;
      }

      /* ============================================
       * AGENT HUB
       * ============================================ */
      #custom-agent-hub {
        background: linear-gradient(135deg, rgba(124, 58, 237, 0.2), rgba(255, 0, 170, 0.1));
        border-color: rgba(124, 58, 237, 0.3);
        color: #7c3aed;
        font-size: 16px;
        padding: 4px 12px;
      }

      #custom-agent-hub:hover {
        background: linear-gradient(135deg, rgba(124, 58, 237, 0.3), rgba(255, 0, 170, 0.2));
        border-color: rgba(124, 58, 237, 0.5);
        box-shadow: 0 0 20px rgba(124, 58, 237, 0.3);
        color: #a78bfa;
      }

      /* ============================================
       * SYSTEM TRAY
       * ============================================ */
      #tray {
        padding: 4px 12px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background: rgba(255, 0, 170, 0.1);
        border-color: rgba(255, 0, 170, 0.3);
      }

      #tray menu {
        background: rgba(18, 18, 26, 0.95);
        border: 1px solid rgba(0, 212, 255, 0.3);
        border-radius: 12px;
      }

      #tray menu menuitem {
        padding: 8px 12px;
        transition: all 0.2s ease;
      }

      #tray menu menuitem:hover {
        background: rgba(0, 212, 255, 0.15);
      }
    '';
  };

  # Create scripts directory and monitoring scripts
  home.file = {
    ".config/waybar/scripts/gpu-monitor.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # GPU Monitor Script for Waybar
        # Priority: Temp > VRAM > Utilization > Clock
        # ============================================

        get_gpu_stats() {
          # Check if nvidia-smi is available
          if ! command -v nvidia-smi &> /dev/null; then
            echo '{"text": "󰢮 N/A", "tooltip": "nvidia-smi not found", "class": "disabled"}'
            exit 0
          fi

          # Get GPU stats
          read -r TEMP VRAM_USED VRAM_TOTAL UTIL CLOCK <<< $(nvidia-smi --query-gpu=temperature.gpu,memory.used,memory.total,utilization.gpu,clocks.current.graphics --format=csv,noheader,nounits | head -1 | tr -d ' ')

          # Calculate VRAM percentage
          if [[ -n "$VRAM_TOTAL" && "$VRAM_TOTAL" -gt 0 ]]; then
            VRAM_PERCENT=$(( (VRAM_USED * 100) / VRAM_TOTAL ))
          else
            VRAM_PERCENT=0
          fi

          # Determine class based on temperature
          CLASS="normal"
          if [[ "$TEMP" -ge 85 ]]; then
            CLASS="critical"
          elif [[ "$TEMP" -ge 75 ]]; then
            CLASS="warning"
          fi

          # Format display: 󰢮 temp | vram% | util%
          TEXT="󰢮 ''${TEMP}°C  ''${VRAM_PERCENT}%  ''${UTIL}%"

          # Build tooltip
          TOOLTIP="NVIDIA GPU Status\n━━━━━━━━━━━━━━━━━━━━━━\n"
          TOOLTIP+="󰔏 Temperature: ''${TEMP}°C\n"
          TOOLTIP+="󰍛 VRAM: ''${VRAM_USED}MiB / ''${VRAM_TOTAL}MiB (''${VRAM_PERCENT}%)\n"
          TOOLTIP+="󰓅 Utilization: ''${UTIL}%\n"
          TOOLTIP+="󰑮 Clock: ''${CLOCK} MHz"

          # Output JSON for Waybar
          echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
        }

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
  };
}
