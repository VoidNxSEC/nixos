# Declarative .deb Package Management Module
# Purpose: Install and manage .deb packages with sandboxing and audit support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.deb;
  sharedTypes = import ../lib/types.nix { inherit lib; };

  # Package type using shared definitions
  packageType = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "this .deb package" // {
          default = true;
        };
        method = mkOption {
          type = sharedTypes.methodType;
          default = "auto";
          description = "Integration method: fhs, native, or auto";
        };
        source = mkOption {
          type = sharedTypes.sourceType;
          description = "Source configuration for the .deb package";
        };
        sandbox = mkOption {
          type = sharedTypes.sandboxType;
          default = { };
          description = "Sandboxing and isolation configuration";
        };
        audit = mkOption {
          type = sharedTypes.auditType cfg.auditByDefault;
          default = { };
          description = "Audit and monitoring configuration";
        };
        wrapper = mkOption {
          type = sharedTypes.wrapperType name;
          default = { };
          description = "Wrapper configuration";
        };
        meta = mkOption {
          type = sharedTypes.metaType;
          default = { };
          description = "Package metadata";
        };
      };
    }
  );

in
{
  imports = [ ./packages/protonpass.nix ];

  options.kernelcore.packages.deb = {
    enable = mkEnableOption "Declarative .deb package management";
    packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
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
      builder = import ./builder.nix {
        inherit pkgs lib;
        inherit (cfg) packages storageDir cacheDir;
      };
      enabledPackages = filterAttrs (_: pkg: pkg.enable) cfg.packages;
      builtPackages = mapAttrs (name: pkg: builder.buildDebPackage name pkg) enabledPackages;
    in
    {
      systemd.tmpfiles.rules = [ "d ${cfg.cacheDir} 0755 root root -" ];
      environment.systemPackages = attrValues builtPackages;

      assertions =
        let
          packagesWithoutHash = filterAttrs (_: pkg: pkg.enable && pkg.source.sha256 == "") cfg.packages;
        in
        [
          {
            assertion = packagesWithoutHash == { };
            message = "All .deb packages MUST have SHA256 hash. Missing: ${concatStringsSep ", " (attrNames packagesWithoutHash)}";
          }
        ];
    }
  );
}
