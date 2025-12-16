# TAR Package Template
#
# Copy this folder and customize for your package.
# This template is 100% self-contained - no external dependencies.
#
# Usage:
#   cp -r _templates/tar-package my-new-package
#   Edit default.nix with your package details
#   Place source.tar.gz in the folder (or use URL)
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.PACKAGE_NAME;

  # ============================================================
  # SOURCE - Choose ONE: local file or URL
  # ============================================================
  src = ./source.tar.gz; # Local file (tracked by Git LFS)
  # OR:
  # src = pkgs.fetchurl {
  #   url = "https://github.com/ORG/REPO/releases/download/vX.Y.Z/package.tar.gz";
  #   sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  # };

  # ============================================================
  # EXTRACTION - Unpack the tarball
  # ============================================================
  extracted = pkgs.runCommand "PACKAGE_NAME-extracted" { } ''
    mkdir -p $out
    ${pkgs.gnutar}/bin/tar -xzf ${src} -C $out --strip-components=1
  '';

  # ============================================================
  # PACKAGE - Native binary with patched interpreter
  # ============================================================
  package = pkgs.stdenv.mkDerivation {
    pname = "PACKAGE_NAME";
    version = "X.Y.Z";
    src = extracted;

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/
      # Adjust path to your binary:
      ln -s $out/PACKAGE_NAME $out/bin/PACKAGE_NAME
    '';

    meta = {
      description = "PACKAGE_NAME description";
      homepage = "https://example.com";
      license = lib.licenses.mit; # Adjust license
      platforms = [ "x86_64-linux" ];
    };
  };

in
{
  options.kernelcore.packages.PACKAGE_NAME = {
    enable = lib.mkEnableOption "PACKAGE_NAME";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
