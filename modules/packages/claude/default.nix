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
    version = "2.1.44";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.44.tgz";
      hash = "sha256-3HhH7LOFA7sNOXGZa6reO3HfXcHFQO0mbFWFpPXFwcM=";
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
        --suffix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib # libstdc++, libgcc_s
            pkgs.zlib
            pkgs.openssl
            pkgs.curl
            pkgs.glib
            pkgs.icu
          ]
        } \
        --prefix PATH : ${
          lib.makeBinPath [
            # Core runtime
            pkgs.procps
            pkgs.bubblewrap
            pkgs.socat
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
            pkgs.diffutils

            # Binary analysis / debugging
            pkgs.strace
            pkgs.ltrace
            pkgs.gdb
            pkgs.patchelf
            pkgs.binutils # readelf, objdump, strings, ld
            pkgs.file

            # Nix tooling
            pkgs.nix
            pkgs.nixfmt

            # Build toolchain
            pkgs.gcc
            pkgs.gnumake
            pkgs.cmake

            # Network / fetch
            pkgs.curl
            pkgs.wget
            pkgs.openssh

            # Git + forges
            pkgs.git
            pkgs.gh
            pkgs.glab

            # Archive / compression
            pkgs.gnutar
            pkgs.unzip
            pkgs.zip
            pkgs.gzip
            pkgs.xz

            # JSON / data
            pkgs.jq
            pkgs.yq-go
            pkgs.sqlite

            # System introspection
            pkgs.lsof
            pkgs.iproute2
            pkgs.util-linux # lsblk, mount, etc.
            pkgs.pstree

            # Dev runtimes
            pkgs.nodejs
            pkgs.python3
            pkgs.cargo
            pkgs.go

            # Container / infra
            pkgs.docker-client

            # Secrets
            pkgs.sops
            pkgs.openssl
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
