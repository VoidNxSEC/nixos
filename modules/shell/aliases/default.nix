{ ... }:

# ============================================================
# Shell Aliases - Main Aggregator
# ============================================================
# Professional alias organization by category
# Version: 2.0.0 - Complete Restructure (2025-11-01)
# ============================================================
#
# Structure:
#   aliases/
#   ├── docker/      - Docker build, run, compose
#   ├── kubernetes/  - kubectl shortcuts
#   ├── gcloud/      - Google Cloud Platform
#   ├── ai/          - AI/ML stack management
#   ├── nix/         - Nix/NixOS system
#   └── system/      - General utilities
#
# Usage in flake.nix:
#   ./modules/shell/aliases
#
# See: ./README.md for complete documentation
# ============================================================

{
  imports = [
    ./docker
    ./kubernetes
    ./gcloud
    ./ai
    ./nix
    ./system
  ];
}
