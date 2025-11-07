{ lib, ... }:

with lib;

let
  packageType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkEnableOption "Enable this js package";
      };
    }
  );
in
{
  options.kernelcore.packages.js = {
    enable = mkEnableOption "js package management" // {
      default = true;
    };

    packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Js packages to install and manage";
    };
  };
}
