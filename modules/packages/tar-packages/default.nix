{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.tar;
  zellij = import ./packages/zellij.nix { inherit pkgs; };

  # Package type definition
  packageType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable this tar.gz package";
        };

        method = mkOption {
          type = types.enum [
            "fhs"
            "native"
            "auto"
          ];
          default = "auto";
          description = ''
            Integration method:
            - fhs: Use buildFHSUserEnv for complex binaries
            - native: Extract and patch for direct Nix integration
            - auto: Automatically detect best method
          '';
        };

        source = mkOption {
          type = types.submodule {
            options = {
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "URL to download tar.gz file";
              };

              path = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Local path to tar.gz file (for Git LFS storage)";
              };

              sha256 = mkOption {
                type = types.str;
                description = "SHA256 hash of the tar.gz file (REQUIRED for security)";
              };
            };
          };
          description = "Source configuration for the tar.gz package";
        };

        wrapper = mkOption {
          type = types.submodule {
            options = {
              executable = mkOption {
                type = types.str;
                default = name;
                example = "bin/myapp";
                description = "Path to executable within extracted tarball (relative to extracted root)";
              };

              environmentVariables = mkOption {
                type = types.attrsOf types.str;
                default = { };
                example = {
                  "ZELLIJ_CONFIG_DIR" = "$HOME/.config/zellij";
                };
                description = "Environment variables to set for the application";
              };
            };
          };
          default = { };
          description = "Wrapper script configuration";
        };

        sandbox = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Enable sandboxing with bubblewrap";
              };

              allowedPaths = mkOption {
                type = types.listOf types.str;
                default = [
                  "/tmp"
                  "$HOME"
                ];
                example = [
                  "/tmp"
                  "/home/user/data"
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
          default = { };
          description = "Sandboxing and isolation configuration";
        };

        audit = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
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
          default = { };
          description = "Audit and monitoring configuration";
        };

        desktopEntry = mkOption {
          type = types.nullOr (
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
          default = null;
          description = "Desktop entry configuration (null = no desktop entry)";
        };

        meta = mkOption {
          type = types.attrs;
          default = { };
          description = "Package metadata";
        };
      };
    }
  );

  # Storage directories
  storageDir = ./storage;
  cacheDir = "/var/cache/tar-packages";

  # Import builder
  builder = import ./builder.nix {
    inherit
      pkgs
      lib
      storageDir
      cacheDir
      ;
    packages = cfg.packages;
  };

  # Build enabled packages
  enabledPackages = filterAttrs (_: pkg: pkg.enable) cfg.packages;

  builtPackages = mapAttrs (name: pkg: builder.buildPackage name pkg) enabledPackages;

in
{
  imports = [
    ./packages/zellij.nix
    ./packages/lynis.nix
  ];

  # ============================================================
  # MODULE OPTIONS
  # ============================================================
  options.kernelcore.packages.tar = {
    enable = mkEnableOption "tar.gz package management" // {
      default = true;
    };

    packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Tar.gz packages to install and manage";
      example = literalExpression ''
        {
          zellij = {
            enable = true;
            source = {
              path = ./tar-packages/storage/zellij-v0.43.1.tar.gz;
              sha256 = "sha256-...";
            };
            wrapper.executable = "zellij";
            sandbox.enable = false;
          };
        }
      '';
    };

    globalSandbox = mkOption {
      type = types.bool;
      default = false;
      description = "Enable sandboxing for all packages by default";
    };

    auditByDefault = mkOption {
      type = types.bool;
      default = false;
      description = "Enable audit logging for all packages by default";
    };

    resolvedPackages = mkOption {
      type = types.attrsOf types.package;
      # Expose the computed packages without letting other modules override them
      default = builtPackages;
      readOnly = true;
      description = "Internal attrset with the built package derivations for reuse in other modules.";
    };
  };

  # ============================================================
  # MODULE CONFIGURATION
  # ============================================================
  config = mkIf cfg.enable {
    # Install all built packages
    environment.systemPackages = attrValues builtPackages;

    # Create cache directory
    systemd.tmpfiles.rules = [
      "d ${cacheDir} 0755 root root -"
      "d /var/log/tar-packages 0755 root root -"
    ];

    # Security requirements
    security.wrappers = mkIf (any (pkg: pkg.sandbox.enable) (attrValues cfg.packages)) {
      bubblewrap = {
        source = "${pkgs.bubblewrap}/bin/bwrap";
        capabilities = "cap_sys_admin,cap_net_admin=ep";
        owner = "root";
        group = "root";
        permissions = "u+rx,g+rx,o+rx";
      };
    };

    # Audit configuration (if any package has audit enabled)
    security.auditd.enable = mkIf (any (pkg: pkg.audit.enable) (attrValues cfg.packages)) true;

    # Add desktop entries for packages that request them
    environment.etc = mkMerge (
      mapAttrsToList (
        name: pkg:
        mkIf (pkg.desktopEntry != null) {
          "xdg/applications/${name}.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=${pkg.desktopEntry.name}
            Comment=${pkg.desktopEntry.comment}
            Exec=${name}
            Terminal=${
              if (pkg.desktopEntry.categories or [ ]) == [ "TerminalEmulator" ] then "true" else "false"
            }
            Categories=${concatStringsSep ";" pkg.desktopEntry.categories};
            ${optionalString (pkg.desktopEntry.icon != null) "Icon=${pkg.desktopEntry.icon}"}
          '';
        }
      ) enabledPackages
    );
  };
}
