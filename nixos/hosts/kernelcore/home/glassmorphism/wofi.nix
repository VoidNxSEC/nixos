# ============================================
# Wofi - Glassmorphism Application Launcher
# ============================================
# Premium frosted glass launcher with:
# - Glass search bar with cyan accent
# - Frosted result cards
# - Nerd Font icons
# - Smooth animations
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;
in
{
  programs.wofi = {
    enable = true;

    settings = {
      # ============================================
      # GENERAL SETTINGS
      # ============================================
      mode = "drun";
      allow_images = true;
      image_size = 32;
      prompt = "Search";

      # Appearance
      width = 600;
      height = 400;
      location = "center";
      orientation = "vertical";
      halign = "fill";

      # Behavior
      allow_markup = true;
      insensitive = true;
      no_actions = false;
      hide_scroll = true;
      matching = "fuzzy";
      sort_order = "default";
      gtk_dark = true;

      # Performance
      dynamic_lines = false;

      # Layer
      layer = "overlay";

      # Search
      exec_search = false;
      search = "";

      # Keys
      key_expand = "Tab";
      key_exit = "Escape";
    };

    style = ''
      /* ============================================
       * Wofi - Glassmorphism Theme
       * Premium frosted glass launcher
       * Using design tokens from colors.nix
       * ============================================ */

      /* Reset */
      * {
        all: unset;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 14px;
      }

      /* Main window - frosted glass */
      window {
        background: ${colors.hexToRgba colors.base.bg0 "0.85"};
        border: 1px solid ${colors.border.light};
        border-radius: ${toString colors.radius.large}px;
        box-shadow: 0 8px 40px ${colors.shadow.dark},
                    0 0 60px ${colors.hexToRgba colors.accent.cyan "0.08"};
        margin: 0;
        padding: ${toString colors.spacing.md}px;
      }

      /* Outer container */
      #outer-box {
        background: transparent;
        border: none;
        padding: 0;
        margin: 0;
      }

      /* Input/search box - glass pill */
      #input {
        background: ${colors.hexToRgba colors.base.bg1 "0.9"};
        border: 1px solid ${colors.hexToRgba colors.accent.cyan "0.3"};
        border-radius: ${toString colors.radius.medium}px;
        padding: 12px 20px;
        margin-bottom: ${toString colors.spacing.md}px;
        color: ${colors.base.fg0};
        font-size: 15px;
        box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.cyan "0.1"};
        transition: all 0.3s ease;
      }

      #input:focus {
        border-color: ${colors.hexToRgba colors.accent.cyan "0.6"};
        box-shadow: 0 0 30px ${colors.hexToRgba colors.accent.cyan "0.2"};
      }

      #input image {
        color: ${colors.accent.cyan};
        margin-right: 12px;
      }

      /* Scrollable area */
      #scroll {
        background: transparent;
        margin: 0;
        padding: 0;
      }

      /* Inner results container */
      #inner-box {
        background: transparent;
        padding: 0;
        margin: 0;
      }

      /* Individual result entries */
      #entry {
        background: ${colors.hexToRgba colors.base.bg1 "0.6"};
        border: 1px solid ${colors.border.lighter};
        border-radius: 10px;
        padding: 10px 16px;
        margin: 4px 0;
        transition: all 0.2s ease;
      }

      #entry:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.12"};
        border-color: ${colors.hexToRgba colors.accent.cyan "0.3"};
        box-shadow: 0 0 20px ${colors.hexToRgba colors.accent.cyan "0.15"};
      }

      #entry:selected {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.cyan "0.2"}, ${colors.hexToRgba colors.accent.violet "0.15"});
        border-color: ${colors.hexToRgba colors.accent.cyan "0.5"};
        box-shadow: 0 0 25px ${colors.hexToRgba colors.accent.cyan "0.2"};
      }

      #entry:selected:hover {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.cyan "0.25"}, ${colors.hexToRgba colors.accent.violet "0.2"});
      }

      /* Text styling */
      #text {
        color: ${colors.base.fg1};
        margin-left: 12px;
      }

      #text:selected {
        color: ${colors.base.fg0};
      }

      #entry:selected #text {
        color: ${colors.accent.cyan};
        font-weight: 500;
      }

      /* Application icons */
      #img {
        margin-right: 8px;
        border-radius: 8px;
        background: ${colors.hexToRgba colors.base.bg3 "0.8"};
        padding: 4px;
      }

      /* Expander (submenu arrow) */
      #expander {
        color: ${colors.base.fg3};
      }

      #expander:selected {
        color: ${colors.accent.cyan};
      }

      /* Scrollbar */
      scrollbar {
        background: transparent;
        border: none;
        min-width: 6px;
        margin-left: 8px;
      }

      scrollbar slider {
        background: ${colors.hexToRgba colors.accent.cyan "0.3"};
        border-radius: 3px;
        min-height: 30px;
      }

      scrollbar slider:hover {
        background: ${colors.hexToRgba colors.accent.cyan "0.5"};
      }

      /* Unmatched text (fuzzy search) */
      #unmatched {
        color: ${colors.base.fg3};
      }

      /* Matched text highlight */
      #matched {
        color: ${colors.accent.cyan};
        font-weight: 600;
      }

      /* Alternative modes styling */

      /* Run mode */
      window#run #input {
        border-color: ${colors.hexToRgba colors.accent.violet "0.3"};
      }

      window#run #input:focus {
        border-color: ${colors.hexToRgba colors.accent.violet "0.6"};
        box-shadow: 0 0 30px ${colors.hexToRgba colors.accent.violet "0.2"};
      }

      window#run #entry:selected {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.violet "0.2"}, ${colors.hexToRgba colors.accent.magenta "0.1"});
        border-color: ${colors.hexToRgba colors.accent.violet "0.5"};
      }

      /* Dmenu mode */
      window#dmenu #input {
        border-color: ${colors.hexToRgba colors.accent.magenta "0.3"};
      }

      window#dmenu #input:focus {
        border-color: ${colors.hexToRgba colors.accent.magenta "0.6"};
        box-shadow: 0 0 30px ${colors.hexToRgba colors.accent.magenta "0.2"};
      }

      window#dmenu #entry:selected {
        background: linear-gradient(135deg, ${colors.hexToRgba colors.accent.magenta "0.2"}, ${colors.hexToRgba colors.accent.violet "0.1"});
        border-color: ${colors.hexToRgba colors.accent.magenta "0.5"};
      }
    '';
  };

  # ============================================
  # CUSTOM WOFI MODES
  # ============================================
  home.file = {
    # Power menu script
    ".config/wofi/scripts/power-menu.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Glassmorphism power menu for wofi

        OPTIONS="󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

        SELECTED=$(echo -e "$OPTIONS" | wofi --dmenu --prompt="Power" --width=250 --height=220 --cache-file=/dev/null)

        case "$SELECTED" in
          "󰌾 Lock")
            hyprlock
            ;;
          "󰗽 Logout")
            hyprctl dispatch exit
            ;;
          "󰤄 Suspend")
            systemctl suspend
            ;;
          "󰜉 Reboot")
            systemctl reboot
            ;;
          "󰐥 Shutdown")
            systemctl poweroff
            ;;
        esac
      '';
    };

    # Emoji picker script
    ".config/wofi/scripts/emoji-picker.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Emoji picker using wofi

        # Check if emoji file exists, if not create basic one
        EMOJI_FILE="$HOME/.config/wofi/emoji.txt"

        if [[ ! -f "$EMOJI_FILE" ]]; then
          cat > "$EMOJI_FILE" << 'EMOJIS'
        😀 grinning face
        😃 grinning face with big eyes
        😄 grinning face with smiling eyes
        😁 beaming face with smiling eyes
        😆 grinning squinting face
        😅 grinning face with sweat
        🤣 rolling on the floor laughing
        😂 face with tears of joy
        🙂 slightly smiling face
        🙃 upside-down face
        😉 winking face
        😊 smiling face with smiling eyes
        😇 smiling face with halo
        🥰 smiling face with hearts
        😍 smiling face with heart-eyes
        🤩 star-struck
        😘 face blowing a kiss
        😗 kissing face
        ☺️ smiling face
        😚 kissing face with closed eyes
        😙 kissing face with smiling eyes
        🥲 smiling face with tear
        😋 face savoring food
        😛 face with tongue
        😜 winking face with tongue
        🤪 zany face
        😝 squinting face with tongue
        🤑 money-mouth face
        🤗 smiling face with open hands
        🤭 face with hand over mouth
        🤫 shushing face
        🤔 thinking face
        👍 thumbs up
        👎 thumbs down
        👏 clapping hands
        🙌 raising hands
        🤝 handshake
        ❤️ red heart
        🔥 fire
        ⭐ star
        ✨ sparkles
        💯 hundred points
        ✅ check mark
        ❌ cross mark
        EMOJIS
        fi

        SELECTED=$(cat "$EMOJI_FILE" | wofi --dmenu --prompt="Emoji" --width=400 --height=300)

        if [[ -n "$SELECTED" ]]; then
          EMOJI=$(echo "$SELECTED" | cut -d' ' -f1)
          echo -n "$EMOJI" | wl-copy
          notify-send -a "Wofi" "󰱨 Emoji Copied" "$EMOJI"
        fi
      '';
    };

    # Clipboard manager script
    ".config/wofi/scripts/clipboard.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Clipboard history viewer using wofi + cliphist

        if command -v cliphist &> /dev/null; then
          SELECTED=$(cliphist list | wofi --dmenu --prompt="Clipboard" --width=600 --height=400)
          if [[ -n "$SELECTED" ]]; then
            echo "$SELECTED" | cliphist decode | wl-copy
          fi
        else
          notify-send -u normal "Clipboard" "cliphist not installed"
        fi
      '';
    };

    # Window switcher script
    ".config/wofi/scripts/window-switcher.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Window switcher using wofi + hyprctl

        # Get list of windows
        WINDOWS=$(hyprctl clients -j | jq -r '.[] | "\(.address) \(.class) - \(.title)"')

        if [[ -z "$WINDOWS" ]]; then
          notify-send -a "Wofi" "No windows open"
          exit 0
        fi

        SELECTED=$(echo "$WINDOWS" | wofi --dmenu --prompt="Windows" --width=700 --height=400)

        if [[ -n "$SELECTED" ]]; then
          ADDRESS=$(echo "$SELECTED" | awk '{print $1}')
          hyprctl dispatch focuswindow address:$ADDRESS
        fi
      '';
    };
  };
}
