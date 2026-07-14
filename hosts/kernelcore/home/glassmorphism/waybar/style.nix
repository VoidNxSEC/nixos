# Waybar glassmorphism — bar CSS (design tokens from colors.nix)
# (part of the waybar.nix split; see ./default.nix)
{
  config,
  osConfig,
  lib,
  ...
}:

let
  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;
in
{
  config = {
    programs.waybar =
      lib.mkIf (osConfig.kernelcore.desktop.hyprland.enable || osConfig.programs.niri.enable)
        {
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
              border-radius: 14px;
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
              margin: 0 3px;
              padding: 0 12px;
              border-radius: 12px;
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
              min-width: 120px;
              padding-left: 14px;
              padding-right: 14px;
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
              min-width: 180px;
              padding: 0 18px;
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

            #custom-spooknix.active,
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
        };
  };
}
