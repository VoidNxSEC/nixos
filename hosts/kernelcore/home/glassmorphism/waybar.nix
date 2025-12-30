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
  flakeManager = "${config.home.homeDirectory}/.config/waybar/scripts/flake-manager.sh";
  systemMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/system-monitor.sh";
  gpuMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/gpu-monitor.sh";
  diskMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/disk-monitor.sh";
  sshSessions = "${config.home.homeDirectory}/.config/waybar/scripts/ssh-sessions.sh";

  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;
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
          "custom/flake"
          "custom/system"
          "custom/gpu"
          "custom/disk"
          "custom/ssh"
          "custom/agent-hub"
          "network"
          "bluetooth"
          "pulseaudio"
          "battery"
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

        # Flake Manager - NixOS system management
        "custom/flake" = {
          exec = flakeManager;
          return-type = "json";
          interval = 60;
          format = "{}";
          tooltip = true;
          on-click = "alacritty -e ${flakeManager} rebuild";
          on-click-right = "alacritty -e ${flakeManager} menu";
        };

        # System Monitor - CPU, RAM, Thermal
        "custom/system" = {
          exec = systemMonitor;
          return-type = "json";
          interval = 3;
          format = "{}";
          tooltip = true;
          on-click = "alacritty -e btop";
        };

        # GPU Monitor - Temp > VRAM > Util > Clock
        "custom/gpu" = {
          exec = gpuMonitor;
          return-type = "json";
          interval = 3;
          format = "{}";
          tooltip = true;
          on-click = "nvidia-settings";
        };

        # Disk Space Monitor
        "custom/disk" = {
          exec = diskMonitor;
          return-type = "json";
          interval = 30;
          format = "{}";
          tooltip = true;
          on-click = "gparted";
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

        # Agent Hub - AI Agent Integration
        "custom/agent-hub" = {
          exec = "${config.home.homeDirectory}/.config/agent-hub/waybar-module.sh";
          return-type = "json";
          interval = 10;
          format = "{}";
          tooltip = true;
          on-click = "${config.home.homeDirectory}/.config/agent-hub/agent-launcher.sh";
          on-click-right = "${config.home.homeDirectory}/.config/agent-hub/quick-prompt.sh";
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

        "tray" = {
          icon-size = 22; # Increased from 18 for better visibility
          spacing = 12; # More breathing room
          show-passive-items = true;
        };
      };
    };

    # ============================================
    # GLASSMORPHISM CSS STYLES (using design tokens)
    # ============================================
    style = ''
      /* ============================================
       * Waybar - Glassmorphism Theme
       * Premium frosted glass with electric accents
       * Using design tokens from colors.nix
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
        background: ${colors.hexToRgba colors.base.bg0 "0.75"};
        border-radius: ${toString colors.radius.large}px;
        border: 1px solid ${colors.border.light};
        box-shadow: 0 4px 20px ${colors.shadow.dark},
                    0 0 40px ${colors.hexToRgba colors.accent.cyan "0.05"};
      }

      window#waybar.hidden {
        opacity: 0;
      }

      /* Tooltip styling */
      tooltip {
        background: ${colors.hexToRgba colors.base.bg1 "0.95"};
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.3"};
        border-radius: ${toString colors.radius.medium}px;
        box-shadow: 0 4px 20px ${colors.shadow.dark},
                    0 0 20px ${colors.hexToRgba colors.accent.cyan "0.1"};
      }

      tooltip label {
        color: ${colors.base.fg1};
        padding: 8px 12px;
      }

      /* Module base styles */
      #workspaces,
      #window,
      #clock,
      #custom-flake,
      #custom-system,
      #custom-gpu,
      #custom-disk,
      #custom-ssh,
      #network,
      #bluetooth,
      #pulseaudio,
      #battery,
      #tray {
        background: ${colors.hexToRgba colors.base.bg1 "0.8"};
        border: 1px solid ${colors.border.lighter};
        border-radius: ${toString colors.radius.pill}px;
        padding: 4px 16px;
        margin: 4px 4px;
        color: ${colors.base.fg1};
        transition: all 0.3s ease;
      }

      /* Hover effects - cyan glow */
      #workspaces:hover,
      #window:hover,
      #clock:hover,
      #custom-flake:hover,
      #custom-system:hover,
      #custom-gpu:hover,
      #custom-disk:hover,
      #custom-ssh:hover,
      #network:hover,
      #bluetooth:hover,
      #pulseaudio:hover,
      #battery:hover,
      #tray:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.15"};
        border-color: ${colors.hexToRgba colors.accent.cyan "0.4"};
        box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.cyan "0.2"};
      }

      /* ============================================
       * WORKSPACES
       * ============================================ */
      #workspaces {
        padding: 2px 8px;
      }

      #workspaces button {
        background: transparent;
        color: ${colors.base.fg3};
        padding: 4px 8px;
        margin: 2px;
        border-radius: ${toString colors.radius.medium}px;
        transition: all 0.3s ease;
      }

      #workspaces button:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.2"};
        color: ${colors.accent.cyan};
      }

      #workspaces button.active {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.cyan "0.3"}, ${colors.hexToRgba colors.accent.violet "0.3"});
        color: ${colors.accent.cyan};
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.5"};
        box-shadow: 0 0 15px ${colors.hexToRgba colors.accent.cyan "0.3"};
      }

      #workspaces button.urgent {
        background: ${colors.hexToRgba colors.accent.magenta "0.3"};
        color: ${colors.accent.magenta};
        border: 1px solid ${colors.hexToRgba colors.accent.magenta "0.5"};
      }

      /* ============================================
       * WINDOW TITLE
       * ============================================ */
      #window {
        color: ${colors.base.fg2};
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
        background: linear-gradient(135deg, ${colors.hexToRgba colors.base.bg1 "0.9"}, ${colors.hexToRgba colors.base.bg2 "0.8"});
        color: ${colors.base.fg0};
        font-weight: 600;
        font-size: 14px;
        padding: 4px 20px;
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.2"};
      }

      #clock:hover {
        border-color: ${colors.hexToRgba colors.accent.cyan "0.5"};
        box-shadow: 0 0 25px ${colors.hexToRgba colors.accent.cyan "0.25"};
      }

      /* ============================================
       * GPU MODULE
       * ============================================ */
      #custom-gpu {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.green "0.15"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.green "0.2"};
      }

      #custom-gpu.warning {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.yellow "0.2"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.yellow "0.4"};
        color: ${colors.accent.yellow};
      }

      #custom-gpu.critical {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.magenta "0.2"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.magenta "0.4"};
        color: ${colors.accent.magenta};
      }

      #custom-gpu:hover {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.green "0.25"}, ${colors.hexToRgba colors.accent.cyan "0.15"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.4"};
      }

      /* ============================================
       * DISK MODULE
       * ============================================ */
      #custom-disk {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.15"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.violet "0.2"};
        color: ${colors.accent.violetLight};
      }

      #custom-disk.warning {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.yellow "0.2"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.yellow "0.4"};
        color: ${colors.accent.yellow};
      }

      #custom-disk.critical {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.magenta "0.2"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.magenta "0.4"};
        color: ${colors.accent.magenta};
      }

      #custom-disk:hover {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.25"}, ${colors.hexToRgba colors.accent.cyan "0.15"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.4"};
      }

      /* ============================================
       * SSH INDICATOR
       * ============================================ */
      #custom-ssh {
        background: ${colors.hexToRgba colors.base.bg1 "0.8"};
        color: ${colors.base.fg3};
      }

      #custom-ssh.active {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.cyan "0.2"}, ${colors.hexToRgba colors.accent.violet "0.15"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.4"};
        color: ${colors.accent.cyan};
      }

      #custom-ssh.active:hover {
        box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.cyan "0.3"};
      }

      /* ============================================
       * NETWORK
       * ============================================ */
      #network {
        color: ${colors.accent.green};
      }

      #network.disconnected {
        color: ${colors.accent.red};
        background: ${colors.hexToRgba colors.accent.red "0.1"};
        border-color: ${colors.hexToRgba colors.accent.red "0.3"};
      }

      #network.wifi {
        color: ${colors.accent.cyan};
      }

      /* ============================================
       * BLUETOOTH
       * ============================================ */
      #bluetooth {
        color: ${colors.accent.blue};
      }

      #bluetooth.disabled {
        color: ${colors.base.fg3};
      }

      #bluetooth.connected {
        color: ${colors.accent.cyan};
      }

      /* ============================================
       * AUDIO
       * ============================================ */
      #pulseaudio {
        color: ${colors.accent.violet};
      }

      #pulseaudio.muted {
        color: ${colors.base.fg3};
        background: ${colors.hexToRgba colors.base.fg3 "0.1"};
      }

      /* ============================================
       * BATTERY
       * ============================================ */
      #battery {
        color: ${colors.accent.green};
      }

      #battery.charging {
        color: ${colors.accent.cyan};
        background: ${colors.hexToRgba colors.accent.cyan "0.1"};
        border-color: ${colors.hexToRgba colors.accent.cyan "0.3"};
      }

      #battery.warning:not(.charging) {
        color: ${colors.accent.yellow};
        background: ${colors.hexToRgba colors.accent.yellow "0.1"};
        border-color: ${colors.hexToRgba colors.accent.yellow "0.3"};
      }

      #battery.critical:not(.charging) {
        color: ${colors.accent.magenta};
        background: ${colors.hexToRgba colors.accent.magenta "0.15"};
        border-color: ${colors.hexToRgba colors.accent.magenta "0.4"};
      }

      /* ============================================
       * AGENT HUB
       * ============================================ */
      #custom-agent-hub {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.2"}, ${colors.hexToRgba colors.accent.magenta "0.1"});
        border-color: ${colors.hexToRgba colors.accent.violet "0.3"};
        color: ${colors.accent.violet};
        font-size: 16px;
        padding: 4px 12px;
      }

      #custom-agent-hub:hover {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.3"}, ${colors.hexToRgba colors.accent.magenta "0.2"});
        border-color: ${colors.hexToRgba colors.accent.violet "0.5"};
        box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.violet "0.3"};
        color: ${colors.accent.violetLight};
      }

      /* ============================================
       * SYSTEM TRAY - PREMIUM REFINED ICONS
       * ============================================ */
      #tray {
        padding: 6px 16px;
        background: linear-gradient(135deg, ${colors.hexToRgba colors.base.bg1 "0.85"}, ${colors.hexToRgba colors.base.bg2 "0.75"});
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.15"};
        margin-left: 8px; /* Visual separator from other modules */
      }

      #tray:hover {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.base.bg1 "0.9"}, ${colors.hexToRgba colors.base.bg2 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.3"};
        box-shadow: 0 0 15px ${colors.hexToRgba colors.accent.cyan "0.15"},
                    inset 0 0 10px ${colors.hexToRgba colors.accent.cyan "0.05"};
      }

      /* Tray icons - individual styling */
      #tray > * {
        padding: 4px;
        margin: 0 2px;
        border-radius: ${toString colors.radius.small}px;
        transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
      }

      /* Passive icons - subtle but visible */
      #tray > .passive {
        -gtk-icon-effect: none; /* Remove dim effect for better visibility */
        opacity: 0.75;
      }

      #tray > .passive:hover {
        opacity: 1;
        background: ${colors.hexToRgba colors.accent.cyan "0.1"};
        box-shadow: 0 0 8px ${colors.hexToRgba colors.accent.cyan "0.4"};
      }

      /* Active icons - prominent with glow */
      #tray > .active {
        background: ${colors.hexToRgba colors.accent.cyan "0.08"};
        box-shadow: 0 0 6px ${colors.hexToRgba colors.accent.cyan "0.3"};
      }

      #tray > .active:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.15"};
        box-shadow: 0 0 10px ${colors.hexToRgba colors.accent.cyan "0.5"};
        transform: translateY(-1px);
      }

      /* Attention-needed icons - magenta pulse effect */
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background: ${colors.hexToRgba colors.accent.magenta "0.15"};
        border: 1px solid ${colors.hexToRgba colors.accent.magenta "0.4"};
        animation: tray-pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
      }

      @keyframes tray-pulse {
        0%, 100% {
          box-shadow: 0 0 12px ${colors.hexToRgba colors.accent.magenta "0.3"};
        }
        50% {
          box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.magenta "0.6"};
        }
      }

      /* Tray context menu - glassmorphism */
      #tray menu {
        background: ${colors.hexToRgba colors.base.bg1 "0.95"};
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.3"};
        border-radius: ${toString colors.radius.medium}px;
        padding: 6px;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4),
                    0 0 20px ${colors.hexToRgba colors.accent.cyan "0.15"};
      }

      #tray menu menuitem {
        padding: 10px 14px;
        border-radius: ${toString colors.radius.small}px;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        margin: 2px 0;
      }

      #tray menu menuitem:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.2"};
        box-shadow: 0 0 12px ${colors.hexToRgba colors.accent.cyan "0.2"};
        transform: translateX(2px);
      }

      #tray menu separator {
        background: ${colors.hexToRgba colors.border.light "0.5"};
        margin: 4px 8px;
      }
    '';
  };

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

        # Handle menu mode
        if [[ "$1" == "menu" ]]; then
          show_menu
          exit 0
        fi

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
          local text="󰻠 ''${cpu_usage}%  ''${mem_percent}%"
          [[ $cpu_temp -gt 0 ]] && text+="  ''${cpu_temp}°C"

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
          local text="󰋊 ''${used}/''${size} (''${percent})"

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
          local text="󰢮 ''${temp}°C  ''${vram_percent}%  ''${util}%"

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
  };
}
