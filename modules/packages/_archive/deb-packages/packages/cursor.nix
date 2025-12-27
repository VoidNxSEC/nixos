# Cursor - AI-Powered Code Editor
# Version: 2.0.34
# Purpose: Modern code editor with AI capabilities
{
  cursor = {
    enable = true;

    # Build method - FHS for Electron apps
    method = "fhs";

    # Source configuration
    source = {
      path = ../storage/cursor_2.0.34_amd64.deb;
      sha256 = "eb0e7ba183084da0e81b13a18d4be90823c82c5d3e69f16e07262207aaea61a6";
    };

    # Wrapper configuration
    wrapper = {
      executable = "usr/bin/cursor";
      environmentVariables = {
        "CURSOR_CONFIG_DIR" = "$HOME/.config/cursor";
      };
    };

    # Sandbox - disabled for IDE (needs file system access)
    sandbox = {
      enable = false;
      # IDEs need broad filesystem access for projects
    };

    # Audit - optional for development tools
    audit = {
      enable = false;
      logLevel = "minimal";
    };

    # Desktop entry - handled by .deb package itself
  };
}
