{ ... }:

{
  imports = [
    ./cognitive-vault.nix
    ./vmctl.nix
    ./phantom.nix # Phantom AI toolkit
  ];

  programs.sway.xwayland.enable = true;

}
