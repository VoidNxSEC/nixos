# Hubstaff 1.7.8 - Time tracking client (binary repack)
#
# The upstream installer is a Makeself archive containing a MojoSetup
# installer with a ZIP payload. We extract the ZIP at a fixed offset,
# unpack it, and wire the ELF binaries with autoPatchelfHook.
#
# To upgrade:
# 1. Download new .sh installer from https://app.hubstaff.com/download/linux
# 2. Find ZIP offset:  python3 -c "d=open('file.sh','rb').read(); print(d.index(b'PK\x03\x04'))"
# 3. Update version, src hash, and zipOffset below
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.hubstaff;

  hubstaff = pkgs.stdenvNoCC.mkDerivation {
    pname = "hubstaff";
    version = "1.7.8";

    src = ./Hubstaff-1.7.8-c835b2c2.sh;

    # ZIP payload starts at byte 524926 inside the Makeself archive
    zipOffset = 524926;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.copyDesktopItems
      pkgs.autoPatchelfHook
      pkgs.unzip
    ];

    buildInputs = [
      # X11
      pkgs.libx11
      pkgs.libxext
      pkgs.libxinerama
      pkgs.libxrender
      pkgs.libxfixes
      pkgs.libxcursor
      pkgs.libxft
      pkgs.libxrandr
      pkgs.libxscrnsaver # libXss.so.1
      pkgs.libsm
      pkgs.libice # GTK3 + GLib (dlopen'd at runtime for tray icon / UI)
      pkgs.gtk3
      pkgs.glib
      # Wayland
      pkgs.wayland
      # Rendering / fonts
      pkgs.cairo
      pkgs.fontconfig
      pkgs.freetype
      pkgs.curl
      pkgs.libnotify
      pkgs.libappindicator-gtk3
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib
      # Screenshot tools for Wayland
      pkgs.grim
      pkgs.slurp
    ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      tail -c +$((zipOffset + 1)) "$src" > payload.zip
      unzip payload.zip
    '';

    installPhase = ''
      mkdir -p $out/{bin,opt/hubstaff,share}
      install -Dm755 data/x86_64/HubstaffClient.bin.x86_64 $out/opt/hubstaff/HubstaffClient
      install -Dm755 data/x86_64/HubstaffHelper.bin.x86_64  $out/opt/hubstaff/HubstaffHelper
      install -Dm755 data/x86_64/HubstaffCLI.bin.x86_64     $out/opt/hubstaff/HubstaffCLI
      mkdir -p $out/opt/hubstaff/lib64/private
      cp -r data/x86_64/lib64/private/* $out/opt/hubstaff/lib64/private/
      cp -r data/data/resources $out/opt/hubstaff/
      for size in 16 22 24 32 48 64 128 256 512; do
        install -Dm644 \
          "data/data/resources/hicolor/''${size}x''${size}/apps/hubstaff-color.png" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/hubstaff.png"
      done
      mkdir -p $out/share/gnome-shell/extensions
      cp -r data/data/gnome-shell-extension/app-es6@hubstaff.com $out/share/gnome-shell/extensions/
      cp -r data/data/LICENSES $out/opt/hubstaff/
    '';

    preFixup =
      let
        runtimeLibs = lib.makeLibraryPath [
          pkgs.gtk3
          pkgs.glib
          pkgs.gdk-pixbuf
          pkgs.pango
          pkgs.cairo
          pkgs.at-spi2-atk
          pkgs.at-spi2-core
          pkgs.wayland
          pkgs.curl
          pkgs.libnotify
          pkgs.libappindicator-gtk3
          pkgs.libxrandr
          pkgs.libxscrnsaver
        ];
      in
      ''
        makeWrapper $out/opt/hubstaff/HubstaffClient $out/bin/hubstaff \
          --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
          --prefix PATH : "${
            lib.makeBinPath [
              pkgs.xdg-utils
              pkgs.libnotify
              pkgs.grim
              pkgs.slurp
            ]
          }" \
          --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
          --chdir "$out/opt/hubstaff"

        makeWrapper $out/opt/hubstaff/HubstaffCLI $out/bin/hubstaff-cli \
          --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
          --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
          --chdir "$out/opt/hubstaff"

        makeWrapper $out/opt/hubstaff/HubstaffHelper $out/bin/hubstaff-helper \
          --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
          --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
          --chdir "$out/opt/hubstaff"
      '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "hubstaff";
        desktopName = "Hubstaff";
        exec = "hubstaff %u";
        icon = "hubstaff";
        categories = [ "Utility" ];
        mimeTypes = [ "x-scheme-handler/hubstaff" ];
      })
    ];

    meta = with lib; {
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "hubstaff";
    };
  };

in
{
  options.kernelcore.packages.hubstaff.enable = lib.mkEnableOption "Hubstaff client";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ hubstaff ];
  };
}
