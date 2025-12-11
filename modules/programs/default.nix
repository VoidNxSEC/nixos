{ ... }:

{
  imports = [
    ./cognitive-vault.nix
  ];

  programs.sway.xwayland.enable = true;

}
