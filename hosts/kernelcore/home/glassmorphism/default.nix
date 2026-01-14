# ============================================
# Glassmorphism Design System - Main Module
# ============================================
# Premium dark glassmorphism theme for NixOS/Hyprland
#
# Components:
# - colors.nix     → Design tokens and color palette
# - waybar.nix     → Status bar with GPU/SSH modules
# - mako.nix       → Notification daemon
# - wofi.nix       → Application launcher
# - hyprlock.nix   → Lock screen
# - wlogout.nix    → Logout menu
# - swappy.nix     → Screenshot editor
# - agent-hub.nix  → AI agent integration placeholder
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
  imports = [
    ./colors.nix
    ./kitty.nix # NEW - Kitty terminal with glassmorphism theme
    ./zellij.nix # NEW - Zellij multiplexer with glassmorphism KDL theme
    ./wallpaper.nix # NEW - Wallpaper management with swaybg service
    ./waybar.nix
    ./mako.nix
    ./wofi.nix
    ./hyprlock.nix
    ./wlogout.nix
    ./swappy.nix
    ./agent-hub.nix
  ];

  # ============================================
  # GLASSMORPHISM GTK THEME
  # ============================================
  gtk = {
    enable = true;

    # Dark theme with custom accent
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    # Papirus icons (dark variant)
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # Cursor theme
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    # GTK2 settings
    gtk2.extraConfig = ''
      gtk-application-prefer-dark-theme=1
    '';

    # GTK3 settings
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "appmenu:none";
      gtk-enable-animations = true;
    };

    # GTK4 settings
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "appmenu:none";
      gtk-enable-animations = true;
    };
  };

  # GTK4 CSS for glassmorphism customizations (using design tokens)
  xdg.configFile."gtk-4.0/colors.css".text = ''
    /* ============================================
     * Glassmorphism GTK4 Color Overrides
     * Using design tokens from colors.nix
     * ============================================ */

    @define-color accent_bg_color ${colors.accent.cyan};
    @define-color accent_fg_color ${colors.base.bg0};
    @define-color accent_color ${colors.accent.cyan};

    @define-color window_bg_color ${colors.base.bg1};
    @define-color window_fg_color ${colors.base.fg1};

    @define-color view_bg_color ${colors.base.bg0};
    @define-color view_fg_color ${colors.base.fg1};

    @define-color headerbar_bg_color ${colors.base.bg1};
    @define-color headerbar_fg_color ${colors.base.fg1};
    @define-color headerbar_border_color ${colors.border.light};

    @define-color card_bg_color ${colors.base.bg2};
    @define-color card_fg_color ${colors.base.fg1};

    @define-color popover_bg_color ${colors.base.bg2};
    @define-color popover_fg_color ${colors.base.fg1};

    @define-color dialog_bg_color ${colors.base.bg1};
    @define-color dialog_fg_color ${colors.base.fg1};

    @define-color sidebar_bg_color ${colors.base.bg0};
    @define-color sidebar_fg_color ${colors.base.fg2};

    @define-color borders ${colors.border.lighter};

    @define-color success_color ${colors.accent.green};
    @define-color warning_color ${colors.accent.yellow};
    @define-color error_color ${colors.accent.magenta};
    @define-color destructive_color ${colors.accent.magenta};
  '';

  # ============================================
  # QT THEME (matches GTK)
  # ============================================
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "kvantum";
      package = pkgs.libsForQt5.qtstyleplugin-kvantum;
    };
  };

  # Kvantum theme configuration
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=KvGnomeDark
  '';

  # ============================================
  # FONTS
  # ============================================
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Core Nerd Fonts for icons
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.symbols-only

    # UI fonts
    inter

    # Icon themes
    papirus-icon-theme

    # Cursor theme
    bibata-cursors

    # GTK themes
    gnome-themes-extra

    # Qt styling
    libsForQt5.qtstyleplugin-kvantum

    # Screenshot tools (required for glassmorphism workflow)
    grim
    slurp
    swappy
    hyprpicker

    # Notification control
    libnotify

    # Wallpaper
    swaybg

    # Clipboard
    wl-clipboard
    cliphist
  ];

  # ============================================
  # SESSION VARIABLES
  # ============================================
  home.sessionVariables = {
    # GTK
    GTK_THEME = "Adwaita:dark";

    # Qt
    QT_QPA_PLATFORMTHEME = "gtk2";
    QT_STYLE_OVERRIDE = "kvantum";

    # Cursor
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # ============================================
  # POINTER CURSOR (Hyprland)
  # ============================================
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ============================================
  # DCONF SETTINGS (GNOME apps)
  # ============================================
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
      font-name = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
      enable-animations = true;
    };
  };
}
