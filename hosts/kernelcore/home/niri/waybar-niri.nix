# ============================================
# Waybar - Niri Adaptations
# ============================================
# Replaces Hyprland-specific modules with Niri equivalents
# Import this INSTEAD of the original waybar.nix when using Niri
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Script paths remain the same
  flakeManager = "${config.home.homeDirectory}/.config/waybar/scripts/flake-manager.sh";
  systemMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/system-monitor.sh";
  gpuMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/gpu-monitor.sh";
  diskMonitor = "${config.home.homeDirectory}/.config/waybar/scripts/disk-monitor.sh";
  sshSessions = "${config.home.homeDirectory}/.config/waybar/scripts/ssh-sessions.sh";

  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;

  # Niri workspace module script
  niriWorkspaces = "${config.home.homeDirectory}/.config/waybar/scripts/niri-workspaces.sh";
  niriActiveWindow = "${config.home.homeDirectory}/.config/waybar/scripts/niri-window.sh";
in
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 52;
        spacing = 8;
        margin-top = 8;
        margin-left = 16;
        margin-right = 16;
        margin-bottom = 0;

        # Module layout - Niri adapted
        modules-left = [
          "custom/niri-workspaces"
          "custom/niri-window"
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
        # NIRI-SPECIFIC MODULES
        # ============================================
        "custom/niri-workspaces" = {
          exec = niriWorkspaces;
          return-type = "json";
          interval = 1;
          format = "{}";
          tooltip = true;
          on-click = "niri msg action focus-workspace-down";
          on-click-right = "niri msg action focus-workspace-up";
          on-scroll-up = "niri msg action focus-column-right";
          on-scroll-down = "niri msg action focus-column-left";
        };

        "custom/niri-window" = {
          exec = niriActiveWindow;
          return-type = "json";
          interval = 1;
          format = "{}";
          tooltip = true;
          max-length = 40;
        };

        # ============================================
        # STANDARD MODULES (same as before)
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
              months = "<span color='${colors.accent.cyan}'><b>{}</b></span>";
              days = "<span color='${colors.base.fg1}'>{}</span>";
              weeks = "<span color='${colors.accent.violet}'><b>W{}</b></span>";
              weekdays = "<span color='${colors.base.fg2}'>{}</span>";
              today = "<span color='${colors.accent.magenta}'><b><u>{}</u></b></span>";
            };
          };
        };

        # Custom modules (unchanged from original)
        "custom/flake" = {
          exec = flakeManager;
          return-type = "json";
          interval = 60;
          format = "{}";
          tooltip = true;
          on-click = "alacritty -e ${flakeManager} rebuild";
          on-click-right = "alacritty -e ${flakeManager} menu";
        };

        "custom/system" = {
          exec = systemMonitor;
          return-type = "json";
          interval = 3;
          format = "{}";
          tooltip = true;
          on-click = "alacritty -e btop";
        };

        "custom/gpu" = {
          exec = gpuMonitor;
          return-type = "json";
          interval = 3;
          format = "{}";
          tooltip = true;
          on-click = "nvidia-settings";
        };

        "custom/disk" = {
          exec = diskMonitor;
          return-type = "json";
          interval = 30;
          format = "{}";
          tooltip = true;
          on-click = "gparted";
        };

        "custom/ssh" = {
          exec = sshSessions;
          return-type = "json";
          interval = 5;
          format = "{}";
          tooltip = true;
          on-click = "alacritty -e htop -p $(pgrep -d, ssh)";
        };

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
          icon-size = 22;
          spacing = 12;
          show-passive-items = true;
        };
      };
    };

    # CSS remains largely the same - just update workspace styles
    style = ''
      /* ============================================
       * Waybar - Glassmorphism Theme (Niri Edition)
       * Same styling, Niri-adapted modules
       * ============================================ */

      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", monospace;
        font-size: 13px;
      }

      window#waybar {
        background: ${colors.hexToRgba colors.base.bg0 "0.75"};
        border-radius: ${toString colors.radius.large}px;
        border: 1px solid ${colors.border.light};
        box-shadow: 0 4px 20px ${colors.shadow.dark},
                    0 0 40px ${colors.hexToRgba colors.accent.cyan "0.05"};
      }

      tooltip {
        background: ${colors.hexToRgba colors.base.bg1 "0.95"};
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.3"};
        border-radius: ${toString colors.radius.medium}px;
      }

      tooltip label {
        color: ${colors.base.fg1};
        padding: 8px 12px;
      }

      /* Module base styles */
      #custom-niri-workspaces,
      #custom-niri-window,
      #clock,
      #custom-flake,
      #custom-system,
      #custom-gpu,
      #custom-disk,
      #custom-ssh,
      #custom-agent-hub,
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

      /* Hover effects */
      #custom-niri-workspaces:hover,
      #custom-niri-window:hover,
      #clock:hover,
      #custom-flake:hover,
      #custom-system:hover,
      #custom-gpu:hover,
      #custom-disk:hover,
      #custom-ssh:hover,
      #custom-agent-hub:hover,
      #network:hover,
      #bluetooth:hover,
      #pulseaudio:hover,
      #battery:hover,
      #tray:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.15"};
        border-color: ${colors.hexToRgba colors.accent.cyan "0.4"};
        box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.cyan "0.2"};
      }

      /* Niri Workspaces - Scrolling indicator */
      #custom-niri-workspaces {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.cyan "0.15"}, ${colors.hexToRgba colors.accent.violet "0.1"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.3"};
        padding: 4px 14px;
        min-width: 80px;
      }

      /* Niri Window */
      #custom-niri-window {
        color: ${colors.base.fg2};
        font-weight: 500;
      }

      /* Clock */
      #clock {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.base.bg1 "0.9"}, ${colors.hexToRgba colors.base.bg2 "0.8"});
        color: ${colors.base.fg0};
        font-weight: 600;
        font-size: 14px;
        padding: 4px 20px;
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.2"};
      }

      /* GPU Module */
      #custom-gpu {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.green "0.15"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.green "0.2"};
      }

      /* Disk Module */
      #custom-disk {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.15"}, ${colors.hexToRgba colors.base.bg1 "0.8"});
        border-color: ${colors.hexToRgba colors.accent.violet "0.2"};
        color: ${colors.accent.violetLight};
      }

      /* SSH Indicator */
      #custom-ssh.active {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.cyan "0.2"}, ${colors.hexToRgba colors.accent.violet "0.15"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.4"};
        color: ${colors.accent.cyan};
      }

      /* Network */
      #network {
        color: ${colors.accent.green};
      }

      #network.disconnected {
        color: ${colors.accent.red};
        background: ${colors.hexToRgba colors.accent.red "0.1"};
      }

      /* Bluetooth */
      #bluetooth {
        color: ${colors.accent.blue};
      }

      #bluetooth.connected {
        color: ${colors.accent.cyan};
      }

      /* Audio */
      #pulseaudio {
        color: ${colors.accent.violet};
      }

      #pulseaudio.muted {
        color: ${colors.base.fg3};
      }

      /* Battery */
      #battery {
        color: ${colors.accent.green};
      }

      #battery.charging {
        color: ${colors.accent.cyan};
        background: ${colors.hexToRgba colors.accent.cyan "0.1"};
      }

      #battery.warning:not(.charging) {
        color: ${colors.accent.yellow};
        background: ${colors.hexToRgba colors.accent.yellow "0.1"};
      }

      #battery.critical:not(.charging) {
        color: ${colors.accent.magenta};
        background: ${colors.hexToRgba colors.accent.magenta "0.15"};
      }

      /* Agent Hub */
      #custom-agent-hub {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.2"}, ${colors.hexToRgba colors.accent.magenta "0.1"});
        border-color: ${colors.hexToRgba colors.accent.violet "0.3"};
        color: ${colors.accent.violet};
        font-size: 16px;
        padding: 4px 12px;
      }

      /* System Tray */
      #tray {
        padding: 6px 16px;
        background: linear-gradient(135deg, ${colors.hexToRgba colors.base.bg1 "0.85"}, ${colors.hexToRgba colors.base.bg2 "0.75"});
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.15"};
        margin-left: 8px;
      }

      #tray > .passive {
        opacity: 0.75;
      }

      #tray > .active {
        background: ${colors.hexToRgba colors.accent.cyan "0.08"};
      }

      #tray menu {
        background: ${colors.hexToRgba colors.base.bg1 "0.95"};
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.3"};
        border-radius: ${toString colors.radius.medium}px;
      }

      #tray menu menuitem:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.2"};
      }
    '';
  };

  # ============================================
  # NIRI-SPECIFIC WAYBAR SCRIPTS
  # ============================================
  home.file = {
    # Niri workspace/scroll indicator
    ".config/waybar/scripts/niri-workspaces.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Niri Workspaces Module for Waybar
        # Shows current workspace and column info
        # ============================================

        # Get current workspace info via niri msg
        WORKSPACE=$(niri msg workspaces 2>/dev/null | grep -E "^\*" | sed 's/^\* //' | head -1)

        if [[ -z "$WORKSPACE" ]]; then
          WORKSPACE="scroll"
        fi

        # Get focused output info
        FOCUSED=$(niri msg focused-window 2>/dev/null | head -1)

        # Build tooltip
        TOOLTIP="Niri Scroll View\n━━━━━━━━━━━━━━━━━━━━━━\n"
        TOOLTIP+="󰍹 Workspace: $WORKSPACE\n"
        TOOLTIP+="\n󰍜 Scroll: Mouse wheel / Mod+H/L\n"
        TOOLTIP+="󰍜 Click: Next workspace"

        # Icon based on workspace
        case "$WORKSPACE" in
          dev)   ICON="󰈮" ;;
          web)   ICON="󰈹" ;;
          chat)  ICON="󰭻" ;;
          media) ICON="󰎆" ;;
          sys)   ICON="󰒓" ;;
          *)     ICON="󰍹" ;;
        esac

        TEXT="$ICON $WORKSPACE"

        printf '{"text": "%s", "tooltip": "%s", "class": "active"}\n' "$TEXT" "$TOOLTIP"
      '';
    };

    # Niri active window
    ".config/waybar/scripts/niri-window.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Niri Active Window Module for Waybar
        # Shows currently focused window
        # ============================================

        # Get focused window info
        WINDOW_INFO=$(niri msg focused-window 2>/dev/null)

        if [[ -z "$WINDOW_INFO" ]]; then
          echo '{"text": "󰇄 Desktop", "tooltip": "No focused window", "class": "empty"}'
          exit 0
        fi

        # Parse app-id and title
        APP_ID=$(echo "$WINDOW_INFO" | grep "app_id:" | sed 's/.*app_id: //' | tr -d '"')
        TITLE=$(echo "$WINDOW_INFO" | grep "title:" | sed 's/.*title: //' | tr -d '"' | head -c 35)

        # Icon mapping
        case "$APP_ID" in
          kitty)           ICON="󰄛" ;;
          Alacritty)       ICON="󰆍" ;;
          foot)            ICON="󰆍" ;;
          firefox)         ICON="󰈹" ;;
          brave-browser)   ICON="󰖟" ;;
          chromium)        ICON="" ;;
          code-oss|Code)   ICON="󰨞" ;;
          VSCodium|codium) ICON="󰨞" ;;
          discord)         ICON="󰙯" ;;
          spotify)         ICON="󰓇" ;;
          nemo)            ICON="󰉋" ;;
          obsidian)        ICON="󰠮" ;;
          mpv)             ICON="󰎁" ;;
          *)               ICON="󰏗" ;;
        esac

        # Truncate title if needed
        [[ ''${#TITLE} -gt 30 ]] && TITLE="''${TITLE:0:30}..."

        TEXT="$ICON $TITLE"
        TOOLTIP="$APP_ID\n$TITLE"

        printf '{"text": "%s", "tooltip": "%s", "class": "active"}\n' "$TEXT" "$TOOLTIP"
      '';
    };
  };
}
