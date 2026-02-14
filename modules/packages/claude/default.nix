# Claude Code - Patched nixpkgs package
#
# Applies build fixes to upstream nixpkgs claude-code:
# 1. Add autoPatchelfHook to patch native .node binaries
# 2. Add stdenv.cc.cc.lib for libstdc++.so.6 (sharp dependency)
# 3. Ignore musl libc deps (glibc-only NixOS)
#
# NOTE: Version bumping via overrideAttrs does NOT work with
# buildNpmPackage + finalAttrs pattern. The internal npmDeps
# derivation gets a broken src (new URL, old hash) because
# finalAttrs.version changes the URL but not the hardcoded hash.
# To upgrade claude-code, wait for nixpkgs to update or use
# an overlay that replaces the entire package definition.
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.claude;

  claude-code-patched = pkgs.claude-code.overrideAttrs (prev: {
    nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [
      pkgs.autoPatchelfHook
    ];

    buildInputs = (prev.buildInputs or [ ]) ++ [
      pkgs.stdenv.cc.cc.lib
    ];

    # The npm package ships MUSL variants of sharp/libvips alongside glibc.
    # NixOS is glibc - ignore missing musl libc (those binaries never run).
    autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];
  });

in
{
  options.kernelcore.packages.claude = {
    enable = lib.mkEnableOption "Claude Code (patched native binaries)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ claude-code-patched ];
  };
}
