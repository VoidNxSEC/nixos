{ config, pkgs, ... }:

{
  home.stateVersion = "25.05";

  # User fonts
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  # Git configuration with GPG signing
  programs.git = {
    enable = true;
    userName = "voidnxlab";
    userEmail = "pina@voidnx.com";

    # GPG signing configuration
    signing = {
      key = "0x590731EE4043D7E8";
      signByDefault = true;
    };

    extraConfig = {
      # Core settings
      core = {
        editor = "nvim";
        autocrlf = "input";
        safecrlf = true;
      };

      # Push settings
      push = {
        default = "simple";
        autoSetupRemote = true;
      };

      # Pull settings
      pull = {
        rebase = true;
      };

      # Commit settings
      commit = {
        gpgsign = true;
        template = "~/.gitmessage";
      };

      # Branch settings
      branch = {
        autosetupmerge = "always";
        autosetuprebase = "always";
      };

      # Merge settings
      merge = {
        ff = "only";
      };

      # Rebase settings
      rebase = {
        autoStash = true;
        autoSquash = true;
      };

      # Status settings
      status = {
        showUntrackedFiles = "all";
      };

      # Log settings
      log = {
        abbrevCommit = true;
        decorate = "short";
      };

      # Color settings
      color = {
        ui = "auto";
        branch = "auto";
        diff = "auto";
        status = "auto";
      };

      # URL rewrites for GitHub
      url = {
        "https://github.com/" = {
          insteadOf = "gh:";
        };
      };
    };

    # Git aliases
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      ca = "commit -a";
      cam = "commit -am";
      cl = "clone";
      df = "diff";
      lg = "log --oneline --graph --decorate --all";
      lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
      lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      ls = "ls-files";
      ign = "ls-files -o -i --exclude-standard";
      graph = "log --graph --date-order -C -M --pretty=format:'<%h> %ad [%an] %Cgreen%d%Creset %s' --all --date=short";
    };
  };

  # GPG configuration for git signing
  programs.gpg = {
    enable = true;
    settings = {
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;
    };
  };

  # Services for GPG agent
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gtk2;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };

  # i3 window manager configuration
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4"; # Windows key
      terminal = "alacritty";
      menu = "rofi -show drun";

      fonts = {
        names = [
          "Inter"
          "Font Awesome 6 Free"
          "Font Awesome 6 Brands"
        ];
        size = 9.0;
      };

      # Modern keybindings with additional functionality
      keybindings = {
        # Basic window management
        "Mod4+Return" = "exec alacritty";
        "Mod4+d" = "exec rofi -show drun";
        "Mod4+Shift+q" = "kill";
        "Mod4+Shift+c" = "reload";
        "Mod4+Shift+r" = "restart";
        "Mod4+Shift+e" = "exec i3-nagbar -t warning -m 'Exit i3?' -b 'Yes' 'i3-msg exit'";

        # Applications (Super + letter shortcuts)
        "Mod4+w" = "exec firefox";
        "Mod4+b" = "exec vivaldi";
        "Mod4+e" = "exec thunar";
        "Mod4+c" = "exec code";
        "Mod4+n" = "exec neovim";
        "Mod4+m" = "exec thunderbird";
        "Mod4+p" = "exec pavucontrol";
        "Mod4+s" = "exec rofi -show ssh";
        "Mod4+r" = "exec rofi -show run";
        "Mod4+v" = "exec rofi -show window";

        # System controls
        "Mod4+l" = "exec i3lock -c 000000";
        "Mod4+t" = "exec i3-theme-toggle";
        "Mod4+x" = "exec arandr";
        "Mod4+y" = "exec lxappearance";

        # Quick actions
        "Mod4+space" = "exec rofi -show drun";
        "Mod4+Tab" = "exec rofi -show window";
        "Mod4+grave" = "exec alacritty --class floating -e htop";
        "Mod4+bracketleft" = "workspace prev";
        "Mod4+bracketright" = "workspace next";

        # Focus controls
        "Mod4+h" = "focus left";
        "Mod4+j" = "focus down";
        "Mod4+k" = "focus up";
        "Mod4+semicolon" = "focus right";

        # Move windows
        "Mod4+Shift+h" = "move left";
        "Mod4+Shift+j" = "move down";
        "Mod4+Shift+k" = "move up";
        "Mod4+Shift+l" = "move right";

        # Resize mode
        "Mod4+Ctrl+h" = "resize shrink width 10 px or 10 ppt";
        "Mod4+Ctrl+j" = "resize grow height 10 px or 10 ppt";
        "Mod4+Ctrl+k" = "resize shrink height 10 px or 10 ppt";
        "Mod4+Ctrl+l" = "resize grow width 10 px or 10 ppt";

        # Layout controls
        "Mod4+f" = "fullscreen toggle";
        "Mod4+Shift+space" = "floating toggle";
        "Mod4+g" = "split h";
        "Mod4+Shift+g" = "split v";
        "Mod4+z" = "layout stacking";
        "Mod4+Shift+z" = "layout tabbed";
        "Mod4+Shift+t" = "layout toggle split";

        # Workspace shortcuts
        "Mod4+1" = "workspace number 1";
        "Mod4+2" = "workspace number 2";
        "Mod4+3" = "workspace number 3";
        "Mod4+4" = "workspace number 4";
        "Mod4+5" = "workspace number 5";
        "Mod4+6" = "workspace number 6";
        "Mod4+7" = "workspace number 7";
        "Mod4+8" = "workspace number 8";
        "Mod4+9" = "workspace number 9";
        "Mod4+0" = "workspace number 10";

        # Move to workspace
        "Mod4+Shift+1" = "move container to workspace number 1";
        "Mod4+Shift+2" = "move container to workspace number 2";
        "Mod4+Shift+3" = "move container to workspace number 3";
        "Mod4+Shift+4" = "move container to workspace number 4";
        "Mod4+Shift+5" = "move container to workspace number 5";
        "Mod4+Shift+6" = "move container to workspace number 6";
        "Mod4+Shift+7" = "move container to workspace number 7";
        "Mod4+Shift+8" = "move container to workspace number 8";
        "Mod4+Shift+9" = "move container to workspace number 9";
        "Mod4+Shift+0" = "move container to workspace number 10";

        # Media controls
        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";
        "Mod4+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "Mod4+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";

        # Brightness controls
        "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
        "Mod4+Shift+equal" = "exec brightnessctl set +5%";
        "Mod4+Shift+minus" = "exec brightnessctl set 5%-";

        # Screenshots
        "Print" = "exec grim ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png";
        "Mod4+Print" = "exec grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png";
        "Mod4+Shift+s" = "exec grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png";

        # Quick toggles and mobility
        "Mod4+Ctrl+m" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "Mod4+Ctrl+w" = "exec toggle-wifi";
        "Mod4+Ctrl+b" = "exec toggle-bluetooth";
        "Mod4+Ctrl+n" = "exec toggle-notifications";

        # Advanced controls
        "Mod4+Ctrl+s" = "exec quick-settings";
        "Mod4+Ctrl+p" = "exec power-menu";
        "Mod4+Ctrl+v" = "exec volume-control";
        "Mod4+Ctrl+d" = "exec brightness-control";
        "Mod4+Ctrl+space" = "exec workspace-manager";
      };

      # Window settings
      window = {
        border = 2;
        hideEdgeBorders = "smart";
      };

      # Gaps for modern look
      gaps = {
        inner = 8;
        outer = 4;
        smartGaps = true;
        smartBorders = "on";
      };

      # Startup applications
      startup = [
        {
          command = "exec --no-startup-id autotiling";
          always = true;
          notification = false;
        }
        {
          command = "exec --no-startup-id polybar main";
          always = true;
          notification = false;
        }
        {
          command = "exec --no-startup-id picom";
          always = true;
          notification = false;
        }
        {
          command = "exec --no-startup-id dunst";
          always = true;
          notification = false;
        }
        {
          command = "exec --no-startup-id feh --bg-scale ~/.config/wallpaper.jpg";
          always = true;
          notification = false;
        }
        {
          command = "exec --no-startup-id i3-theme-dark";
          notification = false;
        }
      ];

      # Remove default bar (we'll use polybar)
      bars = [ ];
    };

    # Include theme file
    extraConfig = ''
      # Load theme colors
      include ~/.config/i3/theme
    '';
  };

  # Polybar configuration
  services.polybar = {
    enable = true;
    script = "polybar main &";
    config = {
      "bar/main" = {
        width = "100%";
        height = 32;
        fixed-center = true;
        background = "\${colors.background}";
        foreground = "\${colors.foreground}";
        line-size = 3;
        line-color = "\${colors.primary}";
        border-size = 0;
        border-color = "#00000000";
        padding-left = 2;
        padding-right = 2;
        module-margin-left = 1;
        module-margin-right = 2;

        font-0 = "Inter:size=9;2";
        font-1 = "Font Awesome 6 Free:style=Solid:size=9;2";
        font-2 = "Font Awesome 6 Brands:size=9;2";

        modules-left = "i3";
        modules-center = "date";
        modules-right = "pulseaudio memory cpu battery network";

        tray-position = "right";
        tray-padding = 2;

        cursor-click = "pointer";
        cursor-scroll = "ns-resize";
      };

      "module/i3" = {
        type = "internal/i3";
        format = "<label-state> <label-mode>";
        index-sort = true;
        wrapping-scroll = false;

        label-mode-padding = 2;
        label-mode-foreground = "#000";
        label-mode-background = "\${colors.primary}";

        label-focused = "%index%";
        label-focused-background = "\${colors.background-alt}";
        label-focused-underline = "\${colors.primary}";
        label-focused-padding = 2;

        label-unfocused = "%index%";
        label-unfocused-padding = 2;

        label-visible = "%index%";
        label-visible-background = "\${colors.background-alt}";
        label-visible-underline = "\${colors.secondary}";
        label-visible-padding = 2;

        label-urgent = "%index%";
        label-urgent-background = "\${colors.alert}";
        label-urgent-padding = 2;
      };

      "module/date" = {
        type = "internal/date";
        interval = 5;
        date = " %d/%m";
        date-alt = " %d/%m/%Y";
        time = "%H:%M";
        time-alt = "%H:%M:%S";
        format-prefix = "";
        format-prefix-foreground = "\${colors.foreground}";
        format-underline = "\${colors.primary}";
        label = "%date% %time%";
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<label-volume> <bar-volume>";
        label-volume = " %percentage%%";
        label-volume-foreground = "\${root.foreground}";
        label-muted = " muted";
        label-muted-foreground = "\${colors.disabled}";

        bar-volume-width = 10;
        bar-volume-foreground-0 = "\${colors.primary}";
        bar-volume-foreground-1 = "\${colors.primary}";
        bar-volume-foreground-2 = "\${colors.primary}";
        bar-volume-foreground-3 = "\${colors.primary}";
        bar-volume-foreground-4 = "\${colors.primary}";
        bar-volume-foreground-5 = "\${colors.secondary}";
        bar-volume-foreground-6 = "\${colors.alert}";
        bar-volume-gradient = false;
        bar-volume-indicator = "|";
        bar-volume-indicator-font = 2;
        bar-volume-fill = "─";
        bar-volume-fill-font = 2;
        bar-volume-empty = "─";
        bar-volume-empty-font = 2;
        bar-volume-empty-foreground = "\${colors.disabled}";
      };

      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format-prefix = " ";
        format-prefix-foreground = "\${colors.primary}";
        format-underline = "\${colors.secondary}";
        label = "%percentage_used%%";
      };

      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = " ";
        format-prefix-foreground = "\${colors.primary}";
        format-underline = "\${colors.secondary}";
        label = "%percentage:2%%";
      };

      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "ADP1";
        full-at = 98;

        format-charging = "<animation-charging> <label-charging>";
        format-charging-underline = "\${colors.primary}";
        format-discharging = "<animation-discharging> <label-discharging>";
        format-discharging-underline = "\${colors.alert}";
        format-full-prefix = " ";
        format-full-prefix-foreground = "\${colors.primary}";
        format-full-underline = "\${colors.primary}";

        ramp-capacity-0 = "";
        ramp-capacity-1 = "";
        ramp-capacity-2 = "";
        ramp-capacity-foreground = "\${colors.foreground}";

        animation-charging-0 = "";
        animation-charging-1 = "";
        animation-charging-2 = "";
        animation-charging-foreground = "\${colors.foreground}";
        animation-charging-framerate = 750;

        animation-discharging-0 = "";
        animation-discharging-1 = "";
        animation-discharging-2 = "";
        animation-discharging-foreground = "\${colors.foreground}";
        animation-discharging-framerate = 750;
      };

      "module/network" = {
        type = "internal/network";
        interface = "wlan0";
        interval = 3;

        format-connected = "<ramp-signal> <label-connected>";
        format-connected-underline = "\${colors.primary}";
        label-connected = "%essid%";

        format-disconnected = "";

        ramp-signal-0 = "";
        ramp-signal-1 = "";
        ramp-signal-2 = "";
        ramp-signal-3 = "";
        ramp-signal-4 = "";
        ramp-signal-foreground = "\${colors.foreground}";
      };

      "settings" = {
        screenchange-reload = true;
      };

      "global/wm" = {
        margin-top = 5;
        margin-bottom = 5;
      };
    };
  };

  # Rofi configuration with modern themes
  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
    extraConfig = {
      modi = "window,run,drun,ssh";
      show-icons = true;
      terminal = "alacritty";
      drun-display-format = "{icon} {name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      display-window = " Windows ";
      display-drun = " Apps ";
      display-run = " Run ";
      display-ssh = " SSH ";
      sidebar-mode = true;
    };
  };

  # Alacritty terminal configuration
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 8;
          y = 8;
        };
        opacity = 0.95;
        decorations = "none";
      };

      font = {
        normal = {
          family = "FiraCode Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "FiraCode Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "FiraCode Nerd Font";
          style = "Italic";
        };
        size = 12.0;
      };

      colors = {
        primary = {
          background = "#2f343f";
          foreground = "#f3f4f5";
        };
        normal = {
          black = "#2f343f";
          red = "#e53935";
          green = "#43a047";
          yellow = "#ffa000";
          blue = "#1e88e5";
          magenta = "#8e24aa";
          cyan = "#00acc1";
          white = "#f3f4f5";
        };
        bright = {
          black = "#676e7d";
          red = "#ff5722";
          green = "#66bb6a";
          yellow = "#ffca28";
          blue = "#42a5f5";
          magenta = "#ab47bc";
          cyan = "#26c6da";
          white = "#ffffff";
        };
      };

      cursor = {
        style = "Block";
        unfocused_hollow = true;
      };

      live_config_reload = true;

      key_bindings = [
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "Plus";
          mods = "Control";
          action = "IncreaseFontSize";
        }
        {
          key = "Minus";
          mods = "Control";
          action = "DecreaseFontSize";
        }
      ];
    };
  };

  # Picom (compositor) configuration
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;

    fade = true;
    fadeSteps = [
      0.028
      0.03
    ];
    fadeDelta = 10;

    shadow = true;
    shadowOpacity = 0.6;
    shadowExclude = [
      "class_g = 'i3-frame'"
      "_GTK_FRAME_EXTENTS@:c"
    ];

    activeOpacity = 1.0;
    inactiveOpacity = 0.95;

    opacityRules = [
      "100:class_g = 'Firefox'"
      "100:class_g = 'Vivaldi-stable'"
      "95:class_g = 'Alacritty'"
      "95:class_g = 'Rofi'"
      "100:class_g = 'polybar'"
    ];

    settings = {
      # Shadow settings
      shadow-radius = 12;
      shadow-offset-x = -8;
      shadow-offset-y = -8;

      # Corner radius
      corner-radius = 8;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];

      # Blur settings
      blur = {
        method = "dual_kawase";
        strength = 3;
        background = false;
        background-frame = false;
        background-fixed = false;
      };

      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "_GTK_FRAME_EXTENTS@:c"
      ];
    };
  };

  # Dunst notification daemon configuration
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "30x50";
        origin = "top-right";
        transparency = 10;
        frame_color = "#2f343f";
        frame_width = 2;
        separator_color = "frame";
        font = "Inter 10";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        word_wrap = true;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        icon_position = "left";
        min_icon_size = 0;
        max_icon_size = 32;
        sticky_history = true;
        history_length = 20;
        browser = "firefox";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 8;
        ignore_dbusclose = false;
        force_xwayland = false;
        force_xinerama = false;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      experimental = {
        per_monitor_dpi = false;
      };

      urgency_low = {
        background = "#2f343f";
        foreground = "#f3f4f5";
        timeout = 10;
      };

      urgency_normal = {
        background = "#2f343f";
        foreground = "#f3f4f5";
        timeout = 10;
      };

      urgency_critical = {
        background = "#e53935";
        foreground = "#ffffff";
        frame_color = "#ff5722";
        timeout = 0;
      };
    };
  };

  # Shell aliases for git workflow and system management
  programs.bash.shellAliases = {
    # Git shortcuts
    gst = "git status";
    gco = "git checkout";
    gcm = "git commit -m";
    gca = "git commit -am";
    gps = "git push";
    gpl = "git pull";
    gad = "git add";
    glg = "git log --graph --oneline --all";

    # NixOS system management
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#voidnx";
    nrt = "nixos-rebuild-test";
    nup = "nixos-update";
    ncl = "nixos-cleanup";
    ngen = "nixos-generations";

    # System monitoring and info
    status = "system-status";
    hwinfo = "hardware-info";
    svc = "service-manager";
    perf = "performance-monitor";

    # Cache management
    cache-status = "cache-server-status";
    cache-restart = "cache-server-restart";

    # Quick settings and themes
    qs = "quick-settings";
    theme-toggle = "i3-theme-toggle";
    theme-dark = "i3-theme-dark";
    theme-light = "i3-theme-light";

    # Directory navigation and file operations
    ll = "ls -alF";
    la = "ls -A";
    l = "ls -CF";
    tree2 = "tree -L 2";
    tree3 = "tree -L 3";
    du1 = "du -h --max-depth=1";
    duf = "ncdu";

    # System shortcuts
    wifi = "toggle-wifi";
    bt = "toggle-bluetooth";
    pm = "power-menu";

    # Development shortcuts
    edit-config = "cd /etc/nixos && nvim configuration.nix";
    edit-home = "cd /etc/nixos && nvim home.nix";
    flake-update = "cd /etc/nixos && nix flake update";

    # Development environment
    dev-setup = "dev-setup";
    gpg-setup = "gpg-setup";
    ssh-setup = "ssh-setup";
  };

  # Git commit message template
  home.file.".gitmessage".text = ''
    # 50-character subject line

    # 72-character wrapped longer description

    # Co-authored-by: voidnxlab <pina@voidnx.com>
  '';
}
