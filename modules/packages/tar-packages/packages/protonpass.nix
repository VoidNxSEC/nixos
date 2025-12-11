# Proton Pass - Secure Password Manager
# Version: Latest from GitHub releases
# Purpose: End-to-end encrypted password manager from Proton
{ lib, ... }:
{
  protonpass = {
    enable = true;

    # Build method - native for pre-built binaries
    method = "native";

    # Source configuration - GitHub releases
    source = {
      # Proton Pass releases on GitHub WebClients repo
      # To get latest: curl -s https://api.github.com/repos/ProtonMail/WebClients/releases | jq -r '.[].tag_name' | grep proton-pass
      # Manual download: https://proton.me/download/pass/linux
      # For now using direct URL (update version as needed)
      url = "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.tar.gz";
      sha256 = ""; # Run rebuild once to get hash, then add it here
    };

    # Wrapper configuration
    wrapper = {
      executable = "proton-pass"; # Binary name inside tarball
      environmentVariables = {
        "PROTON_PASS_CONFIG_DIR" = "$HOME/.config/proton-pass";
      };
    };

    # Sandbox - disabled for password manager (needs browser integration)
    sandbox = {
      enable = false;
    };

    # Audit - disabled by default
    audit = {
      enable = false;
    };

    # Desktop entry - should be included in tarball
    desktopEntry = null;

    # Metadata
    meta = {
      description = "Desktop application for Proton Pass";
      homepage = "https://proton.me/pass";
      license = lib.licenses.gpl3Plus;
      maintainers = with lib.maintainers; [
        luftmensch-luftmensch
        massimogengarelli
        sebtm
      ];
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      mainProgram = "proton-pass";
    };
  };
}
