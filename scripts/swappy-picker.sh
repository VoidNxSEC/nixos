#!/usr/bin/env bash
# ============================================
# Swappy with File Picker Script
# Takes screenshot, opens in swappy for editing, then file picker for save location
# ============================================

set -e

MODE="$1"
TEMP_FILE="/tmp/swappy-picker-$(date +%Y%m%d-%H%M%S).png"
CONFIG_DIR="/tmp/swappy-picker-config"

# Create temp config for swappy
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config" << 'EOF'
[Default]
save_dir=/tmp
save_filename_format=swappy-picker-%Y%m%d-%H%M%S.png
show_panel=true
line_size=5
text_size=20
text_font=JetBrainsMono Nerd Font
paint_mode=brush
early_exit=false
EOF

# Take screenshot based on mode
if [ "$MODE" = "region" ]; then
    grim -g "$(slurp)" "$TEMP_FILE"
elif [ "$MODE" = "screen" ]; then
    grim "$TEMP_FILE"
else
    echo "Usage: $0 [region|screen]"
    exit 1
fi

# Open in swappy with temp config
SWAPPY_CONFIG_DIR="$CONFIG_DIR" swappy -f "$TEMP_FILE"

# After swappy closes, check if user saved (file exists in /tmp)
SAVED_FILE=$(ls -t /tmp/swappy-picker-*.png 2>/dev/null | head -1)

if [ -n "$SAVED_FILE" ] && [ -f "$SAVED_FILE" ]; then
    # Show file picker
    FINAL_FILE=$(zenity --file-selection --save --confirm-overwrite \
        --title="Save Screenshot" \
        --filename="$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png")

    # Move file if user selected location
    if [ -n "$FINAL_FILE" ]; then
        mv "$SAVED_FILE" "$FINAL_FILE"
    fi
fi

# Cleanup
rm -f "$TEMP_FILE"
rm -rf "$CONFIG_DIR"