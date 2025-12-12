# Shared Builder Functions for Package Modules
# Purpose: FHS and Native build strategies for binary packages
{ pkgs, lib }:

with lib;

rec {
  # =============================================================================
  # COMMON FHS PACKAGES
  # =============================================================================
  commonFhsPkgs =
    ps: with ps; [
      bash
      coreutils
      gnugrep
      gnused
      gawk
      findutils
      which
      stdenv.cc.cc.lib
      zlib
      glib
      gtk3
      cairo
      pango
      atk
      gdk-pixbuf
      libGL
      libglvnd
      dbus
      glibc
      bubblewrap
      openssl
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      xorg.libXfixes
    ];

  # =============================================================================
  # BUILD FHS - FHS User Environment for complex binaries
  # =============================================================================
  buildFHS =
    {
      name,
      extracted,
      sandbox ? {
        enable = false;
        blockHardware = [ ];
        allowedPaths = [ ];
      },
      wrapper_raw ? { },
      targetPkgs ? commonFhsPkgs,
      runScript ? null,
      meta ? { },
    }:
    let
      sandboxLib = import ./sandbox.nix { inherit lib; };

      wrapper = {
        name = name;
        environmentVariables = { };
        extraArgs = [ ];
        executable = null;
      }
      // wrapper_raw;

      blockDevices = sandboxLib.mkHardwareBlockArgs sandbox.blockHardware;
      allowedPathsArgs = sandboxLib.mkPathAllowArgs sandbox.allowedPaths;
      binPath = if wrapper.executable != null then wrapper.executable else "bin/${name}";
      relBinPath = removePrefix "/" binPath;

      finalMeta = meta // {
        platforms = meta.platforms or [ "x86_64-linux" ];
        license =
          if (meta.license or null) == "Proprietary" || (meta.license or null) == null then
            lib.licenses.unfree
          else
            meta.license;
      };

      fhsEnv = pkgs.buildFHSEnv {
        name = "${name}-fhs";
        targetPkgs = targetPkgs;

        profile = ''
          export PATH="${extracted}/bin:${extracted}/usr/bin:${extracted}/usr/local/bin:$PATH"
          export LD_LIBRARY_PATH="${extracted}/lib:${extracted}/usr/lib:${extracted}/usr/local/lib:$LD_LIBRARY_PATH"
          ${concatStringsSep "\n" (mapAttrsToList (n: v: "export ${n}='${v}'") wrapper.environmentVariables)}
        '';

        runScript =
          if runScript != null then
            runScript
          else if sandbox.enable then
            pkgs.writeScript wrapper.name ''
              #!/bin/bash
              exec ${pkgs.bubblewrap}/bin/bwrap \
                --ro-bind /nix /nix \
                --ro-bind ${extracted} ${extracted} \
                --tmpfs /tmp --tmpfs /run --proc /proc --dev /dev \
                ${blockDevices} ${allowedPathsArgs} \
                --unshare-all --share-net --die-with-parent \
                ${extracted}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"
            ''
          else if wrapper.extraArgs != [ ] then
            pkgs.writeScript wrapper.name ''
              #!/bin/bash
              exec ${extracted}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"
            ''
          else
            "${extracted}/${relBinPath}";

        meta = finalMeta;
      };
    in
    fhsEnv;

  # =============================================================================
  # BUILD NATIVE - Patch binaries for direct Nix integration
  # =============================================================================
  buildNative =
    {
      name,
      extracted,
      sandbox ? {
        enable = false;
        blockHardware = [ ];
        allowedPaths = [ ];
      },
      wrapper_raw ? { },
      libPath ? [ ],
      meta ? { },
    }:
    let
      sandboxLib = import ./sandbox.nix { inherit lib; };

      wrapper = {
        name = name;
        environmentVariables = { };
        extraArgs = [ ];
        executable = null;
      }
      // wrapper_raw;

      patchedBinaries =
        pkgs.runCommand "${name}-patched"
          {
            buildInputs = [
              pkgs.patchelf
              pkgs.autoPatchelfHook
              pkgs.file
            ];
          }
          ''
            mkdir -p $out
            cp -r ${extracted}/* $out/
            chmod -R +w $out

            find $out -type f -executable | while read binary; do
              if file "$binary" | grep -q ELF; then
                if ldd "$binary" 2>&1 | grep -q "statically linked"; then
                  echo "Skipping static binary: $binary"
                  continue
                fi
                echo "Patching $binary..."
                patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 "$binary" 2>/dev/null || true
                patchelf --set-rpath "$out/lib:${
                  lib.makeLibraryPath ([ pkgs.stdenv.cc.cc.lib ] ++ libPath)
                }" "$binary" 2>/dev/null || true
              fi
            done
          '';

      binPath = if wrapper.executable != null then wrapper.executable else "bin/${name}";
      relBinPath = removePrefix "/" binPath;

      wrapperScript =
        (pkgs.writeShellScriptBin wrapper.name (
          if sandbox.enable then
            let
              blockArgs = sandboxLib.mkHardwareBlockArgs sandbox.blockHardware;
              allowArgs = sandboxLib.mkPathAllowArgs sandbox.allowedPaths;
            in
            ''
              exec ${pkgs.bubblewrap}/bin/bwrap \
                --ro-bind /nix /nix \
                --ro-bind ${patchedBinaries} ${patchedBinaries} \
                --tmpfs /tmp --proc /proc --dev /dev \
                ${blockArgs} ${allowArgs} \
                --unshare-all --share-net --die-with-parent \
                ${
                  concatStringsSep "\n" (mapAttrsToList (n: v: "export ${n}='${v}'") wrapper.environmentVariables)
                } \
                ${patchedBinaries}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"
            ''
          else
            ''
              ${concatStringsSep "\n" (mapAttrsToList (n: v: "export ${n}='${v}'") wrapper.environmentVariables)}
              exec ${patchedBinaries}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"
            ''
        ))
        // {
          inherit meta;
        };
    in
    wrapperScript;

  # =============================================================================
  # AUTO-DETECT METHOD
  # =============================================================================
  autoDetectMethod =
    {
      extracted,
      threshold ? 10,
    }:
    pkgs.runCommand "check-method" { } ''
      lib_count=$(find ${extracted}/usr/lib -type f 2>/dev/null | wc -l || echo 0)
      if [ "$lib_count" -gt ${toString threshold} ]; then
        echo "fhs" > $out
      else
        echo "native" > $out
      fi
    '';
}
