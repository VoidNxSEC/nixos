{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Nix/NixOS System Aliases
# ============================================================

{
  environment.shellAliases = {
    # NixOS Rebuild - Standard
    "nx-rebuild" = "sudo nixos-rebuild switch --flake /etc/nixos";
    "nx-rebuild-test" = "sudo nixos-rebuild test --flake /etc/nixos";
    "nx-rebuild-boot" = "sudo nixos-rebuild boot --flake /etc/nixos";
    "nx-rebuild-trace" = "sudo nixos-rebuild switch --flake /etc/nixos --show-trace";

    # NixOS Rebuild - Laptop Optimized (prevents OOM/thermal issues from heavy builds like magma)
    "nx-rebuild-safe" =
      "sudo nixos-rebuild switch --flake /etc/nixos --max-jobs 1 --cores 4 --keep-going --fallback";
    "nx-rebuild-balanced" =
      "sudo nixos-rebuild switch --flake /etc/nixos --max-jobs 2 --cores 4 --keep-going";
    "nx-rebuild-aggressive" =
      "sudo nixos-rebuild switch --flake /etc/nixos --max-jobs 6 --cores 2 --keep-going";

    # NixOS Rebuild - With Desktop Offload (requires configured builder)
    "nx-rebuild-offload" =
      "sudo nixos-rebuild switch --flake /etc/nixos --max-jobs 2 --cores 2 --builders 'ssh://builder@desktop.local x86_64-linux - 8 3 big-parallel'";

    # NixOS Rebuild - Test variants
    "nx-rebuild-safe-test" =
      "sudo nixos-rebuild test --flake /etc/nixos --max-jobs 1 --cores 4 --keep-going";
    "nx-rebuild-balanced-test" =
      "sudo nixos-rebuild test --flake /etc/nixos --max-jobs 2 --cores 4 --keep-going";

    # Nix Build - Standard
    "nx-build" = "nix build";
    "nx-build-trace" = "nix build --show-trace";
    "nx-run" = "nix run";

    # Nix Build - Laptop Optimized (controls parallelism for heavy packages)
    "nx-build-safe" = "nix build --max-jobs 1 --cores 4 --keep-going --fallback";
    "nx-build-balanced" = "nix build --max-jobs 2 --cores 4 --keep-going";
    "nx-build-aggressive" = "nix build --max-jobs 4 --cores 3 --keep-going";
    "nx-build-trace-safe" = "nix build --show-trace --max-jobs 1 --cores 4 --keep-going";

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
