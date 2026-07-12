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
    ./neovim # stub — integração ML p/ Neovim (TODO)
    ./mcp
  ];
}
