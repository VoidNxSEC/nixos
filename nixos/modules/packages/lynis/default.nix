# Lynis Security Auditing Tool
#
# Self-contained package - no external dependencies
# Version auto-updated via nvfetcher in ../../_sources/
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.lynis;

  package = pkgs.stdenv.mkDerivation {
    pname = "lynis";
    version = "3.1.6";

    src = pkgs.fetchurl {
      url = "https://github.com/CISOfy/lynis/archive/3.1.6.tar.gz";
      sha256 = "sha256-KjHj4CjWufDo9QJAKtZ1KwafkIKJNRTIwCOWL1eGs7Y=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin $out/share/lynis
      cp -r * $out/share/lynis/

      makeWrapper $out/share/lynis/lynis $out/bin/lynis \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.gawk
            pkgs.gnugrep
            pkgs.gnused
          ]
        }
    '';

    meta = {
      description = "Security auditing tool for Linux, macOS, and UNIX-based systems";
      homepage = "https://cisofy.com/lynis/";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.unix;
    };
  };

in
{
  options.kernelcore.packages.lynis = {
    enable = lib.mkEnableOption "Lynis security auditing tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
