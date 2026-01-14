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
      background_opacity = "0.92";
      background_blur = 10;
      dynamic_background_opacity = true;

      # Dim inactive windows
      dim_opacity = "0.85";
      inactive_text_alpha = "0.9";

      # Window padding for breathing room
      window_padding_width = 14;

      # Decorations
      hide_window_decorations = true;
      window_border_width = "1pt";
      draw_minimal_borders = true;

      # Confirm on close
      confirm_os_window_close = 0;

      # ==========================================
      # CURSOR - Electric Cyan
      # ==========================================
      cursor = "#00d4ff";
      cursor_text_color = "#0a0a0f";
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.75";
      cursor_stop_blinking_after = 0;

      # ==========================================
      # SCROLLBACK
      # ==========================================
      scrollback_lines = 50000;
      scrollback_pager_history_size = 100;
      wheel_scroll_multiplier = 3;
      wheel_scroll_min_lines = 1;
      touch_scroll_multiplier = 3;

      # ==========================================
      # MOUSE
      # ==========================================
      mouse_hide_wait = 3;
      url_color = "#00d4ff";
      url_style = "curly";
      open_url_with = "default";
      url_prefixes = "file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh";
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
      active_border_color = "#00d4ff";
      inactive_border_color = "#22222e";
      bell_border_color = "#ff00aa";

      # ==========================================
      # TAB BAR - Glassmorphism Style
      # ==========================================
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_align = "left";
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
      active_tab_foreground = "#ffffff";
      active_tab_background = "#12121a";
      active_tab_font_style = "bold";
      inactive_tab_foreground = "#71717a";
      inactive_tab_background = "#0a0a0f";
      inactive_tab_font_style = "normal";
      tab_bar_background = "#0a0a0f";
      tab_bar_margin_color = "#0a0a0f";

      # ==========================================
      # ADVANCED
      # ==========================================
      shell_integration = "enabled";
      allow_hyperlinks = true;
      term = "xterm-kitty";

      # Wayland specific
      wayland_titlebar_color = "background";
      linux_display_server = "wayland";

      # Allow remote control (for scripts)
      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty-socket";

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
      background #0a0a0f
      selection_foreground #ffffff
      selection_background #7c3aed

      # ==========================================
      # CURSOR COLORS (defined in settings too)
      # ==========================================
      cursor #00d4ff
      cursor_text_color #0a0a0f

      # ==========================================
      # URL UNDERLINE COLOR
      # ==========================================
      url_color #00d4ff

      # ==========================================
      # KITTY WINDOW BORDER COLORS
      # ==========================================
      active_border_color #00d4ff
      inactive_border_color #22222e
      bell_border_color #ff00aa

      # ==========================================
      # TITLE BAR COLORS
      # ==========================================
      wayland_titlebar_color #0a0a0f

      # ==========================================
      # MARK COLORS (for marked text)
      # ==========================================
      mark1_foreground #0a0a0f
      mark1_background #00d4ff
      mark2_foreground #0a0a0f
      mark2_background #7c3aed
      mark3_foreground #0a0a0f
      mark3_background #ff00aa

      # ==========================================
      # STANDARD COLORS - Glassmorphism Palette
      # ==========================================
      # Black (dark surfaces)
      color0 #1a1a24
      color8 #22222e

      # Red (magenta for errors/danger)
      color1 #ff00aa
      color9 #f472b6

      # Green (success)
      color2 #22c55e
      color10 #4ade80

      # Yellow (warning)
      color3 #eab308
      color11 #facc15

      # Blue (info)
      color4 #3b82f6
      color12 #60a5fa

      # Magenta (violet accent)
      color5 #7c3aed
      color13 #a78bfa

      # Cyan (primary electric cyan)
      color6 #00d4ff
      color14 #67e8f9

      # White (text)
      color7 #a1a1aa
      color15 #ffffff
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
