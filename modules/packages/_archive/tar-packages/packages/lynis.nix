# Lynis - Security Auditing Tool
# Version: Auto-updated via nvfetcher
# Purpose: Custom management outside nixpkgs for more control
{ pkgs, ... }:
let
  inherit (pkgs) lib;
  sources = pkgs.callPackage ../../_sources/generated.nix { };
in
{
  kernelcore.packages.tar.packages.lynis = {
    enable = true;

    # Build method - native works for shell scripts
    method = "native";

    # Source configuration
    source = {
      path = sources.lynis.src;
      sha256 = ""; # Managed by sources.lynis.src
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
