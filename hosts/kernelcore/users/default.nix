{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./actions.nix
    ./claude-code.nix
    ./codex-agent.nix
    ./gemini-agent.nix
    ./gitlab-runner.nix
  ];

  # Service users centralization module
  # This module provides a unified interface for managing all service users
  # across the system, ensuring consistent permissions and security policies.
}
