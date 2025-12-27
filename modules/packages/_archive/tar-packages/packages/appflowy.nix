# AppFlowy - Open-source Notion alternative
# Version: 0.10.6
# Purpose: Privacy-first note-taking and project management
{
  appflowy = {
    enable = true;

    # Build method - FHS for Electron/Flutter apps (dynamically linked)
    method = "fhs";

    # Source configuration
    source = {
      path = ../storage/AppFlowy-0.10.6-linux-x86_64.tar.gz;
      sha256 = "sha256-87mauW50ccOaPyK04O4I7+0bsvxVrdFxhi/Muc53wDY=";
    };

    # Wrapper configuration
    wrapper = {
      executable = "AppFlowy/AppFlowy";
      environmentVariables = {
        "APPFLOWY_DATA_DIR" = "$HOME/.appflowy";
      };
    };

    # Sandbox - disabled (needs file system access for notes)
    sandbox = {
      enable = false;
    };

    # Audit - optional
    audit = {
      enable = false;
    };

    # Desktop entry
    desktopEntry = {
      name = "AppFlowy";
      comment = "Open-source Notion alternative";
      categories = [
        "Office"
        "ProjectManagement"
        "Utility"
      ];
      icon = null;
    };
  };
}
