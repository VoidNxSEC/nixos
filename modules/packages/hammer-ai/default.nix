# HammerAI - local roleplay chat client (Electron/Chromium app)
#
# Source: vendor-distributed .deb, no stable download URL was found, so the
# archive is vendored in this directory. To update: replace the .deb file
# with the new version and bump `version` below.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.hammer-ai;

  version = "1.0.50";

  hammer-ai = pkgs.stdenv.mkDerivation {
    pname = "hammer-ai";
    inherit version;

    src = ./hammerai_1.0.50_amd64.deb;

    nativeBuildInputs = [
      pkgs.binutils # ar, to split the .deb into control/data members
      pkgs.zstd
      pkgs.libwebp # dwebp - the bundled "hammerai.png" is actually WebP data
      pkgs.imagemagick # generate hicolor icon sizes from the decoded artwork
      pkgs.makeWrapper
      pkgs.autoPatchelfHook
      pkgs.copyDesktopItems
    ];

    buildInputs = [
      pkgs.alsa-lib
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
      pkgs.cairo
      pkgs.cups
      pkgs.dbus
      pkgs.expat
      pkgs.gdk-pixbuf
      pkgs.glib
      pkgs.gtk3
      pkgs.libdrm
      pkgs.libnotify
      pkgs.libxkbcommon
      pkgs.mesa
      pkgs.nspr
      pkgs.nss
      pkgs.pango
      pkgs.systemd
      pkgs.vulkan-loader
      pkgs.libx11
      pkgs.libxcb
      pkgs.libxcomposite
      pkgs.libxdamage
      pkgs.libxext
      pkgs.libxfixes
      pkgs.libxshmfence
      pkgs.libxrandr
    ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack

      # dpkg-deb -x would try to restore chrome-sandbox's setuid bit, which
      # the build sandbox refuses ("Operation not permitted"). Extract the
      # data member directly and drop ownership/permission restoration.
      ar x $src
      tar --no-same-permissions --no-same-owner --zstd -xf data.tar.zst

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/hammer-ai $out/bin
      cp -r usr/lib/hammerai/* $out/opt/hammer-ai/

      # usr/share/pixmaps/hammerai.png ships as WebP data despite the .png
      # name; gdk-pixbuf has no WebP loader by default so it renders blank.
      # Decode it to a real PNG and populate the hicolor theme at every size.
      dwebp usr/share/pixmaps/hammerai.png -o hammerai-icon.png
      for size in 16 24 32 48 64 128 256 512 1024; do
        dir=$out/share/icons/hicolor/''${size}x''${size}/apps
        mkdir -p "$dir"
        magick hammerai-icon.png -resize ''${size}x''${size} "$dir/hammerai.png"
      done

      # Setuid sandbox helper is useless from the nix store (can't be root-owned
      # setuid here); Chromium falls back fine when launched with --no-sandbox.
      rm -f $out/opt/hammer-ai/chrome-sandbox

      makeWrapper $out/opt/hammer-ai/HammerAI $out/bin/hammerai \
        --add-flags "--no-sandbox" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.xdg-utils ]}

      runHook postInstall
    '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "hammerai";
        desktopName = "HammerAI";
        comment = "Chat with role-playing AI characters that run locally on your computer";
        exec = "hammerai %U";
        icon = "hammerai";
        startupNotify = true;
        categories = [
          "Network"
          "Game"
        ];
      })
    ];

    meta = {
      description = "Chat with role-playing AI characters that run locally on your computer";
      homepage = "https://www.hammerai.com";
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "hammerai";
    };
  };
in
{
  options.kernelcore.packages.hammer-ai = {
    enable = lib.mkEnableOption "HammerAI local roleplay chat client";

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Locally packaged HammerAI derivation.";
    };
  };

  config = lib.mkMerge [
    {
      kernelcore.packages.hammer-ai.package = hammer-ai;
    }

    (lib.mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];
    })
  ];
}
