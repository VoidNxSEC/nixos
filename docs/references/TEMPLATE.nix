# MOVE: Scaffold
# ============================================================
# Module Name/Title
# ============================================================
# Description: [Brief description of what this module does]
# Maintainer: [Your Name/Role]
# Dependencies: [List key dependencies if any]
# ============================================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Define the configuration namespace
  cfg = config.category.module-name;
in
{
  # ============================================================
  # OPTIONS
  # ============================================================
  options.category.module-name = {
    enable = mkEnableOption "Enable [Module Name]";

    # Boolean option example
    enableFeature = mkOption {
      type = types.bool;
      default = true;
      description = "Enable specific feature X";
    };

    # String option example
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration lines to append";
    };

    # Package option example (allow overriding the package)
    package = mkOption {
      type = types.package;
      default = pkgs.hello;
      description = "Package to use for this module";
    };

    # Submodule example (for nested configuration)
    # settings = mkOption {
    #   type = types.submodule {
    #     options = {
    #       port = mkOption {
    #         type = types.port;
    #         default = 8080;
    #         description = "Port number";
    #       };
    #     };
    #   };
    #   default = {};
    #   description = "Nested settings";
    # };
  };

  # ============================================================
  # CONFIGURATION
  # ============================================================
  config = mkIf cfg.enable {
    # 1. System Packages
    environment.systemPackages = [
      cfg.package
    ];

    # 2. Environment Variables
    environment.sessionVariables = {
      # EXAMPLE_VAR = "value";
    };

    # 3. Service Definition (if applicable)
    # systemd.services.myservice = {
    #   description = "My Service";
    #   after = [ "network.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     ExecStart = "${cfg.package}/bin/myservice";
    #     Restart = "on-failure";
    #   };
    # };

    # 4. Configuration Files
    # environment.etc."myservice/config.conf".text = ''
    #   enable_feature=${toString cfg.enableFeature}
    #   ${cfg.extraConfig}
    # '';

    # 5. Assertions (Validation)
    assertions = [
      {
        assertion = cfg.enableFeature -> (cfg.package != null);
        message = "Package must be defined if feature is enabled";
      }
    ];
  };
}
