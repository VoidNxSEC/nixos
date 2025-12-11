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
    pkgs.runCommand "${name}-extracted" {
      buildInputs = [ pkgs.binutils pkgs.gzip ]; # Add pkgs.binutils for 'ar' command
    } ''
      # Manually extract .deb file to avoid dpkg-deb permission issues with chrome-sandbox
      # .deb files are ar archives containing debian-binary, control.tar.gz, and data.tar.xz
      mkdir -p $out
      local tmp_dir=$(mktemp -d)
      cd "$tmp_dir"

      # Extract data.tar.xz
      ar x "${debFile}"
      tar --no-same-permissions --no-same-owner -xJf data.tar.xz -C "$out"

      # Remove setuid bit from chrome-sandbox if it exists
      # This is crucial for Electron apps like Proton Pass, whose internal sandbox might clash with Nix's
      find "$out" -type f -name "chrome-sandbox" -exec chmod -s {} + 2>/dev/null || true
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
        wrapper_raw = pkg.wrapper;
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
          let
            auditResult = import ./audit.nix {
              inherit
                pkgs
                lib
                name
                pkg
                package
                ;
            };
          in
          auditResult.auditWrapper
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
