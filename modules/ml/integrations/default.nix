{
  config,
  lib,
  pkgs,
  ...
}:

# ML Integrations Layer
# External integrations: MCP servers, Neovim, etc.

{
  imports = [
    ./mcp
  ];
}
