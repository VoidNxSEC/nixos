# Lynis - Security Auditing Tool
# Version: 3.1.6
# Purpose: Custom management outside nixpkgs for more control
{ pkgs, ... }:
let
  inherit (pkgs) lib;
in
{
  lynis = {
    enable = true;

    # Build method - native works for shell scripts
    method = "native";

    # Source configuration
    source = {
      # Download from: https://github.com/CISOfy/lynis/releases
      path = ../storage/lynis-3.1.6.tar.gz;
      sha256 = "0513f62ba5ab615c4333827b804237d58cf7bd623d09e1b4918d3fc85f08fc70";
    };

    # Wrapper configuration
    wrapper = {
      executable = "lynis/lynis";
      environmentVariables = {
        # Inject standard tools into PATH so lynis doesn't fail with busybox or missing bins
        PATH = lib.makeBinPath [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.gawk
          pkgs.findutils
          pkgs.procps
          pkgs.nettools
          pkgs.git
          pkgs.systemd
          pkgs.kmod
          pkgs.which
          pkgs.gzip
          pkgs.curl
          pkgs.hostname
          pkgs.iproute2
        ];
        # LYNIS_HOME will be set by builder to point to extracted directory
      };
    };

    # Sandbox - disabled for system auditing tool
    sandbox = {
      enable = false;
      # Lynis needs full system access for auditing
    };

    # Audit - enable for security tool itself
    audit = {
      enable = true;
      logLevel = "verbose";
    };

    # No desktop entry for CLI tool (null is default)
  };
}
