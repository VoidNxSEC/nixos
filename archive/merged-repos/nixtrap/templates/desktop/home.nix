{ config, pkgs, ... }:

{
  home.stateVersion = "25.05";

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  # Shell aliases
  programs.bash.shellAliases = {
    ll = "ls -alh";
    rebuild = "sudo nixos-rebuild switch --flake .";
  };
}
