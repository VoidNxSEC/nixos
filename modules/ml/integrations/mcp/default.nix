{
  config,
  lib,
  pkgs,
  ...
}:

# MCP Integration
# Model Context Protocol server and configuration

{
  imports = [
    ./config.nix
    # ./server is a separate TypeScript project, not imported here
  ];
}
