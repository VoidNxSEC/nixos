{
  pkgs,
  lib,
  packages,
  storageDir,
  cacheDir,
}:

with lib;

let
  # Fetch or use local tar.gz file
  fetchTarball =
    name: source:
    if source.path != null then
      source.path
    else if source.url != null then
      pkgs.fetchurl {
        url = source.url;
        sha256 = source.sha256;
        name = "${name}.tar.gz";
      }
    else
      throw "Package ${name}: Either 'path' or 'url' must be specified in source";

  # Extract tar.gz file
  extractTarball =
    name: tarFile:
    pkgs.runCommand "${name}-extracted"
      {
        buildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];
      }
      ''
        mkdir -p $out
        # Try without stripping first (for single-binary tarballs)
        tar -xzf ${tarFile} -C $out

        # If extraction created a single directory, move contents up
        if [ $(ls -A $out | wc -l) -eq 1 ] && [ -d $out/* ]; then
          mv $out/*/* $out/ 2>/dev/null || true
          rmdir $out/*/ 2>/dev/null || true
        fi
      '';

  # Detect binaries in extracted directory
  detectBinaries =
    extracted:
    let
      binaries =
        pkgs.runCommand "detect-bins"
          {
            buildInputs = [
              pkgs.findutils
              pkgs.file
            ];
          }
          ''
            find ${extracted} -type f -executable -exec file {} \; | grep -i elf | cut -d: -f1 > $out
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

      fhsEnv = pkgs.buildFHSEnv {
        name = "${name}-fhs";

        # Common FHS directories for binary compatibility
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
          export PATH="${extracted}/bin:${extracted}/usr/bin:${extracted}/usr/local/bin:$PATH"
          export LD_LIBRARY_PATH="${extracted}/lib:${extracted}/usr/lib:${extracted}/usr/local/lib:$LD_LIBRARY_PATH"
          ${concatStringsSep "\n" (
            mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
          )}
        '';

        # Run script - determines if sandboxed or direct execution
        runScript =
          if pkg.sandbox.enable then
            pkgs.writeShellScript "${name}-sandboxed" ''
              # Bubblewrap sandbox wrapper
              exec ${pkgs.bubblewrap}/bin/bwrap \
                --ro-bind /nix/store /nix/store \
                --dev /dev \
                --proc /proc \
                --tmpfs /tmp \
                --tmpfs /run \
                --bind "$HOME" "$HOME" \
                ${blockDevices} \
                ${allowedPathsArgs} \
                --unshare-all \
                --share-net \
                --die-with-parent \
                --setenv PATH "${extracted}/bin:${extracted}/usr/bin:/usr/bin:/bin" \
                --setenv LD_LIBRARY_PATH "${extracted}/lib:${extracted}/usr/lib" \
                ${pkg.wrapper.executable} "$@"
            ''
          else
            pkgs.writeShellScript "${name}-direct" ''
              export PATH="${extracted}/bin:${extracted}/usr/bin:$PATH"
              export LD_LIBRARY_PATH="${extracted}/lib:${extracted}/usr/lib:$LD_LIBRARY_PATH"
              ${concatStringsSep "\n" (
                mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
              )}
              exec ${pkg.wrapper.executable} "$@"
            '';
      };
    in
    fhsEnv;

  # Build using native Nix approach with patchelf
  buildNative =
    name: pkg: extracted:
    let
      # Patch ELF binaries for Nix store
      patchedBinaries =
        pkgs.runCommand "${name}-patched"
          {
            buildInputs = with pkgs; [
              patchelf
              autoPatchelfHook
              stdenv.cc.cc.lib
              zlib
              file
            ];
          }
          ''
            cp -r ${extracted} $out
            chmod -R +w $out

            # Find and patch all ELF binaries (skip statically linked ones)
            find $out -type f -executable | while read binary; do
              if file "$binary" | grep -q ELF; then
                # Check if statically linked
                if ldd "$binary" 2>&1 | grep -q "statically linked"; then
                  echo "Skipping static binary: $binary"
                  continue
                fi

                # Only patch dynamically linked binaries
                patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$binary" 2>/dev/null || true
                patchelf --set-rpath "${
                  lib.makeLibraryPath [
                    pkgs.stdenv.cc.cc.lib
                    pkgs.zlib
                  ]
                }" "$binary" 2>/dev/null || true
              fi
            done
          '';

      # Create wrapper script
      wrapperScript =
        if pkg.sandbox.enable then
          pkgs.writeShellScriptBin name ''
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --ro-bind /nix/store /nix/store \
              --dev /dev \
              --proc /proc \
              --tmpfs /tmp \
              --bind "$HOME" "$HOME" \
              ${
                concatStringsSep " " (map (hw: "--dev-bind-try /dev/null /dev/${hw}") pkg.sandbox.blockHardware)
              } \
              ${concatStringsSep " " (map (path: "--bind ${path} ${path}") pkg.sandbox.allowedPaths)} \
              --unshare-all \
              --share-net \
              --die-with-parent \
              ${patchedBinaries}/${pkg.wrapper.executable} "$@"
          ''
        else
          pkgs.writeShellScriptBin name ''
            # Set base directory for tools that need to find their files
            export PACKAGE_BASE_DIR="${patchedBinaries}"
            
            # Set tool-specific environment variables
            ${concatStringsSep "\n" (
              mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
            )}
            
            # For tools like lynis that need to find include directories
            cd "${patchedBinaries}"
            exec ${patchedBinaries}/${pkg.wrapper.executable} "$@"
          '';
    in
    wrapperScript;

  # Auto-detect best build method
  autoDetectMethod =
    name: extracted:
    let
      # Check for complex dependencies
      hasManyLibs = pkgs.runCommand "check-libs" { } ''
        count=$(find ${extracted} -name "*.so*" | wc -l)
        if [ $count -gt 5 ]; then
          echo "fhs" > $out
        else
          echo "native" > $out
        fi
      '';
    in
    builtins.readFile hasManyLibs;

  # Main builder function
  buildPackage =
    name: pkg:
    let
      tarFile = fetchTarball name pkg.source;
      extracted = extractTarball name tarFile;

      # Determine build method
      method =
        if pkg.method == "auto" then
          if pkg.sandbox.enable || (builtins.pathExists "${extracted}/lib") then "fhs" else "native"
        else
          pkg.method;

      # Build the package
      package = if method == "fhs" then buildFHS name pkg extracted else buildNative name pkg extracted;
    in
    package;

in
{
  # Export builder function
  inherit buildPackage;
}
