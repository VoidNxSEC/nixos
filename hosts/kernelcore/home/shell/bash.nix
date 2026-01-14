{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Bash Configuration (Fallback/Alternative)
# ============================================================

let
  cfg = config.myShell;
in
{
  config = lib.mkIf (cfg.enable && cfg.defaultShell == "bash") {
    programs.bash = {
      enable = true;
      enableCompletion = true;

      # History Configuration
      historySize = 10000;
      historyFileSize = 20000;
      historyControl = [
        "ignoredups"
        "erasedups"
      ];

      # Shell Aliases (same as zsh for consistency)
      shellAliases = {
        # Navigation
        ll = "eza -la --icons --git";
        la = "eza -la --icons --git";
        lt = "eza --tree --icons --git";
        ls = "eza --icons";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";

        # Git
        gs = "git status";
        ga = "git add";
        gaa = "git add --all";
        gc = "git commit -m";
        gp = "git push";
        gl = "git log --oneline --graph --decorate --all -10";
        gd = "git diff";
        gco = "git checkout";

        # Docker
        dps = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";
        dimg = "docker images";
        dstop = "docker stop $(docker ps -q)";
        dclean = "docker system prune -af";

        # Quick access
        dots = "cd ~/.config";
        neo = "cd ~/.config/nvim";
        dev = "cd ~/dev";
        nx = "cd /etc/nixos/";

        # Shell reload
        reload = "source ~/.bashrc";

        # Hyprland & Desktop
        reland = "hyprctl reload";
        hypredit = "$EDITOR ~/.config/hypr/hyprland.conf";
        hyprconf = "cd ~/.config/hypr && ls -la";

        # Waybar
        wayreload = "killall waybar && waybar &";
        wayedit = "$EDITOR ~/.config/waybar/config";
        waystyle = "$EDITOR ~/.config/waybar/style.css";

        # Utilities
        cat = "bat";
        grep = "rg";
        weather = "curl wttr.in";
      };

      bashrcExtra = ''
        # Enhanced history
        export HISTSIZE=10000
        export HISTFILESIZE=20000
        export HISTCONTROL=ignoredups:erasedups
        export HISTTIMEFORMAT="%F %T "
        shopt -s histappend

        # Application defaults
        export EDITOR="nvim"
        export VISUAL="nvim"
        export BROWSER="brave"

        # Better cd behavior
        shopt -s autocd
        shopt -s cdspell

        # Zoxide integration
        eval "$(zoxide init bash)"

        # Starship prompt
        eval "$(starship init bash)"
      '';
    };

    # Use starship for bash prompt
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
