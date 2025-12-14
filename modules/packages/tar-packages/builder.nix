# TAR Package Builder
# Purpose: Build tar.gz packages using shared builders and fetchers
{
  pkgs,
  lib,
  packages,
  storageDir,
  cacheDir,
}:

with lib;

let
  builders = import ../lib/builders.nix { inherit pkgs lib; };
  fetchers = import ../lib/fetchers.nix { inherit pkgs lib; };

  # Auto-detect best build method based on binary characteristics
  autoDetectMethod =
    name: pkg: extracted:
    let
      executable = "${extracted}/${pkg.wrapper.executable or name}";
      targetTriple = fetchers.detectTargetTriple (pkg.wrapper.executable or name);
      hasDynamicLibs = builtins.pathExists "${extracted}/lib";

      linkType =
        if builtins.pathExists executable then
          lib.removeSuffix "\n" (builtins.readFile (fetchers.detectDynamicLinking executable))
        else
          "unknown";

      decision =
        if targetTriple == "musl" then
          {
            method = "native";
            reason = "MUSL binaries are statically linked";
          }
        else if targetTriple == "gnu" && linkType == "dynamic" then
          {
            method = "fhs";
            reason = "GNU dynamically linked";
          }
        else if hasDynamicLibs then
          {
            method = "fhs";
            reason = "Package includes dynamic libraries";
          }
        else if linkType == "static" then
          {
            method = "native";
            reason = "Statically linked binary";
          }
        else
          {
            method = "native";
            reason = "Default fallback";
          };

      # Debug trace disabled in production - uncomment for debugging:
      # _ = builtins.trace "Package ${name}: method='${decision.method}' (${decision.reason})" null;
    in
    decision.method;

  buildPackage =
    name: pkg:
    let
      tarFile = fetchers.fetchSource name pkg.source "tar.gz";
      extracted = fetchers.extractTarball name tarFile;
      method = if pkg.method == "auto" then autoDetectMethod name pkg extracted else pkg.method;
      # Debug trace disabled in production - uncomment for debugging:
      # _ = builtins.trace "Package ${name}: Using '${method}'" null;

      commonArgs = {
        inherit name extracted;
        sandbox = pkg.sandbox;
        wrapper_raw = pkg.wrapper;
        meta =
          if pkg.meta != { } then
            pkg.meta
          else
            {
              description = "${name} package";
              license = lib.licenses.unfree;
              platforms = [ "x86_64-linux" ];
            };
      };

      package = if method == "fhs" then builders.buildFHS commonArgs else builders.buildNative commonArgs;
    in
    package;

in
{
  inherit buildPackage;
}
