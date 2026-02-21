# Hubstaff 1.7.8 - Time tracking client with maximum isolation
#
# Architecture:
#   kernelcore runs "hubstaff" (launcher script)
#     └─ xhost +SI:localuser:hubstaff
#     └─ sudo -u hubstaff → hubstaff-run  (autoPatchelf'd binary)
#
#   hubstaff (system user, home /var/lib/hubstaff)
#     └─ cannot read /home/kernelcore (mode 700, different UID)
#     └─ has access to /var/lib/hubstaff/Downloads (bind mount)
#     └─ network restricted by nftables to DNS + HTTP/HTTPS only
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.hubstaff;

  # ── Shared runtime library path ────────────────────────────────────────────
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

  # ── Main package (autoPatchelf — same approach as last working commit) ──────
  #
  # Binary is exposed as "hubstaff-run" to avoid clashing with the launcher
  # wrapper (which is the user-facing "hubstaff" command).
  hubstaff-pkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "hubstaff";
    version = "1.7.8";

    src = ./Hubstaff-1.7.8-c835b2c2.sh;

    zipOffset = 524926;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.copyDesktopItems
      pkgs.autoPatchelfHook
      pkgs.unzip
    ];

    buildInputs = [
      pkgs.libx11
      pkgs.libxext
      pkgs.libxinerama
      pkgs.libxrender
      pkgs.libxfixes
      pkgs.libxcursor
      pkgs.libxft
      pkgs.libxrandr
      pkgs.libxscrnsaver
      pkgs.libsm
      pkgs.libice
      pkgs.gtk3
      pkgs.glib
      pkgs.wayland
      pkgs.cairo
      pkgs.fontconfig
      pkgs.freetype
      pkgs.curl
      pkgs.libnotify
      pkgs.libappindicator-gtk3
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib
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
      install -Dm755 data/x86_64/HubstaffClient.bin.x86_64  $out/opt/hubstaff/HubstaffClient
      install -Dm755 data/x86_64/HubstaffHelper.bin.x86_64  $out/opt/hubstaff/HubstaffHelper
      install -Dm755 data/x86_64/HubstaffCLI.bin.x86_64     $out/opt/hubstaff/HubstaffCLI
      mkdir -p $out/opt/hubstaff/lib64/private
      cp -r data/x86_64/lib64/private/* $out/opt/hubstaff/lib64/private/
      cp -r data/data/resources $out/opt/hubstaff/

      for size in 16 22 24 32 48 64 128 256 512; do
        if [ -f "data/data/resources/hicolor/''${size}x''${size}/apps/hubstaff-color.png" ]; then
          install -Dm644 \
            "data/data/resources/hicolor/''${size}x''${size}/apps/hubstaff-color.png" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/hubstaff.png"
        fi
        if [ -f "data/data/resources/hicolor/''${size}x''${size}/apps/hubstaff-white.png" ]; then
          install -Dm644 \
            "data/data/resources/hicolor/''${size}x''${size}/apps/hubstaff-white.png" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/hubstaff-white.png"
        fi
      done

      mkdir -p $out/share/gnome-shell/extensions
      cp -r data/data/gnome-shell-extension/app-es6@hubstaff.com $out/share/gnome-shell/extensions/
      cp -r data/data/LICENSES $out/opt/hubstaff/
    '';

    preFixup = ''
      # "hubstaff-run" is the inner binary invoked via sudo as the hubstaff user.
      # The user-facing "hubstaff" command is the launcher script below.
      makeWrapper $out/opt/hubstaff/HubstaffClient $out/bin/hubstaff-run \
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
        --set QT_QPA_PLATFORM xcb \
        --chdir "$out/opt/hubstaff"

      makeWrapper $out/opt/hubstaff/HubstaffCLI $out/bin/hubstaff-cli-run \
        --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
        --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
        --chdir "$out/opt/hubstaff"

      makeWrapper $out/opt/hubstaff/HubstaffHelper $out/bin/hubstaff-helper \
        --prefix LD_LIBRARY_PATH : "$out/opt/hubstaff/lib64/private:${runtimeLibs}" \
        --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
        --chdir "$out/opt/hubstaff"
    '';

    meta = with lib; {
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

  # ── Session wrapper (runs *as* hubstaff via sudo) ──────────────────────────
  #
  # Sets up a private D-Bus session bus and XDG_RUNTIME_DIR before exec'ing
  # the actual binary. This gives Hubstaff its own bus so AppIndicator (tray
  # icon) and libdbusmenu work correctly without access to kernelcore's bus.
  hubstaff-session = pkgs.writeShellScriptBin "hubstaff-session" ''
    export XDG_RUNTIME_DIR=/var/lib/hubstaff/.runtime
    exec ${pkgs.dbus}/bin/dbus-run-session -- \
      /run/current-system/sw/bin/hubstaff-run
  '';

  # ── Launcher (runs as kernelcore, delegates to isolated hubstaff user) ──────
  hubstaff-launcher = pkgs.writeShellScriptBin "hubstaff" ''
    set -euo pipefail

    # Grant the hubstaff user X11 display access; revoked on exit.
    ${pkgs.xhost}/bin/xhost +SI:localuser:hubstaff

    cleanup() {
      ${pkgs.xhost}/bin/xhost -SI:localuser:hubstaff 2>/dev/null || true
    }
    trap cleanup EXIT

    exec sudo -u hubstaff \
      HOME=/var/lib/hubstaff \
      DISPLAY="$DISPLAY" \
      /run/current-system/sw/bin/hubstaff-session
  '';

  # ── nftables isolation scripts ──────────────────────────────────────────────
  #
  # Restricts outbound traffic from the hubstaff UID to DNS + HTTP/HTTPS.
  # Priority filter+1 runs after the main firewall chains but can still
  # issue terminating drop verdicts (nftables evaluates all base chains
  # regardless of accept verdicts in earlier chains).
  hubstaff-nft-start = pkgs.writeShellScript "hubstaff-nft-start" ''
    NFT="${pkgs.nftables}/bin/nft"

    $NFT add table inet hubstaff_isolation
    $NFT add chain inet hubstaff_isolation output \
      '{ type filter hook output priority filter + 1; policy accept; }'

    # Loopback always permitted (dbus sockets, IPC)
    $NFT add rule inet hubstaff_isolation output oifname lo accept

    # Don't break connections that were already established before these rules loaded
    $NFT add rule inet hubstaff_isolation output \
      meta skuid hubstaff ct state '{' established,related '}' accept

    # DNS (hostname resolution)
    $NFT add rule inet hubstaff_isolation output meta skuid hubstaff udp dport 53 accept
    $NFT add rule inet hubstaff_isolation output meta skuid hubstaff tcp dport 53 accept

    # HTTPS (Hubstaff APIs + S3 screenshot upload)
    $NFT add rule inet hubstaff_isolation output meta skuid hubstaff tcp dport 443 accept

    # HTTP (redirects)
    $NFT add rule inet hubstaff_isolation output meta skuid hubstaff tcp dport 80 accept

    # Drop everything else from the hubstaff UID
    $NFT add rule inet hubstaff_isolation output meta skuid hubstaff drop

    echo "hubstaff nftables isolation: rules applied"
  '';

  hubstaff-nft-stop = pkgs.writeShellScript "hubstaff-nft-stop" ''
    ${pkgs.nftables}/bin/nft delete table inet hubstaff_isolation 2>/dev/null || true
    echo "hubstaff nftables isolation: rules removed"
  '';

in
{
  options.kernelcore.packages.hubstaff.enable =
    lib.mkEnableOption "Hubstaff time tracker (runs as isolated system user)";

  config = lib.mkIf cfg.enable {

    # ── Dedicated system user ─────────────────────────────────────────────────
    #
    # File-system isolation is implicit: /home/kernelcore has mode 700 and
    # belongs to kernelcore, so the hubstaff process simply cannot read it.
    users.users.hubstaff = {
      isSystemUser = true;
      group = "hubstaff";
      home = "/var/lib/hubstaff";
      createHome = false; # managed by systemd-tmpfiles below
      description = "Hubstaff isolation user (no interactive login)";
      extraGroups = [
        "video"
        "render"
        "audio"
      ]; # screenshots + audio detection
    };
    users.groups.hubstaff = { };

    # ── Directory structure ───────────────────────────────────────────────────
    systemd.tmpfiles.rules = [
      "d /var/lib/hubstaff           0750 hubstaff hubstaff -"
      "d /var/lib/hubstaff/.config   0750 hubstaff hubstaff -"
      "d /var/lib/hubstaff/Downloads 0750 hubstaff hubstaff -"
      "d /var/lib/hubstaff/.runtime  0700 hubstaff hubstaff -"
    ];

    # ── Bind mount ~/Downloads into hubstaff's home ───────────────────────────
    systemd.mounts = [
      {
        what = "/home/kernelcore/Downloads";
        where = "/var/lib/hubstaff/Downloads";
        type = "none";
        options = "bind";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-tmpfiles-setup.service" ];
      }
    ];

    # ── sudo: kernelcore → hubstaff (no password, env passthrough) ───────────
    security.sudo.extraRules = [
      {
        users = [ "kernelcore" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/hubstaff-session";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
          {
            command = "/run/current-system/sw/bin/hubstaff-cli-run";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];

    # ── nftables network isolation ────────────────────────────────────────────
    #
    # PartOf= causes re-application whenever firewall.service restarts
    # (e.g. after nixos-rebuild switch reloads the firewall ruleset).
    # Note: NixOS names the service "firewall.service", not "nftables.service".
    systemd.services.hubstaff-nftables = {
      description = "Hubstaff nftables network isolation (UID-based port whitelist)";
      after = [ "firewall.service" ];
      partOf = [ "firewall.service" ];
      wantedBy = [ "firewall.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = hubstaff-nft-start;
        ExecStop = hubstaff-nft-stop;
      };
    };

    # ── Packages ──────────────────────────────────────────────────────────────
    environment.systemPackages = [
      hubstaff-pkg # provides hubstaff-run, hubstaff-cli-run, hubstaff-helper
      hubstaff-session # provides hubstaff-session (inner, called via sudo)
      hubstaff-launcher # provides user-facing "hubstaff" command

      (pkgs.makeDesktopItem {
        name = "hubstaff";
        desktopName = "Hubstaff";
        genericName = "Time Tracker";
        comment = "Time tracking for remote teams";
        exec = "hubstaff %u";
        icon = "hubstaff";
        startupWMClass = "HubstaffClient";
        categories = [
          "Utility"
          "Office"
        ];
        mimeTypes = [ "x-scheme-handler/hubstaff" ];
      })
    ];
  };
}
