# Antigravity - Google's Anti-Gravity Editor
# Version: 1.11.5
# Purpose: Modern code editor with AI capabilities
{
  antigravity = {
    enable = true;

    # Build method - FHS for Electron apps (dynamically linked, requires system libraries)
    method = "fhs";

    # Source configuration
    source = {
      path = ../storage/Antigravity.tar.gz;
      sha256 = "4548789f5e30ad13ef341ef112f3a399b2d6b0e0cc95e7bf5a0625b08a5a7120";
    };

    # Wrapper configuration
    wrapper = {
      executable = "Antigravity/antigravity";
      environmentVariables = {
        "ANTIGRAVITY_USER_DATA_DIR" = "$HOME/.config/antigravity";
      };
    };

    # Sandbox - disabled for IDE (needs broad file system access)
    sandbox = {
      enable = false;
      # IDEs need access to project files across the filesystem
    };

    # Audit - optional for development tools
    audit = {
      enable = false;
    };

    # Desktop entry - Electron app benefits from desktop integration
    desktopEntry = {
      name = "Antigravity";
      comment = "Google's Anti-Gravity Code Editor with AI";
      categories = [
        "Development"
        "IDE"
        "TextEditor"
      ];
      icon = null; # Could extract icon from app if needed
    };
  };
}
