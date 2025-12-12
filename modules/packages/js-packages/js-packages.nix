# Declarative JS/NPM Package Management Module
# Purpose: Install and manage npm packages with sandboxing support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.js;
  sharedTypes = import ../lib/types.nix { inherit lib; };

  # Package type using shared definitions
  packageType = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "this js package";
        version = mkOption {
          type = types.str;
          description = "Package version";
        };
        source = mkOption {
          type = sharedTypes.sourceType;
          description = "Source configuration";
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
          type = sharedTypes.sandboxType;
          default = {
            enable = true;
          };
          description = "Sandboxing configuration";
        };
        wrapper = mkOption {
          type = sharedTypes.wrapperType name;
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
      builder = import ./builder.nix { inherit pkgs lib; };
      enabledPackages = filterAttrs (_: pkg: pkg.enable) cfg.packages;
      builtPackages = mapAttrs (name: pkg: builder.buildNpm name pkg) enabledPackages;
    in
    {
      environment.systemPackages = attrValues builtPackages;
    }
  );
}
