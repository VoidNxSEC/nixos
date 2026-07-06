# ============================================
# Wallpaper Management - AI-Driven Dynamic Wallpapers
# ============================================
# awww daemon + llama.cpp color generation +
# ImageMagick procedural rendering + systemd timer
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
  currentWallpaper = "${wallpaperDir}/ai-current.png";

  aiWallpaperScript = pkgs.writeShellScriptBin "ai-wallpaper-gen" ''
    #!/usr/bin/env bash
    set -euo pipefail

    WALLPAPER_DIR="${wallpaperDir}"
    OUTPUT="$WALLPAPER_DIR/ai-current.png"
    WIDTH=1920
    HEIGHT=1080
    LLAMA_URL="http://127.0.0.1:8080"

    mkdir -p "$WALLPAPER_DIR"

    # ── Fallback color palettes ─────────────────────────────────
    # TODO(human): Add your own palette entries here.
    # Format: "name:#bg:#c1:#c2:#c3"
    #   bg  = very dark near-black (#000000 to #151520)
    #   c1/c2/c3 = vibrant electric/neon accent colors
    # Example: "synthwave:#05050d:#ff6b9d:#c44dff:#4dd9ff"
    PALETTES=(
    )

    # ── Try AI palette via llama.cpp ────────────────────────────
    ai_palette() {
      local response json
      response=$(${pkgs.curl}/bin/curl -sf --connect-timeout 3 --max-time 10 \
        "$LLAMA_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d '{"model":"default","messages":[{"role":"user","content":"Generate a stunning dark desktop wallpaper color palette. Reply ONLY with compact JSON, no markdown or explanation: {\"bg\":\"#RRGGBB\",\"c1\":\"#RRGGBB\",\"c2\":\"#RRGGBB\",\"c3\":\"#RRGGBB\"}. Rules: bg must be near-black very dark, c1/c2/c3 must be vivid electric neon contrasting colors that look great on dark backgrounds."}],"temperature":1.3,"max_tokens":60,"stream":false}' \
        2>/dev/null) || return 1

      json=$(echo "$response" \
        | ${pkgs.jq}/bin/jq -r '.choices[0].message.content // ""' 2>/dev/null \
        | grep -oP '\{[^}]+\}' | head -1) || return 1

      [[ -z "$json" ]] && return 1

      BG=$(echo "$json" | grep -oP '"bg"\s*:\s*"\K#[0-9a-fA-F]{6}')
      C1=$(echo "$json" | grep -oP '"c1"\s*:\s*"\K#[0-9a-fA-F]{6}')
      C2=$(echo "$json" | grep -oP '"c2"\s*:\s*"\K#[0-9a-fA-F]{6}')
      C3=$(echo "$json" | grep -oP '"c3"\s*:\s*"\K#[0-9a-fA-F]{6}')

      [[ -n "$BG" && -n "$C1" && -n "$C2" && -n "$C3" ]] || return 1
      echo "[ai-wallpaper] AI palette: bg=$BG c1=$C1 c2=$C2 c3=$C3" >&2
    }

    # ── Random fallback palette ─────────────────────────────────
    random_palette() {
      if [[ ''${#PALETTES[@]} -eq 0 ]]; then
        BG="#0a0a0f"; C1="#00d4ff"; C2="#7c3aed"; C3="#ff00aa"
        echo "[ai-wallpaper] No palettes defined, using built-in default" >&2
        return 0
      fi
      local entry="''${PALETTES[$((RANDOM % ''${#PALETTES[@]}))]}"
      IFS=':' read -r _ BG C1 C2 C3 <<< "$entry"
      echo "[ai-wallpaper] Random palette: bg=$BG c1=$C1 c2=$C2 c3=$C3" >&2
    }

    # Select palette (AI first, random fallback)
    if ! ai_palette 2>/dev/null; then
      random_palette
    fi

    # ── Randomize orb positions ─────────────────────────────────
    R() { echo $(( RANDOM % $1 )); }
    X1=$(( $(R 500) + 80  )) ; Y1=$(( $(R 380) + 80  ))
    X2=$(( $(R 500) + 880 )) ; Y2=$(( $(R 380) + 380 ))
    X3=$(( $(R 400) + 580 )) ; Y3=$(( $(R 280) + 40  ))
    X4=$(( $(R 380) + 40  )) ; Y4=$(( $(R 380) + 480 ))
    X5=$(( $(R 480) + 1150)) ; Y5=$(( $(R 180) + 130 ))
    X6=$(( $(R 580) + 280 )) ; Y6=$(( $(R 180) + 780 ))

    # ── Render via ImageMagick ──────────────────────────────────
    # Layer 1: large soft orbs with heavy blur (background ambiance)
    # Layer 2: small bright highlight dots with medium blur (focal points)
    # Layer 3: Gaussian noise for texture
    ${pkgs.imagemagick}/bin/magick \
      -size "''${WIDTH}x''${HEIGHT}" xc:"$BG" \
      -fill "''${C1}1a" -draw "circle ''${X1},''${Y1} $((X1+320)),''${Y1}" \
      -fill "''${C2}16" -draw "circle ''${X2},''${Y2} $((X2+380)),''${Y2}" \
      -fill "''${C3}12" -draw "circle ''${X3},''${Y3} $((X3+260)),''${Y3}" \
      -fill "''${C1}0e" -draw "circle ''${X4},''${Y4} $((X4+430)),''${Y4}" \
      -fill "''${C2}12" -draw "circle ''${X5},''${Y5} $((X5+220)),''${Y5}" \
      -fill "''${C3}0a" -draw "circle ''${X6},''${Y6} $((X6+340)),''${Y6}" \
      -blur 0x72 \
      -fill "''${C1}dd" -draw "circle $((X1+8)),$((Y1+8)) $((X1+12)),$((Y1+8))" \
      -fill "''${C2}dd" -draw "circle $((X2-10)),$((Y2+14)) $((X2-7)),$((Y2+14))" \
      -fill "''${C3}bb" -draw "circle $((X3+6)),$((Y3-7)) $((X3+9)),$((Y3-7))" \
      -fill "''${C1}99" -draw "circle $((X4+18)),$((Y4-4)) $((X4+21)),$((Y4-4))" \
      -blur 0x18 \
      -attenuate 0.016 +noise Gaussian \
      -modulate 100,118,100 \
      "$OUTPUT"

    echo "[ai-wallpaper] Generated: $OUTPUT"

    # ── Apply via swww with animated transition ─────────────────
    if ${pkgs.swww}/bin/swww query &>/dev/null 2>&1; then
      ${pkgs.swww}/bin/swww img "$OUTPUT" \
        --transition-type random \
        --transition-fps 60 \
        --transition-duration 1.5 \
        --transition-bezier 0.25,0.46,0.45,0.94
      echo "[ai-wallpaper] Applied via swww"
    else
      echo "[ai-wallpaper] swww daemon not running; wallpaper ready at $OUTPUT" >&2
    fi
  '';

in
{
  # ============================================
  # PACKAGES
  # ============================================
  home.packages = with pkgs; [
    awww # Animated wallpaper daemon (replaces swaybg)
    imagemagick # Procedural wallpaper rendering
    jq # JSON parsing for AI response
    curl # llama.cpp API calls
    aiWallpaperScript # ai-wallpaper-gen command
  ];

  # ============================================
  # WALLPAPER DIRECTORY
  # ============================================
  home.activation.createWallpaperDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${wallpaperDir}
  '';

  # ============================================
  # SYSTEMD: swww daemon
  # ============================================
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww animated wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ============================================
  # SYSTEMD: wallpaper generator (oneshot)
  # ============================================
  systemd.user.services.ai-wallpaper = {
    Unit = {
      Description = "AI wallpaper generator";
      After = [
        "awww-daemon.service"
        "graphical-session.target"
      ];
      Wants = [ "awww-daemon.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2"; # Wait for swww daemon
      ExecStart = "${aiWallpaperScript}/bin/ai-wallpaper-gen";
    };
  };

  # ============================================
  # SYSTEMD: rotation timer (30s boot delay, then every 2h)
  # ============================================
  systemd.user.timers.ai-wallpaper = {
    Unit.Description = "AI wallpaper rotation timer";
    Timer = {
      OnBootSec = "30s";
      OnUnitActiveSec = "2h";
      Unit = "ai-wallpaper.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
