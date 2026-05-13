# ============================================
# Hyprland Modular - Plugin System
# ============================================
# Plugin management for Hyprland plugins:
# - hyprexpo: Workspace overview
# - hyprspace: Alternative overview
# - hyprbars: Window title bars
# - hyprtrails: Cursor trails
# - borders-plus-plus: Enhanced borders
# - csgo-vulkan-fix: Game-specific fix
# ============================================
{
  lib,
  pkgs,
  cfg,
}:

let
  # Helper to get plugin package
  getPlugin =
    name:
    if builtins.hasAttr name pkgs.hyprlandPlugins then
      pkgs.hyprlandPlugins.${name}
    else
      throw "Hyprland plugin '${name}' not found in nixpkgs";

  # Plugin configurations
  pluginConfigs = {
    # ----------------------------------------
    # HYPREXPO - Workspace overview (like MacOS)
    # ----------------------------------------
    hyprexpo = {
      package = getPlugin "hyprexpo";
      settings = {
        "plugin:hyprexpo" = {
          columns = 3;
          gap_size = 5;
          bg_col = "rgb(111111)";
          workspace_method = "first 1";
          enable_gesture = true;
          gesture_fingers = 3;
          gesture_distance = 300;
          gesture_positive = true;
        };
      };
      binds = [
        "$mainMod, grave, hyprexpo:expo, toggle"
      ];
    };

    # ----------------------------------------
    # HYPRSPACE - Alternative workspace overview
    # ----------------------------------------
    hyprspace = {
      package = getPlugin "Hyprspace";
      settings = {
        "plugin:overview" = {
          panelHeight = 200;
          panelBorderWidth = 2;
          workspaceActiveBorder = "rgba(00d4ffff)";
          workspaceInactiveBorder = "rgba(22222eff)";
          workspaceBorderSize = 3;
          dragAlpha = 0.8;
          centerAligned = true;
          hideBackgroundLayers = true;
          hideTopLayers = true;
          showNewWorkspace = true;
          autoDrag = true;
          exitOnSwitch = true;
        };
      };
      binds = [
        "$mainMod, O, overview:toggle"
      ];
    };

    # ----------------------------------------
    # HYPRBARS - Window title bars
    # ----------------------------------------
    hyprbars = {
      package = getPlugin "hyprbars";
      settings = {
        "plugin:hyprbars" = {
          bar_height = 24;
          bar_color = "rgb(1e1e2e)";
          bar_text_size = 10;
          bar_text_font = "JetBrains Mono Nerd Font";
          bar_part_of_window = true;
          bar_precedence_over_border = true;

          hyprbars-button = [
            # color, size, icon, on-click
            "rgb(ff6b6b), 14, , hyprctl dispatch killactive"
            "rgb(feca57), 14, , hyprctl dispatch fullscreen 1"
            "rgb(1dd1a1), 14, , hyprctl dispatch togglefloating"
          ];
        };
      };
      binds = [ ];
    };

    # ----------------------------------------
    # HYPRTRAILS - Cursor trails
    # ----------------------------------------
    hyprtrails = {
      package = getPlugin "hyprtrails";
      settings = {
        "plugin:hyprtrails" = {
          color = "rgba(00d4ffaa)";
          bezier_step = 0.025;
          points_per_step = 2;
          history_points = 20;
          history_step = 2;
        };
      };
      binds = [ ];
    };

    # ----------------------------------------
    # BORDERS-PLUS-PLUS - Enhanced borders
    # ----------------------------------------
    borders-plus-plus = {
      package = getPlugin "borders-plus-plus";
      settings = {
        "plugin:borders-plus-plus" = {
          add_borders = 1;
          "col.border_1" = "rgb(00d4ff)";
          "col.border_2" = "rgb(7c3aed)";
          border_size_1 = 2;
          border_size_2 = 2;
          natural_rounding = true;
        };
      };
      binds = [ ];
    };

    # ----------------------------------------
    # CSGO-VULKAN-FIX - Game-specific fix
    # ----------------------------------------
    csgo-vulkan-fix = {
      package = getPlugin "csgo-vulkan-fix";
      settings = {
        "plugin:csgo-vulkan-fix" = {
          res_w = 1920;
          res_h = 1080;
          class = "cs2";
        };
      };
      binds = [ ];
    };
  };

in
{
  # ==========================================
  # RESOLVE PLUGINS - Get packages for enabled plugins
  # ==========================================
  resolvePlugins =
    pluginList:
    map (
      name:
      if builtins.hasAttr name pluginConfigs then
        pluginConfigs.${name}.package
      else
        throw "Unknown plugin: ${name}"
    ) pluginList;

  # ==========================================
  # GET PLUGIN SETTINGS - Merge settings for enabled plugins
  # ==========================================
  getPluginSettings =
    pluginList:
    lib.mkMerge (
      map (
        name: if builtins.hasAttr name pluginConfigs then pluginConfigs.${name}.settings else { }
      ) pluginList
    );

  # ==========================================
  # GET PLUGIN BINDS - Get keybindings for enabled plugins
  # ==========================================
  getPluginBinds =
    pluginList:
    lib.flatten (
      map (
        name: if builtins.hasAttr name pluginConfigs then pluginConfigs.${name}.binds else [ ]
      ) pluginList
    );

  # ==========================================
  # AVAILABLE PLUGINS - List available plugins
  # ==========================================
  availablePlugins = builtins.attrNames pluginConfigs;

  # ==========================================
  # PLUGIN DESCRIPTIONS
  # ==========================================
  pluginDescriptions = {
    hyprexpo = "Workspace overview similar to macOS Mission Control";
    hyprspace = "Alternative workspace overview with customizable panel";
    hyprbars = "Window title bars with customizable buttons";
    hyprtrails = "Cursor trail effects";
    borders-plus-plus = "Additional customizable border layers";
    csgo-vulkan-fix = "Fix for CS2/CSGO Vulkan rendering issues";
  };
}
