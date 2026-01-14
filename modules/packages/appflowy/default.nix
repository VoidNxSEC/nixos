# AppFlowy - derivation based on nixpkgs official
# Updated for version 0.10.8
{
  pkgs,
  lib,
  ...
}:

let
  appflowy = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "appflowy";
    version = "0.10.8";

    src = pkgs.fetchzip {
      url = "https://github.com/AppFlowy-IO/appflowy/releases/download/${finalAttrs.version}/AppFlowy-${finalAttrs.version}-linux-x86_64.tar.gz";
      hash = "sha256-87mauW50ccOaPyK04O4I7+0bsvxVrdFxhi/Muc53wDY=";
      stripRoot = false;
    };

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.copyDesktopItems
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.gtk3
      pkgs.gsettings-desktop-schemas
      pkgs.keybinder3
      pkgs.libnotify
      # File picker support (Flutter file_picker package requires zenity)
      pkgs.zenity
      pkgs.xdg-utils
      pkgs.dbus
      # GStreamer for media support
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
    ];

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      cd AppFlowy/

      mkdir -p $out/{bin,opt}

      # Copy archive contents to the output directory
      cp -r ./* $out/opt/

      # Copy icon
      install -Dm444 data/flutter_assets/assets/images/flowy_logo.svg $out/share/icons/hicolor/scalable/apps/appflowy.svg

      runHook postInstall
    '';

    postInstall = ''
            # Fix version.json mismatch (upstream bug: release 0.10.8 still reports 0.10.6)
            cat > $out/opt/data/flutter_assets/version.json << EOF
      {"app_name":"appflowy","version":"${finalAttrs.version}","package_name":"appflowy"}
      EOF
    '';

    preFixup = ''
      # Add missing libraries to appflowy using the ones it comes with
      makeWrapper $out/opt/AppFlowy $out/bin/appflowy \
        --set LD_LIBRARY_PATH "$out/opt/lib/" \
        --prefix PATH : "${
          lib.makeBinPath [
            pkgs.xdg-user-dirs
            pkgs.xdg-utils
            pkgs.zenity
          ]
        }" \
        --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
        --set-default XDG_RUNTIME_DIR "/run/user/$UID" \
        --unset DBUS_SESSION_BUS_ADDRESS
    '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "appflowy";
        desktopName = "AppFlowy";
        comment = finalAttrs.meta.description;
        exec = "appflowy %U";
        icon = "appflowy";
        categories = [ "Office" ];
        mimeTypes = [ "x-scheme-handler/appflowy-flutter" ];
      })
    ];

    meta = with lib; {
      description = "Open-source alternative to Notion";
      homepage = "https://www.appflowy.io/";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.agpl3Only;
      platforms = [ "x86_64-linux" ];
      mainProgram = "appflowy";
    };
  });
in
{
  # Add to system packages
  environment.systemPackages = [ appflowy ];
}
