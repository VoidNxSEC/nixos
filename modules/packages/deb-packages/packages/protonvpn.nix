# ProtonVPN - Secure VPN Client
# Version: 1.0.8
# Status: Removed from nixpkgs unstable - candidate for upstream PR
{
  protonvpn = {
    enable = true;

    # Build method - FHS for complex GUI applications
    method = "fhs";

    # Source configuration
    source = {
      # Download from: https://repo.protonvpn.com/debian/dists/stable/main/binary-all/
      path = ../storage/protonvpn-stable-release_1.0.8_all.deb;
      sha256 = "0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180";
    };

    # Wrapper configuration
    wrapper = {
      executable = "usr/bin/protonvpn";
      environmentVariables = {
        # ProtonVPN specific variables
        "PROTONVPN_CONFIG_DIR" = "$HOME/.config/protonvpn";
      };
    };

    # Sandbox - disabled for VPN (needs network access)
    sandbox = {
      enable = false;
      allowedPaths = [];
      blockHardware = [];
      resourceLimits = {
        memory = null;
        cpu = null;
        tasks = null;
      };
    };

    # Audit - enable for security-critical VPN
    audit = {
      enable = true;
      logLevel = "standard";
    };

    # Desktop entry - handled by .deb package itself
  };
}
