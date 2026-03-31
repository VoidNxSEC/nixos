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
  osConfig,
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
  actionsTvWaybarEnabled = lib.attrByPath [ "programs" "actionsTv" "waybar" "enable" ] false config;
  spooknixWaybarEnabled = lib.attrByPath [ "programs" "spooknix" "waybar" "enable" ] false config;

  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;
in
{
  config = {
    programs.waybar =
      lib.mkIf (osConfig.services.hyprland-desktop.enable || osConfig.programs.niri.enable)
        {
          enable = true;

          settings = {
            mainBar = {
              layer = "top";
              position = "top";
              height = 58;
              spacing = 6;
              margin-top = 10;
              margin-left = 18;
              margin-right = 18;
              margin-bottom = 0;

              # Module layout (compositor-agnostic)
              modules-left =
                if osConfig.services.hyprland-desktop.enable then
                  [
                    "hyprland/workspaces"
                    "hyprland/window"
                  ]
                else if osConfig.programs.niri.enable then
                  [
                    "niri/workspaces"
                    "niri/window"
                  ]
                else
                  [ ];

              modules-center = [
                "clock"
              ];

              modules-right = lib.mkForce (
                [
                  "custom/flake"
                ]
                ++ lib.optional actionsTvWaybarEnabled "custom/actions-tv"
                ++ lib.optional spooknixWaybarEnabled "custom/spooknix"
                ++ [
                  "custom/agent-hub"
                  "custom/system"
                  "custom/gpu"
                  "custom/disk"
                  "custom/ssh"
                  "network"
                  "bluetooth"
                  "pulseaudio"
                  "battery"
                  "tray"
                ]
              );

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
                # on-click is not needed - workspaces are clicked automatically
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
                max-length = 48;
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
                  "chromium-browser" = "󰊯 Chromium";
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
              # NIRI MODULES (for Niri specialisation)
              # ============================================
              "niri/workspaces" = {
                format = "{icon}";
                format-icons = {
                  "1" = "󰲠";
                  "2" = "󰲢";
                  "3" = "󰲤";
                  "4" = "󰲦";
                  "5" = "󰲨";
                  urgent = "󰀨";
                  active = "󰮯";
                  default = "󰊠";
                };
              };

              "niri/window" = {
                format = "{class}";
                max-length = 48;
                rewrite = {
                  # Terminal emulators
                  "Alacritty" = "󰆍 Alacritty";
                  "kitty" = "󰄛 Kitty";
                  "foot" = "󰆍 Foot";

                  # Browsers
                  "firefox" = "󰈹 Firefox";
                  "brave-browser" = "󰖟 Brave";
                  "chromium-browser" = "󰊯 Chromium";
                  "code-oss" = "󰨞 VSCode";
                  "VSCodium" = "󰨞 VSCodium";
                  "codium" = "󰨞 VSCodium";
                  "nemo" = "󰉋 Files";
                  "discord" = "󰙯 Discord";
                  "obsidian" = "󰠮 Obsidian";
                  "" = "󰇄 Desktop";
                };
              };

              # ============================================
              # CENTER MODULES
              # ============================================
              "clock" = {
                format = "󰃭 {:%a %d %b · %H:%M}";
                format-alt = "󰥔 {:%A, %d %B %Y · %H:%M:%S}";
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
                on-click-middle = "alacritty -e ${flakeManager} check";
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

              "custom/spooknix" = lib.mkIf spooknixWaybarEnabled {
                on-click = lib.mkForce "${pkgs.systemd}/bin/systemctl --user start spooknix-gui.service";
              };

              "network" = {
                format-wifi = "󰤨 {signalStrength}%";
                format-ethernet = "󰈀 {ifname}";
                format-linked = "󰈀 link";
                format-disconnected = "󰤭";
                format-alt = "{ifname}: {ipaddr}/{cidr}";
                tooltip-format = "󰩟 {ifname}\n󰩠 {ipaddr}/{cidr}\n󰖩 {essid}\n󰁝 {bandwidthUpBytes}\n󰁅 {bandwidthDownBytes}";
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
                icon-size = 18;
                spacing = 8;
                show-passive-items = true;
              };
            };
          };

          # ============================================
          # GLASSMORPHISM CSS STYLES (using design tokens)
          # ============================================
          style = lib.mkForce ''
            * {
              border: none;
              border-radius: 0;
              min-height: 0;
              font-family: "JetBrainsMono Nerd Font", "FiraCode Nerd Font", "Noto Color Emoji", monospace;
              font-size: 13px;
              font-weight: 600;
            }

            window#waybar {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.base.bg0 "0.86"},
                ${colors.hexToRgba colors.base.bg1 "0.74"}
              );
              color: ${colors.base.fg1};
              border-radius: 22px;
              border: 1px solid ${colors.hexToRgba colors.base.fg0 "0.08"};
              box-shadow: 0 18px 42px ${colors.shadow.dark},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.08"},
                          0 0 36px ${colors.hexToRgba colors.accent.cyan "0.08"};
            }

            window#waybar.hidden {
              opacity: 0.18;
            }

            window#waybar > box {
              padding: 5px 8px;
            }

            tooltip {
              background: ${colors.hexToRgba colors.base.bg1 "0.96"};
              border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.24"};
              border-radius: ${toString colors.radius.medium}px;
              box-shadow: 0 12px 36px ${colors.shadow.dark},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.05"};
            }

            tooltip label {
              color: ${colors.base.fg1};
              padding: 10px 14px;
            }

            #workspaces,
            #window,
            #clock,
            #custom-flake,
            #custom-actions-tv,
            #custom-spooknix,
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
              min-height: 0;
              margin: 0 4px;
              padding: 0 15px;
              border-radius: 16px;
              background: linear-gradient(
                180deg,
                ${colors.hexToRgba colors.base.bg2 "0.88"},
                ${colors.hexToRgba colors.base.bg1 "0.74"}
              );
              color: ${colors.base.fg1};
              border: 1px solid ${colors.hexToRgba colors.base.fg0 "0.07"};
              box-shadow: inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              transition: all ${toString colors.animation.normal}ms cubic-bezier(${colors.animation.bezier.gentle});
            }

            #window:hover,
            #clock:hover,
            #custom-flake:hover,
            #custom-actions-tv:hover,
            #custom-spooknix:hover,
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
              border-color: ${colors.hexToRgba colors.accent.cyan "0.24"};
              box-shadow: 0 10px 24px ${colors.hexToRgba colors.base.bg0 "0.18"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.05"};
            }

            @keyframes pulse-cyan {
              0% {
                box-shadow: 0 0 0 ${colors.hexToRgba colors.accent.cyan "0.00"};
              }
              50% {
                box-shadow: 0 0 18px ${colors.hexToRgba colors.accent.cyan "0.28"};
              }
              100% {
                box-shadow: 0 0 0 ${colors.hexToRgba colors.accent.cyan "0.00"};
              }
            }

            @keyframes pulse-amber {
              0% {
                box-shadow: 0 0 0 ${colors.hexToRgba colors.accent.yellow "0.00"};
              }
              50% {
                box-shadow: 0 0 18px ${colors.hexToRgba colors.accent.yellow "0.30"};
              }
              100% {
                box-shadow: 0 0 0 ${colors.hexToRgba colors.accent.yellow "0.00"};
              }
            }

            @keyframes pulse-magenta {
              0% {
                box-shadow: 0 0 0 ${colors.hexToRgba colors.accent.magenta "0.00"};
              }
              50% {
                box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.magenta "0.36"};
              }
              100% {
                box-shadow: 0 0 0 ${colors.hexToRgba colors.accent.magenta "0.00"};
              }
            }

            #workspaces {
              padding: 4px 8px;
              border-radius: 18px;
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.cyan "0.08"},
                ${colors.hexToRgba colors.accent.violet "0.10"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.16"};
            }

            #workspaces button {
              min-width: 34px;
              padding: 0 6px;
              margin: 4px 2px;
              border-radius: 12px;
              background: transparent;
              color: ${colors.base.fg3};
              transition: all ${toString colors.animation.fast}ms cubic-bezier(${colors.animation.bezier.snappy});
            }

            #workspaces button:hover {
              background: ${colors.hexToRgba colors.accent.cyan "0.14"};
              color: ${colors.accent.cyanLight};
            }

            #workspaces button.active {
              background: linear-gradient(135deg, ${colors.accent.cyanLight}, ${colors.accent.cyan});
              color: ${colors.base.bg0};
              box-shadow: 0 10px 20px ${colors.hexToRgba colors.accent.cyan "0.28"};
            }

            #workspaces button.urgent {
              background: ${colors.hexToRgba colors.accent.magenta "0.22"};
              color: ${colors.accent.magentaLight};
            }

            #workspaces button.special {
              background: ${colors.hexToRgba colors.accent.violet "0.18"};
              color: ${colors.accent.violetLight};
            }

            #window {
              min-width: 260px;
              padding-left: 18px;
              padding-right: 20px;
              color: ${colors.base.fg2};
              background: linear-gradient(
                120deg,
                ${colors.hexToRgba colors.base.bg1 "0.82"},
                ${colors.hexToRgba colors.base.bg2 "0.58"}
              );
              border-color: ${colors.hexToRgba colors.accent.violet "0.18"};
            }

            window#waybar.empty #window {
              background: transparent;
              border-color: transparent;
              box-shadow: none;
            }

            #clock {
              min-width: 232px;
              padding: 0 24px;
              color: ${colors.base.fg0};
              font-size: 15px;
              font-weight: 700;
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.cyan "0.18"},
                ${colors.hexToRgba colors.accent.violet "0.20"},
                ${colors.hexToRgba colors.base.bg2 "0.92"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.28"};
              box-shadow: 0 16px 30px ${colors.hexToRgba colors.base.bg0 "0.24"},
                          0 0 22px ${colors.hexToRgba colors.accent.cyan "0.10"};
            }

            #custom-flake,
            #custom-actions-tv,
            #custom-spooknix,
            #custom-agent-hub {
              color: ${colors.base.fg0};
            }

            #custom-flake {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.violet "0.22"},
                ${colors.hexToRgba colors.base.bg2 "0.86"}
              );
              border-color: ${colors.hexToRgba colors.accent.violet "0.30"};
              color: ${colors.accent.cyanLight};
            }

            #custom-flake.warning {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.yellow "0.18"},
                ${colors.hexToRgba colors.base.bg2 "0.86"}
              );
              border-color: ${colors.hexToRgba colors.accent.yellow "0.36"};
              color: ${colors.accent.yellow};
            }

            #custom-flake.building {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.cyan "0.24"},
                ${colors.hexToRgba colors.accent.violet "0.22"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.48"};
              color: ${colors.base.fg0};
              animation: pulse-cyan 1.6s infinite;
            }

            #custom-actions-tv {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.blue "0.18"},
                ${colors.hexToRgba colors.base.bg2 "0.86"}
              );
              border-color: ${colors.hexToRgba colors.accent.blue "0.28"};
              color: ${colors.accent.blue};
            }

            #custom-actions-tv.healthy {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.green "0.20"},
                ${colors.hexToRgba colors.base.bg2 "0.86"}
              );
              border-color: ${colors.hexToRgba colors.accent.green "0.32"};
              color: ${colors.accent.green};
            }

            #custom-actions-tv.running {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.yellow "0.18"},
                ${colors.hexToRgba colors.base.bg2 "0.86"}
              );
              border-color: ${colors.hexToRgba colors.accent.yellow "0.34"};
              color: ${colors.accent.yellow};
              animation: pulse-amber 1.6s infinite;
            }

            #custom-actions-tv.failed,
            #custom-actions-tv.error {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.magenta "0.22"},
                ${colors.hexToRgba colors.accent.red "0.14"}
              );
              border-color: ${colors.hexToRgba colors.accent.magenta "0.44"};
              color: ${colors.accent.magentaLight};
            }

            #custom-actions-tv.idle,
            #custom-actions-tv.missing {
              background: linear-gradient(
                180deg,
                ${colors.hexToRgba colors.base.bg2 "0.88"},
                ${colors.hexToRgba colors.base.bg1 "0.74"}
              );
              color: ${colors.base.fg2};
              border-color: ${colors.hexToRgba colors.base.fg0 "0.08"};
            }

            #custom-spooknix {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.cyan "0.16"},
                ${colors.hexToRgba colors.accent.blue "0.18"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.30"};
              color: ${colors.accent.cyanLight};
            }

            #custom-spooknix.inactive {
              background: linear-gradient(
                180deg,
                ${colors.hexToRgba colors.base.bg2 "0.88"},
                ${colors.hexToRgba colors.base.bg1 "0.74"}
              );
              border-color: ${colors.hexToRgba colors.base.fg0 "0.06"};
              color: ${colors.base.fg3};
            }

            #custom-agent-hub {
              min-width: 44px;
              padding: 0 14px;
              font-size: 16px;
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.violet "0.30"},
                ${colors.hexToRgba colors.accent.magenta "0.18"}
              );
              border-color: ${colors.hexToRgba colors.accent.violet "0.36"};
              color: ${colors.accent.violetLight};
            }

            #custom-agent-hub.active {
              border-color: ${colors.hexToRgba colors.accent.cyan "0.34"};
              color: ${colors.accent.cyanLight};
            }

            #custom-agent-hub.thinking {
              color: ${colors.base.fg0};
              animation: pulse-magenta 1.3s infinite;
            }

            #custom-system,
            #custom-gpu,
            #custom-disk,
            #custom-ssh {
              padding: 0 14px;
            }

            #custom-system {
              border-color: ${colors.hexToRgba colors.accent.cyan "0.20"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.cyan "0.58"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
            }

            #custom-system.warning {
              border-color: ${colors.hexToRgba colors.accent.yellow "0.34"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.yellow "0.70"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.yellow};
            }

            #custom-system.critical {
              border-color: ${colors.hexToRgba colors.accent.red "0.36"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.red "0.72"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.red};
            }

            #custom-gpu {
              border-color: ${colors.hexToRgba colors.accent.green "0.20"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.green "0.58"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
            }

            #custom-gpu.warning {
              border-color: ${colors.hexToRgba colors.accent.yellow "0.34"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.yellow "0.70"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.yellow};
            }

            #custom-gpu.critical {
              border-color: ${colors.hexToRgba colors.accent.magenta "0.40"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.magenta "0.72"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.magentaLight};
              animation: pulse-magenta 1.6s infinite;
            }

            #custom-gpu.disabled {
              border-color: ${colors.hexToRgba colors.base.fg0 "0.08"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.base.fg0 "0.16"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.base.fg3};
            }

            #custom-disk {
              border-color: ${colors.hexToRgba colors.accent.violet "0.20"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.violet "0.62"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.violetLight};
            }

            #custom-disk.warning {
              border-color: ${colors.hexToRgba colors.accent.yellow "0.34"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.yellow "0.70"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.yellow};
            }

            #custom-disk.critical {
              border-color: ${colors.hexToRgba colors.accent.magenta "0.40"};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.magenta "0.72"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
              color: ${colors.accent.magentaLight};
            }

            #custom-ssh {
              color: ${colors.base.fg3};
            }

            #custom-ssh.active {
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.cyan "0.12"},
                ${colors.hexToRgba colors.accent.violet "0.14"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.30"};
              color: ${colors.accent.cyanLight};
              box-shadow: inset 3px 0 0 ${colors.hexToRgba colors.accent.cyan "0.66"},
                          inset 0 1px 0 ${colors.hexToRgba colors.base.fg0 "0.04"};
            }

            #network,
            #bluetooth,
            #pulseaudio,
            #battery {
              padding: 0 12px;
            }

            #network {
              color: ${colors.accent.cyanLight};
              border-color: ${colors.hexToRgba colors.accent.cyan "0.18"};
            }

            #network.disconnected {
              color: ${colors.accent.red};
              background: ${colors.hexToRgba colors.accent.red "0.10"};
              border-color: ${colors.hexToRgba colors.accent.red "0.30"};
            }

            #bluetooth {
              color: ${colors.accent.blue};
            }

            #bluetooth.disabled {
              color: ${colors.base.fg3};
            }

            #bluetooth.connected {
              color: ${colors.accent.cyan};
            }

            #pulseaudio {
              color: ${colors.accent.violetLight};
            }

            #pulseaudio.muted {
              color: ${colors.base.fg3};
              background: ${colors.hexToRgba colors.base.fg3 "0.08"};
            }

            #battery {
              color: ${colors.accent.green};
            }

            #battery.charging {
              color: ${colors.accent.cyanLight};
              background: linear-gradient(
                135deg,
                ${colors.hexToRgba colors.accent.cyan "0.16"},
                ${colors.hexToRgba colors.accent.green "0.14"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.32"};
            }

            #battery.warning:not(.charging) {
              color: ${colors.accent.yellow};
              background: ${colors.hexToRgba colors.accent.yellow "0.10"};
              border-color: ${colors.hexToRgba colors.accent.yellow "0.30"};
            }

            #battery.critical:not(.charging) {
              color: ${colors.accent.magentaLight};
              background: ${colors.hexToRgba colors.accent.magenta "0.14"};
              border-color: ${colors.hexToRgba colors.accent.magenta "0.36"};
              animation: pulse-magenta 1.6s infinite;
            }

            #tray {
              padding: 0 14px;
              background: linear-gradient(
                180deg,
                ${colors.hexToRgba colors.base.bg2 "0.90"},
                ${colors.hexToRgba colors.base.bg1 "0.80"}
              );
              border-color: ${colors.hexToRgba colors.accent.cyan "0.14"};
              margin-left: 6px;
            }

            #tray > * {
              padding: 0 4px;
              margin: 6px 2px;
              border-radius: 10px;
              transition: all ${toString colors.animation.fast}ms cubic-bezier(${colors.animation.bezier.snappy});
            }

            #tray > .passive {
              -gtk-icon-effect: none;
              opacity: 0.70;
            }

            #tray > .passive:hover {
              opacity: 1;
              background: ${colors.hexToRgba colors.accent.cyan "0.10"};
            }

            #tray > .active {
              background: ${colors.hexToRgba colors.accent.cyan "0.08"};
            }

            #tray > .needs-attention {
              -gtk-icon-effect: highlight;
              background: ${colors.hexToRgba colors.accent.magenta "0.15"};
              border: 1px solid ${colors.hexToRgba colors.accent.magenta "0.34"};
            }

            #tray menu {
              background: ${colors.hexToRgba colors.base.bg1 "0.96"};
              border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.26"};
              border-radius: ${toString colors.radius.medium}px;
              padding: 6px;
              box-shadow: 0 8px 32px ${colors.shadow.dark};
            }

            #tray menu menuitem {
              padding: 10px 14px;
              border-radius: ${toString colors.radius.small}px;
              margin: 2px 0;
            }

            #tray menu menuitem:hover {
              background: ${colors.hexToRgba colors.accent.cyan "0.18"};
            }

            #tray menu separator {
              background: ${colors.hexToRgba colors.base.fg0 "0.16"};
              margin: 4px 8px;
            }
          '';
        }; # End programs.waybar

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
            local text="󰻠 ''${cpu_usage}% · 󰍛 ''${mem_percent}%"
            [[ $cpu_temp -gt 0 ]] && text+=" · 󰔏 ''${cpu_temp}°"

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
            local text="󰢮 ''${temp}° · ''${util}%"

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
  }; # End config
}
