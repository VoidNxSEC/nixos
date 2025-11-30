# ============================================
# Wallpaper Management - Glassmorphism Theme
# ============================================
# Manages themed wallpaper for Hyprland with:
# - Static wallpaper via swaybg
# - Wallpaper generation script (optional)
# - Color-matched dark glassmorphism aesthetic
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Wallpaper paths
  wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
  defaultWallpaper = "${wallpaperDir}/glassmorphism-default.png";
  
  # Glassmorphism color palette for wallpaper generation
  colors = {
    bg = "#0a0a0f";
    cyan = "#00d4ff";
    magenta = "#ff00aa";
    violet = "#7c3aed";
  };

  # Script to generate a glassmorphism-style wallpaper using ImageMagick
  wallpaperGeneratorScript = pkgs.writeShellScriptBin "generate-glassmorphism-wallpaper" ''
    #!/usr/bin/env bash
    # ============================================
    # Glassmorphism Wallpaper Generator
    # ============================================
    # Generates a dark abstract wallpaper with
    # cyan/violet luminescent accents
    # ============================================

    set -euo pipefail

    OUTPUT_DIR="${wallpaperDir}"
    OUTPUT_FILE="$OUTPUT_DIR/glassmorphism-default.png"
    WIDTH="''${1:-1920}"
    HEIGHT="''${2:-1080}"

    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR"

    echo "Generating glassmorphism wallpaper ($WIDTH x $HEIGHT)..."

    # Calculate positions
    W4=$((WIDTH/4))
    H3=$((HEIGHT/3))
    W34=$((WIDTH*3/4))
    H23=$((HEIGHT*2/3))
    W2=$((WIDTH/2))
    H5=$((HEIGHT/5))
    W45=$((WIDTH*4/5))
    H4=$((HEIGHT/4))
    W6=$((WIDTH/6))
    H45=$((HEIGHT*4/5))
    W5=$((WIDTH/5))
    H25=$((HEIGHT*2/5))
    H2=$((HEIGHT/2))
    H34=$((HEIGHT*3/4))

    # Generate wallpaper using ImageMagick
    # Creates a dark gradient base with luminescent accent orbs
    ${pkgs.imagemagick}/bin/magick \
      -size "''${WIDTH}x''${HEIGHT}" \
      xc:'#0a0a0f' \
      -fill 'rgba(0,212,255,0.12)' -draw "circle $W4,$H3 $((W4+200)),$H3" \
      -fill 'rgba(124,58,237,0.10)' -draw "circle $W34,$H23 $((W34+180)),$H23" \
      -fill 'rgba(255,0,170,0.08)' -draw "circle $W2,$H5 $((W2+120)),$H5" \
      -fill 'rgba(0,212,255,0.06)' -draw "circle $W45,$H4 $((W45+250)),$H4" \
      -fill 'rgba(124,58,237,0.09)' -draw "circle $W6,$H45 $((W6+150)),$H45" \
      -blur 0x60 \
      -fill 'rgba(0,212,255,0.25)' -draw "circle $W5,$H25 $((W5+4)),$H25" \
      -fill 'rgba(255,0,170,0.20)' -draw "circle $W45,$H2 $((W45+3)),$H2" \
      -fill 'rgba(124,58,237,0.30)' -draw "circle $W2,$H34 $((W2+5)),$H34" \
      -blur 0x20 \
      -attenuate 0.02 +noise Gaussian \
      "$OUTPUT_FILE"

    echo "Wallpaper saved to: $OUTPUT_FILE"
    
    # Optionally restart swaybg if running
    if pgrep -x swaybg > /dev/null; then
      echo "Refreshing swaybg..."
      pkill swaybg || true
      sleep 0.5
      swaybg -i "$OUTPUT_FILE" -m fill &
      disown
    fi

    echo "Done!"
  '';

  # Script to download curated glassmorphism wallpapers
  wallpaperDownloadScript = pkgs.writeShellScriptBin "download-glassmorphism-wallpaper" ''
    #!/usr/bin/env bash
    # ============================================
    # Glassmorphism Wallpaper Downloader
    # ============================================
    # Downloads curated dark abstract wallpapers
    # that match the glassmorphism theme
    # ============================================

    set -euo pipefail

    OUTPUT_DIR="${wallpaperDir}"
    OUTPUT_FILE="$OUTPUT_DIR/glassmorphism-default.png"

    mkdir -p "$OUTPUT_DIR"

    echo "󰇚 Downloading glassmorphism wallpaper..."

    # Curated wallpaper URLs (dark abstract with cyan/violet tones)
    # These are placeholder URLs - user should replace with actual sources
    WALLPAPERS=(
      # Dark abstract gradient wallpapers
      "https://images.unsplash.com/photo-1557682250-33bd709cbe85?w=1920&h=1080&fit=crop"
      "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1920&h=1080&fit=crop"
      "https://images.unsplash.com/photo-1557683316-973673baf926?w=1920&h=1080&fit=crop"
    )

    # Download first available
    for URL in "''${WALLPAPERS[@]}"; do
      echo "  Trying: $URL"
      if ${pkgs.curl}/bin/curl -fsSL "$URL" -o "$OUTPUT_FILE.tmp" 2>/dev/null; then
        mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
        echo "✨ Downloaded to: $OUTPUT_FILE"
        
        # Optionally restart swaybg
        if pgrep -x swaybg > /dev/null; then
          echo "󰑓 Refreshing swaybg..."
          pkill swaybg || true
          sleep 0.5
          swaybg -i "$OUTPUT_FILE" -m fill &
          disown
        fi
        
        echo "󰄬 Done!"
        exit 0
      fi
    done

    echo "❌ Failed to download wallpaper. Please download manually or run generate-glassmorphism-wallpaper"
    exit 1
  '';

  # Script to set wallpaper
  setWallpaperScript = pkgs.writeShellScriptBin "set-wallpaper" ''
    #!/usr/bin/env bash
    # ============================================
    # Set Wallpaper Script
    # ============================================

    WALLPAPER="''${1:-${defaultWallpaper}}"
    
    if [[ ! -f "$WALLPAPER" ]]; then
      echo "❌ Wallpaper not found: $WALLPAPER"
      echo "Run 'generate-glassmorphism-wallpaper' or 'download-glassmorphism-wallpaper' first"
      exit 1
    fi

    echo "󰋩 Setting wallpaper: $WALLPAPER"
    
    # Kill existing swaybg
    pkill swaybg || true
    sleep 0.3
    
    # Start swaybg with new wallpaper
    swaybg -i "$WALLPAPER" -m fill &
    disown
    
    echo "󰄬 Wallpaper set!"
  '';

in
{
  # ============================================
  # PACKAGES
  # ============================================
  home.packages = with pkgs; [
    swaybg
    imagemagick  # For wallpaper generation
    curl         # For wallpaper download
    
    # Custom scripts
    wallpaperGeneratorScript
    wallpaperDownloadScript
    setWallpaperScript
  ];

  # ============================================
  # WALLPAPER DIRECTORY SETUP
  # ============================================
  home.file.".local/share/wallpapers/.gitkeep".text = "";
  
  # Create wallpapers directory
  home.activation.createWallpaperDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${wallpaperDir}
  '';

  # ============================================
  # SYSTEMD USER SERVICE - Wallpaper Daemon
  # ============================================
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wayland wallpaper daemon (swaybg)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${defaultWallpaper} -m fill";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
      Restart = "on-failure";
      RestartSec = 1;
    };
    
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # ============================================
  # PLACEHOLDER WALLPAPER
  # ============================================
  # Creates a simple dark placeholder if no wallpaper exists
  # User should run the generator or download script
  home.file."Pictures/wallpapers/glassmorphism-placeholder.svg" = {
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080">
        <defs>
          <!-- Dark gradient background -->
          <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#0a0a0f;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#12121a;stop-opacity:1" />
          </linearGradient>
          
          <!-- Cyan orb gradient -->
          <radialGradient id="cyan-orb" cx="50%" cy="50%" r="50%">
            <stop offset="0%" style="stop-color:#00d4ff;stop-opacity:0.3" />
            <stop offset="100%" style="stop-color:#00d4ff;stop-opacity:0" />
          </radialGradient>
          
          <!-- Violet orb gradient -->
          <radialGradient id="violet-orb" cx="50%" cy="50%" r="50%">
            <stop offset="0%" style="stop-color:#7c3aed;stop-opacity:0.25" />
            <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:0" />
          </radialGradient>
          
          <!-- Magenta orb gradient -->
          <radialGradient id="magenta-orb" cx="50%" cy="50%" r="50%">
            <stop offset="0%" style="stop-color:#ff00aa;stop-opacity:0.15" />
            <stop offset="100%" style="stop-color:#ff00aa;stop-opacity:0" />
          </radialGradient>
          
          <!-- Blur filter -->
          <filter id="blur">
            <feGaussianBlur stdDeviation="60" />
          </filter>
        </defs>
        
        <!-- Background -->
        <rect width="1920" height="1080" fill="url(#bg)" />
        
        <!-- Luminescent orbs -->
        <ellipse cx="400" cy="350" rx="350" ry="350" fill="url(#cyan-orb)" filter="url(#blur)" />
        <ellipse cx="1500" cy="700" rx="300" ry="300" fill="url(#violet-orb)" filter="url(#blur)" />
        <ellipse cx="960" cy="200" rx="200" ry="200" fill="url(#magenta-orb)" filter="url(#blur)" />
        <ellipse cx="1700" cy="250" rx="250" ry="250" fill="url(#cyan-orb)" filter="url(#blur)" opacity="0.5" />
        <ellipse cx="200" cy="900" rx="280" ry="280" fill="url(#violet-orb)" filter="url(#blur)" opacity="0.7" />
        
        <!-- Subtle accent dots -->
        <circle cx="300" cy="450" r="3" fill="#00d4ff" opacity="0.6" />
        <circle cx="1600" cy="500" r="4" fill="#ff00aa" opacity="0.5" />
        <circle cx="960" cy="800" r="5" fill="#7c3aed" opacity="0.7" />
        
        <!-- Very subtle noise texture overlay would go here in production -->
      </svg>
    '';
  };

  # ============================================
  # README for wallpaper setup
  # ============================================
  home.file."Pictures/wallpapers/README.md".text = ''
    # Glassmorphism Wallpapers

    ## Quick Start

    1. **Generate a wallpaper** (recommended):
       ```bash
       generate-glassmorphism-wallpaper 1920 1080
       ```

    2. **Or download a curated wallpaper**:
       ```bash
       download-glassmorphism-wallpaper
       ```

    3. **Set a custom wallpaper**:
       ```bash
       set-wallpaper ~/Pictures/wallpapers/your-image.png
       ```

    ## Color Palette

    The glassmorphism theme uses these colors:
    - **Background**: `#0a0a0f` (deep dark)
    - **Cyan accent**: `#00d4ff` (electric cyan - primary)
    - **Violet accent**: `#7c3aed` (soft violet - secondary)
    - **Magenta accent**: `#ff00aa` (neon magenta - danger/alert)

    ## Recommended Sources

    For high-quality dark abstract wallpapers:
    - Unsplash (search: "dark gradient", "abstract dark", "neon gradient")
    - Wallhaven (search: "dark minimalist", "cyberpunk gradient")
    - r/wallpaper (filter by dark/AMOLED)

    ## File Location

    Place your wallpaper at:
    ```
    ~/Pictures/wallpapers/glassmorphism-default.png
    ```

    The swaybg service will automatically use this file.
  '';
}