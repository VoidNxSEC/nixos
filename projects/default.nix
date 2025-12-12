{ ... }:

{
  # Projects aggregator
  # Individual projects are imported via their respective NixOS modules:
  # - modules/programs/vmctl.nix
  # - modules/programs/cognitive-vault.nix
  # 
  # This file exists to satisfy the import in flake.nix
  # Projects with their own flakes are built independently
}
