{ config, pkgs, lib, ... }:

# ============================================================
# Nix/NixOS System Aliases
# ============================================================

{
  environment.shellAliases = {
    # NixOS Rebuild
    "nx-rebuild" = "sudo nixos-rebuild switch --flake /etc/nixos";
    "nx-rebuild-test" = "sudo nixos-rebuild test --flake /etc/nixos";
    "nx-rebuild-boot" = "sudo nixos-rebuild boot --flake /etc/nixos";
    "nx-rebuild-trace" = "sudo nixos-rebuild switch --flake /etc/nixos --show-trace";

    # Nix Build
    "nx-build" = "nix build";
    "nx-build-trace" = "nix build --show-trace";
    "nx-run" = "nix run";

    # Nix Shell
    "nx-shell" = "nix-shell -p";
    "nx-dev" = "nix develop";

    # Nix Search
    "nx-search" = "nix search nixpkgs";
    "nx-info" = "nix-env -qa --description";

    # Nix Flake
    "nx-flake-check" = "nix flake check";
    "nx-flake-update" = "nix flake update";
    "nx-flake-show" = "nix flake show";

    # Garbage Collection
    "nx-gc" = "sudo nix-collect-garbage -d";
    "nx-gc-old" = "sudo nix-collect-garbage --delete-older-than 7d";
    "nx-optimize" = "sudo nix-store --optimize";

    # Nix Store
    "nx-store-verify" = "nix-store --verify --check-contents";
    "nx-store-repair" = "nix-store --repair --verify --check-contents";

    # System Info
    "nx-generations" = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    "nx-rollback" = "sudo nixos-rebuild switch --rollback";
  };
}
