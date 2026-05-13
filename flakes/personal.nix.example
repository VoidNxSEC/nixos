# ============================================================
# Personal Flake Inputs — Template
# ============================================================
# Copy this file to flakes/personal.nix and add your own
# private/SSH-authenticated inputs here. This file is
# intentionally NOT imported by default in flake.nix.
#
# Why this pattern?
#   The main flake.nix stays community-clean (no SSH URLs,
#   no absolute paths). Your private project inputs live here.
#
# Usage:
#   1. cp flakes/personal.nix.example flakes/personal.nix
#   2. Edit flakes/personal.nix with your repos
#   3. In flake.nix, add:
#        personal = {
#          url = "path:./flakes/personal.nix";
#        };
#      Then wire outputs as needed.
# ============================================================

{
  description = "Personal flake inputs — not for community distribution";

  inputs = {
    # ── SSH-authenticated repos ────────────────────────────
    # my-private-service = {
    #   url = "git+ssh://git@github.com/YOUR-ORG/your-service";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # ── Local paths (monorepo siblings, in-progress projects) ─
    # my-local-project = {
    #   url = "path:/home/YOUR-USERNAME/projects/my-project";
    # };

    # ── ML / inference backends ───────────────────────────
    # ml-offload-api = {
    #   url = "git+ssh://git@github.com/YOUR-ORG/ml-offload-api";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, ... }@inputs: {
    # Re-export inputs for use in NixOS host configurations
    inherit inputs;

    # Example: overlay for your custom packages
    # overlay = final: prev: {
    #   my-package = inputs.my-private-service.packages.${prev.system}.default;
    # };
  };
}
