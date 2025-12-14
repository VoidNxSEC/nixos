# Swissknife Debug Tools Integration
# Professional debugging, monitoring, and system health tools
# Note: Tools come from inputs.swissknife flake (git+file:///home/kernelcore/dev/projects/swissknife)
{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.kernelcore.swissknife = {
    enable = lib.mkEnableOption "Swissknife Debug Tools";

    enableSystray = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Swiss Monitor systray indicator on Wayland";
    };
  };

  config = lib.mkIf config.kernelcore.swissknife.enable {
    # Install swissknife tools from flake input
    # pkgs.swissknife-tools is defined in flake.nix via overlay
    environment.systemPackages =
      with pkgs.swissknife-tools;
      [
        swiss-rebuild
        swiss-doctor
        swiss-monitor
      ]
      ++ lib.optionals config.kernelcore.swissknife.enableSystray [
        swiss-systray
      ];

    # Handy aliases
    environment.shellAliases = {
      # Quick access (using different names to avoid conflicts with rebuild-advanced.nix)
      doctor = "sudo swiss-doctor";
      swiss = "sudo swiss-rebuild"; # Renamed from 'rebuild' to avoid conflict

      # Monitor aliases
      monitor = "swiss-monitor";
      soc = "swiss-monitor";
      soc-tray = "swiss-systray &";
    };

    # Autostart systray on Hyprland login
    # User can add to their Hyprland config: exec-once = swiss-systray
  };
}
