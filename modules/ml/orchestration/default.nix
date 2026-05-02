{ ... }:

# ============================================================
# ML Orchestration — Placeholder
# ============================================================
# The api/ subdirectory contains a standalone Rust/Nix flake
# (ml-offload-api) — it is a separate project, not a NixOS
# module to import here.
#
# To wire the orchestration API into your system:
#   1. Add it as a flake input in flakes/personal.nix
#   2. Import its NixOS module via specialArgs in your host
#
# NixOS modules for orchestration go here when ready.
# ============================================================

{
  imports = [ ];
}
