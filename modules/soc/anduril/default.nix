{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc.anduril;

  # Python environment for the auditor
  pythonEnv = pkgs.python313.withPackages (
    ps: with ps; [
      # Core dependencies (minimal)
    ]
  );

  # Package the auditor script
  andurilAudit = pkgs.writeScriptBin "anduril-audit" ''
    #!${pkgs.bash}/bin/bash
    exec ${pythonEnv}/bin/python3 ${./auditor.py} "$@"
  '';

  # Copy STIG database to a known location
  stigDatabase = pkgs.runCommand "anduril-stig-db" { } ''
    mkdir -p $out/share/anduril
    cp ${./stig-database.json} $out/share/anduril/stig-database.json
  '';

in
{
  options.kernelcore.soc.anduril = {
    enable = mkEnableOption "Anduril STIG Auditor for NixOS hardening compliance";

    autoAudit = mkOption {
      type = types.bool;
      default = false;
      description = "Run audit automatically during system activation (not recommended for MVP)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      andurilAudit
      stigDatabase
    ];

    # Create symlink to STIG database in a predictable location
    environment.etc."anduril/stig-database.json".source =
      "${stigDatabase}/share/anduril/stig-database.json";
  };
}
