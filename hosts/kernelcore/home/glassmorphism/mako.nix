# ============================================
# Mako - Glassmorphism Notifications
# ============================================
# Premium frosted glass notification daemon with:
# - Urgency-based colored borders (cyan/violet/magenta)
# - Slide-in animations from top-right
# - App icon integration with circular frame
# - Progress bars with glass track
# - Grouped notification stacking
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.mako = {
    enable = true;

    # ============================================
    # GENERAL SETTINGS (using new settings.* format)
    # ============================================
    settings = {
      # Font
      font = "JetBrainsMono Nerd Font 11";

      # Position and layout
      anchor = "top-right";
      layer = "overlay";
      margin = "16,16,0,0";
      padding = "16,20,16,20";
      width = 380;
      height = 150;

      # Appearance
      background-color = "#12121aE6"; # 90% opacity
      text-color = "#e4e4e7";
      border-size = 2;
      border-color = "#7c3aed"; # Default: violet
      border-radius = 12;

      # Icons
      icons = true;
      max-icon-size = 48;

      # Behavior
      max-visible = 5;
      default-timeout = 5000;
      ignore-timeout = false;

      # Grouping
      group-by = "app-name,summary";

      # Actions
      actions = true;

      # Markup
      markup = true;
      format = "<b>%s</b>\\n%b";
    };

    # ============================================
    # URGENCY-BASED STYLING
    # ============================================
    extraConfig = ''
      # ============================================
      # LOW URGENCY - Cyan accent
      # ============================================
      [urgency=low]
      border-color=#00d4ff
      background-color=#12121aCC
      text-color=#a1a1aa
      default-timeout=3000

      # ============================================
      # NORMAL URGENCY - Violet accent (default)
      # ============================================
      [urgency=normal]
      border-color=#7c3aed
      background-color=#12121aE6
      text-color=#e4e4e7
      default-timeout=5000

      # ============================================
      # CRITICAL URGENCY - Magenta accent
      # ============================================
      [urgency=critical]
      border-color=#ff00aa
      background-color=#1a0a12E6
      text-color=#ffffff
      default-timeout=0
      ignore-timeout=1

      # ============================================
      # APP-SPECIFIC STYLING
      # ============================================

      # Discord
      [app-name="Discord"]
      border-color=#5865F2

      # Spotify
      [app-name="Spotify"]
      border-color=#1DB954

      # Firefox
      [app-name="Firefox"]
      border-color=#FF7139

      # Brave
      [app-name="Brave"]
      border-color=#FB542B

      # VSCode/VSCodium
      [app-name="Code"]
      border-color=#007ACC

      [app-name="VSCodium"]
      border-color=#2F80ED

      # Terminal notifications
      [app-name="Alacritty"]
      border-color=#00d4ff

      [app-name="kitty"]
      border-color=#67e8f9

      # Zellij notifications
      [app-name="zellij"]
      border-color=#00d4ff

      # System notifications
      [app-name="notify-send"]
      border-color=#7c3aed

      # Screenshot notifications
      [app-name="Swappy"]
      border-color=#00d4ff

      [app-name="grim"]
      border-color=#00d4ff

      # Volume/Brightness OSD
      [app-name="pamixer"]
      border-color=#7c3aed
      max-visible=1
      default-timeout=1500

      [app-name="brightnessctl"]
      border-color=#7c3aed
      max-visible=1
      default-timeout=1500

      # Network Manager
      [app-name="NetworkManager"]
      border-color=#22c55e

      [app-name="nm-applet"]
      border-color=#22c55e

      # Bluetooth
      [app-name="blueman"]
      border-color=#3b82f6

      # KeePassXC
      [app-name="KeePassXC"]
      border-color=#22c55e

      # Agent Hub placeholder
      [app-name="Agent Hub"]
      border-color=#ff00aa
      background-color=#1a0a18E6

      # ============================================
      # GROUPED NOTIFICATIONS
      # ============================================
      [grouped]
      format=<b>%s</b> (%g)\n%b

      # ============================================
      # HIDDEN (for do-not-disturb mode)
      # ============================================
      [mode=do-not-disturb]
      invisible=1
    '';
  };

  # ============================================
  # NOTIFICATION HELPER SCRIPTS
  # ============================================
  home.file = {
    # Volume notification helper
    ".config/mako/scripts/volume-notify.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Volume change notification with progress bar

        VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
        MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)

        if [[ "$MUTED" -eq 1 ]]; then
          ICON="󰝟"
          TEXT="Muted"
        elif [[ "$VOLUME" -ge 70 ]]; then
          ICON="󰕾"
          TEXT="$VOLUME%"
        elif [[ "$VOLUME" -ge 30 ]]; then
          ICON="󰖀"
          TEXT="$VOLUME%"
        else
          ICON="󰕿"
          TEXT="$VOLUME%"
        fi

        notify-send -a "pamixer" -h string:x-canonical-private-synchronous:volume \
          -h int:value:$VOLUME "$ICON Volume" "$TEXT"
      '';
    };

    # Brightness notification helper
    ".config/mako/scripts/brightness-notify.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Brightness change notification with progress bar

        BRIGHTNESS=$(brightnessctl get)
        MAX=$(brightnessctl max)
        PERCENT=$((BRIGHTNESS * 100 / MAX))

        if [[ "$PERCENT" -ge 70 ]]; then
          ICON="󰃠"
        elif [[ "$PERCENT" -ge 30 ]]; then
          ICON="󰃟"
        else
          ICON="󰃞"
        fi

        notify-send -a "brightnessctl" -h string:x-canonical-private-synchronous:brightness \
          -h int:value:$PERCENT "$ICON Brightness" "$PERCENT%"
      '';
    };

    # Screenshot notification helper
    ".config/mako/scripts/screenshot-notify.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Screenshot notification with preview

        FILE="$1"
        TYPE="$2"  # "area", "screen", "clipboard"

        case "$TYPE" in
          clipboard)
            notify-send -a "grim" "󰹑 Screenshot" "Copied to clipboard"
            ;;
          area|screen)
            if [[ -f "$FILE" ]]; then
              notify-send -a "grim" -i "$FILE" "󰹑 Screenshot Saved" "$FILE"
            fi
            ;;
        esac
      '';
    };

    # Test notification script
    ".config/mako/scripts/test-notifications.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Test different notification urgencies and styles

        echo "Testing Mako Glassmorphism Notifications..."

        # Low urgency - cyan
        notify-send -u low "󰋼 Low Urgency" "This is a low priority notification with cyan accent"
        sleep 1

        # Normal urgency - violet
        notify-send -u normal "󰋽 Normal Urgency" "This is a normal priority notification with violet accent"
        sleep 1

        # Critical urgency - magenta
        notify-send -u critical "󰀦 Critical Urgency" "This is a critical notification with magenta accent"
        sleep 1

        # App-specific
        notify-send -a "Discord" "󰙯 Discord" "New message from user"
        sleep 1

        notify-send -a "Spotify" "󰓇 Now Playing" "Song Title - Artist Name"
        sleep 1

        # Agent Hub
        notify-send -a "Agent Hub" "󰚩 Agent Hub" "AI agent ready for tasks"

        echo "Done! Check your notifications."
      '';
    };
  };
}
