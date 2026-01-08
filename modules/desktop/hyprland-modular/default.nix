# ============================================
# Hyprland Modular Framework
# ============================================
# A composable, extensible Hyprland configuration system
# with feature flags, theming, profiles, and plugin support.
#
# Usage in your flake:
#   imports = [ ./modules/desktop/hyprland ];
#   programs.hyprland-modular = {
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
  cfg = config.programs.hyprland-modular;

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
  options.programs.hyprland-modular = {
    enable = lib.mkEnableOption "Hyprland Modular Framework";

    # ==========================================
    # THEME CONFIGURATION
    # ==========================================
    theme = lib.mkOption {
      type = lib.types.enum [
        "glassmorphism"
        "nord"
        "dracula"
        "catppuccin"
        "gruvbox"
        "tokyonight"
        "custom"
      ];
      default = "glassmorphism";
      description = "Visual theme preset for Hyprland";
    };

    customTheme = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            colors = lib.mkOption { type = lib.types.attrsOf lib.types.str; };
            opacity = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  active = lib.mkOption {
                    type = lib.types.float;
                    default = 0.95;
                  };
                  inactive = lib.mkOption {
                    type = lib.types.float;
                    default = 0.90;
                  };
                };
              };
            };
            blur = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  size = lib.mkOption {
                    type = lib.types.int;
                    default = 10;
                  };
                  passes = lib.mkOption {
                    type = lib.types.int;
                    default = 3;
                  };
                };
              };
            };
            rounding = lib.mkOption {
              type = lib.types.int;
              default = 12;
            };
          };
        }
      );
      default = null;
      description = "Custom theme definition (when theme = 'custom')";
    };

    # ==========================================
    # PROFILE CONFIGURATION
    # ==========================================
    profile = lib.mkOption {
      type = lib.types.enum [
        "default"
        "gaming"
        "work"
        "minimal"
        "presentation"
        "development"
        "streaming"
      ];
      default = "default";
      description = "Usage profile that adjusts animations, performance, etc.";
    };

    # ==========================================
    # FEATURE FLAGS
    # ==========================================
    features = {
      blur = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable window blur effects";
      };

      animations = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable window animations";
      };

      shadows = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable window shadows";
      };

      rounding = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable rounded corners";
      };

      vrr = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Variable Refresh Rate";
      };

      dimInactive = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Dim inactive windows";
      };

      windowSwallowing = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable terminal window swallowing";
      };

      clipboard = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable clipboard manager (cliphist)";
      };

      screenshotTools = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable screenshot utilities (grim, slurp, swappy)";
      };

      idleManagement = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable hypridle for screen lock/dpms";
      };

      notifications = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable notification daemon (mako)";
      };

      xdgPortals = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable XDG desktop portals";
      };
    };

    # ==========================================
    # MONITOR CONFIGURATION
    # ==========================================
    monitors = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Monitor identifier (empty for auto)";
            };
            resolution = lib.mkOption {
              type = lib.types.str;
              default = "preferred";
              description = "Resolution (e.g., '1920x1080@144')";
            };
            position = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              description = "Position (e.g., '0x0' or 'auto')";
            };
            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "Display scale factor";
            };
            vrr = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = "Per-monitor VRR override";
            };
            transform = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Rotation (0=normal, 1=90°, 2=180°, 3=270°)";
            };
          };
        }
      );
      default = [
        {
          resolution = "1920x1080@144";
          position = "auto";
          scale = 1.0;
        }
      ];
      description = "Monitor configurations";
    };

    # ==========================================
    # INPUT CONFIGURATION
    # ==========================================
    input = {
      keyboard = {
        layout = lib.mkOption {
          type = lib.types.str;
          default = "br";
          description = "Keyboard layout";
        };
        variant = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Keyboard variant";
        };
        options = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "XKB options (e.g., 'caps:escape')";
        };
      };

      mouse = {
        sensitivity = lib.mkOption {
          type = lib.types.float;
          default = 0.0;
          description = "Mouse sensitivity (-1.0 to 1.0)";
        };
        accelProfile = lib.mkOption {
          type = lib.types.enum [
            "flat"
            "adaptive"
            "custom"
          ];
          default = "flat";
          description = "Mouse acceleration profile";
        };
        naturalScroll = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable natural scrolling for mouse";
        };
      };

      touchpad = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable touchpad";
        };
        naturalScroll = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable natural scrolling";
        };
        tapToClick = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable tap-to-click";
        };
        disableWhileTyping = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Disable touchpad while typing";
        };
      };
    };

    # ==========================================
    # TERMINAL CONFIGURATION
    # ==========================================
    terminal = {
      primary = lib.mkOption {
        type = lib.types.str;
        default = "kitty";
        description = "Primary terminal emulator";
      };
      secondary = lib.mkOption {
        type = lib.types.str;
        default = "alacritty";
        description = "Secondary/fallback terminal";
      };
      multiplexer = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "zellij"
            "tmux"
            "none"
          ]
        );
        default = "zellij";
        description = "Terminal multiplexer to auto-attach";
      };
    };

    # ==========================================
    # APPLICATION LAUNCHERS
    # ==========================================
    launcher = lib.mkOption {
      type = lib.types.enum [
        "wofi"
        "rofi"
        "fuzzel"
        "tofi"
        "bemenu"
      ];
      default = "wofi";
      description = "Application launcher";
    };

    fileManager = lib.mkOption {
      type = lib.types.str;
      default = "nemo";
      description = "File manager application";
    };

    # ==========================================
    # KEYBINDING CONFIGURATION
    # ==========================================
    mainMod = lib.mkOption {
      type = lib.types.str;
      default = "SUPER";
      description = "Primary modifier key";
    };

    keybindings = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable default keybindings";
      };

      modules = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "core"
            "window"
            "workspace"
            "media"
            "screenshot"
            "power"
            "custom"
          ]
        );
        default = [
          "core"
          "window"
          "workspace"
          "media"
          "screenshot"
          "power"
        ];
        description = "Keybinding modules to enable";
      };

      extraBinds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional keybindings";
      };

      extraBindE = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional repeating keybindings";
      };
    };

    # ==========================================
    # WINDOW RULES
    # ==========================================
    windowRules = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable default window rules";
      };

      categories = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "development"
            "browsers"
            "fileManagers"
            "systemUtilities"
            "media"
            "productivity"
            "communication"
            "dialogs"
            "performance"
            "gaming"
          ]
        );
        default = [
          "development"
          "browsers"
          "fileManagers"
          "systemUtilities"
          "media"
          "productivity"
          "communication"
          "dialogs"
          "performance"
        ];
        description = "Window rule categories to enable";
      };

      extra = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional window rules";
      };
    };

    # ==========================================
    # WORKSPACE CONFIGURATION
    # ==========================================
    workspaces = {
      count = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Number of workspaces (1-10)";
      };

      specialWorkspaces = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption { type = lib.types.str; };
              key = lib.mkOption { type = lib.types.str; };
              modifiers = lib.mkOption {
                type = lib.types.str;
                default = "$mainMod";
              };
            };
          }
        );
        default = [
          {
            name = "magic";
            key = "S";
          }
        ];
        description = "Special workspace definitions";
      };

      persistentRules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Workspace rules (e.g., 'workspace 1, default:true')";
      };
    };

    # ==========================================
    # PLUGINS
    # ==========================================
    plugins = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland plugin support";
      };

      list = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "hyprexpo"
            "hyprspace"
            "hyprbars"
            "hyprtrails"
            "borders-plus-plus"
            "csgo-vulkan-fix"
          ]
        );
        default = [ ];
        description = "Plugins to enable";
      };
    };

    # ==========================================
    # IDLE & LOCK
    # ==========================================
    idle = {
      lockTimeout = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "Seconds before screen lock";
      };
      dpmsTimeout = lib.mkOption {
        type = lib.types.int;
        default = 600;
        description = "Seconds before display off";
      };
      suspendTimeout = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Seconds before suspend (null = disabled)";
      };
    };

    # ==========================================
    # AUTOSTART
    # ==========================================
    autostart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional programs to autostart";
    };

    # ==========================================
    # EXTRA SETTINGS (ESCAPE HATCH)
    # ==========================================
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional Hyprland settings (merged with generated config)";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw Hyprland config lines appended to settings";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
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

            # Polkit
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

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
          windowrulev2 = lib.flatten [
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
            vfr = true;
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
          };

          dwindle = {
            pseudotile = true;
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
  };
}
