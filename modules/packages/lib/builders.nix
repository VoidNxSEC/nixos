{ pkgs, lib }:

with lib;

rec {

  # Common libraries often needed by closed-source binaries
  commonFhsPkgs = ps: with ps; [
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
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXfixes
    dbus
    glibc
    # Add bubblewrap for sandboxing
    bubblewrap
    openssl
  ];

    # Build using FHS User Environment (generic)

    buildFHS =

      {

        name,

        extracted, # Path to extracted content

        sandbox ? { enable = false; blockHardware = []; allowedPaths = []; },

        wrapper_raw ? {}, # Raw wrapper config

        targetPkgs ? commonFhsPkgs,

        runScript ? null, # Optional override

        meta ? {},

      }:

      let

        sandboxLib = import ./sandbox.nix { inherit lib; };

        

        # Merge default wrapper options with user-provided ones

        wrapper = {

          name = name; # Default to package name

          environmentVariables = {};

          extraArgs = [];

          executable = null;

        } // wrapper_raw;

  

        # Determine blocked devices for bubblewrap

        blockDevices = sandboxLib.mkHardwareBlockArgs sandbox.blockHardware;

  

        # Build allowed paths arguments

        allowedPathsArgs = sandboxLib.mkPathAllowArgs sandbox.allowedPaths;

  

        # Determine executable path

        binPath = if wrapper.executable != null then wrapper.executable else "bin/${name}";

        # Ensure it doesn't start with /

        relBinPath = removePrefix "/" binPath;

  

        fhsEnv = pkgs.buildFHSEnv {

          name = "${name}-fhs";

  

          targetPkgs = targetPkgs;

  

          # Environment for the FHS environment

          profile = ''

            export PATH="${extracted}/bin:${extracted}/usr/bin:${extracted}/usr/local/bin:$PATH"

            export LD_LIBRARY_PATH="${extracted}/lib:${extracted}/usr/lib:${extracted}/usr/local/lib:$LD_LIBRARY_PATH"

            ${concatStringsSep "\n" (

              mapAttrsToList (name: value: "export ${name}='${value}'") wrapper.environmentVariables

            )}

          '';

  

          # Run command - wrap with sandbox if enabled

          runScript = if runScript != null then runScript else

            if sandbox.enable then

              pkgs.writeScript wrapper.name ''

                #!/bin/bash

                exec ${pkgs.bubblewrap}/bin/bwrap \

                  --ro-bind /nix /nix \

                  --ro-bind ${extracted} ${extracted} \

                  --tmpfs /tmp \

                  --tmpfs /run \

                  --proc /proc \

                  --dev /dev \

                  ${blockDevices} \

                  ${allowedPathsArgs} \

                  --unshare-all \

                  --share-net \

                  --die-with-parent \

                  ${extracted}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"

              ''

            else

               # For non-sandboxed, we might need a small wrapper to pass args if they exist

               if wrapper.extraArgs != [] then

                  pkgs.writeScript wrapper.name ''

                    #!/bin/bash

                    exec ${extracted}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"

                  ''

               else

                  "${extracted}/${relBinPath}";

  

          meta = meta // {

            platforms = [ "x86_64-linux" ];

          };

        };

  

      in

      fhsEnv;

  

    # Build using native Nix integration (patch binaries)

    buildNative =

      {

        name,

        extracted,

        sandbox ? { enable = false; blockHardware = []; allowedPaths = []; },

        wrapper_raw ? {}, # Raw wrapper config

        libPath ? [],

        meta ? {},

      }:

      let

        sandboxLib = import ./sandbox.nix { inherit lib; };

        

        # Merge default wrapper options with user-provided ones

        wrapper = {

          name = name; # Default to package name

          environmentVariables = {};

          extraArgs = [];

          executable = null;

        } // wrapper_raw;

        

        patchedBinaries = pkgs.runCommand "${name}-patched" { 

          buildInputs = [ pkgs.patchelf pkgs.autoPatchelfHook pkgs.file ]; 

        } ''

          mkdir -p $out

          cp -r ${extracted}/* $out/

          chmod -R +w $out

  

          # Find and patch all ELF binaries (skip statically linked ones)

          find $out -type f -executable | while read binary; do

            if file "$binary" | grep -q ELF; then

              # Check if statically linked

              if ldd "$binary" 2>&1 | grep -q "statically linked"; then

                echo "Skipping static binary: $binary"

                continue

              fi

  

              echo "Patching $binary..."

              # Only patch dynamically linked binaries

              patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 "$binary" 2>/dev/null || true

              patchelf --set-rpath "$out/lib:${

                lib.makeLibraryPath ([ pkgs.stdenv.cc.cc.lib ] ++ libPath)

              }" "$binary" 2>/dev/null || true

            fi

          done

        '';

  

        # Determine executable path

        binPath = if wrapper.executable != null then wrapper.executable else "bin/${name}";

        # Ensure it doesn't start with /

        relBinPath = removePrefix "/" binPath;

  

        # Create wrapper with sandbox if enabled

        wrapperScript = (pkgs.writeShellScriptBin wrapper.name (

          if sandbox.enable then

            let 

               blockArgs = sandboxLib.mkHardwareBlockArgs sandbox.blockHardware;

               allowArgs = sandboxLib.mkPathAllowArgs sandbox.allowedPaths;

            in

            ''

              exec ${pkgs.bubblewrap}/bin/bwrap \

                --ro-bind /nix /nix \

                --ro-bind ${patchedBinaries} ${patchedBinaries} \

                --tmpfs /tmp \

                --proc /proc \

                --dev /dev \

                ${blockArgs} \

                ${allowArgs} \

                --unshare-all \

                --share-net \

                --die-with-parent \

                ${

                  concatStringsSep "\n" (

                    mapAttrsToList (name: value: "export ${name}='${value}'") wrapper.environmentVariables

                  )

                } \

                ${patchedBinaries}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"

            ''

          else

            ''

              ${concatStringsSep "\n" (

                mapAttrsToList (name: value: "export ${name}='${value}'") wrapper.environmentVariables

              )}

              exec ${patchedBinaries}/${relBinPath} ${concatStringsSep " " wrapper.extraArgs} "$@"

            ''

        )) // { inherit meta; };

  

      in

      wrapperScript;
    
  # Simple heuristic auto-detection
  autoDetectMethod =
    {
       extracted,
       threshold ? 10
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
