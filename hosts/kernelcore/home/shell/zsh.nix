{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Zsh Configuration with Powerlevel10k
# ============================================================

let
  cfg = config.myShell;
in
{
  config = lib.mkIf (cfg.enable && cfg.defaultShell == "zsh") {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      # ========================================================
      # History Configuration
      # ========================================================
      history = {
        size = 10000;
        save = 20000;
        path = "${config.home.homeDirectory}/.zsh_history";
        ignoreDups = true;
        ignoreSpace = true;
        extended = true;
        share = true;
      };

      # ========================================================
      # Shell Options
      # ========================================================
      defaultKeymap = "emacs";

      # ========================================================
      # Advanced Completion System
      # ========================================================
      completionInit = ''
        # Load and initialize the completion system
        autoload -Uz compinit
        compinit

        # Advanced completion options
        zstyle ':completion:*' menu select                          # Select completions with arrow keys
        zstyle ':completion:*' group-name '''                       # Group results by category
        zstyle ':completion:*:descriptions' format '%B%d%b'         # Format group descriptions
        zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
        zstyle ':completion:*' use-cache yes                        # Cache completions
        zstyle ':completion:*' cache-path ~/.zsh/cache

        # Fuzzy matching for typos
        zstyle ':completion:*' completer _complete _match _approximate
        zstyle ':completion:*:match:*' original only
        zstyle ':completion:*:approximate:*' max-errors 1 numeric

        # Case-insensitive completion
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

        # Color completion for files
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

        # Complete process names with menu
        zstyle ':completion:*:*:kill:*' menu yes select
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
        zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

        # SSH/SCP/RSYNC hostname completion
        zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
        zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
        zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

        # Docker completion enhancements
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        # Git completion enhancements
        zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
        zstyle ':completion:*:*:git:*' tag-order 'common-commands'

        # Directory navigation
        zstyle ':completion:*' special-dirs true                    # Complete . and ..
        zstyle ':completion:*' squeeze-slashes true                 # Remove redundant slashes

        # Pip completion
        compdef -d pip pip3

        # AWS CLI completion
        which aws_zsh_completer.sh &>/dev/null && source $(which aws_zsh_completer.sh)
      '';

      # ========================================================
      # Oh My Zsh Integration
      # ========================================================
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "docker"
          "kubectl"
          "aws"
          "sudo"
          "extract"
          "colored-man-pages"
          "command-not-found"
          "history-substring-search"
          # Note: zsh-autosuggestions and zsh-syntax-highlighting are managed
          # natively by home-manager via autosuggestion.enable and
          # syntaxHighlighting.enable options (lines 19-20)
        ];
      };

      # ========================================================
      # Shell Aliases
      # ========================================================
      shellAliases = {
        # Navigation with eza
        ll = "eza -la --icons --git";
        la = "eza -la --icons --git";
        lt = "eza --tree --icons --git";
        ls = "eza --icons";

        # Directory navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";

        # System monitoring
        ps = "ps auxf";
        psg = "ps aux | grep -v grep | grep -i -e VSZ -e";
        mkdir = "mkdir -p";
        meminfo = "free -m -l -t";
        cpuinfo = "lscpu";

        # Network diagnostics
        ports = "netstat -tulanp";
        listening = "lsof -i -P | grep LISTEN";

        # Git shortcuts
        gs = "git status";
        ga = "git add";
        gaa = "git add --all";
        gc = "git commit -m";
        gp = "git push -u origin main";
        gl = "git log --oneline --graph --decorate --all -10";
        gd = "git diff";
        gco = "git checkout";

        # NixOS management
        clean = "sudo nix-collect-garbage -d && sudo nix-store --gc";
        cleanold = "sudo nix-collect-garbage --delete-older-than 7d";

        # Docker shortcuts
        dps = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";
        dimg = "docker images";
        dstop = "docker stop $(docker ps -q)";
        dclean = "docker system prune -af";

        # Quick access
        dots = "cd ~/.config";
        neo = "cd ~/.config/nvim";
        dev = "cd ~/dev";
        nx = "cd /etc/nixos/";

        nxbd = "sudo nixos-rebuild switch --flake /etc/nixos\#kernelcore --cores 8 --max-jobs 8 --verbose --show-trace --upgrade";

        # Shell switching
        tobash = "chsh -s $(which bash) && exec bash";
        tozsh = "chsh -s $(which zsh) && exec zsh";

        # Shell reload
        reload = "source ~/.zshrc";

        # Hyprland & Desktop
        reland = "hyprctl reload";
        hypredit = "$EDITOR ~/.config/hypr/hyprland.conf";
        hyprconf = "cd ~/.config/hypr && ls -la";

        t = "tree -a -L 2 -C --dirsfirst \
            -P *.md|*.nix|*.txt|*.wordx|*.sh|*.pdf|*.zip|*.yaml|*.yml|*.py|*.toml|*.rs|*.sql|*.env|*.env.*|*.json|*.lock|*.gitignore|*.dockerignore|Dockerfile|*.dockerfile|tauri.conf.json|vite.config.*|svelte.config.*|next.config.*|astro.config.*|nuxt.config.*|wrangler.toml|deno.json|deno.jsonc|pyproject.toml|*.png|*.jpg|*.jpeg|*.gif|*.svg|*.webp|*.ico \
            -I node_modules|.git|target|dist|build|out|.next|.svelte-kit|.vite|.nuxt|.vercel|.turbo|.cache|.parcel-cache|.esbuild|__pycache__|*.pyc|*.map|*.tsbuildinfo|.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.d.ts|*.tsbuildinfo|.tauri/tmp|temp|.DS_Store|*.log|coverage|storybook-static \
            --prune";

        # MCP Server (disabled - project moved externally)
        # mcp-server-start = "node /etc/nixos/projects/securellm-mcp/build/src/index.js --log-level=INFO";

        # Smart Commits
        git-commit-smart = "git add -A && git commit -m \"feat: $(date +%Y-%m-%d) - $(git status --porcelain | grep -c ^M) changes\"";
        git-commit-ai = "/etc/nixos/scripts/auto-commit.sh";

        # Waybar
        wayreload = "killall waybar && waybar &";
        wayedit = "$EDITOR ~/.config/waybar/config";
        waystyle = "$EDITOR ~/.config/waybar/style.css";

        # Quick edits
        aliases = "cd /etc/nixos/modules/shell/aliases && ls -la";

        # Utilities
        weather = "curl wttr.in";
        cat = "bat";
        grep = "rg";
      };

      # ========================================================
      # ZSH Init Content
      # ========================================================
      initContent = ''
        # ====================================================
        # POWERLEVEL10K CONFIGURATION
        # ====================================================
        ${lib.optionalString cfg.enablePowerlevel10k ''
          # Enable Powerlevel10k instant prompt
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi

          # Load Powerlevel10k theme
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

          # Powerlevel10k configuration
          # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        ''}

        # ====================================================
        # ENVIRONMENT VARIABLES
        # ====================================================
        export EDITOR="nvim"
        export VISUAL="nvim"
        export BROWSER="brave"
        export ANTHROPIC_MODEL="claude-sonnet-4-5-20250929"

        # Security paranoia
        umask 077

        # ====================================================
        # KEY BINDINGS
        # ====================================================
        # History search with arrow keys
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down

        # Ctrl+arrow for word navigation
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word

        # Home/End keys
        bindkey "^[[H" beginning-of-line
        bindkey "^[[F" end-of-line

        # Delete key
        bindkey "^[[3~" delete-char

        # ====================================================
        # ZSH OPTIONS
        # ====================================================
        setopt AUTO_CD              # cd by typing directory name
        setopt AUTO_PUSHD           # Push the old directory onto the stack
        setopt PUSHD_IGNORE_DUPS    # Don't push multiple copies
        setopt PUSHD_SILENT         # Don't print directory stack
        setopt CORRECT              # Spelling correction
        setopt EXTENDED_GLOB        # Extended globbing
        setopt NO_CASE_GLOB         # Case insensitive globbing
        setopt NUMERIC_GLOB_SORT    # Sort filenames numerically

        # ====================================================
        # CUSTOM FUNCTIONS
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

        # Quick note taking
        note() {
          echo "$(date +'%Y-%m-%d %H:%M:%S'): $*" >> ~/notes.txt
        }

        # Create directory and cd into it
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }

        # ====================================================
        # INTEGRATIONS
        # ====================================================
        # Zoxide (smarter cd)
        eval "$(zoxide init zsh)"

        # FZF key bindings
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        source ${pkgs.fzf}/share/fzf/completion.zsh

        # ====================================================
        # WELCOME MESSAGE
        # ====================================================
        # Uncomment for a welcome message
        # echo "⚡ Welcome to ZSH with Powerlevel10k! Ready to hack? 🚀"
      '';

      # ========================================================
      # Local Variables
      # ========================================================
      localVariables = {
        # ZSH autosuggestions
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#666666";
        ZSH_AUTOSUGGEST_STRATEGY = [
          "history"
          "completion"
        ];

        # History substring search colors
        HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND = "bg=green,fg=white,bold";
        HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND = "bg=red,fg=white,bold";
      };
    };

    # ========================================================
    # Powerlevel10k Configuration File
    # ========================================================
    home.file.".p10k.zsh" = lib.mkIf cfg.enablePowerlevel10k {
      source = ./p10k.zsh;
    };
  };
}
