{
  config,
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      antigravity = prev.stdenv.mkDerivation rec {
        pname = "antigravity";
        version = "1.13.3";

        src = prev.fetchurl {
          url = "https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_1.13.3-1766182170_amd64_365061c50063f9bd47a9ff88432261b8.deb";
          sha256 = "0jxxxa4srhd1bmwic3mppw2hd87fnh3scwqgmcfmn9480yg0z4nr";
        };

        nativeBuildInputs = [
          prev.dpkg
          prev.autoPatchelfHook
          prev.makeWrapper
          prev.wrapGAppsHook # Standard for GTK/Electron apps to find schemas/libs
        ];

        buildInputs = [
          prev.glibc
          prev.gcc-unwrapped.lib
          prev.zlib
          prev.xorg.libX11
          prev.xorg.libXcursor
          prev.xorg.libXrandr
          prev.xorg.libXi
          prev.libGL
          prev.glib
          prev.nss
          prev.nspr
          prev.dbus
          prev.atk
          prev.cups
          prev.cairo
          prev.gtk3
          prev.pango
          prev.xorg.libXcomposite
          prev.xorg.libXdamage
          prev.xorg.libXfixes
          prev.xorg.libxcb
          prev.mesa
          prev.expat
          prev.libxkbcommon
          prev.udev
          prev.alsa-lib
          prev.at-spi2-atk
          prev.at-spi2-core
          prev.xorg.libxkbfile
          prev.libdrm
          prev.libxshmfence
        ];

        runtimeDependencies = [
          prev.systemd # often needed for libudev
          prev.libudev0-shim
        ];

        unpackPhase = ''
          dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r usr/* $out/
          
          # Fix permissions
          chmod -R u+w $out
          
          runHook postInstall
        '';

        # Add libudev to rpath explicitly if needed
        postFixup = ''
          addAutoPatchelfSearchPath ${prev.libudev0-shim}/lib
          addAutoPatchelfSearchPath ${prev.systemd}/lib
        '';

        meta = with lib; {
          description = "Antigravity CLI Tool";
          homepage = "https://antigravity.dev";
          license = licenses.unfree;
          platforms = [ "x86_64-linux" ];
        };
      };
    })
  ];

  environment.systemPackages = [ pkgs.antigravity ];
}
