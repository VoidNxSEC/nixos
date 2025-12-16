# Shared Type Definitions for Package Modules
# Purpose: Eliminate duplicate type definitions across deb/tar/js packages
{ lib }:

with lib;

rec {
  # =============================================================================
  # SOURCE TYPE - Unified source configuration for all package types
  # =============================================================================
  sourceType = types.submodule {
    options = {
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL to download package file";
      };
      path = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Local path to package file (for Git LFS storage)";
      };
      sha256 = mkOption {
        type = types.str;
        default = "";
        description = "SHA256 hash of the package file (REQUIRED for security)";
      };
    };
  };

  # =============================================================================
  # SANDBOX TYPE - Bubblewrap isolation configuration
  # =============================================================================
  sandboxType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable sandboxing with bubblewrap";
      };
      allowedPaths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "/tmp"
          "$HOME/.config/myapp"
        ];
        description = "Paths accessible from within sandbox";
      };
      blockHardware = mkOption {
        type = types.listOf (
          types.enum [
            "gpu"
            "audio"
            "usb"
            "camera"
            "bluetooth"
          ]
        );
        default = [ ];
        example = [
          "gpu"
          "camera"
        ];
        description = "Hardware devices to block access to";
      };
      resourceLimits = mkOption {
        type = types.submodule {
          options = {
            memory = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "2G";
              description = "Maximum memory (systemd MemoryMax format)";
            };
            cpu = mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 50;
              description = "CPU quota percentage (0-100)";
            };
            tasks = mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 1024;
              description = "Maximum number of tasks/threads";
            };
          };
        };
        default = { };
        description = "Resource limits enforced via systemd";
      };
    };
  };

  # =============================================================================
  # WRAPPER TYPE - Executable wrapper configuration
  # =============================================================================
  wrapperType =
    name:
    types.submodule {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "Name of the wrapper executable";
        };
        executable = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "bin/myapp";
          description = "Path to executable within extracted package";
        };
        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra arguments to pass to the binary";
        };
        environmentVariables = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = {
            LD_LIBRARY_PATH = "/usr/local/lib";
          };
          description = "Environment variables for the binary";
        };
      };
    };

  # =============================================================================
  # AUDIT TYPE - Logging and monitoring configuration
  # =============================================================================
  auditType =
    auditByDefault:
    types.submodule {
      options = {
        enable = mkOption {
          type = types.bool;
          default = auditByDefault;
          description = "Enable audit logging for this package";
        };
        logLevel = mkOption {
          type = types.enum [
            "minimal"
            "standard"
            "verbose"
          ];
          default = "standard";
          description = "Audit logging verbosity";
        };
      };
    };

  # =============================================================================
  # META TYPE - Package metadata
  # =============================================================================
  metaType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        description = "Package description";
      };
      homepage = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Package homepage";
      };
      license = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Package license";
      };
      platforms = mkOption {
        type = types.listOf types.str;
        default = [ "x86_64-linux" ];
        description = "Supported platforms";
      };
    };
  };

  # =============================================================================
  # DESKTOP ENTRY TYPE - XDG desktop entry configuration
  # =============================================================================
  desktopEntryType =
    name:
    types.nullOr (
      types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "Application name shown in menu";
          };
          comment = mkOption {
            type = types.str;
            default = "";
            description = "Application description";
          };
          categories = mkOption {
            type = types.listOf types.str;
            default = [ "Utility" ];
            example = [
              "Development"
              "TerminalEmulator"
            ];
            description = "Desktop entry categories";
          };
          icon = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Icon name or path";
          };
        };
      }
    );

  # =============================================================================
  # INTEGRATION METHOD TYPE
  # =============================================================================
  methodType = types.enum [
    "fhs"
    "native"
    "auto"
  ];
}
