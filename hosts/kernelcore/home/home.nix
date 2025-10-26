{
  config,
  pkgs,
  lib,
  ...
}:

{
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
      obs-studio
      imagemagick

      # Music
      reaper
      ardour
      steam

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
      noto-fonts-emoji
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
    # BASH Configuration
    # ========================================================
    bash = {
      enable = true;

      shellAliases = {
        # Navigation with eza
        ll = "eza -la --icons --git";
        la = "eza -la --icons --git";
        lt = "eza --tree --icons --git";
        ls = "eza --icons";

        # System monitoring
        ps = "ps auxf";
        psg = "ps aux | grep -v grep | grep -i -e VSZ -e";
        mkdir = "mkdir -p";
        meminfo = "free -m -l -t";
        cpuinfo = "lscpu";

        # Network diagnostics
        ports = "netstat -tulanp";
        listening = "lsof -i -P | grep LISTEN";

        # Git shortcuts (enhanced)
        gs = "git status";
        ga = "git add";
        gaa = "git add --all";
        gc = "git commit -m";
        gp = "git push -u origin main";
        gl = "git log --oneline --graph --decorate --all -10";
        gd = "git diff";
        gco = "git checkout";
        gar = "git add remote origin";

        # NixOS management (usando home-manager agora!)
        rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --show-trace";
        build = "home-manager switch --flake ~/.config/NixHM#kernelcore";
        upgrade = "nix flake update ~/.config/home-manager && home-manager switch --flake ~/.config/NixHM#kernelcore";
        clean = "sudo nix-collect-garbage -d && sudo nix-store --gc";
        cleanold = "sudo nix-collect-garbage --delete-older-than 7d";

        # Docker shortcuts
        dps = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";
        dimg = "docker images";
        dstop = "docker stop $(docker ps -q)";
        dclean = "docker system prune -af";

        # Security & Privacy
        shred = "shred -vfz -n 3";

        # Quick access
        dots = "cd ~/.config/NixHM";
        neo = "cd ~/.config/nvim";
        dev = "cd ~/Dev";
        dock = "cd ~/Dev/docker-hub/";
        ml-clusters = "cd ~/Dev/docker-hub//ml-clusters/";

        # Fun stuff
        weather = "curl wttr.in";
        speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";
      };

      bashrcExtra = ''
                # ====================================================
                # SHELL ENVIRONMENT
                # ====================================================

                # Enhanced history
                export HISTSIZE=10000
                export HISTFILESIZE=20000
                export HISTCONTROL=ignoredups:erasedups
                export HISTTIMEFORMAT="%F %T "
                shopt -s histappend # Append to history, don't overwrite

                # Application defaults
                export EDITOR="nvim"
                export VISUAL="nvim"
                export BROWSER="brave"
                export ANTHROPIC_MODEL="claude-sonnet-4-5-20250929"

                # Security paranoia
                umask 077

                # Better cd behavior
                shopt -s autocd # cd by typing directory name
                shopt -s cdspell # autocorrect typos in path

                # Zoxide integration (smarter cd)
                eval "$(zoxide init bash)"

                # ====================================================
                # CUSTOM PROMPT (Git-aware)
                # ====================================================

                parse_git_branch() {
                  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
                }

                parse_git_dirty() {
                  [[ $(git status --porcelain 2> /dev/null) ]] && echo "*"
                }

                # Colorful prompt with git status
                export PS1="\[\033[32m\]\u@\h\[\033[00m\]:\[\033[34m\]\w\[\033[31m\]\$(parse_git_branch)\$(parse_git_dirty)\[\033[00m\]\$ "

                # ====================================================
                # QUALITY OF LIFE FUNCTIONS
                # ====================================================

                # Quick cd up multiple directories
                up() {
                  local d=""
                  local limit="''${1:-1}"
                  for ((i=1; i<=limit; i++)); do
                    d="../$d"
                  done
                  cd "$d" || return
                }

                # Extract any archive
                extract() {
                  if [ -f "$1" ]; then
                    case "$1" in
                      *.tar.bz2)   tar xjf "$1"     ;;
                      *.tar.gz)    tar xzf "$1"     ;;
                      *.bz2)       bunzip2 "$1"     ;;
                      *.rar)       unrar x "$1"     ;;
                      *.gz)        gunzip "$1"      ;;
                      *.tar)       tar xf "$1"      ;;
                      *.tbz2)      tar xjf "$1"     ;;
                      *.tgz)       tar xzf "$1"     ;;
                      *.zip)       unzip "$1"       ;;
                      *.Z)         uncompress "$1"  ;;
                      *.7z)        7z x "$1"        ;;
                      *)           echo "'$1' cannot be extracted via extract()" ;;
                    esac
                  else
                    echo "'$1' is not a valid file"
                  fi
                }

                # Quick backup
                backup() {
                  cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
                }

                # ====================================================
                # LOAD DOMAIN-SPECIFIC ALIASES
                # ====================================================

                # GPU aliases
                if [ -f ~/.config/NixHM/aliases/gpu.sh ]; then
                  source ~/.config/NixHM/aliases/gpu.sh
                fi

                # GPU Management (orchestration)
                if [ -f ~/.config/NixHM/aliases/gpu-management.sh ]; then
                  source ~/.config/NixHM/aliases/gpu-management.sh
                fi

                # GCloud aliases
                if [ -f ~/.config/NixHM/aliases/gcloud.sh ]; then
                  source ~/.config/NixHM/aliases/gcloud.sh
                fi

                # AI-Docker Inference aliases
                if [ -f ~/.config/NixHM/aliases/multimodal.sh ]; then
                  source ~/.config/NixHM/aliases/multimodal.sh
                fi

        	# Nix Aliases
        	if [ -f ~/.config/NixHM/aliases/nx.sh ]; then
                  source ~/.config/NixHM/aliases/nx.sh
                fi

        	# GPU-docker-core Aliases
        	if [ -f ~/.config/NixHM/aliases/gpu-docker-core.sh ]; then
                  source ~/.config/NixHM/aliases/gpu-docker-core.sh
                fi

        	# AI-ML-Stack Aliases
        	if [ -f ~/.config/NixHM/aliases/ai-ml-stack.sh ]; then
                  source ~/.config/NixHM/aliases/ai-ml-stack.sh
                fi

        	# Ai-Compose-Stack Docker Aliases
        	if [ -f ~/.config/NixHM/aliases/ai-compose-stack.sh ]; then
                  source ~/.config/NixHM/aliases/ai-compose-stack.sh
                fi

        	if [ -f ~/.config/NixHM/aliases/litellm_runtime_manager.sh ]; then
                  source ~/.config/NixHM/aliases/litellm_runtime_manager.sh
                fi

                # Welcome message
                #echo "⚡ Welcome back, $(whoami)! Ready to hack? 🚀"

        	#EXPORT=jup-ml --port 8899 --workdir ~/my‑project
      '';
    };

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
    # Eza (Modern ls replacement)
    # ========================================================
    eza = {
      enable = true;
      enableBashIntegration = true;
      git = true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
        "--header"
        "--long"
      ];
    };

    # ========================================================
    # Fzf (Fuzzy finder)
    # ========================================================
    fzf = {
      enable = true;
      enableBashIntegration = true;

      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--border"
        "--layout=reverse"
        "--preview 'bat --color=always {}'"
        "--bind 'ctrl-/:toggle-preview'"
      ];

      colors = {
        bg = "#1e1e1e";
        "bg+" = "#2e2e2e";
        fg = "#d4d4d4";
        "fg+" = "#ffffff";
      };
    };

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
    # Bat (Better cat with syntax highlighting)
    # ========================================================
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
      };
    };

    # ========================================================
    # Zoxide (Smarter cd)
    # ========================================================
    zoxide = {
      enable = true;
      enableBashIntegration = true;
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
      size = 11;
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

    # GPU aliases (source file)
    ".config/NixHM/aliases/gpu.sh".source = ./aliases/gpu.sh;

    # GPU Management aliases (GPU orchestration)
    ".config/NixHM/aliases/gpu-management.sh".source = ./aliases/gpu-management.sh;

    # GCloud aliases (source file)
    ".config/NixHM/aliases/gcloud.sh".source = ./aliases/gcloud.sh;

    # Local AI inference (source file)
    ".config/NixHM/aliases/multimodal.sh".source = ./aliases/multimodal.sh;

    # Local AI inference (source file)
    ".config/NixHM/aliases/gpu-docker-core.sh".source = ./aliases/gpu-docker-core.sh;

    # Local AI inference (source file)
    ".config/NixHM/aliases/ai-ml-stack.sh".source = ./aliases/ai-ml-stack.sh;

    # Local AI inference (source file)
    ".config/NixHM/aliases/nx.sh".source = ./aliases/nx.sh;

    # Docker Aliases (source file)
    ".config/NixHM/aliases/ai-compose-stack.sh".source = ./aliases/ai-compose-stack.sh;

    ".config/NixHM/aliases/litellm_runtime_manager.sh".source = ./aliases/litellm_runtime_manager.sh;

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
    BROWSER = "brave";
    TERMINAL = "gnome-terminal";

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
