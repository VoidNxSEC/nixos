# ============================================
# Alacritty Terminal Configuration
# ============================================
# Declarative configuration for Alacritty terminal emulator
# - Optimized for Zellij integration
# - Gruvbox Dark theme
# - Performance tuning for modern systems
# - URL hints and clipboard integration
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.alacritty = {
    enable = true;

    settings = {
      # ============================================
      # GENERAL SETTINGS
      # ============================================
      general = {
        live_config_reload = true;
        import = [ ];
      };

      # ============================================
      # ENVIRONMENT VARIABLES
      # ============================================
      env = {
        TERM = "alacritty";
        # Enable better color support
        COLORTERM = "truecolor";
      };

      # ============================================
      # WINDOW CONFIGURATION
      # ============================================
      window = {
        padding = {
          x = 14;
          y = 16;
        };
        dynamic_padding = true;
        decorations = "None";
        opacity = 0.94;
        blur = true; # Enable background blur (Wayland/compositor dependent)
        startup_mode = "Maximized";
        title = "Alacritty + Zellij";
        dynamic_title = true;

        # Window class for WM integration
        class = {
          general = "Alacritty";
          instance = "alacritty-main";
        };

        # Resize increments (helps with tiling WMs)
        resize_increments = true;
      };

      # ============================================
      # SCROLLING CONFIGURATION
      # ============================================
      scrolling = {
        history = 50000; # Large history for Zellij scrollback
        multiplier = 3;
      };

      # ============================================
      # FONT CONFIGURATION
      # ============================================
      font = {
        size = 13.5;

        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Medium";
        };

        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };

        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Medium Italic";
        };

        bold_italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold Italic";
        };

        # Fine-tune glyph rendering
        glyph_offset = {
          x = 0;
          y = 1;
        };
        offset = {
          x = 0;
          y = 2;
        };

        # Better anti-aliasing
        builtin_box_drawing = true;
      };

      # ============================================
      # CURSOR CONFIGURATION
      # ============================================
      cursor = {
        style = {
          shape = "Beam";
          blinking = "Always";
        };

        vi_mode_style = {
          shape = "Block";
          blinking = "Off";
        };

        thickness = 0.14;
        unfocused_hollow = false;
        blink_interval = 750;
        blink_timeout = 0; # Never stop blinking
      };

      # ============================================
      # SELECTION & CLIPBOARD
      # ============================================
      selection = {
        save_to_clipboard = true;
        semantic_escape_chars = ",│`|:\"' ()[]{}<>\\t";
      };

      # ============================================
      # BELL CONFIGURATION
      # ============================================
      bell = {
        animation = "EaseOutSine";
        duration = 120;
        color = "#fb4934"; # Gruvbox red
      };

      # ============================================
      # COLOR SCHEME - Gruvbox Dark
      # ============================================
      colors = {
        # Primary colors
        primary = {
          background = "#282828";
          foreground = "#ebdbb2";
        };

        # Cursor colors
        cursor = {
          text = "#282828";
          cursor = "#ebdbb2";
        };

        vi_mode_cursor = {
          text = "#282828";
          cursor = "#d79921";
        };

        # Selection colors
        selection = {
          text = "#282828";
          background = "#ebdbb2";
        };

        # Search colors
        search = {
          matches = {
            foreground = "#282828";
            background = "#d79921";
          };
          focused_match = {
            foreground = "#282828";
            background = "#fb4934";
          };
        };

        # Footer bar colors
        footer_bar = {
          background = "#3c3836";
          foreground = "#ebdbb2";
        };

        # Line indicator
        line_indicator = {
          foreground = "None";
          background = "None";
        };

        # Normal colors
        normal = {
          black = "#3c3836";
          red = "#cc241d";
          green = "#98971a";
          yellow = "#d79921";
          blue = "#458588";
          magenta = "#b16286";
          cyan = "#689d6a";
          white = "#a89984";
        };

        # Bright colors
        bright = {
          black = "#928374";
          red = "#fb4934";
          green = "#b8bb26";
          yellow = "#fabd2f";
          blue = "#83a598";
          magenta = "#d3869b";
          cyan = "#8ec07c";
          white = "#ebdbb2";
        };

        # Dim colors
        dim = {
          black = "#1d2021";
          red = "#9d0006";
          green = "#79740e";
          yellow = "#b57614";
          blue = "#076678";
          magenta = "#8f3f71";
          cyan = "#427b58";
          white = "#928374";
        };
      };

      # ============================================
      # TERMINAL CONFIGURATION
      # ============================================
      terminal = {
        # Full OSC52 support for clipboard
        osc52 = "CopyPaste";

        # Shell configuration
        shell = {
          program = "/run/current-system/sw/bin/zellij";
          args = [
            "attach"
            "--create"
            "main"
          ];
        };
      };

      # ============================================
      # MOUSE CONFIGURATION
      # ============================================
      mouse = {
        hide_when_typing = true;

        bindings = [
          {
            mouse = "Middle";
            action = "PasteSelection";
          }
          {
            mouse = "Right";
            mods = "Control";
            action = "Paste";
          }
        ];
      };

      # ============================================
      # DEBUG SETTINGS
      # ============================================
      debug = {
        render_timer = false;
        persistent_logging = false;
        log_level = "Warn";
        print_events = false;
        highlight_damage = false;
      };

      # ============================================
      # KEYBOARD BINDINGS
      # ============================================
      keyboard.bindings = [
        # ==========================================
        # Instance Management
        # ==========================================
        {
          key = "Return";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }

        # ==========================================
        # Vi Mode Toggle
        # ==========================================
        {
          key = "Space";
          mods = "Control|Shift";
          action = "ToggleViMode";
        }

        # ==========================================
        # Font Size Controls
        # ==========================================
        {
          key = "Plus";
          mods = "Control";
          action = "IncreaseFontSize";
        }
        {
          key = "Minus";
          mods = "Control";
          action = "DecreaseFontSize";
        }
        {
          key = "Key0";
          mods = "Control";
          action = "ResetFontSize";
        }

        # ==========================================
        # Fullscreen
        # ==========================================
        {
          key = "F11";
          action = "ToggleFullscreen";
        }

        # ==========================================
        # Copy/Paste
        # ==========================================
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "Insert";
          mods = "Shift";
          action = "PasteSelection";
        }

        # ==========================================
        # Search
        # ==========================================
        {
          key = "F";
          mods = "Control|Shift";
          action = "SearchForward";
        }
        {
          key = "B";
          mods = "Control|Shift";
          action = "SearchBackward";
        }

        # ==========================================
        # Clear Terminal
        # ==========================================
        {
          key = "L";
          mods = "Control";
          chars = "\\u000c";
        }

        # ==========================================
        # ENHANCEMENTS: Quick Actions
        # ==========================================
        {
          key = "N";
          mods = "Control|Shift";
          action = "CreateNewWindow";
        }
        {
          key = "Q";
          mods = "Control|Shift";
          action = "Quit";
        }
      ];

      # ============================================
      # HINTS CONFIGURATION
      # ============================================
      hints = {
        enabled = [
          {
            # URL detection and opening
            regex = "(ipfs:|ipns:|magnet:|mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^\\\\u0000-\\\\u001f\\\\u007f-\\\\u009f<>\"\\\\\\\\s{-}\\\\\\\\^⟨⟩`]+";
            hyperlinks = true;
            post_processing = true;
            action = "Copy";

            mouse = {
              enabled = true;
              mods = "None";
            };

            binding = {
              key = "U";
              mods = "Control|Shift";
            };
          }
          {
            # IP address detection
            regex = "\\\\b(?:[0-9]{1,3}\\\\.){3}[0-9]{1,3}\\\\b";
            action = "Copy";

            mouse = {
              enabled = true;
              mods = "Control";
            };

            binding = {
              key = "I";
              mods = "Control|Shift";
            };
          }
          {
            # Path detection
            regex = "(/?[\\\\w.-]+)+";
            action = "Copy";

            mouse = {
              enabled = true;
              mods = "Shift";
            };

            binding = {
              key = "P";
              mods = "Control|Shift";
            };
          }
        ];
      };
    };
  };

  # ============================================
  # ADDITIONAL PACKAGES
  # ============================================
  # Fonts are managed in home-manager configuration

  # ============================================
  # XDG MIME ASSOCIATIONS
  # ============================================
  # Set Alacritty as default terminal emulator
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
  };

  # ============================================
  # SYSTEMD SERVICE (optional)
  # ============================================
  # Auto-start Alacritty server for faster startup
  systemd.user.services.alacritty-server = {
    Unit = {
      Description = "Alacritty Terminal Server";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.alacritty}/bin/alacritty --daemon";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
