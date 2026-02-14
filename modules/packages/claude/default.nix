# Claude Code - Patched nixpkgs package with version override
#
# Fixes from upstream nixpkgs claude-code:
# 1. Add autoPatchelfHook to patch native .node binaries
# 2. Add stdenv.cc.cc.lib for libstdc++.so.6 (sharp dependency)
# 3. Ignore musl libc deps (glibc-only NixOS)
#
# Version tracking:
# - nixpkgs: 2.1.37
# - latest npm: 2.1.42 (checked 2026-02-14)
#
# To upgrade to latest:
# 1. Set version = "2.1.42" below
# 2. Update src.hash (already set for 2.1.42)
# 3. Set npmDepsHash = "" and rebuild to get expected hash
# 4. Update npmDepsHash with the hash from error message
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
    version = "2.1.42";
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.42.tgz";
      hash = "sha256-+99eaqKAOUvz+omHJ4bxlDepdpn8FNLmvxKcVDR76o4=";
    };
    npmDepsHash = ""; # Rebuild to get expected hash from error

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
