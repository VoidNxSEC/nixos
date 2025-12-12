{
  config,
  lib,
  pkgs,
  ...
}:

# ML Applications Layer
# Standalone ML applications now managed as independent flakes in projects/
# - securellm-bridge -> projects/securellm-bridge (imported via flake input)

{
  imports = [
    # Applications moved to projects/ folder as independent flakes
  ];
}
