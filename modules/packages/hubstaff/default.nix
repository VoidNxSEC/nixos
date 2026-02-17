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
      pkgs.xorg.libX11
      pkgs.xorg.libXext
      pkgs.xorg.libXinerama
      pkgs.xorg.libXrender
      pkgs.xorg.libXfixes
      pkgs.xorg.libXcursor
      pkgs.xorg.libXft
      pkgs.xorg.libXrandr
      pkgs.xorg.libXScrnSaver # libXss.so.1
      pkgs.xorg.libSM
      pkgs.xorg.libICE
      # GTK3 + GLib (dlopen'd at runtime for tray icon / UI)
      pkgs.gtk3
      pkgs.glib
      # Wayland
      pkgs.wayland
      # Rendering / fonts
      pkgs.cairo
      pkgs.fontconfig
      pkgs.freetype
      # Network (curl with OpenSSL — binary probes multiple sonames)
      pkgs.curl
      # Notifications / tray
      pkgs.libnotify
      pkgs.libappindicator-gtk3
      # Core
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib # libstdc++, libgcc_s
    ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack

      # Extract ZIP payload from Makeself archive
      tail -c +$((zipOffset + 1)) "$src" > payload.zip
      unzip payload.zip

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,opt/hubstaff,share}

      # Install binaries
      install -Dm755 data/x86_64/HubstaffClient.bin.x86_64 $out/opt/hubstaff/HubstaffClient
      install -Dm755 data/x86_64/HubstaffHelper.bin.x86_64  $out/opt/hubstaff/HubstaffHelper
      install -Dm755 data/x86_64/HubstaffCLI.bin.x86_64     $out/opt/hubstaff/HubstaffCLI

      # Install bundled private libs (libXss fallback)
      mkdir -p $out/opt/hubstaff/lib64/private
      cp -r data/x86_64/lib64/private/* $out/opt/hubstaff/lib64/private/

      # Install resources
      cp -r data/data/resources $out/opt/hubstaff/

      # Install icons into hicolor
      for size in 16 22 24 32 48 64 128 256 512; do
        install -Dm644 \
          "data/data/resources/hicolor/''${size}x''${size}/apps/hubstaff-color.png" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/hubstaff.png"
      done

      # Install GNOME Shell extension
      mkdir -p $out/share/gnome-shell/extensions
      cp -r data/data/gnome-shell-extension/app-es6@hubstaff.com \
        $out/share/gnome-shell/extensions/

      # Install licenses
      cp -r data/data/LICENSES $out/opt/hubstaff/

      runHook postInstall
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
          pkgs.xorg.libXrandr
          pkgs.xorg.libXScrnSaver
        ];
      in
      ''
        # Wrapper for the main client
        makeWrapper $out/opt/hubstaff/HubstaffClient $out/bin/hubstaff \
          --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
          --prefix PATH : "${
            lib.makeBinPath [
              pkgs.xdg-utils
              pkgs.libnotify
            ]
          }" \
          --chdir "$out/opt/hubstaff"

        # Wrapper for CLI
        makeWrapper $out/opt/hubstaff/HubstaffCLI $out/bin/hubstaff-cli \
          --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
          --chdir "$out/opt/hubstaff"

        # Wrapper for Helper (used internally by client)
        makeWrapper $out/opt/hubstaff/HubstaffHelper $out/bin/hubstaff-helper \
          --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
          --chdir "$out/opt/hubstaff"
      '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "hubstaff";
        desktopName = "Hubstaff";
        comment = "Time tracking and productivity monitoring";
        exec = "hubstaff %u";
        icon = "hubstaff";
        categories = [ "Utility" ];
        mimeTypes = [ "x-scheme-handler/hubstaff" ];
        startupNotify = true;
      })
    ];

    meta = with lib; {
      description = "Hubstaff time tracking client";
      homepage = "https://hubstaff.com";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "hubstaff";
    };
  };

in
{
  options.kernelcore.packages.hubstaff = {
    enable = lib.mkEnableOption "Hubstaff time tracking client";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ hubstaff ];
  };
}
