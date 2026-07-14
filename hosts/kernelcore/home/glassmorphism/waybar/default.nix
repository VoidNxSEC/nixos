# ============================================
# Waybar - Glassmorphism Status Bar (aggregator)
# ============================================
# Phase 5 split (previously a single 1402-line waybar.nix):
# - default.nix  → enable + bar geometry + module layout
# - modules.nix  → per-module definitions (workspaces, clock, custom/*)
# - style.nix    → glassmorphism CSS (design tokens)
# - scripts.nix  → monitoring scripts (~/.config/waybar/scripts/)
# ============================================

{
  config,
  osConfig,
  lib,
  ...
}:

let
  spooknixWaybarEnabled = lib.attrByPath [ "programs" "spooknix" "waybar" "enable" ] false config;
in
{
  imports = [
    ./modules.nix
    ./style.nix
    ./scripts.nix
  ];

  config = {
    programs.waybar =
      lib.mkIf (osConfig.kernelcore.desktop.hyprland.enable || osConfig.programs.niri.enable)
        {
          enable = true;

          settings = {
            mainBar = {
              layer = "top";
              position = "top";
              height = 44;
              spacing = 6;
              margin-top = 6;
              margin-left = 12;
              margin-right = 12;
              margin-bottom = 0;

              # Module layout (compositor-agnostic)
              modules-left =
                if osConfig.kernelcore.desktop.hyprland.enable then
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
            };
          };
        };
  };
}
