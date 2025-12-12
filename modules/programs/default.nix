{ ... }:

{
  imports = [
    ./cognitive-vault.nix
    ./vmctl.nix
  ];

  programs.sway.xwayland.enable = true;

}
