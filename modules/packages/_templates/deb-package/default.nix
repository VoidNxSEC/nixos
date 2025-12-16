# DEB Package Template
#
# Copy this folder and customize for your package.
# This template is 100% self-contained - no external dependencies.
#
# Usage:
#   cp -r _templates/deb-package my-new-package
#   Edit default.nix with your package details
#   Place package.deb in the folder (or use URL)
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.PACKAGE_NAME;

  # ============================================================
  # SOURCE - Choose ONE: local file or URL
  # ============================================================
  src = ./package.deb; # Local file (tracked by Git LFS)
  # OR:
  # src = pkgs.fetchurl {
  #   url = "https://example.com/package.deb";
  #   sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  # };

  # ============================================================
  # EXTRACTION - Unpack the .deb archive
  # ============================================================
  extracted =
    pkgs.runCommand "PACKAGE_NAME-extracted"
      {
        buildInputs = [
          pkgs.binutils
          pkgs.gnutar
          pkgs.xz
        ];
      }
      ''
        mkdir -p $out
        cd $out
        ar x ${src}
        tar -xf data.tar.* --strip-components=0
        rm -f control.tar.* data.tar.* debian-binary
      '';

  # ============================================================
  # PACKAGE - FHS environment for complex binaries (Electron, etc)
  # ============================================================
  package = pkgs.buildFHSEnv {
    name = "PACKAGE_NAME";

    targetPkgs =
      ps: with ps; [
        # Common dependencies - adjust as needed
        stdenv.cc.cc.lib
        glib
        gtk3
        nss
        nspr
        atk
        cups
        dbus
        expat
        libdrm
        libxkbcommon
        pango
        cairo
        mesa
        alsa-lib
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libxcb
      ];

    runScript = "${extracted}/usr/bin/EXECUTABLE_NAME";

    meta = {
      description = "PACKAGE_NAME description";
      homepage = "https://example.com";
      license = lib.licenses.unfree; # Most .deb are proprietary
      platforms = [ "x86_64-linux" ];
    };
  };

in
{
  options.kernelcore.packages.PACKAGE_NAME = {
    enable = lib.mkEnableOption "PACKAGE_NAME";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
