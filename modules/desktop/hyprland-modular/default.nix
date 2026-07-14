# ============================================
# Hyprland Modular Framework
# ============================================
# A composable, extensible Hyprland configuration system
# with feature flags, theming, profiles, and plugin support.
#
# Usage in your flake:
#   imports = [ ./modules/desktop/hyprland ];
#   kernelcore.desktop.hyprland-modular = {
#     enable = true;
#     theme = "glassmorphism";
#     profile = "work";
#     features.blur = true;
#   };
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.desktop.hyprland-modular;

  # Import library functions
  hyprLib = import ./lib { inherit lib pkgs; };

  # Import subsystems
  themes = import ./themes { inherit lib pkgs hyprLib; };
  profiles = import ./profiles {
    inherit
      lib
      pkgs
      hyprLib
      cfg
      ;
  };
  bindings = import ./bindings {
    inherit
      lib
      pkgs
      hyprLib
      cfg
      ;
  };
  rules = import ./rules {
    inherit
      lib
      pkgs
      hyprLib
      cfg
      ;
  };
  plugins = import ./plugins { inherit lib pkgs cfg; };

  # Resolve the active theme
  activeTheme = themes.${cfg.theme} or themes.glassmorphism;

  # Resolve the active profile
  activeProfile = profiles.${cfg.profile} or profiles.default;

  # Merge configurations with precedence: user > profile > theme > defaults
  finalConfig = lib.recursiveUpdate (lib.recursiveUpdate activeTheme.settings activeProfile.settings) cfg.extraSettings;

in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      # Keep the active Hyprland config on hyprland.conf. Home Manager 26.05
      # defaults to Lua, but Hyprland still prefers an existing .conf first.
      configType = "hyprlang";
      xwayland.enable = true;
      systemd.enable = true;

      plugins = lib.optionals cfg.plugins.enable (plugins.resolvePlugins cfg.plugins.list);

      settings = lib.mkMerge [
        # Monitor configuration
        {
          monitor = map (
            m:
            "${m.name},${m.resolution},${m.position},${toString m.scale}"
            + lib.optionalString (m.transform != 0) ",transform,${toString m.transform}"
          ) cfg.monitors;
        }

        # Input configuration
        {
          input = {
            kb_layout = cfg.input.keyboard.layout;
            kb_variant = cfg.input.keyboard.variant;
            kb_options = cfg.input.keyboard.options;
            follow_mouse = 1;
            sensitivity = cfg.input.mouse.sensitivity;
            accel_profile = cfg.input.mouse.accelProfile;
            touchpad = lib.mkIf cfg.input.touchpad.enable {
              natural_scroll = cfg.input.touchpad.naturalScroll;
              disable_while_typing = cfg.input.touchpad.disableWhileTyping;
              tap-to-click = cfg.input.touchpad.tapToClick;
            };
          };
        }

        # Theme settings (general, decoration, animations)
        activeTheme.settings

        # Profile overrides (performance, animations)
        activeProfile.settings

        # Feature flag overrides
        (lib.mkIf (!cfg.features.blur) {
          decoration.blur.enabled = false;
        })
        (lib.mkIf (!cfg.features.animations) {
          animations.enabled = false;
        })
        (lib.mkIf (!cfg.features.shadows) {
          decoration.shadow.enabled = false;
        })
        (lib.mkIf (!cfg.features.rounding) {
          decoration.rounding = 0;
        })
        (lib.mkIf (!cfg.features.dimInactive) {
          decoration.dim_inactive = false;
        })

        # VRR
        {
          misc = {
            vrr = if cfg.features.vrr then 1 else 0;
          };
        }

        # Window swallowing
        (lib.mkIf cfg.features.windowSwallowing {
          misc = {
            enable_swallow = true;
            swallow_regex = "^(${cfg.terminal.primary}|${cfg.terminal.secondary})$";
          };
        })

        # Variables
        {
          "$mainMod" = cfg.mainMod;
          "$terminal" = cfg.terminal.primary;
          "$terminal2" = cfg.terminal.secondary;
          "$launcher" = cfg.launcher;
          "$fileManager" = cfg.fileManager;
        }

        # Autostart
        {
          exec-once = lib.flatten [
            # Status bar
            "waybar"

            # Notifications
            (lib.optional cfg.features.notifications "mako")

            # Network applet
            "nm-applet --indicator"

            # Clipboard
            (lib.optionals cfg.features.clipboard [
              "wl-paste --type text --watch cliphist store"
              "wl-paste --type image --watch cliphist store"
            ])

            # User autostart
            cfg.autostart
          ];
        }

        # Keybindings
        (lib.mkIf cfg.keybindings.enable {
          bind = lib.flatten [
            (bindings.resolveModules cfg.keybindings.modules)
            cfg.keybindings.extraBinds
          ];
          binde = lib.flatten [
            bindings.repeatBinds
            cfg.keybindings.extraBindE
          ];
          bindm = bindings.mouseBinds;
        })

        # Window rules
        (lib.mkIf cfg.windowRules.enable {
          windowrule = lib.flatten [
            (rules.resolveCategories cfg.windowRules.categories)
            cfg.windowRules.extra
          ];
          layerrule = rules.layerRules;
        })

        # Workspace special
        {
          workspace = cfg.workspaces.persistentRules;
        }

        # Misc common settings
        {
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            mouse_move_enables_dpms = true;
            key_press_enables_dpms = true;
            focus_on_activate = true;
            animate_manual_resizes = true;
            animate_mouse_windowdragging = true;
            layers_hog_keyboard_focus = true;
            initial_workspace_tracking = 2;
            middle_click_paste = false;
            background_color = "0x000000";
          };

          cursor = {
            no_hardware_cursors = true;
            enable_hyprcursor = true;
            hide_on_key_press = true;
            inactive_timeout = 5;
          };

          debug = {
            disable_logs = true;
            disable_time = true;
            vfr = true;
          };

          dwindle = {
            preserve_split = true;
            force_split = 2;
            smart_split = true;
            smart_resizing = true;
          };

          master = {
            new_status = "master";
            mfact = 0.55;
          };

          general = {
            layout = "dwindle";
            allow_tearing = false;
            resize_on_border = true;
          };
        }

        # User extra settings (highest precedence)
        cfg.extraSettings
      ];

      extraConfig = cfg.extraConfig;
    };

    xdg.configFile."hypr/hyprland.conf".force = true;

    # Hypridle configuration
    services.hypridle = lib.mkIf cfg.features.idleManagement {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
        };
        listener = lib.flatten [
          [
            {
              timeout = cfg.idle.lockTimeout;
              on-timeout = "hyprlock";
            }
          ]
          [
            {
              timeout = cfg.idle.dpmsTimeout;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ]
          (lib.optional (cfg.idle.suspendTimeout != null) {
            timeout = cfg.idle.suspendTimeout;
            on-timeout = "systemctl suspend";
          })
        ];
      };
    };

    # ==========================================
    # XDG DESKTOP PORTALS
    # ==========================================
    # Enable file picker and other desktop integration
    xdg.portal = lib.mkIf cfg.features.xdgPortals {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      config = {
        common = {
          default = [ "gtk" ];
        };
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
      xdgOpenUsePortal = true;
    };
  };
}
