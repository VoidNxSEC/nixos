{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.deb;

  # Package type definition
  packageType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable this .deb package";
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
                description = "URL to download .deb file";
              };

              path = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Local path to .deb file (for Git LFS storage)";
              };

              sha256 = mkOption {
                type = types.str;
                description = "SHA256 hash of the .deb file (REQUIRED for security)";
              };
            };
          };
          description = "Source configuration for the .deb package";
        };

        sandbox = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable sandboxing with bubblewrap";
              };

              allowedPaths = mkOption {
                type = types.listOf types.str;
                default = [ ];
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
                  "audio"
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
                default = cfg.auditByDefault;
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

        wrapper = mkOption {
          type = types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = "Name of the wrapper executable";
              };

              executable = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Path to the executable within the extracted package (e.g. 'usr/bin/myapp')";
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
          default = { };
          description = "Wrapper configuration";
        };

        meta = mkOption {
          type = types.submodule {
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
            };
          };
          default = { };
          description = "Package metadata";
        };
      };
    }
  );

in
{
  imports = [
    ./packages/protonpass.nix
  ];

  options.kernelcore.packages.deb = {
    enable = mkEnableOption "Declarative .deb package management";

    packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      example = literalExpression ''
        {
          my-tool = {
            method = "fhs";
            source = {
              url = "https://example.com/my-tool.deb";
              sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };
            sandbox = {
              enable = true;
              blockHardware = [ "gpu" ];
              resourceLimits.memory = "2G";
            };
          };
        }
      '';
      description = "Attribute set of .deb packages to manage";
    };

    auditByDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Enable audit logging by default for all packages";
    };

    storageDir = mkOption {
      type = types.path;
      default = /etc/nixos/modules/packages/deb-packages/storage;
      description = "Directory for storing .deb files (with Git LFS)";
    };

    cacheDir = mkOption {
      type = types.path;
      default = "/var/cache/deb-packages";
      description = "Runtime cache directory for extracted packages";
    };
  };

  config = mkIf cfg.enable (
    let
      # Import builder functions
      builder = import ./builder.nix {
        inherit pkgs lib;
        inherit (cfg) packages storageDir cacheDir;
      };

      # Build enabled packages
      enabledPackages = filterAttrs (_: pkg: pkg.enable) cfg.packages;
      builtPackages = mapAttrs (name: pkg: builder.buildDebPackage name pkg) enabledPackages;
    in
    {
      # Create cache directory
      systemd.tmpfiles.rules = [
        "d ${cfg.cacheDir} 0755 root root -"
      ];

      # Export packages to system environment
      environment.systemPackages = attrValues builtPackages;

      # Security assertion: SHA256 must be provided
      assertions =
        let
          packagesWithoutHash = filterAttrs (_: pkg: pkg.enable && pkg.source.sha256 == "") cfg.packages;
        in
        [
          {
            assertion = packagesWithoutHash == { };
            message = ''
              All .deb packages MUST have SHA256 hash specified for security.
              Packages missing hash: ${concatStringsSep ", " (attrNames packagesWithoutHash)}
            '';
          }
        ];
    }
  );
}
