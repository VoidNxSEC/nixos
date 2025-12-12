# Declarative tar.gz Package Management Module
# Purpose: Install and manage tar.gz packages with sandboxing and audit support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.tar;
  sharedTypes = import ../lib/types.nix { inherit lib; };

  # Package type using shared definitions
  packageType = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "this tar.gz package" // {
          default = true;
        };
        method = mkOption {
          type = sharedTypes.methodType;
          default = "auto";
          description = "Integration method: fhs, native, or auto";
        };
        source = mkOption {
          type = sharedTypes.sourceType;
          description = "Source configuration for the tar.gz package";
        };
        wrapper = mkOption {
          type = sharedTypes.wrapperType name;
          default = { };
          description = "Wrapper script configuration";
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
        desktopEntry = mkOption {
          type = sharedTypes.desktopEntryType name;
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

  storageDir = ./storage;
  cacheDir = "/var/cache/tar-packages";

  builder = import ./builder.nix {
    inherit
      pkgs
      lib
      storageDir
      cacheDir
      ;
    packages = cfg.packages;
  };

  enabledPackages = filterAttrs (_: pkg: pkg.enable) cfg.packages;
  builtPackages = mapAttrs (name: pkg: builder.buildPackage name pkg) enabledPackages;

in
{
  imports = [
    ./packages/zellij.nix
    ./packages/lynis.nix
  ];

  options.kernelcore.packages.tar = {
    enable = mkEnableOption "tar.gz package management" // {
      default = true;
    };
    packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Tar.gz packages to install and manage";
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
      default = builtPackages;
      readOnly = true;
      description = "Internal attrset with the built package derivations";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = attrValues builtPackages;
    systemd.tmpfiles.rules = [
      "d ${cacheDir} 0755 root root -"
      "d /var/log/tar-packages 0755 root root -"
    ];

    security.wrappers = mkIf (any (pkg: pkg.sandbox.enable) (attrValues cfg.packages)) {
      bubblewrap = {
        source = "${pkgs.bubblewrap}/bin/bwrap";
        capabilities = "cap_sys_admin,cap_net_admin=ep";
        owner = "root";
        group = "root";
        permissions = "u+rx,g+rx,o+rx";
      };
    };

    security.auditd.enable = mkIf (any (pkg: pkg.audit.enable) (attrValues cfg.packages)) true;

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
