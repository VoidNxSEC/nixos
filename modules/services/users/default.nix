{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./claude-code.nix
    ./codex-agent.nix
    # Add more service users here as needed
  ];

  # Service users centralization module
  # This module provides a unified interface for managing all service users
  # across the system, ensuring consistent permissions and security policies.
}
