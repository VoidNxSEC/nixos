{
  config,
  lib,
  pkgs,
  ...
}:

# ML Applications Layer
# Standalone ML applications (SecureLLM Bridge, etc.)

{
  imports = [
    ./securellm-bridge
    # Future applications here
  ];
}
