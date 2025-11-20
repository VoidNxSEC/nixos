{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ============================================================
  # IMPORTS
  # ============================================================
  imports = [
    ./shell # Modern shell configuration with zsh + powerlevel10k
  ];

  # ============================================================
  # SHELL CONFIGURATION
  # ============================================================
  myShell = {
    enable = true;
    defaultShell = "zsh"; # Options: "zsh" or "bash"
    enablePowerlevel10k = true;
    enableNerdFonts = true;
  };

  # ============================================================
  # CORE IDENTITY MATRIX
  # ============================================================
  home = {
    username = "kernelcore";
    homeDirectory = "/home/kernelcore";
    stateVersion = "25.05";

    # ========================================================
    # OPERATIONAL PACKAGES
    # ========================================================
    packages = with pkgs; [
      # ─────────────────────────────────────────────────────
      # Terminal & System Intelligence
      # ─────────────────────────────────────────────────────
      neofetch
      htop
      btop
      tree
      ripgrep
      fd
      bat
      eza
      zoxide
      fzf
      fq
      yazi
      starship

      # ─────────────────────────────────────────────────────
      # Network Reconnaissance
      # ─────────────────────────────────────────────────────
      nmap
      wireshark
      tcpdump
      curl
      wget
      dig
      busybox
      netcat

      # ─────────────────────────────────────────────────────
      # Development Arsenal
      # ─────────────────────────────────────────────────────
      git
      git-lfs

      qwen-code

      caddy
      python313Packages.meson
      kitty
      vim
      neovim
      vscode

      # ─────────────────────────────────────────────────────
      # Neovim Plugins
      # ─────────────────────────────────────────────────────

      # ─────────────────────────────────────────────────────
      # Package Managers & Python
      # ─────────────────────────────────────────────────────
      uv
      python313Packages.python
      python313Packages.torchWithCuda

      # ─────────────────────────────────────────────────────
      # Build Tools
      # ─────────────────────────────────────────────────────
      gcc
      gnumake
      cmake
      glibc
      # ─────────────────────────────────────────────────────
      # Navigation & Multiplexing
      # ─────────────────────────────────────────────────────
      tmux
      fish

      # ─────────────────────────────────────────────────────
      # Environment Management
      # ─────────────────────────────────────────────────────
      nix-direnv
      direnv

      # ─────────────────────────────────────────────────────
      # File Management
      # ─────────────────────────────────────────────────────
      nemo-with-extensions
      nemo-emblems
      folder-color-switcher
      nemo-python
      nemo-fileroller

      # ─────────────────────────────────────────────────────
      # Clipboard & Shell
      # ─────────────────────────────────────────────────────
      xclip
      wl-clipboard
      zsh
      oh-my-zsh

      # ─────────────────────────────────────────────────────
      # File & Archive Operations
      # ─────────────────────────────────────────────────────
      unzip
      zip
      p7zip
      rsync
      rclone

      # ─────────────────────────────────────────────────────
      # Media & Graphics
      # ─────────────────────────────────────────────────────
      mpv
      vlc
      gimp
      imagemagick

      # Music
      reaper
      ardour

      # Secrets
      proton-pass
      python313Packages.proton-keyring-linux

      # VPN

      # Email
      thunderbird

      # Certs
      openssl

      # ─────────────────────────────────────────────────────
      # Browser Fleet
      # ─────────────────────────────────────────────────────
      brave
      vivaldi
      chromium

      # ─────────────────────────────────────────────────────
      # Communication Channels
      # ─────────────────────────────────────────────────────
      discord

      # ─────────────────────────────────────────────────────
      # Productivity Suite
      # ─────────────────────────────────────────────────────
      obsidian

      # ─────────────────────────────────────────────────────
      # System Utilities
      # ─────────────────────────────────────────────────────
      gparted
      bleachbit
      keepassxc

      # ─────────────────────────────────────────────────────
      # Containerization
      # ─────────────────────────────────────────────────────
      docker
      docker-compose
      docker-buildx
      bun
      rustup
      wrangler

      # ─────────────────────────────────────────────────────
      # Machine Learning
      # ─────────────────────────────────────────────────────
      ollama-cuda
      llama-cpp
      python313Packages.vllm
      python313Packages.hf-xet
      python313Packages.llama-index-embeddings-huggingface
      python313Packages.kernels
      python313Packages.huggingface-hub
      python313Packages.langchain-huggingface
      python313Packages.litellm
      python313Packages.uv
      python313Packages.pip
      python313Packages.python-lsp-server

      # ─────────────────────────────────────────────────────
      # Nerd Fonts
      # ─────────────────────────────────────────────────────
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.meslo-lg
      nerd-fonts.ubuntu-mono

      # Additional quality fonts
      fira-code
      fira-code-symbols
      jetbrains-mono
      liberation_ttf
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
    ];
  };

  # ============================================================
  # PROGRAM CONFIGURATIONS
  # ============================================================
  programs = {
    # ========================================================
    # Home Manager
    # ========================================================
    home-manager.enable = true;

    # ========================================================
    # BASH Configuration - MANAGED BY SHELL MODULE
    # ========================================================
    # All shell configuration (bash/zsh) is now in ./shell/
    # To switch shells, edit: myShell.defaultShell = "bash" or "zsh"

    # ========================================================
    # Git Configuration
    # ========================================================
    git = {
      enable = true;
      settings = {
        user.name = "marcosfpina";
        user.email = "sec@voidnxlabs.com";
        init.defaultBranch = "main";
        core.editor = "nvim";
        pull.rebase = false;

        # Security configurations
        user.signingkey = "5606AB430E95F5AD";
        commit.gpgsign = true;

        # Performance optimizations
        core.preloadindex = true;
        core.fscache = true;
        gc.auto = 256;

        # Better diffs
        diff.algorithm = "histogram";

        # Colorful output
        color.ui = true;

        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          df = "diff";
          lg = "log --oneline --graph --decorate --all";
          lol = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          amend = "commit --amend --no-edit";
          undo = "reset --soft HEAD^";
        };
      };
    };
    # ========================================================
    # Tmux Configuration
    # ========================================================
    tmux = {
      enable = true;
      terminal = "screen-256color";
      keyMode = "vi";
      mouse = true;

      extraConfig = ''
        # Prefix key
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix

        # Split panes with intuitive keys
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        # Easy pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Reload config
        bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

        # Status bar
        set -g status-position bottom
        set -g status-bg black
        set -g status-fg white
        set -g status-left '#[fg=green,bold]#H #[fg=blue]| '
        set -g status-right '#[fg=yellow]#(uptime | cut -d "," -f 1) #[fg=white]| %H:%M'
        set -g status-interval 60

        # Window status
        setw -g window-status-current-style 'fg=black bg=green bold'

        # Start windows at 1, not 0
        set -g base-index 1
        setw -g pane-base-index 1
      '';
    };

    # ========================================================
    # Eza (Modern ls replacement) - MANAGED BY SHELL MODULE
    # ========================================================
    # Configuration moved to shell module

    # ========================================================
    # Fzf (Fuzzy finder) - MANAGED BY SHELL MODULE
    # ========================================================
    # Configuration moved to shell module

    # ========================================================
    # Ripgrep (Better grep)
    # ========================================================
    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=150"
        "--max-columns-preview"
        "--smart-case"
        "--hidden"
        "--glob=!.git/*"
      ];
    };

    # ========================================================
    # Bat (Better cat with syntax highlighting) - MANAGED BY SHELL MODULE
    # ========================================================
    # Configuration moved to shell module

    # ========================================================
    # Zoxide (Smarter cd) - MANAGED BY SHELL MODULE
    # ========================================================
    # Configuration moved to shell module
  };

  # ============================================================
  # SERVICES
  # ============================================================
  services = {
    # GPG agent
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      maxCacheTtl = 7200;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };
  };

  # ============================================================
  # XDG DIRECTORIES
  # ============================================================
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;

      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };

    # XDG MIME associations
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "application/pdf" = "firefox.desktop";
        "image/png" = "gimp.desktop";
        "image/jpeg" = "gimp.desktop";
      };
    };
  };

  xdg.configFile."mimeapps.list".force = true;

  # ============================================================
  # GTK THEME
  # ============================================================
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # ============================================================
  # FONTS
  # ============================================================
  fonts.fontconfig.enable = true;

  # ============================================================
  # DOTFILES & CONFIG FILES
  # ============================================================
  home.file = {
    # Vim configuration
    ".vimrc".text = ''
      syntax on
      set number
      set relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set autoindent
      set hlsearch
      set incsearch
      set ignorecase
      set smartcase

      " Security
      set noswapfile
      set nobackup
      set noundofile

      " Quality of life
      set mouse=a
      set clipboard=unnamedplus

      " Better colors
      set termguicolors
    '';

    # Neovim init (simple config)
    #".config/nvim/init.lua".text = ''

    #'';

    ".config/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nvim.rescue";

    # Desktop entry
    ".local/share/applications/htop.desktop".text = ''
      [Desktop Entry]
      Name=htop
      Comment=Interactive process viewer
      Exec=gnome-terminal -- htop
      Icon=utilities-system-monitor
      Type=Application
      Categories=System;Monitor;
    '';

    # Starship prompt config (optional alternative to bash prompt)
    ".config/starship.toml".text = ''
      format = """
      [┌───────────────────>](bold green)
      [│](bold green)$directory$git_branch$git_status
      [└─>](bold green) """

      [directory]
      style = "blue"

      [git_branch]
      symbol = " "
      style = "red"

      [git_status]
      style = "red"
    '';
  };

  # ============================================================
  # SESSION VARIABLES
  # ============================================================
  home.sessionVariables = {
    # Editor & Browser
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";

    # Python/Pipx
    #PIPX_HOME = "${config.home.homeDirectory}/.local/share/pipx";
    #PIPX_BIN_DIR = "${config.home.homeDirectory}/.local/bin";
    #PIPX_MAN_DIR = "${config.home.homeDirectory}/.local/share/man";

    # Development
    GOPATH = "${config.home.homeDirectory}/go";

    # Security
    GNUPGHOME = "${config.home.homeDirectory}/.gnupg";

    # Anthropic
    ANTHROPIC_MODEL = "claude-sonnet-4-5-20250929";

    # XDG compliance
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
  };

  # ============================================================
  # SESSION PATH
  # ============================================================
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
  ];
}
