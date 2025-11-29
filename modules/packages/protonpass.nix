{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.protonpass;

  protonpass = pkgs.stdenv.mkDerivation rec {
    pname = "proton-pass";
    version = "37.9.0";

    # Use extracted files from storage (relative path)
    src = ./deb-packages/storage/ProtonPass;

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      wrapGAppsHook3
      makeWrapper
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      glib
      gtk3
      cairo
      pango
      atk
      gdk-pixbuf
      libGL
      libglvnd
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      xorg.libXfixes
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXScrnSaver
      xorg.libxkbfile
      xorg.libxshmfence
      dbus
      cups
      expat
      nspr
      nss
      alsa-lib
      at-spi2-atk
      at-spi2-core
      libdrm
      libxkbcommon
      mesa
      wayland
    ];

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      # Create output directories
      mkdir -p $out/bin
      mkdir -p $out/lib/proton-pass
      mkdir -p $out/share/applications
      mkdir -p $out/share/pixmaps

      # Copy application files
      cp -r usr/lib/proton-pass/* $out/lib/proton-pass/

      # Copy desktop entry and icon
      cp usr/share/applications/proton-pass.desktop $out/share/applications/
      cp usr/share/pixmaps/proton-pass.png $out/share/pixmaps/

      # Create wrapper script
      makeWrapper "$out/lib/proton-pass/Proton Pass" $out/bin/proton-pass \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils ]}" \
        --set PROTON_PASS_CONFIG_DIR "\$HOME/.config/proton-pass" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

      # Fix desktop entry
      substituteInPlace $out/share/applications/proton-pass.desktop \
        --replace "Exec=proton-pass" "Exec=$out/bin/proton-pass"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Proton Pass - End-to-end encrypted password manager";
      homepage = "https://proton.me/pass";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };

in
{
  options.programs.protonpass = {
    enable = mkEnableOption "Proton Pass password manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ protonpass ];

    # Add desktop integration
    services.dbus.packages = [ protonpass ];
  };
}
