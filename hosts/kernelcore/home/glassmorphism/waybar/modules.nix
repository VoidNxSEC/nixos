# Waybar glassmorphism — per-module bar definitions
# (part of the waybar.nix split; see ./default.nix)
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
  spooknixWaybarEnabled = lib.attrByPath [ "programs" "spooknix" "waybar" "enable" ] false config;

  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;
in
{
  config = {
    programs.waybar =
      lib.mkIf (osConfig.kernelcore.desktop.hyprland.enable || osConfig.programs.niri.enable)
        {
          settings = {
            mainBar = {
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
        };
  };
}
