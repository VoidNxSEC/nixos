# Claude Code 2.1.81 - Full package build (NOT overrideAttrs)
#
# overrideAttrs cannot bump versions on buildNpmPackage + finalAttrs
# because the internal npmDeps gets a broken src (new URL, old hash).
# Instead we call buildNpmPackage directly via callPackage.
#
# Uses npmDepsFetcherVersion = 2: fetcher gera o lock internamente,
# não precisa de package-lock.json no source.
#
# To upgrade:
# 1. Update version + src hash (nix-prefetch-url --unpack <url>)
# 2. Set npmDepsHash = lib.fakeHash, rebuild, paste correct hash
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
    version = "2.1.92";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.92.tgz";
      hash = "sha256-WT+fj9H/5hlr/U8MygiIdE2QZ32kRz6wTjYEABtmBPU=";
    };

    npmDepsHash = lib.fakeHash;
    npmDepsFetcherVersion = 2;

    strictDeps = true;

    postPatch = ''
      cp ${./package-lock.json} package-lock.json
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
