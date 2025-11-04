# Zellij Terminal Multiplexer
# Version: 0.43.1
# Purpose: Testing tar-packages module with Zellij
{
  zellij = {
    enable = true;

    # Build method - native works well for single Rust binaries
    method = "native";

    # Source configuration
    source = {
      path = ../storage/zellij-v0.43.1-x86_64-unknown-linux-musl.tar.gz;
      sha256 = "541d98efef5558293ef85ad9acd29e4d920b6e881513b9e77255d8207020d75a";
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
