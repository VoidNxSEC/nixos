{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.js;

  # Package type definition
  packageType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkEnableOption "Enable this js package";

        version = mkOption {
          type = types.str;
          description = "Package version";
        };

        source = mkOption {
          type = types.submodule {
            options = {
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "URL to download package tarball";
              };

              path = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Local path to package tarball";
              };

              sha256 = mkOption {
                type = types.str;
                default = "";
                description = "SHA256 hash of the tarball";
              };
            };
          };
          description = "Source configuration";
        };

        lockfile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to custom package-lock.json (overrides source lockfile)";
        };

        npmDepsHash = mkOption {
          type = types.str;
          description = "Hash of npm dependencies (run 'prefetch-npm-deps package-lock.json')";
        };

        npmFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra flags for npm install";
        };

        makeCacheWritable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to make the npm cache writable (fixes some ENOTCACHED errors)";
        };

        nativeBuildInputs = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Native build inputs (pkgs used at build time)";
        };

        buildInputs = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Build inputs (pkgs used at runtime/link time)";
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
                description = "Hardware devices to block access to";
              };
            };
          };
          default = { };
          description = "Sandboxing configuration";
        };

        wrapper = mkOption {
          type = types.submodule {
            options = {
              name = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Name of the wrapper executable (defaults to package name)";
              };

              executable = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Path to executable inside the package (e.g. bin/cli)";
              };

              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra arguments to pass to the binary";
              };

              environmentVariables = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Environment variables for the binary";
              };
            };
          };
          default = { };
          description = "Wrapper configuration";
        };
      };
    }
  );
in
{
  options.kernelcore.packages.js = {
    enable = mkEnableOption "Declarative JS package management";

    packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Js packages to install and manage";
    };
  };

  config = mkIf cfg.enable (
    let
      # Import builder
      builder = import ./builder.nix { inherit pkgs lib; };

      # Build enabled packages
      enabledPackages = filterAttrs (_: pkg: pkg.enable) cfg.packages;
      builtPackages = mapAttrs (name: pkg: builder.buildNpm name pkg) enabledPackages;
    in
    {
      environment.systemPackages = attrValues builtPackages;
    }
  );
}
