# Proton Pass - Secure Password Manager
# Version: 37.9.0
# Purpose: End-to-end encrypted password manager from Proton
{
  protonpass = {
    enable = true;

    # Build method - FHS for Electron apps
    method = "fhs";

    # Source configuration
    source = {
      path = ../storage/proton-pass-37.9.0.tar.gz;
      sha256 = "52166a5b11c3a6636c6697e63dda4007658e0a9e93ecbe84cf3a1349ef0b64eb";
    };

    # Wrapper configuration
    wrapper = {
      executable = "usr/bin/proton-pass";
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
      ];
      blockHardware = [ ];
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
