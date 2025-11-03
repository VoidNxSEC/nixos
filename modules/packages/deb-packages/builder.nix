{
  pkgs,
  lib,
  packages,
  storageDir,
  cacheDir,
}:

with lib;

let
  # Fetch or use local .deb file
  fetchDeb =
    name: source:
    if source.path != null then
      source.path
    else if source.url != null then
      pkgs.fetchurl {
        url = source.url;
        sha256 = source.sha256;
        name = "${name}.deb";
      }
    else
      throw "Package ${name}: Either 'path' or 'url' must be specified in source";

  # Extract .deb file
  extractDeb =
    name: debFile:
    pkgs.runCommand "${name}-extracted" { buildInputs = [ pkgs.dpkg ]; } ''
      mkdir -p $out
      dpkg-deb -x ${debFile} $out
    '';

  # Detect binary dependencies
  detectDependencies =
    extracted:
    let
      binaries = pkgs.runCommand "detect-deps" { buildInputs = [ pkgs.findutils ]; } ''
        find ${extracted} -type f -executable > $out
      '';
    in
    binaries;

  # Build using FHS User Environment (for complex binaries)
  buildFHS =
    name: pkg: extracted:
    let
      # Determine blocked devices for bubblewrap
      blockDevices = concatStringsSep " " (
        map (hw: "--dev-bind-try /dev/null /dev/${hw}") pkg.sandbox.blockHardware
      );

      # Build allowed paths arguments
      allowedPathsArgs = concatStringsSep " " (
        map (path: "--bind ${path} ${path}") pkg.sandbox.allowedPaths
      );

      fhsEnv = pkgs.buildFHSUserEnv {
        name = "${name}-fhs";

        # Common FHS directories for .deb compatibility
        targetPkgs =
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
          ];

        # Environment for the FHS environment
        profile = ''
          export PATH="${extracted}/usr/bin:${extracted}/usr/local/bin:$PATH"
          export LD_LIBRARY_PATH="${extracted}/usr/lib:${extracted}/usr/local/lib:$LD_LIBRARY_PATH"
          ${concatStringsSep "\n" (
            mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
          )}
        '';

        # Run command - wrap with sandbox if enabled
        runScript =
          if pkg.sandbox.enable then
            pkgs.writeScript "${name}-sandboxed" ''
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
                ${extracted}/usr/bin/${name} "$@"
            ''
          else
            "${extracted}/usr/bin/${name}";

        meta = pkg.meta // {
          platforms = [ "x86_64-linux" ];
        };
      };

    in
    fhsEnv;

  # Build using native Nix integration (patch binaries)
  buildNative =
    name: pkg: extracted:
    let
      patchedBinaries = pkgs.runCommand "${name}-patched" { buildInputs = [ pkgs.patchelf ]; } ''
        mkdir -p $out/bin
        mkdir -p $out/lib

        # Copy binaries
        if [ -d ${extracted}/usr/bin ]; then
          cp -r ${extracted}/usr/bin/* $out/bin/ || true
        fi

        # Copy libraries
        if [ -d ${extracted}/usr/lib ]; then
          cp -r ${extracted}/usr/lib/* $out/lib/ || true
        fi

        # Patch binaries
        for bin in $out/bin/*; do
          if [ -f "$bin" ] && [ -x "$bin" ]; then
            echo "Patching $bin..."
            patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 "$bin" 2>/dev/null || true
            patchelf --set-rpath "$out/lib:${
              lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]
            }" "$bin" 2>/dev/null || true
          fi
        done
      '';

      # Create wrapper with sandbox if enabled
      wrapper = pkgs.writeShellScriptBin pkg.wrapper.name (
        if pkg.sandbox.enable then
          ''
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --ro-bind /nix /nix \
              --ro-bind ${patchedBinaries} ${patchedBinaries} \
              --tmpfs /tmp \
              --proc /proc \
              --dev /dev \
              ${
                concatStringsSep " " (map (hw: "--dev-bind-try /dev/null /dev/${hw}") pkg.sandbox.blockHardware)
              } \
              ${concatStringsSep " " (map (path: "--bind ${path} ${path}") pkg.sandbox.allowedPaths)} \
              --unshare-all \
              --share-net \
              --die-with-parent \
              ${
                concatStringsSep "\n" (
                  mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
                )
              } \
              ${patchedBinaries}/bin/${name} ${concatStringsSep " " pkg.wrapper.extraArgs} "$@"
          ''
        else
          ''
            ${concatStringsSep "\n" (
              mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
            )}
            exec ${patchedBinaries}/bin/${name} ${concatStringsSep " " pkg.wrapper.extraArgs} "$@"
          ''
      );

    in
    wrapper;

  # Auto-detect best method
  autoDetectMethod =
    name: pkg: extracted:
    let
      # Simple heuristic: if package has many libraries or complex dependencies, use FHS
      hasComplexDeps = pkgs.runCommand "check-deps" { } ''
        lib_count=$(find ${extracted}/usr/lib -type f 2>/dev/null | wc -l || echo 0)
        if [ "$lib_count" -gt 10 ]; then
          echo "fhs" > $out
        else
          echo "native" > $out
        fi
      '';
      detectedMethod = readFile hasComplexDeps;
    in
    if detectedMethod == "fhs" then buildFHS name pkg extracted else buildNative name pkg extracted;

  # Main build function
  buildDebPackage =
    name: pkg:
    let
      debFile = fetchDeb name pkg.source;
      extracted = extractDeb name debFile;

      package =
        if pkg.method == "fhs" then
          buildFHS name pkg extracted
        else if pkg.method == "native" then
          buildNative name pkg extracted
        else
          autoDetectMethod name pkg extracted;

      # Wrap with audit/monitoring if enabled
      finalPackage =
        if pkg.audit.enable then
          import ./audit.nix {
            inherit
              pkgs
              lib
              name
              pkg
              package
              ;
          }
        else
          package;

    in
    finalPackage;

in
{
  inherit
    buildDebPackage
    fetchDeb
    extractDeb
    buildFHS
    buildNative
    autoDetectMethod
    ;
}
