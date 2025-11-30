# ============================================
# Alacritty Terminal Configuration
# ============================================
# Declarative configuration for Alacritty terminal emulator
# - Optimized for Zellij integration
# - Glassmorphism Dark theme with electric accents
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
          instance = "Alacritty";
          general = "alacritty-main";
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
        color = "#ff00aa"; # Glassmorphism magenta
      };

      # ============================================
      # COLOR SCHEME - Glassmorphism Dark
      # Electric cyan/magenta/violet accents
      # ============================================
      colors = {
        # Primary colors - Dark glassmorphism base
        primary = {
          background = "#0a0a0f";
          foreground = "#e4e4e7";
          bright_foreground = "#ffffff";
          dim_foreground = "#a1a1aa";
        };

        # Cursor colors - Electric cyan
        cursor = {
          text = "#0a0a0f";
          cursor = "#00d4ff";
        };

        vi_mode_cursor = {
          text = "#0a0a0f";
          cursor = "#7c3aed";
        };

        # Selection colors - Violet tint
        selection = {
          text = "#ffffff";
          background = "#7c3aed";
        };

        # Search colors - Cyan highlight
        search = {
          matches = {
            foreground = "#0a0a0f";
            background = "#00d4ff";
          };
          focused_match = {
            foreground = "#0a0a0f";
            background = "#ff00aa";
          };
        };

        # Footer bar colors
        footer_bar = {
          background = "#12121a";
          foreground = "#e4e4e7";
        };

        # Line indicator
        line_indicator = {
          foreground = "None";
          background = "None";
        };

        # Hints (URL detection)
        hints = {
          start = {
            foreground = "#0a0a0f";
            background = "#00d4ff";
          };
          end = {
            foreground = "#0a0a0f";
            background = "#7c3aed";
          };
        };

        # Normal colors - Glassmorphism palette
        normal = {
          black = "#1a1a24"; # Dark surface
          red = "#ff00aa"; # Magenta (error/danger)
          green = "#22c55e"; # Success green
          yellow = "#eab308"; # Warning yellow
          blue = "#3b82f6"; # Info blue
          magenta = "#7c3aed"; # Violet accent
          cyan = "#00d4ff"; # Electric cyan (primary)
          white = "#a1a1aa"; # Muted text
        };

        # Bright colors - Lighter variants
        bright = {
          black = "#22222e"; # Elevated surface
          red = "#f472b6"; # Light magenta
          green = "#4ade80"; # Bright green
          yellow = "#facc15"; # Bright yellow
          blue = "#60a5fa"; # Bright blue
          magenta = "#a78bfa"; # Light violet
          cyan = "#67e8f9"; # Light cyan
          white = "#ffffff"; # Pure white
        };

        # Dim colors - Darker variants
        dim = {
          black = "#0a0a0f"; # Deepest background
          red = "#be185d"; # Dark magenta
          green = "#166534"; # Dark green
          yellow = "#a16207"; # Dark yellow
          blue = "#1e40af"; # Dark blue
          magenta = "#5b21b6"; # Dark violet
          cyan = "#0891b2"; # Dark cyan
          white = "#71717a"; # Disabled text
        };
      };

      # ============================================
      # TERMINAL CONFIGURATION
      # ============================================
      terminal = {
        # Full OSC52 support for clipboard
        osc52 = "CopyPaste";

        # Shell configuration - use user's default shell
        # Zellij is launched via Hyprland keybindings, not auto-started
        # This keeps alacritty as a standalone terminal emulator
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
            command = "Copy";

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
            command = "Copy";

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
            command = "Copy";

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

  # Note: Alacritty doesn't support daemon mode, so no systemd service needed
  # Terminal instances are launched on-demand via keybindings
}
