# ============================================
# Hyprland Modular - Window Rules System
# ============================================
# Declarative window rules organized by:
# - development: IDEs, terminals, editors
# - browsers: Web browsers
# - fileManagers: File managers
# - systemUtilities: System tools
# - media: Players, viewers
# - productivity: Notes, PDFs
# - communication: Chat apps
# - dialogs: Modal dialogs
# - performance: Performance optimizations
# - gaming: Game-specific rules
# ============================================
{
  lib,
  pkgs,
  hyprLib,
  cfg,
}:

let
  inherit (hyprLib) appRule floatingApp dialogRule;

  # Theme-aware opacity helper
  # Uses slightly lower opacity for inactive windows
  opacityRule =
    class: active: inactive:
    "opacity ${toString active} ${toString inactive}, class:^(${class})$";

in
rec {
  # ==========================================
  # RULE CATEGORIES
  # ==========================================

  categories = {
    # ----------------------------------------
    # DEVELOPMENT - IDEs, terminals, editors
    # ----------------------------------------
    development = lib.flatten [
      # Terminals - High transparency for background visibility
      (appRule {
        class = "kitty";
        opacity = 0.92;
        extra = [ "animation slide" ];
      })
      (appRule {
        class = "Alacritty";
        opacity = 0.90;
      })
      (appRule {
        class = "foot";
        opacity = 0.90;
      })
      (appRule {
        class = "wezterm";
        opacity = 0.92;
      })

      # Code editors - Slightly less transparent
      (appRule {
        class = "code-oss";
        opacity = 0.95;
      })
      (appRule {
        class = "Code";
        opacity = 0.95;
      })
      (appRule {
        class = "VSCodium";
        opacity = 0.95;
      })
      (appRule {
        class = "codium";
        opacity = 0.95;
      })
      (appRule {
        class = "neovide";
        opacity = 0.95;
      })
      (appRule {
        class = "jetbrains-.*";
        opacity = 0.96;
      })
      (appRule {
        class = "emacs";
        opacity = 0.95;
      })
    ];

    # ----------------------------------------
    # BROWSERS - Web browsers (near opaque)
    # ----------------------------------------
    browsers = lib.flatten [
      (appRule {
        class = "firefox";
        opacity = 0.98;
      })
      (appRule {
        class = "Firefox";
        opacity = 0.98;
      })
      (appRule {
        class = "firefox-esr";
        opacity = 0.98;
      })
      (appRule {
        class = "brave-browser";
        opacity = 0.98;
      })
      (appRule {
        class = "chromium";
        opacity = 0.98;
      })
      (appRule {
        class = "Google-chrome";
        opacity = 0.98;
      })
      (appRule {
        class = "zen-browser";
        opacity = 0.98;
      })
      (appRule {
        class = "librewolf";
        opacity = 0.98;
      })
    ];

    # ----------------------------------------
    # FILE MANAGERS
    # ----------------------------------------
    fileManagers = lib.flatten [
      (floatingApp "nemo" 1200 700 ++ [ "opacity 0.92 0.88, class:^(nemo)$" ])
      (floatingApp "thunar" 1200 700 ++ [ "opacity 0.92 0.88, class:^(thunar)$" ])
      (floatingApp "nautilus" 1200 700 ++ [ "opacity 0.92 0.88, class:^(nautilus)$" ])
      (floatingApp "dolphin" 1200 700 ++ [ "opacity 0.92 0.88, class:^(dolphin)$" ])
      (floatingApp "pcmanfm" 1200 700 ++ [ "opacity 0.92 0.88, class:^(pcmanfm)$" ])
    ];

    # ----------------------------------------
    # SYSTEM UTILITIES
    # ----------------------------------------
    systemUtilities = lib.flatten [
      # Audio control
      (floatingApp "pavucontrol" 800 500)
      (floatingApp "org.pulseaudio.pavucontrol" 800 500)

      # Network
      (floatingApp "nm-connection-editor" 600 400)
      (floatingApp "nm-applet" 400 300)

      # Bluetooth
      (floatingApp "blueman-manager" 600 400)
      (floatingApp ".blueman-manager-wrapped" 600 400)

      # System monitor
      (floatingApp "gnome-system-monitor" 1000 700)
      (floatingApp "btop" 1200 800)

      # Settings
      (floatingApp "gnome-control-center" 900 600)
      (floatingApp "nwg-look" 800 600)

      # Calculator
      (floatingApp "gnome-calculator" 400 500)
      (floatingApp "qalculate-gtk" 500 400)
    ];

    # ----------------------------------------
    # MEDIA - Players and viewers
    # ----------------------------------------
    media = lib.flatten [
      # Image viewers
      (floatingApp "imv" 1400 900)
      (floatingApp "feh" 1400 900)
      (floatingApp "eog" 1200 800)
      (floatingApp "loupe" 1200 800)

      # Video players
      (floatingApp "mpv" 1280 720)
      (floatingApp "vlc" 1280 720)
      (floatingApp "celluloid" 1280 720)

      # Picture-in-Picture (stay on top)
      [
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "size 400 225, title:^(Picture-in-Picture)$"
        "move 100%-420 100%-245, title:^(Picture-in-Picture)$"
      ]

      # Music players
      (appRule {
        class = "spotify";
        opacity = 0.95;
      })
      (appRule {
        class = "Spotify";
        opacity = 0.95;
      })
    ];

    # ----------------------------------------
    # PRODUCTIVITY
    # ----------------------------------------
    productivity = lib.flatten [
      # Password managers
      (floatingApp "org.keepassxc.KeePassXC" 1000 700)
      (floatingApp "1password" 1000 700)
      (floatingApp "bitwarden" 1000 700)

      # Note-taking
      (appRule {
        class = "obsidian";
        opacity = 0.95;
      })
      (appRule {
        class = "logseq";
        opacity = 0.95;
      })
      (appRule {
        class = "notion-app";
        opacity = 0.95;
      })

      # PDF viewers
      (appRule {
        class = "org.pwmt.zathura";
        opacity = 0.98;
      })
      (appRule {
        class = "evince";
        opacity = 0.98;
      })
      (appRule {
        class = "okular";
        opacity = 0.98;
      })

      # Office
      (appRule {
        class = "libreoffice-.*";
        opacity = 0.98;
      })
    ];

    # ----------------------------------------
    # COMMUNICATION
    # ----------------------------------------
    communication = lib.flatten [
      (appRule {
        class = "discord";
        opacity = 0.95;
      })
      (appRule {
        class = "Discord";
        opacity = 0.95;
      })
      (appRule {
        class = "vesktop";
        opacity = 0.95;
      })
      (appRule {
        class = "slack";
        opacity = 0.95;
      })
      (appRule {
        class = "Slack";
        opacity = 0.95;
      })
      (appRule {
        class = "teams";
        opacity = 0.95;
      })
      (appRule {
        class = "Microsoft Teams.*";
        opacity = 0.95;
      })
      (appRule {
        class = "telegram-desktop";
        opacity = 0.95;
      })
      (appRule {
        class = "Signal";
        opacity = 0.95;
      })
      (appRule {
        class = "element";
        opacity = 0.95;
      })
      (appRule {
        class = "thunderbird";
        opacity = 0.96;
      })
    ];

    # ----------------------------------------
    # DIALOGS - Modal dialogs
    # ----------------------------------------
    dialogs = lib.flatten [
      # File dialogs
      [
        "float, title:^(Open File)$"
        "float, title:^(Save File)$"
        "float, title:^(Save As)$"
        "float, title:^(Choose Files)$"
        "float, title:^(Select Folder)$"
        "float, title:^(Open Folder)$"
      ]

      # Polkit authentication
      [
        "float, class:^(polkit-gnome-authentication-agent-1)$"
        "pin, class:^(polkit-gnome-authentication-agent-1)$"
        "stayfocused, class:^(polkit-gnome-authentication-agent-1)$"
        "size 450 200, class:^(polkit-gnome-authentication-agent-1)$"
        "center, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
      ]

      # Confirmation dialogs
      (dialogRule "Confirm")
      (dialogRule "Delete")
      (dialogRule "Warning")
      (dialogRule "Error")
      (dialogRule "Alert")

      # File operations
      [
        "float, title:^(File Operation Progress)$"
        "pin, title:^(File Operation Progress)$"
        "center, title:^(File Operation Progress)$"
      ]

      # Screenshot tools
      (floatingApp "swappy" 1000 700 ++ [ "opacity 0.95 0.90, class:^(swappy)$" ])
    ];

    # ----------------------------------------
    # PERFORMANCE - Performance optimizations
    # ----------------------------------------
    performance = [
      # Disable animations for launchers (snappier feel)
      "noanim, class:^(wofi)$"
      "noanim, class:^(rofi)$"
      "noanim, class:^(fuzzel)$"
      "noanim, title:^(wlogout)$"

      # Immediate rendering for terminals (reduce input latency)
      "immediate, class:^(kitty)$"
      "immediate, class:^(Alacritty)$"
      "immediate, class:^(foot)$"
      "immediate, class:^(wezterm)$"
    ];

    # ----------------------------------------
    # GAMING - Game-specific rules
    # ----------------------------------------
    gaming = [
      # Steam games (allow tearing, immediate render)
      "immediate, class:^(steam_app_).*$"
      "fullscreen, class:^(steam_app_).*$"

      # Gamescope
      "immediate, class:^(gamescope)$"
      "fullscreen, class:^(gamescope)$"

      # Lutris
      "immediate, class:^(lutris)$"

      # Wine/Proton games
      "immediate, class:^(.*\.exe)$"

      # Steam client
      "float, class:^(steam)$, title:^(Steam - News)$"
      "float, class:^(steam)$, title:^(Friends List)$"

      # Heroic Games Launcher
      (floatingApp "heroic" 1200 800)
    ];
  };

  # ==========================================
  # LAYER RULES - Blur for glassmorphism
  # ==========================================
  layerRules = [
    "blur, waybar"
    "blur, notifications"
    "blur, wofi"
    "blur, rofi"
    "blur, fuzzel"
    "blur, swappy"
    "blur, logout_dialog"
    "blur, hyprlock"
    "blur, gtk-layer-shell"
    "blur, wlogout"
    "blur, mako"
  ];

  # ==========================================
  # RESOLVER - Combine selected categories
  # ==========================================
  resolveCategories = categoryList: lib.flatten (map (c: categories.${c} or [ ]) categoryList);
}
