# ============================================
# Kitty Terminal - Glassmorphism Theme
# ============================================
# Premium GPU-accelerated terminal with:
# - Native graphics protocol (images in terminal)
# - Background blur on Wayland
# - Electric cyan/magenta/violet accents
# - 144Hz optimizations
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  colors = config.glassmorphism.colors;
  shellProgram = "${pkgs.zsh}/bin/zsh --login";
  kittySocket = "unix:/tmp/kitty-${config.home.username}.sock";
in
{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;

    # ============================================
    # FONT CONFIGURATION
    # ============================================
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13.5;
    };

    # ============================================
    # KITTY SETTINGS
    # ============================================
    settings = {
      # ==========================================
      # APPEARANCE - Glassmorphism
      # ==========================================
      # Background with transparency for glass effect
      background_opacity = "0.93";
      background_blur = 12;
      dynamic_background_opacity = true;

      # Dim inactive windows
      dim_opacity = "0.82";
      inactive_text_alpha = "0.9";

      # Window padding for breathing room
      window_padding_width = 16;
      window_margin_width = 6;
      single_window_margin_width = 10;
      placement_strategy = "center";

      # Decorations
      hide_window_decorations = true;
      window_border_width = "1pt";
      draw_minimal_borders = true;

      # Confirm on close
      confirm_os_window_close = 0;

      # ==========================================
      # CURSOR - Electric Cyan
      # ==========================================
      cursor = colors.accent.cyan;
      cursor_text_color = colors.base.bg0;
      cursor_shape = "beam";
      cursor_beam_thickness = "1.6";
      cursor_blink_interval = "0.75";
      cursor_stop_blinking_after = 0;
      cursor_trail = 1;
      cursor_trail_decay = "0.08 0.24";
      cursor_trail_start_threshold = 1;

      # ==========================================
      # SCROLLBACK
      # ==========================================
      scrollback_lines = 50000;
      scrollback_pager_history_size = 100;
      scrollback_fill_enlarged_window = true;
      wheel_scroll_multiplier = 3;
      wheel_scroll_min_lines = 1;
      touch_scroll_multiplier = 3;

      # ==========================================
      # MOUSE
      # ==========================================
      mouse_hide_wait = 3;
      url_color = colors.accent.cyan;
      url_style = "curly";
      open_url_with = "default";
      url_prefixes = "file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh";
      url_excluded_characters = "\"'`()[]{}<>";
      detect_urls = true;
      show_hyperlink_targets = true;
      copy_on_select = "clipboard";
      paste_actions = "quote-urls-at-prompt";
      strip_trailing_spaces = "smart";
      select_by_word_characters = "@-./_~?&=%+#";

      # ==========================================
      # PERFORMANCE - 144Hz Optimizations
      # ==========================================
      repaint_delay = 6; # ~166fps cap (slightly above 144Hz)
      input_delay = 2;
      sync_to_monitor = true;

      # ==========================================
      # TERMINAL BELL
      # ==========================================
      enable_audio_bell = false;
      visual_bell_duration = "0.15";
      visual_bell_color = "#ff00aa";
      window_alert_on_bell = true;
      bell_on_tab = "🔔 ";

      # ==========================================
      # WINDOW LAYOUT
      # ==========================================
      remember_window_size = true;
      initial_window_width = 1200;
      initial_window_height = 800;
      enabled_layouts = "splits,stack,tall,fat,grid,horizontal,vertical";
      window_resize_step_cells = 2;
      window_resize_step_lines = 2;

      # Active window border - cyan glow
      active_border_color = colors.accent.cyan;
      inactive_border_color = colors.base.bg3;
      bell_border_color = colors.accent.magenta;

      # ==========================================
      # TAB BAR - Glassmorphism Style
      # ==========================================
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_align = "left";
      tab_bar_margin_height = "6.0 0.0";
      tab_bar_margin_width = "10.0";
      tab_bar_min_tabs = 2;
      tab_switch_strategy = "previous";
      tab_fade = "0.25 0.5 0.75 1";
      tab_separator = " ┇ ";
      tab_activity_symbol = "󰖲 ";

      # Tab title format
      tab_title_max_length = 25;
      tab_title_template = "{fmt.fg.tab}{bell_symbol}{activity_symbol}{index}: {title}";
      active_tab_title_template = "{fmt.fg._00d4ff}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index}: {title}";

      # Tab colors
      active_tab_foreground = colors.base.fg0;
      active_tab_background = colors.base.bg1;
      active_tab_font_style = "bold";
      inactive_tab_foreground = colors.base.fg3;
      inactive_tab_background = colors.base.bg0;
      inactive_tab_font_style = "normal";
      tab_bar_background = colors.base.bg0;
      tab_bar_margin_color = colors.base.bg0;

      # ==========================================
      # ADVANCED
      # ==========================================
      shell = shellProgram;
      shell_integration = "enabled";
      allow_hyperlinks = true;
      term = "xterm-kitty";

      # Wayland specific
      wayland_titlebar_color = "background";
      linux_display_server = "wayland";

      # Allow remote control (for scripts)
      allow_remote_control = "socket-only";
      listen_on = kittySocket;

      # Clipboard
      clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";
      clipboard_max_size = 512;

      # Notifications
      notify_on_cmd_finish = "unfocused 30.0";

      # ==========================================
      # MACOS SPECIFIC (ignored on Linux)
      # ==========================================
      macos_option_as_alt = "both";
      macos_quit_when_last_window_closed = false;
    };

    # ============================================
    # COLOR SCHEME - Glassmorphism Dark
    # Electric cyan/magenta/violet accents
    # ============================================
    extraConfig = ''
      # ==========================================
      # PRIMARY COLORS
      # ==========================================
      foreground #e4e4e7
      background ${colors.base.bg0}
      selection_foreground ${colors.base.fg0}
      selection_background ${colors.accent.violet}

      # ==========================================
      # CURSOR COLORS (defined in settings too)
      # ==========================================
      cursor ${colors.accent.cyan}
      cursor_text_color ${colors.base.bg0}

      # ==========================================
      # URL UNDERLINE COLOR
      # ==========================================
      url_color ${colors.accent.cyan}

      # ==========================================
      # KITTY WINDOW BORDER COLORS
      # ==========================================
      active_border_color ${colors.accent.cyan}
      inactive_border_color ${colors.base.bg3}
      bell_border_color ${colors.accent.magenta}

      # ==========================================
      # TITLE BAR COLORS
      # ==========================================
      wayland_titlebar_color ${colors.base.bg0}

      # ==========================================
      # MARK COLORS (for marked text)
      # ==========================================
      mark1_foreground ${colors.base.bg0}
      mark1_background ${colors.accent.cyan}
      mark2_foreground ${colors.base.bg0}
      mark2_background ${colors.accent.violet}
      mark3_foreground ${colors.base.bg0}
      mark3_background ${colors.accent.magenta}

      # ==========================================
      # STANDARD COLORS - Glassmorphism Palette
      # ==========================================
      # Black (dark surfaces)
      color0 ${colors.base.bg2}
      color8 ${colors.base.bg3}

      # Red (magenta for errors/danger)
      color1 ${colors.accent.magenta}
      color9 ${colors.accent.magentaLight}

      # Green (success)
      color2 ${colors.accent.green}
      color10 #4ade80

      # Yellow (warning)
      color3 ${colors.accent.yellow}
      color11 #facc15

      # Blue (info)
      color4 ${colors.accent.blue}
      color12 #60a5fa

      # Magenta (violet accent)
      color5 ${colors.accent.violet}
      color13 ${colors.accent.violetLight}

      # Cyan (primary electric cyan)
      color6 ${colors.accent.cyan}
      color14 ${colors.accent.cyanLight}

      # White (text)
      color7 ${colors.base.fg2}
      color15 ${colors.base.fg0}
    '';

    # ============================================
    # KEYBOARD SHORTCUTS
    # ============================================
    keybindings = {
      # ==========================================
      # CLIPBOARD
      # ==========================================
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";

      # ==========================================
      # SCROLLING
      # ==========================================
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+z" = "scroll_to_prompt -1";
      "ctrl+shift+x" = "scroll_to_prompt 1";
      "ctrl+shift+h" = "show_scrollback";

      # ==========================================
      # WINDOW MANAGEMENT
      # ==========================================
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+f" = "move_window_forward";
      "ctrl+shift+b" = "move_window_backward";
      "ctrl+shift+`" = "move_window_to_top";
      "ctrl+shift+r" = "start_resizing_window";
      "ctrl+shift+1" = "first_window";
      "ctrl+shift+2" = "second_window";
      "ctrl+shift+3" = "third_window";
      "ctrl+shift+4" = "fourth_window";
      "ctrl+shift+5" = "fifth_window";

      # ==========================================
      # TAB MANAGEMENT
      # ==========================================
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";
      "ctrl+shift+alt+t" = "set_tab_title";
      "ctrl+tab" = "next_tab";
      "ctrl+shift+tab" = "previous_tab";

      # ==========================================
      # LAYOUT
      # ==========================================
      "ctrl+shift+l" = "next_layout";
      "ctrl+alt+t" = "goto_layout tall";
      "ctrl+alt+s" = "goto_layout stack";
      "ctrl+alt+g" = "goto_layout grid";

      # ==========================================
      # FONT SIZE
      # ==========================================
      "ctrl+shift+equal" = "change_font_size all +1.0";
      "ctrl+shift+minus" = "change_font_size all -1.0";
      "ctrl+shift+backspace" = "change_font_size all 0";

      # ==========================================
      # HINTS (URL/PATH SELECTION)
      # ==========================================
      "ctrl+shift+e" = "open_url_with_hints";
      "ctrl+shift+p>f" = "kitten hints --type path --program -";
      "ctrl+shift+p>shift+f" = "kitten hints --type path";
      "ctrl+shift+p>l" = "kitten hints --type line --program -";
      "ctrl+shift+p>w" = "kitten hints --type word --program -";
      "ctrl+shift+p>h" = "kitten hints --type hash --program -";

      # ==========================================
      # MISC
      # ==========================================
      "ctrl+shift+f11" = "toggle_fullscreen";
      "ctrl+shift+f10" = "toggle_maximized";
      "ctrl+shift+u" = "kitten unicode_input";
      "ctrl+shift+f2" = "edit_config_file";
      "ctrl+shift+escape" = "kitty_shell window";
      "ctrl+shift+a>m" = "toggle_marker iregex 1 \\bERROR\\b 2 \\bWARNING\\b";
      "ctrl+shift+delete" = "clear_terminal reset active";
      "ctrl+shift+f5" = "load_config_file";
      "ctrl+shift+f6" = "debug_config";
    };

    # ============================================
    # ENVIRONMENT VARIABLES
    # ============================================
    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
      mode = "enabled";
    };
  };

  # ============================================
  # XDG MIME ASSOCIATIONS
  # ============================================
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/kitty" = "kitty.desktop";
  };
}
