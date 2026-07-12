# ============================================
# Niri Configuration - Glassmorphism Edition
# ============================================
# KDL gerado como raw string — o gerador KDL customizado (home/niri.nix)
# não serializa spring params nem rgba corretamente, então geramos direto.
# As cores vêm do design system glassmorphism/colors.nix via interpolação Nix.
# ============================================

{
  lib,
  pkgs,
  config,
  ...
}:

let
  colors = config.glassmorphism.colors;

  # Wallpaper 4K gerado no nix store usando as cores do design system
  aestheticWallpaper = pkgs.runCommand "niri-wallpaper" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    magick -size 3840x2160 gradient:"${colors.base.bg0}-${colors.base.overlay}" $out/wallpaper.png
  '';

  screenshotScript = pkgs.writeShellScriptBin "niri-screenshot" ''
    #!/usr/bin/env bash
    case "$1" in
      region)    grim -g "$(slurp)" - | swappy -f - ;;
      screen)    grim - | swappy -f - ;;
      window)    grim -g "$(slurp)" - | swappy -f - ;;
      clipboard) grim -g "$(slurp)" - | wl-copy ;;
      *)         echo "Usage: niri-screenshot [region|screen|window|clipboard]" ;;
    esac
  '';
in
{
  home.packages = with pkgs; [
    swww           # wallpaper animado com transições
    swaylock
    swayidle
    grim
    slurp
    swappy
    screenshotScript
    hyprpicker
    playerctl
    brightnessctl
    wl-clipboard
    cliphist
    libnotify
  ];

  # Config KDL raw — bypassa o gerador customizado com force=true
  xdg.configFile."niri/config.kdl" = {
    force = true;
    text = ''
      input {
          keyboard {
              xkb {
                  layout "br"
                  options "caps:escape"
              }
              repeat-delay 300
              repeat-rate 50
          }
          mouse {
              accel-profile "flat"
          }
          touchpad {
              tap
              natural-scroll false
              dwt
              accel-profile "adaptive"
          }
          focus-follows-mouse {
              enable
              max-scroll-amount "25%"
          }
          warp-mouse-to-focus
      }

      layout {
          gaps 16
          center-focused-column "on-overflow"
          preset-column-widths {
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
              proportion 1.0
          }
          default-column-width { proportion 0.5; }

          // Focus ring: gradiente cyan→violet do design system
          focus-ring {
              width 2
              active-gradient from="${colors.accent.cyan}" to="${colors.accent.violet}" angle=45 relative-to="workspace-view"
              inactive-gradient from="${colors.base.bg3}88" to="${colors.base.bg3}44" angle=45
          }

          // Border semi-transparente glassmorphism
          border {
              width 1
              active-gradient from="${colors.accent.cyan}44" to="${colors.accent.violet}44" angle=45 relative-to="workspace-view"
              inactive-gradient from="${colors.base.bg3}22" to="${colors.base.bg3}11" angle=45
          }

          // Sombra suave com glow
          shadow {
              on
              softness 40
              spread 5
              offset-x 0
              offset-y 8
              draw-behind-window true
              color "#00000070"
          }
      }

      // ──────────────────────────────────────────────────────────────
      // OUTPUT — Monitor 144Hz + VRR
      // Descomente e ajuste o nome da saída (use `niri msg outputs`)
      // ──────────────────────────────────────────────────────────────
      // output "eDP-1" {
      //     mode "1920x1080@144.000"
      //     scale 1.0
      //     variable-refresh-rate on-demand
      // }
      // output "DP-1" {
      //     mode "1920x1080@144.000"
      //     scale 1.0
      //     variable-refresh-rate on-demand
      //     position x=1920 y=0
      // }

      cursor {
          theme "Bibata-Modern-Classic"
          size 24
      }

      prefer-no-csd
      screenshot-path "~/Pictures/Screenshots/screenshot-%Y%m%d-%H%M%S.png"

      // Cantos arredondados + clip glassmorphism em todas as janelas
      window-rule {
          geometry-corner-radius 14
          clip-to-geometry true
      }

      // Floating windows
      window-rule {
          match app-id="^pavucontrol$"
          match app-id="^nm-connection-editor$"
          match app-id="^blueman-manager$"
          match app-id="^nemo$"
          match app-id="^thunar$"
          match app-id="^imv$"
          match app-id="^mpv$"
          match app-id="^swappy$"
          match title="^Picture-in-Picture$"
          open-floating true
      }

      // Terminais: mais transparentes
      window-rule {
          match app-id="^kitty$"
          match app-id="^Alacritty$"
          match app-id="^foot$"
          opacity 0.92
      }

      // Editors: levemente transparentes
      window-rule {
          match app-id="^code-oss$"
          match app-id="^Code$"
          match app-id="^VSCodium$"
          match app-id="^codium$"
          opacity 0.95
      }

      // Browsers: mais largos por padrão
      window-rule {
          match app-id="^firefox$"
          match app-id="^brave-browser$"
          match app-id="^chromium$"
          default-column-width { proportion 0.66667; }
      }

      // Browsers: quase opacos (legibilidade)
      window-rule {
          match app-id="^firefox$"
          match app-id="^brave-browser$"
          match app-id="^chromium$"
          opacity 0.98
      }

      // Agent Hub
      window-rule {
          match app-id="^agent-hub-.*$"
          open-floating true
          opacity 0.95
      }

      // Animações elásticas spring (damping < 1.0 = bounce)
      animations {
          workspace-switch {
              spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001
          }
          horizontal-view-movement {
              spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001
          }
          window-open {
              duration-ms 350
              curve "ease-out-expo"
          }
          window-close {
              duration-ms 200
              curve "ease-in-expo"
          }
          window-movement {
              spring damping-ratio=0.7 stiffness=800 epsilon=0.0001
          }
          window-resize {
              spring damping-ratio=0.7 stiffness=800 epsilon=0.0001
          }
          config-notification-open-close {
              spring damping-ratio=0.6 stiffness=1000 epsilon=0.001
          }
      }

      spawn-at-startup "waybar"
      spawn-at-startup "mako"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "nm-applet" "--indicator"
      spawn-at-startup "swww-daemon"
      spawn-at-startup "sh" "-c" "sleep 0.5 && swww img ${aestheticWallpaper}/wallpaper.png --transition-type grow --transition-pos 0.5,0.5 --transition-duration 2 --transition-fps 60"
      spawn-at-startup "sh" "-c" "wl-paste --type text --watch cliphist store"
      spawn-at-startup "sh" "-c" "wl-paste --type image --watch cliphist store"
      spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f" "timeout" "600" "niri msg action power-off-monitors" "resume" "niri msg action power-on-monitors" "before-sleep" "swaylock -f"

      environment {
          QT_QPA_PLATFORM "wayland"
          SDL_VIDEODRIVER "wayland"
          CLUTTER_BACKEND "wayland"
          GDK_BACKEND "wayland,x11"
          XDG_CURRENT_DESKTOP "niri"
          XDG_SESSION_TYPE "wayland"
          XDG_SESSION_DESKTOP "niri"
          GBM_BACKEND "nvidia-drm"
          __GLX_VENDOR_LIBRARY_NAME "nvidia"
          WLR_NO_HARDWARE_CURSORS "1"
          NVD_BACKEND "direct"
          MOZ_ENABLE_WAYLAND "1"
          ELECTRON_OZONE_PLATFORM_HINT "auto"
          GTK_THEME "Adwaita:dark"
          QT_STYLE_OVERRIDE "kvantum"
      }

      workspace "dev"
      workspace "web"
      workspace "chat"
      workspace "media"
      workspace "sys"

      binds {
          // ── Terminais ──────────────────────────────────────────────
          Mod+Return { spawn "kitty" "-e" "zellij" "attach" "--create" "main"; }
          Mod+Shift+Return { spawn "alacritty" "-e" "zellij" "attach" "--create" "alt"; }
          Mod+Ctrl+Return { spawn "kitty"; }
          Mod+Alt+Return { spawn "foot"; }

          // ── Launchers ──────────────────────────────────────────────
          Mod+D { spawn "wofi" "--show" "drun"; }
          Mod+Shift+D { spawn "wofi" "--show" "run"; }
          Mod+E { spawn "nemo"; }

          // ── Janelas ────────────────────────────────────────────────
          Mod+Q { close-window; }
          Mod+Shift+Q { quit skip-confirmation=true; }

          // ── Foco ───────────────────────────────────────────────────
          Mod+H { focus-column-left; }
          Mod+L { focus-column-right; }
          Mod+Left { focus-column-left; }
          Mod+Right { focus-column-right; }
          Mod+K { focus-window-up; }
          Mod+J { focus-window-down; }
          Mod+Up { focus-window-up; }
          Mod+Down { focus-window-down; }
          Mod+Home { focus-column-first; }
          Mod+End { focus-column-last; }

          // ── Mover ──────────────────────────────────────────────────
          Mod+Shift+H { move-column-left; }
          Mod+Shift+L { move-column-right; }
          Mod+Shift+Left { move-column-left; }
          Mod+Shift+Right { move-column-right; }
          Mod+Shift+K { move-window-up; }
          Mod+Shift+J { move-window-down; }
          Mod+Shift+Up { move-window-up; }
          Mod+Shift+Down { move-window-down; }
          Mod+Shift+Home { move-column-to-first; }
          Mod+Shift+End { move-column-to-last; }

          // ── Colunas ────────────────────────────────────────────────
          Mod+BracketLeft { consume-window-into-column; }
          Mod+BracketRight { expel-window-from-column; }
          Mod+R { switch-preset-column-width; }
          Mod+Ctrl+H { set-column-width "-10%"; }
          Mod+Ctrl+L { set-column-width "+10%"; }
          Mod+Ctrl+Left { set-column-width "-10%"; }
          Mod+Ctrl+Right { set-column-width "+10%"; }
          Mod+Ctrl+K { set-window-height "-10%"; }
          Mod+Ctrl+J { set-window-height "+10%"; }
          Mod+Ctrl+Up { set-window-height "-10%"; }
          Mod+Ctrl+Down { set-window-height "+10%"; }
          Mod+Ctrl+R { reset-window-height; }

          // ── Fullscreen ─────────────────────────────────────────────
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }

          // ── Floating ───────────────────────────────────────────────
          Mod+V { toggle-window-floating; }
          Mod+Shift+V { switch-focus-between-floating-and-tiling; }

          // ── Workspaces ─────────────────────────────────────────────
          Mod+1 { focus-workspace "dev"; }
          Mod+2 { focus-workspace "web"; }
          Mod+3 { focus-workspace "chat"; }
          Mod+4 { focus-workspace "media"; }
          Mod+5 { focus-workspace "sys"; }
          Mod+Shift+1 { move-window-to-workspace "dev"; }
          Mod+Shift+2 { move-window-to-workspace "web"; }
          Mod+Shift+3 { move-window-to-workspace "chat"; }
          Mod+Shift+4 { move-window-to-workspace "media"; }
          Mod+Shift+5 { move-window-to-workspace "sys"; }
          Mod+Page_Up { focus-workspace-up; }
          Mod+Page_Down { focus-workspace-down; }

          // ── Monitor ────────────────────────────────────────────────
          Mod+Shift+Ctrl+H { move-column-to-monitor-left; }
          Mod+Shift+Ctrl+L { move-column-to-monitor-right; }
          Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
          Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

          // ── Canvas scroll ──────────────────────────────────────────
          Mod+Ctrl+Shift+H { focus-column-left-or-last; }
          Mod+Ctrl+Shift+L { focus-column-right-or-first; }
          Mod+Ctrl+C { center-column; }

          // ── Screenshots ────────────────────────────────────────────
          Print { screenshot; }
          Shift+Print { screenshot-screen; }
          Ctrl+Print { screenshot-window; }
          Mod+Print { spawn "${screenshotScript}/bin/niri-screenshot" "region"; }

          // ── Áudio ──────────────────────────────────────────────────
          XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
          XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
          XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
          XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }

          // ── Brilho ─────────────────────────────────────────────────
          XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "5%+"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }

          // ── Lock / Power ───────────────────────────────────────────
          Super+Alt+L { spawn "swaylock" "-f"; }
          Mod+Escape { spawn "wlogout" "-p" "layer-shell"; }
          Mod+Shift+Escape { spawn "systemctl" "suspend"; }
          Mod+Shift+P { power-off-monitors; }

          // ── Utilitários ────────────────────────────────────────────
          Mod+C { spawn "sh" "-c" "cliphist list | wofi --dmenu | cliphist decode | wl-copy"; }
          Mod+Shift+C { spawn "hyprpicker" "-a"; }
          Mod+N { spawn "makoctl" "dismiss"; }
          Mod+Shift+N { spawn "makoctl" "dismiss" "--all"; }
          Mod+Shift+W { spawn "sh" "-c" "killall waybar; waybar &"; }

          // ── Agent Hub ──────────────────────────────────────────────
          Mod+A { spawn "${config.home.homeDirectory}/.config/agent-hub/agent-launcher.sh"; }
          Mod+Shift+A { spawn "${config.home.homeDirectory}/.config/agent-hub/quick-prompt.sh"; }

          // ── Help ───────────────────────────────────────────────────
          Mod+Shift+Slash { show-hotkey-overlay; }
      }
    '';
  };

  # ============================================
  # SWAYLOCK — glassmorphism lock screen
  # ============================================
  programs.swaylock = {
    enable = true;
    settings = {
      color = lib.removePrefix "#" colors.base.bg0;
      image = "${config.home.homeDirectory}/Pictures/wallpapers/glassmorphism-default.png";
      effect-blur = "10x3";
      effect-vignette = "0.5:0.5";
      ring-color = lib.removePrefix "#" colors.accent.cyan;
      ring-ver-color = lib.removePrefix "#" colors.accent.violet;
      ring-wrong-color = lib.removePrefix "#" colors.accent.magenta;
      ring-clear-color = lib.removePrefix "#" colors.accent.green;
      key-hl-color = lib.removePrefix "#" colors.accent.cyan;
      bs-hl-color = lib.removePrefix "#" colors.accent.magenta;
      inside-color = lib.removePrefix "#" colors.base.bg1;
      inside-ver-color = lib.removePrefix "#" colors.base.bg1;
      inside-wrong-color = "1a0a12";
      inside-clear-color = lib.removePrefix "#" colors.base.bg1;
      text-color = lib.removePrefix "#" colors.base.fg1;
      text-ver-color = lib.removePrefix "#" colors.accent.cyan;
      text-wrong-color = lib.removePrefix "#" colors.accent.magenta;
      text-clear-color = lib.removePrefix "#" colors.accent.green;
      indicator-radius = 120;
      indicator-thickness = 10;
      font = "JetBrainsMono Nerd Font";
      font-size = 24;
      ignore-empty-password = true;
      show-failed-attempts = true;
      fade-in = 0.2;
    };
  };
}
