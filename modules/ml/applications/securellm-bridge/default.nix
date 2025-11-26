{
  config,
  lib,
  pkgs,
  ...
}:

# SecureLLM Bridge (formerly unified-llm)
#
# This is a standalone application with its own flake.nix.
# It is not directly integrated into NixOS configuration.
#
# To build: cd /etc/nixos/modules/ml/applications/securellm-bridge && nix build
# To develop: cd /etc/nixos/modules/ml/applications/securellm-bridge && nix develop
#
# See flake.nix and CLAUDE.md for details.

{
  # Empty module - securellm-bridge is a standalone application
  # with its own build system (flake.nix)
}
