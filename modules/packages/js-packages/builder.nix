{
  pkgs,
  lib,
}:

with lib;

let
  sandboxLib = import ../lib/sandbox.nix { inherit lib; };

  buildNpm =
    name: pkg:
    let
      # Define source
      src =
        if pkg.source.path != null then
          pkg.source.path
        else if pkg.source.url != null then
          pkgs.fetchurl {
            url = pkg.source.url;
            sha256 = pkg.source.sha256;
          }
        else
          throw "Package ${name}: Source must be provided (url or path)";

      # Build the package using buildNpmPackage
      npmPackage = pkgs.buildNpmPackage {
        pname = name;
        version = pkg.version;
        src = src;
        npmDepsHash = pkg.npmDepsHash;

        # Pass through other common buildNpmPackage options if needed
        # We can expose them in the module options if necessary
        npmFlags = pkg.npmFlags;

        dontCheckNoBrokenSymlinks = true; # Common fix for some packages

        # Native dependencies if specified
        nativeBuildInputs =
          with pkgs;
          pkg.nativeBuildInputs
          ++ [
            python3
            pkg-config
          ];
        buildInputs = with pkgs; pkg.buildInputs;
      };

      # Determine executable name (default to package name)
      executable = if pkg.wrapper.executable != null then pkg.wrapper.executable else "bin/${name}";
      # Ensure relative path
      relExecutable = removePrefix "/" executable;

      # Create the final package with wrapper
      finalPackage =
        if pkg.sandbox.enable then
          let
            blockArgs = sandboxLib.mkHardwareBlockArgs pkg.sandbox.blockHardware;
            allowArgs = sandboxLib.mkPathAllowArgs pkg.sandbox.allowedPaths;

            # Env vars
            envVars = concatStringsSep "\n" (
              mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
            );
          in
          pkgs.writeShellScriptBin (pkg.wrapper.name or name) ''
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --ro-bind /nix /nix \
              --ro-bind ${npmPackage} ${npmPackage} \
              --tmpfs /tmp \
              --proc /proc \
              --dev /dev \
              ${blockArgs} \
              ${allowArgs} \
              --unshare-all \
              --share-net \
              --die-with-parent \
              ${envVars} \
              ${npmPackage}/${relExecutable} ${concatStringsSep " " pkg.wrapper.extraArgs} "$@"
          ''
        else
        # Just symlink if no sandbox, or simple wrapper if env vars needed
        if pkg.wrapper.environmentVariables != { } || pkg.wrapper.extraArgs != [ ] then
          pkgs.writeShellScriptBin (pkg.wrapper.name or name) ''
            ${concatStringsSep "\n" (
              mapAttrsToList (name: value: "export ${name}='${value}'") pkg.wrapper.environmentVariables
            )}
            exec ${npmPackage}/${relExecutable} ${concatStringsSep " " pkg.wrapper.extraArgs} "$@"
          ''
        else
          # Simple symlink
          pkgs.symlinkJoin {
            name = name;
            paths = [ npmPackage ];
          };

    in
    finalPackage;
in
{
  inherit buildNpm;
}
