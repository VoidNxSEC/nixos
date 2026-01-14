# ============================================
# Swappy - Glassmorphism Screenshot Editor
# ============================================
# Premium screenshot annotation tool with:
# - Glass toolbar
# - Frosted annotation tools
# - Cyan accent drawing colors
# - Integrated with grim/slurp pipeline
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ============================================
  # SWAPPY CONFIGURATION
  # ============================================
  xdg.configFile."swappy/config".text = ''
    [Default]
    # Save directory
    save_dir=$HOME/Pictures/Screenshots
    save_filename_format=screenshot-%Y%m%d-%H%M%S.png

    # Display settings
    show_panel=true
    line_size=5
    text_size=20
    text_font=JetBrainsMono Nerd Font

    # Colors - Glassmorphism accent colors
    paint_mode=brush
    early_exit=false

    # Default tool color (cyan accent)
    # Note: Swappy uses GTK colors, configured via CSS below
  '';

  # ============================================
  # GTK CSS FOR SWAPPY GLASSMORPHISM
  # ============================================
  # Swappy uses GTK4, so we style it via gtk.css
  xdg.configFile."gtk-4.0/gtk.css".text = ''
    /* ============================================
     * Swappy Glassmorphism Theme
     * Applied via GTK4 CSS
     * ============================================ */

    /* Swappy window background */
    window.swappy {
      background-color: rgba(18, 18, 26, 0.95);
    }

    /* Toolbar styling */
    .swappy-toolbar {
      background: rgba(18, 18, 26, 0.9);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 8px;
      margin: 8px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
    }

    /* Tool buttons */
    .swappy-toolbar button {
      background: rgba(34, 34, 46, 0.8);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 8px;
      padding: 8px;
      margin: 2px;
      color: #e4e4e7;
      transition: all 0.2s ease;
    }

    .swappy-toolbar button:hover {
      background: rgba(0, 212, 255, 0.15);
      border-color: rgba(0, 212, 255, 0.4);
      color: #00d4ff;
    }

    .swappy-toolbar button:checked,
    .swappy-toolbar button:active {
      background: linear-gradient(135deg, rgba(0, 212, 255, 0.25), rgba(124, 58, 237, 0.15));
      border-color: rgba(0, 212, 255, 0.6);
      color: #00d4ff;
      box-shadow: 0 0 15px rgba(0, 212, 255, 0.2);
    }

    /* Color picker button */
    .swappy-color-picker {
      border-radius: 50%;
      padding: 4px;
    }

    /* Size slider */
    .swappy-toolbar scale {
      padding: 8px;
    }

    .swappy-toolbar scale trough {
      background: rgba(34, 34, 46, 0.8);
      border-radius: 4px;
    }

    .swappy-toolbar scale highlight {
      background: linear-gradient(90deg, #00d4ff, #7c3aed);
      border-radius: 4px;
    }

    .swappy-toolbar scale slider {
      background: #00d4ff;
      border-radius: 50%;
      box-shadow: 0 0 10px rgba(0, 212, 255, 0.3);
    }

    /* Action buttons (Save, Copy, etc.) */
    .swappy-action-button {
      background: rgba(18, 18, 26, 0.9);
      border: 1px solid rgba(0, 212, 255, 0.3);
      border-radius: 10px;
      padding: 10px 20px;
      color: #00d4ff;
      font-weight: 500;
      transition: all 0.2s ease;
    }

    .swappy-action-button:hover {
      background: rgba(0, 212, 255, 0.15);
      border-color: rgba(0, 212, 255, 0.5);
      box-shadow: 0 0 20px rgba(0, 212, 255, 0.2);
    }

    .swappy-action-button.save {
      border-color: rgba(34, 197, 94, 0.3);
      color: #22c55e;
    }

    .swappy-action-button.save:hover {
      background: rgba(34, 197, 94, 0.15);
      border-color: rgba(34, 197, 94, 0.5);
      box-shadow: 0 0 20px rgba(34, 197, 94, 0.2);
    }

    .swappy-action-button.copy {
      border-color: rgba(124, 58, 237, 0.3);
      color: #7c3aed;
    }

    .swappy-action-button.copy:hover {
      background: rgba(124, 58, 237, 0.15);
      border-color: rgba(124, 58, 237, 0.5);
      box-shadow: 0 0 20px rgba(124, 58, 237, 0.2);
    }

    /* Cancel/Close button */
    .swappy-action-button.cancel {
      border-color: rgba(255, 0, 170, 0.3);
      color: #ff00aa;
    }

    .swappy-action-button.cancel:hover {
      background: rgba(255, 0, 170, 0.15);
      border-color: rgba(255, 0, 170, 0.5);
      box-shadow: 0 0 20px rgba(255, 0, 170, 0.2);
    }
  '';

  # ============================================
  # SCREENSHOT HELPER SCRIPTS
  # ============================================
  home.file = {
    # Full screenshot pipeline script
    ".config/swappy/scripts/screenshot.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Glassmorphism Screenshot Script
        # Uses: grim + slurp + swappy pipeline
        # ============================================

        SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$SCREENSHOT_DIR"

        MODE="''${1:-region}"  # region, screen, or window

        case "$MODE" in
          region)
            # Region select to swappy
            grim -g "$(slurp)" - | swappy -f -
            ;;
          screen)
            # Full screen to swappy
            grim - | swappy -f -
            ;;
          window)
            # Active window to swappy
            GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            grim -g "$GEOMETRY" - | swappy -f -
            ;;
          quick-region)
            # Region select directly to file
            FILENAME="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
            grim -g "$(slurp)" "$FILENAME"
            notify-send -a "Screenshot" "󰹑 Screenshot Saved" "$FILENAME"
            ;;
          quick-screen)
            # Full screen directly to file
            FILENAME="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
            grim "$FILENAME"
            notify-send -a "Screenshot" "󰹑 Screenshot Saved" "$FILENAME"
            ;;
          clipboard-region)
            # Region select to clipboard
            grim -g "$(slurp)" - | wl-copy
            notify-send -a "Screenshot" "󰹑 Screenshot" "Copied to clipboard"
            ;;
          clipboard-screen)
            # Full screen to clipboard
            grim - | wl-copy
            notify-send -a "Screenshot" "󰹑 Screenshot" "Copied to clipboard"
            ;;
          *)
            echo "Usage: screenshot.sh [region|screen|window|quick-region|quick-screen|clipboard-region|clipboard-screen]"
            exit 1
            ;;
        esac
      '';
    };

    # OCR screenshot script (requires tesseract)
    ".config/swappy/scripts/screenshot-ocr.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Screenshot OCR - Extract text from screen region
        # Requires: tesseract-ocr
        # ============================================

        if ! command -v tesseract &> /dev/null; then
          notify-send -u critical "OCR Error" "tesseract not installed"
          exit 1
        fi

        TEMP_FILE=$(mktemp /tmp/screenshot-ocr-XXXXXX.png)

        # Capture region
        grim -g "$(slurp)" "$TEMP_FILE"

        if [[ -f "$TEMP_FILE" ]]; then
          # Run OCR
          TEXT=$(tesseract "$TEMP_FILE" stdout 2>/dev/null)
          
          if [[ -n "$TEXT" ]]; then
            echo -n "$TEXT" | wl-copy
            notify-send -a "Screenshot OCR" "󰊄 Text Extracted" "$(echo "$TEXT" | head -c 100)..."
          else
            notify-send -u low "Screenshot OCR" "No text detected"
          fi
          
          rm -f "$TEMP_FILE"
        fi
      '';
    };

    # Color picker script
    ".config/swappy/scripts/color-picker.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Color Picker - Extract color from screen
        # Requires: hyprpicker
        # ============================================

        if ! command -v hyprpicker &> /dev/null; then
          notify-send -u critical "Color Picker" "hyprpicker not installed"
          exit 1
        fi

        # Pick color (auto-copies to clipboard)
        COLOR=$(hyprpicker -a -f hex)

        if [[ -n "$COLOR" ]]; then
          notify-send -a "Color Picker" "󰏘 Color Picked" "$COLOR copied to clipboard"
        fi
      '';
    };

    # Open file script
    ".config/swappy/scripts/open-file.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Open File in Swappy
        # Uses: zenity for file picking
        # ============================================

        FILE=$(${pkgs.zenity}/bin/zenity --file-selection --title="Open Image in Swappy" --file-filter="Images | *.png *.jpg *.jpeg *.webp *.svg")

        if [ -n "$FILE" ]; then
          ${pkgs.swappy}/bin/swappy -f "$FILE"
        fi
      '';
    };
  };

  # Desktop entry for opening files in Swappy
  xdg.desktopEntries."swappy-open" = {
    name = "Swappy Editor";
    genericName = "Image Editor";
    comment = "Open image file in Swappy";
    icon = "swappy";
    exec = "${config.home.homeDirectory}/.config/swappy/scripts/open-file.sh";
    terminal = false;
    categories = [
      "Graphics"
      "Utility"
    ];
    mimeType = [
      "image/png"
      "image/jpeg"
      "image/webp"
      "image/svg+xml"
    ];
  };

  # Ensure screenshots directory exists
  home.activation.createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/Pictures/Screenshots
  '';
}
