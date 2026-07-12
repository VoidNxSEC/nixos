{ ... }:
{
  imports = [
    ./system.nix
    ./rebuild-advanced.nix
    ./rebuild-helpers.nix # Colorized rebuild helpers (enable-gated)
    ./analytics.nix
    ./specialisations.nix
  ];
}
