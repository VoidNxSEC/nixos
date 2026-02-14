# Claude Code 2.1.42 - Full package build (NOT overrideAttrs)
#
# overrideAttrs cannot bump versions on buildNpmPackage + finalAttrs
# because the internal npmDeps gets a broken src (new URL, old hash).
# Instead we call buildNpmPackage directly via callPackage.
#
# To upgrade:
# 1. Update version + src hash (nix-prefetch-url --unpack <url>)
# 2. Regenerate package-lock.json: npm install --package-lock-only
# 3. Set npmDepsHash = lib.fakeHash, rebuild, paste correct hash
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.claude;

  claude-code = pkgs.buildNpmPackage {
    pname = "claude-code";
    version = "2.1.42";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.42.tgz";
      hash = "sha256-+99eaqKAOUvz+omHJ4bxlDepdpn8FNLmvxKcVDR76o4=";
    };

    npmDepsHash = "sha256-Rbt6PiFJapHow4yEBafyMdHWLUaYIDRDDJB1a93ZqsI=";

    strictDeps = true;

    postPatch = ''
      cp ${./package-lock.json} package-lock.json
      substituteInPlace cli.js \
        --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
    '';

    dontNpmBuild = true;

    env.AUTHORIZED = "1";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
    ];

    # MUSL variants of sharp/libvips ship alongside glibc.
    # NixOS is glibc-only — ignore missing musl libc.
    autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

    postInstall = ''
      wrapProgram $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --unset DEV \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.procps
            pkgs.bubblewrap
            pkgs.socat
          ]
        }
    '';

    meta = {
      description = "Agentic coding tool that lives in your terminal";
      homepage = "https://github.com/anthropics/claude-code";
      license = lib.licenses.unfree;
      mainProgram = "claude";
    };
  };

in
{
  options.kernelcore.packages.claude = {
    enable = lib.mkEnableOption "Claude Code (patched native binaries)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ claude-code ];
  };
}
