# Proton Pass - Secure Password Manager
# Version: 1.33.0
# Purpose: End-to-end encrypted password manager from Proton
{
  protonpass = {
    enable = true;

    # Build method - FHS for Electron apps
    method = "fhs";

    # Source configuration - using local .deb from storage
    source = {
      path = ../storage/ProtonPass.deb;
      sha256 = "10b03e615f9a6e341685bd447067b839fd3a770e9bb1110ca04d0418d6beaca8";
    };

    # Wrapper configuration
    wrapper = {
      executable = "usr/bin/proton-pass";
      name = "proton-pass";
      extraArgs = [];
      environmentVariables = {
        "PROTON_PASS_CONFIG_DIR" = "$HOME/.config/proton-pass";
      };
    };

    # Sandbox - moderate restrictions for password manager
    sandbox = {
      enable = true;
      allowedPaths = [
        "$HOME/.config/proton-pass"
        "$HOME/.local/share/proton-pass"
        "$HOME/.cache/proton-pass"
      ];
      blockHardware = [ ]; # Allow all hardware for proper functionality
      resourceLimits = {
        memory = "2G";
        cpu = null;
        tasks = null;
      };
    };

    # Audit - enable for security-critical password manager
    audit = {
      enable = true;
      logLevel = "standard";
    };

    # Metadata
    meta = {
      description = "Proton Pass - End-to-end encrypted password manager";
      homepage = "https://proton.me/pass";
      license = "Proprietary";
    };
  };
}
