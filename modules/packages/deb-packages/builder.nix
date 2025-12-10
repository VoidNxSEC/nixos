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

  # Main build function
  buildDebPackage =
    name: pkg:
    let
      debFile = fetchDeb name pkg.source;
      extracted = extractDeb name debFile;
      
      # Prepare arguments for shared builders
      commonArgs = {
        inherit name extracted;
        sandbox = pkg.sandbox;
        wrapper = pkg.wrapper;
        meta = pkg.meta;
      };

      # Detect method if auto
      method = if pkg.method == "auto" then
        readFile (builders.autoDetectMethod { inherit extracted; })
      else
        pkg.method;

      package =
        if method == "fhs" then
          builders.buildFHS commonArgs
        else
          builders.buildNative commonArgs;

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
    ;
}
