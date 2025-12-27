# DEB Package Builder
# Purpose: Build .deb packages using shared builders and fetchers
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

  buildDebPackage =
    name: pkg:
    let
      debFile = fetchers.fetchSource name pkg.source "deb";
      extracted = fetchers.extractDeb name debFile;

      commonArgs = {
        inherit name extracted;
        sandbox = pkg.sandbox;
        wrapper_raw = pkg.wrapper;
        meta = pkg.meta;
      };

      method =
        if pkg.method == "auto" then
          readFile (builders.autoDetectMethod { inherit extracted; })
        else
          pkg.method;

      package = if method == "fhs" then builders.buildFHS commonArgs else builders.buildNative commonArgs;

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
  inherit buildDebPackage;
  fetchDeb = name: source: fetchers.fetchSource name source "deb";
  extractDeb = fetchers.extractDeb;
}
