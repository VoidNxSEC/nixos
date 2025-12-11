# Zellij Terminal Multiplexer
# Version: Auto-updated via nvfetcher
# Purpose: Production tar-package with auto-updates
{ pkgs, ... }:
let
  sources = pkgs.callPackage ../../_sources/generated.nix { };
in
{
  kernelcore.packages.tar.packages.zellij = {
    enable = true;

    # Build method - native works well for single Rust binaries
    method = "native";

    # Source configuration
    source = {
      path = sources.zellij.src;
      # sha256 is handled by the source derivation
      sha256 = ""; 
    };

    # Wrapper configuration
    wrapper = {
      executable = "zellij";
      environmentVariables = {
        # Zellij looks for config in standard XDG paths
        "ZELLIJ_CONFIG_DIR" = "$HOME/.config/zellij";
      };
    };

    # Sandbox - disabled for terminal multiplexer (needs full system access)
    sandbox = {
      enable = false;
      # Terminal multiplexers need broad access to work properly
    };

    # Audit - optional, disabled by default for CLI tools
    audit = {
      enable = false;
    };

    # Desktop entry - optional for terminal apps
    desktopEntry = null;
  };
}
