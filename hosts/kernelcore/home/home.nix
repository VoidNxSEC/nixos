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
    ./yazi.nix # Yazi file manager configuration
    ./alacritty.nix # Alacritty terminal emulator (Zellij integration)
    ./hyprland.nix # Hyprland config (bindings + defaults)
    ./git.nix # Git configuration
    ./tmux.nix # Tmux configuration
    ./flameshot.nix # Screenshot tool (legacy - swappy preferred)
    ./glassmorphism # Glassmorphism design system (replaces theme.nix)
    ./brave.nix # Brave browser configuration
    ./electron-config.nix # Electron app performance optimization
    ./firefox.nix # Self-hosted Firefox (extensions in Nix store)
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
    stateVersion = "26.05";

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
      netcat

      # ─────────────────────────────────────────────────────
      # Development Arsenal
      # ─────────────────────────────────────────────────────
      # git (configured in git.nix)
      git-lfs

      qwen-code

      caddy
      python313Packages.meson
      kitty
      vim
      neovim
      vscode

      # ─────────────────────────────────────────────────────
      # Package Managers & Python
      # ─────────────────────────────────────────────────────
      uv
      python313Packages.python

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
      # tmux (configured in tmux.nix)
      fish
      foot # Minimal Wayland terminal for emergency fallback

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
      nemo-preview

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
      #reaper
      #ardour

      # Secrets
      python313Packages.proton-keyring-linux

      # Email
      thunderbird

      # Certs
      openssl

      # ─────────────────────────────────────────────────────
      # Browser Fleet
      # ─────────────────────────────────────────────────────
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

      # ─────────────────────────────────────────────────────
      # Machine Learning
      # ─────────────────────────────────────────────────────
      llama-cpp
      #python313Packages.vllm
      #python313Packages.hf-xet
      #python313Packages.llama-index-embeddings-huggingface
      #python313Packages.kernels
      #python313Packages.huggingface-hub
      #python313Packages.langchain-huggingface
      #python313Packages.litellm
      # python313Packages.uv
      #python313Packages.pip
      #python313Packages.python-lsp-server

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
