# ============================================
# Hyprlock - Glassmorphism Lock Screen
# ============================================
# Premium frosted glass lock screen with:
# - Blurred wallpaper background
# - Glass input field with cyan glow
# - Animated clock display
# - User avatar with glass frame
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.hyprlock = {
    enable = true;

    settings = {
      # ============================================
      # GENERAL SETTINGS
      # ============================================
      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
        no_fade_out = false;
        ignore_empty_input = true;
      };

      # ============================================
      # BACKGROUND - Blurred wallpaper
      # ============================================
      background = [
        {
          monitor = "";
          path = "screenshot"; # Use screenshot of current screen
          blur_passes = 4;
          blur_size = 8;
          noise = 0.02;
          contrast = 0.85;
          brightness = 0.6;
          vibrancy = 0.2;
          vibrancy_darkness = 0.5;

          # Dark overlay
          color = "rgba(10, 10, 15, 0.3)";
        }
      ];

      # ============================================
      # INPUT FIELD - Glass password box
      # ============================================
      input-field = [
        {
          monitor = "";

          # Size and position
          size = "350, 55";
          position = "0, -150";
          halign = "center";
          valign = "center";

          # Glass styling
          outline_thickness = 2;
          outer_color = "rgba(0, 212, 255, 0.5)";
          inner_color = "rgba(18, 18, 26, 0.85)";
          font_color = "rgb(228, 228, 231)";

          # Fade animation
          fade_on_empty = true;
          fade_timeout = 2000;

          # Placeholder
          placeholder_text = "<span foreground='##71717a'>󰌾 Enter Password...</span>";

          # Hide password
          hide_input = false;

          # Dots styling
          dots_size = 0.3;
          dots_spacing = 0.2;
          dots_center = true;
          dots_rounding = -1;

          # Rounding
          rounding = 12;

          # Check and fail colors
          check_color = "rgba(0, 212, 255, 0.8)";
          fail_color = "rgba(255, 0, 170, 0.8)";
          fail_text = "<span foreground='##ff00aa'>󰀦 Authentication Failed</span>";
          fail_transition = 300;

          # Caps lock warning
          capslock_color = "rgba(234, 179, 8, 0.8)";
          numlock_color = "rgba(124, 58, 237, 0.5)";
          bothlock_color = "rgba(234, 179, 8, 0.8)";

          # Swap font color on fail
          swap_font_color = true;

          # Shadow
          shadow_passes = 3;
          shadow_size = 8;
          shadow_color = "rgba(0, 0, 0, 0.4)";
          shadow_boost = 1.2;
        }
      ];

      # ============================================
      # CLOCK - Elegant time display
      # ============================================
      label = [
        # Time
        {
          monitor = "";
          text = "cmd[update:1000] date +%H:%M";
          color = "rgba(255, 255, 255, 1)";
          font_size = 95;
          font_family = "JetBrainsMono Nerd Font";

          position = "0, 200";
          halign = "center";
          valign = "center";

          shadow_passes = 3;
          shadow_size = 5;
          shadow_color = "rgba(0, 0, 0, 0.5)";
          shadow_boost = 1.5;
        }

        # Date
        {
          monitor = "";
          text = "cmd[update:60000] date '+%A, %B %d'";
          color = "rgba(161, 161, 170, 1)";
          font_size = 24;
          font_family = "JetBrainsMono Nerd Font";

          position = "0, 100";
          halign = "center";
          valign = "center";

          shadow_passes = 2;
          shadow_size = 3;
          shadow_color = "rgba(0, 0, 0, 0.4)";
        }

        # User greeting
        {
          monitor = "";
          text = "Hi, $USER";
          color = "rgba(0, 212, 255, 0.9)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";

          position = "0, -80";
          halign = "center";
          valign = "center";
        }

        # Lock icon
        {
          monitor = "";
          text = "󰌾";
          color = "rgba(124, 58, 237, 0.8)";
          font_size = 28;
          font_family = "JetBrainsMono Nerd Font";

          position = "0, -220";
          halign = "center";
          valign = "center";
        }

        # System info (bottom)
        {
          monitor = "";
          text = "cmd[update:5000] echo '󰍛 '$(free -h | awk '/^Mem:/ {print $3}')' / '$(free -h | awk '/^Mem:/ {print $2}')";
          color = "rgba(113, 113, 122, 0.7)";
          font_size = 12;
          font_family = "JetBrainsMono Nerd Font";

          position = "0, 50";
          halign = "center";
          valign = "bottom";
        }

        # Hostname (bottom left)
        {
          monitor = "";
          text = "cmd[update:0] hostname";
          color = "rgba(0, 212, 255, 0.6)";
          font_size = 11;
          font_family = "JetBrainsMono Nerd Font";

          position = "20, 20";
          halign = "left";
          valign = "bottom";
        }

        # Battery (bottom right) - if applicable
        {
          monitor = "";
          text = "cmd[update:10000] cat /sys/class/power_supply/BAT0/capacity 2>/dev/null && echo '%' || echo ''";
          color = "rgba(34, 197, 94, 0.7)";
          font_size = 11;
          font_family = "JetBrainsMono Nerd Font";

          position = "-20, 20";
          halign = "right";
          valign = "bottom";
        }
      ];

      # ============================================
      # USER IMAGE - Avatar with glass frame
      # ============================================
      image = [
        {
          monitor = "";
          path = "$HOME/.face"; # Standard location for user avatar
          size = 120;
          border_size = 3;
          border_color = "rgba(0, 212, 255, 0.6)";
          rounding = -1; # Full circle

          position = "0, 0";
          halign = "center";
          valign = "center";

          shadow_passes = 3;
          shadow_size = 6;
          shadow_color = "rgba(0, 0, 0, 0.5)";
          shadow_boost = 1.2;
        }
      ];
    };
  };

  # Create a default user avatar if none exists
  home.file.".face.icon" = {
    text = ""; # Empty placeholder - user should replace with actual image
    # To set avatar: place a PNG/JPEG at ~/.face
  };
}
