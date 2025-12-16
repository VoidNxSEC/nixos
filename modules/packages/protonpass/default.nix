# Proton Pass - Secure Password Manager
#
# Self-contained package - no external dependencies
# Uses FHS environment for Electron app
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.protonpass;

  # Source: Local .deb file (tracked by Git LFS)
  src = ./ProtonPass.deb;

  # Extract the .deb archive
  extracted =
    pkgs.runCommand "protonpass-extracted"
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
        # Remove setuid bit from chrome-sandbox
        find $out -name "chrome-sandbox" -exec chmod -s {} + 2>/dev/null || true
      '';

  # FHS environment for Electron app
  package = pkgs.buildFHSEnv {
    name = "proton-pass";

    targetPkgs =
      ps: with ps; [
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
        libGL
        udev
        libsecret
      ];

    runScript = "${extracted}/usr/bin/proton-pass";

    meta = {
      description = "Proton Pass - End-to-end encrypted password manager";
      homepage = "https://proton.me/pass";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

in
{
  options.kernelcore.packages.protonpass = {
    enable = lib.mkEnableOption "Proton Pass password manager";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
