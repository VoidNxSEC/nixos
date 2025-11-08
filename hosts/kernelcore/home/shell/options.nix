{
  config,
  lib,
  ...
}:

# ============================================================
# Shell Configuration Options
# ============================================================
# Allows easy switching between bash and zsh
# ============================================================

{
  options.myShell = {
    enable = lib.mkEnableOption "Custom shell configuration";

    defaultShell = lib.mkOption {
      type = lib.types.enum [ "bash" "zsh" ];
      default = "zsh";
      description = "Default shell to use (bash or zsh)";
    };

    enablePowerlevel10k = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Powerlevel10k theme for zsh";
    };

    enableNerdFonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Nerd Fonts support";
    };
  };
}
