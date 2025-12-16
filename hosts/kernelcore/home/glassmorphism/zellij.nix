# ============================================
# Zellij Terminal Multiplexer - Glassmorphism Theme
# ============================================
# Premium terminal multiplexer with:
# - Transparent pane backgrounds
# - Electric cyan/magenta/violet accents
# - Styled tab bar and status line
# - Vim-like keybindings
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Reference glassmorphism design tokens (single source of truth)
  colors = config.glassmorphism.colors;
in
{
  programs.zellij = {
    enable = true;
    enableBashIntegration = false; # Don't auto-start, we launch explicitly
    enableZshIntegration = false;

    settings = {
      # ============================================
      # GENERAL SETTINGS
      # ============================================
      default_shell = "zsh";
      default_layout = "default";
      default_mode = "normal";

      # Session management
      on_force_close = "detach";
      session_serialization = true;
      pane_viewport_serialization = true;
      scrollback_lines_to_serialize = 10000;

      # Mouse support
      mouse_mode = true;
      scroll_buffer_size = 50000;

      # Copy behavior
      copy_command = "wl-copy";
      copy_clipboard = "primary";
      copy_on_select = true;

      # Scrollback editor
      scrollback_editor = "nvim";

      # Mirror session (for streaming/pairing)
      mirror_session = false;

      # Auto layout (adjusts based on pane count)
      auto_layout = true;

      # Styling options
      styled_underlines = true;

      # Performance
      serialization_interval = 1; # Seconds between saves
      disable_session_metadata = false;

      # Simplified UI
      simplified_ui = false;
      pane_frames = true;

      # Theme reference (defined in themes section)
      theme = "glassmorphism";

      # Layout directory
      layout_dir = "${config.home.homeDirectory}/.config/zellij/layouts";

      # ============================================
      # KEYBINDINGS
      # ============================================
      keybinds = {
        # Unbind defaults we want to override
        unbind = [ "Ctrl g" ];

        # Normal mode
        normal = {
          # Pane navigation (vim-like)
          "bind \"Alt h\"" = {
            MoveFocus = "Left";
          };
          "bind \"Alt l\"" = {
            MoveFocus = "Right";
          };
          "bind \"Alt k\"" = {
            MoveFocus = "Up";
          };
          "bind \"Alt j\"" = {
            MoveFocus = "Down";
          };

          # Pane resizing
          "bind \"Alt H\"" = {
            Resize = "Increase Left";
          };
          "bind \"Alt L\"" = {
            Resize = "Increase Right";
          };
          "bind \"Alt K\"" = {
            Resize = "Increase Up";
          };
          "bind \"Alt J\"" = {
            Resize = "Increase Down";
          };

          # Tab navigation
          "bind \"Alt 1\"" = {
            GoToTab = 1;
          };
          "bind \"Alt 2\"" = {
            GoToTab = 2;
          };
          "bind \"Alt 3\"" = {
            GoToTab = 3;
          };
          "bind \"Alt 4\"" = {
            GoToTab = 4;
          };
          "bind \"Alt 5\"" = {
            GoToTab = 5;
          };
          "bind \"Alt 6\"" = {
            GoToTab = 6;
          };
          "bind \"Alt 7\"" = {
            GoToTab = 7;
          };
          "bind \"Alt 8\"" = {
            GoToTab = 8;
          };
          "bind \"Alt 9\"" = {
            GoToTab = 9;
          };

          # Quick actions
          "bind \"Alt n\"" = {
            NewPane = "Down";
          };
          "bind \"Alt v\"" = {
            NewPane = "Right";
          };
          "bind \"Alt t\"" = {
            NewTab = { };
          };
          "bind \"Alt x\"" = {
            CloseFocus = { };
          };
          "bind \"Alt f\"" = {
            ToggleFocusFullscreen = { };
          };
          "bind \"Alt z\"" = {
            TogglePaneFrames = { };
          };
          "bind \"Alt s\"" = {
            ToggleFloatingPanes = { };
          };

          # Sync input to all panes
          "bind \"Alt a\"" = {
            ToggleActiveSyncTab = { };
          };
        };

        # Locked mode (for passthrough to apps like vim)
        locked = {
          "bind \"Ctrl g\"" = {
            SwitchToMode = "Normal";
          };
        };

        # Pane mode
        pane = {
          "bind \"h\"" = {
            MoveFocus = "Left";
          };
          "bind \"l\"" = {
            MoveFocus = "Right";
          };
          "bind \"k\"" = {
            MoveFocus = "Up";
          };
          "bind \"j\"" = {
            MoveFocus = "Down";
          };
          "bind \"n\"" = {
            NewPane = "Down";
          };
          "bind \"v\"" = {
            NewPane = "Right";
          };
          "bind \"x\"" = {
            CloseFocus = { };
          };
          "bind \"f\"" = {
            ToggleFocusFullscreen = { };
          };
          "bind \"z\"" = {
            TogglePaneFrames = { };
          };
          "bind \"w\"" = {
            ToggleFloatingPanes = { };
          };
          "bind \"e\"" = {
            TogglePaneEmbedOrFloating = { };
          };
          "bind \"r\"" = {
            SwitchToMode = "RenamePane";
            PaneNameInput = [ 0 ];
          };
        };

        # Tab mode
        tab = {
          "bind \"h\"" = {
            GoToPreviousTab = { };
          };
          "bind \"l\"" = {
            GoToNextTab = { };
          };
          "bind \"n\"" = {
            NewTab = { };
          };
          "bind \"x\"" = {
            CloseTab = { };
          };
          "bind \"s\"" = {
            ToggleActiveSyncTab = { };
          };
          "bind \"r\"" = {
            SwitchToMode = "RenameTab";
            TabNameInput = [ 0 ];
          };
          "bind \"1\"" = {
            GoToTab = 1;
          };
          "bind \"2\"" = {
            GoToTab = 2;
          };
          "bind \"3\"" = {
            GoToTab = 3;
          };
          "bind \"4\"" = {
            GoToTab = 4;
          };
          "bind \"5\"" = {
            GoToTab = 5;
          };
        };

        # Resize mode
        resize = {
          "bind \"h\"" = {
            Resize = "Increase Left";
          };
          "bind \"l\"" = {
            Resize = "Increase Right";
          };
          "bind \"k\"" = {
            Resize = "Increase Up";
          };
          "bind \"j\"" = {
            Resize = "Increase Down";
          };
          "bind \"H\"" = {
            Resize = "Decrease Left";
          };
          "bind \"L\"" = {
            Resize = "Decrease Right";
          };
          "bind \"K\"" = {
            Resize = "Decrease Up";
          };
          "bind \"J\"" = {
            Resize = "Decrease Down";
          };
          "bind \"=\"" = {
            Resize = "Increase";
          };
          "bind \"-\"" = {
            Resize = "Decrease";
          };
        };

        # Move mode
        move = {
          "bind \"h\"" = {
            MovePane = "Left";
          };
          "bind \"l\"" = {
            MovePane = "Right";
          };
          "bind \"k\"" = {
            MovePane = "Up";
          };
          "bind \"j\"" = {
            MovePane = "Down";
          };
          "bind \"n\"" = {
            MovePane = { };
          };
          "bind \"Tab\"" = {
            MovePane = { };
          };
        };

        # Search mode
        search = {
          "bind \"n\"" = {
            Search = "Down";
          };
          "bind \"N\"" = {
            Search = "Up";
          };
          "bind \"c\"" = {
            SearchToggleOption = "CaseSensitivity";
          };
          "bind \"w\"" = {
            SearchToggleOption = "Wrap";
          };
          "bind \"o\"" = {
            SearchToggleOption = "WholeWord";
          };
        };

        # Session mode
        session = {
          "bind \"d\"" = {
            Detach = { };
          };
          # Plugin launcher removed - requires plugin path specification
        };

        # Note: shared_except removed due to KDL syntax issues with home-manager
        # Keybindings are defined per-mode instead
      };

      # ============================================
      # THEMES - Glassmorphism
      # ============================================
      themes = {
        glassmorphism = {
          # UI frame colors (dark glassmorphism base)
          fg = colors.base.fg1;
          bg = colors.base.bg0; # Use darkest background instead of transparent

          # Base colors
          black = colors.base.bg3;
          white = colors.base.fg0;

          # Accent colors matching glassmorphism palette
          red = colors.accent.magenta; # Using magenta for red
          green = colors.accent.green;
          yellow = colors.accent.yellow;
          blue = colors.accent.blue;
          magenta = colors.accent.violet; # Using violet for magenta
          cyan = colors.accent.cyan; # Primary accent
          orange = colors.accent.orange;
        };
      };

      # ============================================
      # UI CONFIGURATION
      # ============================================
      ui = {
        pane_frames = {
          rounded_corners = true;
          hide_session_name = false;
        };
      };

      # ============================================
      # PLUGINS
      # ============================================
      plugins = {
        tab-bar = {
          path = "tab-bar";
        };
        status-bar = {
          path = "status-bar";
        };
        strider = {
          path = "strider";
        };
        compact-bar = {
          path = "compact-bar";
        };
        session-manager = {
          path = "session-manager";
        };
      };
    };
  };

  # ============================================
  # ZELLIJ LAYOUTS
  # ============================================
  home.file = {
    # Default layout - clean workspace
    ".config/zellij/layouts/default.kdl".text = ''
      // ============================================
      // Glassmorphism Default Layout
      // ============================================

      layout {
        default_tab_template {
          // Bottom tab bar with glassmorphism styling
          pane size=1 borderless=true {
            plugin location="tab-bar"
          }
          children
          // Status bar at bottom
          pane size=2 borderless=true {
            plugin location="status-bar"
          }
        }

        // Initial tab setup
        tab name="main" focus=true {
          pane
        }
      }
    '';

    # Development layout - split panes for coding
    ".config/zellij/layouts/dev.kdl".text = ''
      // ============================================
      // Glassmorphism Development Layout
      // ============================================
      // Editor on left, terminal on right (top/bottom split)

      layout {
        default_tab_template {
          pane size=1 borderless=true {
            plugin location="tab-bar"
          }
          children
          pane size=2 borderless=true {
            plugin location="status-bar"
          }
        }

        tab name="code" focus=true {
          pane split_direction="vertical" {
            // Main editor pane (60% width)
            pane size="60%" name="editor"
            // Right side split (40% width)
            pane split_direction="horizontal" {
              // Terminal for commands (70% height)
              pane size="70%" name="terminal"
              // Watch/test output (30% height)
              pane name="watch"
            }
          }
        }

        tab name="git" {
          pane command="lazygit"
        }

        tab name="logs" {
          pane split_direction="horizontal" {
            pane name="log1"
            pane name="log2"
          }
        }
      }
    '';

    # Minimal layout - no status bars
    ".config/zellij/layouts/minimal.kdl".text = ''
      // ============================================
      // Glassmorphism Minimal Layout
      // ============================================
      // Clean layout without bars

      layout {
        tab name="term" focus=true {
          pane borderless=true
        }
      }
    '';

    # Monitoring layout - multiple panes for logs/monitoring
    ".config/zellij/layouts/monitor.kdl".text = ''
      // ============================================
      // Glassmorphism Monitoring Layout
      // ============================================
      // Grid layout for multiple log/status views

      layout {
        default_tab_template {
          pane size=1 borderless=true {
            plugin location="compact-bar"
          }
          children
        }

        tab name="monitor" focus=true {
          pane split_direction="horizontal" {
            pane split_direction="vertical" {
              pane name="sys" command="btop"
              pane name="net" command="bandwhich" {
                start_suspended true
              }
            }
            pane split_direction="vertical" {
              pane name="logs1"
              pane name="logs2"
            }
          }
        }
      }
    '';

    # Pair programming layout
    ".config/zellij/layouts/pair.kdl".text = ''
      // ============================================
      // Glassmorphism Pair Programming Layout
      // ============================================
      // Side-by-side terminals for collaboration

      layout {
        default_tab_template {
          pane size=1 borderless=true {
            plugin location="tab-bar"
          }
          children
          pane size=2 borderless=true {
            plugin location="status-bar"
          }
        }

        tab name="pair" focus=true {
          pane split_direction="vertical" {
            pane name="user1" borderless=false
            pane name="user2" borderless=false
          }
        }
      }
    '';
  };

  # ============================================
  # FORCE OVERWRITE EXISTING CONFIG
  # ============================================
  # Force home-manager to overwrite any existing unmanaged zellij config
  xdg.configFile."zellij/config.kdl".force = true;

  # ============================================
  # ADDITIONAL PACKAGES
  # ============================================
  home.packages = with pkgs; [
    # For clipboard support
    wl-clipboard

    # Optional utilities for layouts
    lazygit
    bandwhich
    btop
  ];
}
