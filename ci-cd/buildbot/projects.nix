# /etc/nixos/modules/services/ci/buildbot-projects.nix
{ config, lib, ... }:

{
  # Projects auto-discovered via GitHub topic "nix-ci"
  # Add this topic to each repo you want CI for:
  #
  # VoidNxLabs/swissknife      - Debug tools, Python GTK4
  # VoidNxLabs/securellm-mcp   - MCP Server, TypeScript
  # VoidNxLabs/nixos           - Main NixOS config
  # VoidNxLabs/securellm-bridge - Rust LLM proxy
  # VoidNxLabs/cognitive-vault  - Go/Rust knowledge vault

  # Each repo needs a flake.nix with:
  # - checks.${system}.* - for CI tests
  # - packages.${system}.* - for builds
  # - devShells.${system}.* - optional dev environments
}
