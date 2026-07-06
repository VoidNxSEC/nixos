# ============================================
# Screenshot Tools - Wayland Native
# ============================================
# Modern Wayland screenshot stack:
# - grim: Screen capture
# - slurp: Region selection
# - swappy: Quick annotation editor
# - satty: Modern annotation tool (Flameshot alternative)
#
# Keybinds (configured in hyprland.nix):
#   Print        → grim + slurp + swappy (region select)
#   Shift+Print  → grim + swappy (fullscreen)
#   Ctrl+Print   → grim (save to file)
#   Super+Print  → grim + slurp + wl-copy (to clipboard)
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Screenshot save directory
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
in
{
  # Required packages for screenshot workflow
  home.packages = with pkgs; [
    # Core screenshot tools
    grim # Wayland screen capture
    slurp # Region selection
    wl-clipboard # Clipboard utilities

    # Annotation editors (choose your preferred)
    swappy # Quick & simple editor
    # satty          # Modern Flameshot-like editor (uncomment if available)
  ];

  # Swappy configuration
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=${screenshotDir}
    save_filename_format=screenshot-%Y%m%d-%H%M%S.png
    show_panel=true
    line_size=5
    text_size=20
    text_font=JetBrainsMono Nerd Font
    paint_mode=brush
    early_exit=false
    fill_shape=false
  '';

  # Create screenshot directory
  home.activation.createScreenshotDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${screenshotDir}"
  '';

  # Helper scripts for screenshot workflow
  home.file.".local/bin/screenshot" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Universal screenshot script for Wayland

      SCREENSHOT_DIR="${screenshotDir}"
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)
      FILENAME="screenshot-$TIMESTAMP.png"

      case "''${1:-region}" in
        region|r)
          # Region select → annotation
          ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
          ;;
        full|f)
          # Full screen → annotation
          ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f -
          ;;
        window|w)
          # Active window (using hyprctl)
          GEOMETRY=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
          ${pkgs.grim}/bin/grim -g "$GEOMETRY" - | ${pkgs.swappy}/bin/swappy -f -
          ;;
        save|s)
          # Region → save directly (no annotation)
          ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" "$SCREENSHOT_DIR/$FILENAME"
          ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$FILENAME" -i camera-photo
          ;;
        copy|c)
          # Region → clipboard
          ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
          ${pkgs.libnotify}/bin/notify-send "Screenshot copied" "Image copied to clipboard" -i camera-photo
          ;;
        *)
          echo "Usage: screenshot [region|full|window|save|copy]"
          echo ""
          echo "Modes:"
          echo "  region (r)  - Select region, open in editor"
          echo "  full (f)    - Full screen, open in editor"
          echo "  window (w)  - Active window, open in editor"
          echo "  save (s)    - Select region, save to file"
          echo "  copy (c)    - Select region, copy to clipboard"
          ;;
      esac
    '';
  };

  # Add to PATH
  home.sessionPath = [ "$HOME/.local/bin" ];
}
