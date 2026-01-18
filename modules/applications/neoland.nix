{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.neoland;
in
{
  options.programs.neoland = {
    enable = mkEnableOption "Neoland AI Agent Interface";

    serverPort = mkOption {
      type = types.port;
      default = 50051;
      description = "Internal gRPC port";
    };

    restPort = mkOption {
      type = types.port;
      default = 3001;
      description = "Internal REST API port";
    };
  };

  config = mkIf cfg.enable {
    # Environment variables for default connection
    environment.variables = {
      NEOLAND_GRPC_PORT = toString cfg.serverPort;
      NEOLAND_REST_PORT = toString cfg.restPort;
    };

    # System Packages
    # Assumes 'neoland' is provided by flake overlay
    environment.systemPackages = [ pkgs.neoland ];

    # Hyprland Integration Rules
    # Defines Neoland as a floating scratchpad window with special effects
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "float,class:^(neoland)$"
        "size 1000 800,class:^(neoland)$"
        "center,class:^(neoland)$"
        "opacity 0.95 override 0.90 override,class:^(neoland)$"
        "workspace special:scratch_neoland,class:^(neoland)$"
        "dimaround,class:^(neoland)$"
        "animation popin,class:^(neoland)$"
      ];

      bind = [
        # Toggle Neoland scratchpad with Super+N
        "SUPER, N, togglespecialworkspace, scratch_neoland"
      ];
    };
  };
}
