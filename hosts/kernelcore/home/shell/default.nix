{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Shell Module - Main Entry Point
# ============================================================
# Provides zsh with powerlevel10k or bash configuration
# Toggle between shells easily with myShell.defaultShell option
# ============================================================

{
  imports = [
    ./options.nix
    ./zsh.nix
    ./bash.nix
  ];

  config = lib.mkIf config.myShell.enable {
    # Set default user shell
    home.sessionVariables = {
      SHELL =
        if config.myShell.defaultShell == "zsh" then "${pkgs.zsh}/bin/zsh" else "${pkgs.bash}/bin/bash";
    };

    # Install required packages
    home.packages = with pkgs; [
      # Shell enhancements
      zsh
      zsh-powerlevel10k
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-completions
      nix-zsh-completions

      # Additional tools for better experience
      eza # Modern ls
      bat # Better cat
      ripgrep # Better grep
      fd # Better find
      fzf # Fuzzy finder
      zoxide # Smarter cd
      # thefuck removed (incompatible with python 3.12+)
      direnv # Directory-based environments
      nix-direnv # Direnv for Nix
    ];

    # Enable tool integrations (use mkDefault to allow overriding)
    programs.eza.enable = lib.mkDefault true;
    programs.eza.enableZshIntegration = lib.mkDefault true;

    programs.bat.enable = lib.mkDefault true;

    programs.fzf.enable = lib.mkDefault true;
    programs.fzf.enableZshIntegration = lib.mkDefault true;

    programs.zoxide.enable = lib.mkDefault true;
    programs.zoxide.enableZshIntegration = lib.mkDefault true;

    programs.direnv.enable = lib.mkDefault true;
    programs.direnv.enableZshIntegration = lib.mkDefault true;
    programs.direnv.nix-direnv.enable = lib.mkDefault true;
  };
}
