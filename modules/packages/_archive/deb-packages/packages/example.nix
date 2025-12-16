# Example .deb package configuration
# This demonstrates all available options for configuring a .deb package

{
  # Example 1: Simple package with URL source
  example-tool = {
    enable = true;
    method = "auto"; # auto, fhs, or native

    source = {
      url = "https://example.com/releases/example-tool_1.0.0_amd64.deb";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    sandbox = {
      enable = true;
      allowedPaths = [ "/tmp" ];
      blockHardware = [ ];
      resourceLimits = { };
    };

    audit = {
      enable = true;
      logLevel = "standard"; # minimal, standard, or verbose
    };

    wrapper = {
      name = "example-tool";
      extraArgs = [ ];
      environmentVariables = { };
    };

    meta = {
      description = "Example tool from .deb package";
      homepage = "https://example.com";
      license = "MIT";
    };
  };

  # Example 2: Package with Git LFS storage
  local-tool = {
    enable = false; # Disabled by default
    method = "fhs";

    source = {
      path = ../storage/local-tool.deb;
      sha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
    };

    sandbox = {
      enable = true;
      allowedPaths = [
        "/home/user/workspace"
        "/tmp"
      ];
      blockHardware = [ "gpu" ]; # Block GPU access
      resourceLimits = {
        memory = "4G";
        cpu = 75;
        tasks = 1024;
      };
    };

    audit = {
      enable = true;
      logLevel = "verbose"; # Full logging
    };

    wrapper = {
      name = "local-tool";
      extraArgs = [ "--verbose" ];
      environmentVariables = {
        TOOL_CONFIG = "/etc/tool/config.yaml";
      };
    };

    meta = {
      description = "Local tool stored with Git LFS";
      homepage = "https://internal.example.com";
      license = "Proprietary";
    };
  };

  # Example 3: Strict sandboxed application
  untrusted-app = {
    enable = false;
    method = "fhs";

    source = {
      url = "https://untrusted-source.com/app.deb";
      sha256 = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";
    };

    sandbox = {
      enable = true;
      allowedPaths = [ ]; # No host filesystem access
      blockHardware = [
        "gpu"
        "audio"
        "camera"
        "usb"
        "bluetooth"
      ]; # Block all hardware
      resourceLimits = {
        memory = "1G"; # Strict memory limit
        cpu = 25; # Limited CPU
        tasks = 256; # Limited processes
      };
    };

    audit = {
      enable = true;
      logLevel = "verbose"; # Maximum logging
    };

    wrapper = {
      name = "untrusted-app";
      extraArgs = [ ];
      environmentVariables = {
        HOME = "/tmp/app-home";
      };
    };

    meta = {
      description = "Untrusted application with maximum isolation";
      homepage = "https://untrusted-source.com";
      license = "Unknown";
    };
  };

  # Example 4: Development tool with relaxed sandbox
  dev-tool = {
    enable = false;
    method = "native";

    source = {
      url = "https://dev-tools.example.com/tool.deb";
      sha256 = "sha256-DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=";
    };

    sandbox = {
      enable = true;
      allowedPaths = [
        "/home/user/projects"
        "/tmp"
        "/var/tmp"
      ];
      blockHardware = [ ]; # Allow all hardware
      resourceLimits = {
        memory = "8G";
        cpu = 100; # No CPU limit
      };
    };

    audit = {
      enable = true;
      logLevel = "minimal"; # Minimal logging for dev tools
    };

    wrapper = {
      name = "dev-tool";
      extraArgs = [ ];
      environmentVariables = {
        PATH = "/usr/local/bin:$PATH";
        LANG = "en_US.UTF-8";
      };
    };

    meta = {
      description = "Development tool with relaxed restrictions";
      homepage = "https://dev-tools.example.com";
      license = "Apache-2.0";
    };
  };
}
