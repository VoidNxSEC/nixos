{
  pkgs,
  lib,
  packages,
  storageDir,
  cacheDir,
}:

with lib;

let
  # Import shared builders
  builders = import ../lib/builders.nix { inherit pkgs lib; };

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

  # Detect if a binary is dynamically linked
  detectDynamicLinking =
    binary:
    pkgs.runCommand "check-dynamic"
      {
        buildInputs = [
          pkgs.file
          pkgs.glibc.bin
        ];
      }
      ''
        if [ ! -f "${binary}" ]; then
          echo "unknown" > $out
          exit 0
        fi

        # Check if file is ELF and dynamically linked
        if file "${binary}" | grep -q "dynamically linked"; then
          echo "dynamic" > $out
        elif file "${binary}" | grep -q "statically linked"; then
          echo "static" > $out
        else
          echo "unknown" > $out
        fi
      '';

  # Detect target triple from executable name
  detectTargetTriple =
    execName:
    if lib.hasSuffix "-musl" execName then
      "musl"
    else if lib.hasSuffix "-gnu" execName then
      "gnu"
    else if lib.hasInfix "musl" execName then
      "musl"
    else if lib.hasInfix "gnu" execName then
      "gnu"
    else
      "unknown";

  # Auto-detect best build method based on binary characteristics
  autoDetectMethod =
    name: pkg: extracted:
    let
      executable = "${extracted}/${pkg.wrapper.executable}";
      targetTriple = detectTargetTriple pkg.wrapper.executable;
      hasDynamicLibs = builtins.pathExists "${extracted}/lib";

      # Detect linkage type if executable exists
      linkType =
        if builtins.pathExists executable then
          lib.removeSuffix "\n" (builtins.readFile (detectDynamicLinking executable))
        else
          "unknown";

      # Decision logic with explanations
      decision =
        if targetTriple == "musl" then
          {
            method = "native";
            reason = "MUSL binaries are statically linked and work with native patching";
          }
        else if targetTriple == "gnu" && linkType == "dynamic" then
          {
            method = "fhs";
            reason = "GNU dynamically linked binaries require FHS environment";
          }
        else if hasDynamicLibs then
          {
            method = "fhs";
            reason = "Package includes dynamic libraries, needs FHS environment";
          }
        else if linkType == "static" then
          {
            method = "native";
            reason = "Statically linked binary works with native patching";
          }
        else
          {
            method = "native";
            reason = "Default fallback for unknown binary type";
          };

      # Log decision for debugging
      _ = builtins.trace "Package ${name}: Auto-detected method='${decision.method}' (target=${targetTriple}, linkType=${linkType}, reason: ${decision.reason})" null;
    in
    decision.method;

  # Main builder function
  buildPackage =
    name: pkg:
    let
      tarFile = fetchTarball name pkg.source;
      extracted = extractTarball name tarFile;

      # Determine build method with improved auto-detection
      method = if pkg.method == "auto" then autoDetectMethod name pkg extracted else pkg.method;

      # Log final method selection
      _ = builtins.trace "Package ${name}: Using build method '${method}'" null;
      
      # Prepare arguments for shared builders
      commonArgs = {
        inherit name extracted;
        sandbox = pkg.sandbox;
        wrapper_raw = pkg.wrapper; # Now includes executable
        meta = pkg.meta or {};
      };

      # Build the package
      package = if method == "fhs" then 
          builders.buildFHS commonArgs 
        else 
          builders.buildNative commonArgs;
    in
    package;

in
{
  # Export builder function
  inherit buildPackage;
}
