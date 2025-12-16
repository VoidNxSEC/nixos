# NPM Package Template
#
# Copy this folder and customize for your package.
# This template is 100% self-contained - no external dependencies.
#
# Usage:
#   cp -r _templates/npm-package my-new-package
#   Edit default.nix with your package details
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.PACKAGE_NAME;

  package = pkgs.buildNpmPackage {
    pname = "PACKAGE_NAME";
    version = "X.Y.Z";

    # ============================================================
    # SOURCE - npm registry or GitHub
    # ============================================================
    src = pkgs.fetchFromGitHub {
      owner = "ORG";
      repo = "REPO";
      rev = "vX.Y.Z";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    # ============================================================
    # NPM DEPENDENCIES HASH
    # First build with lib.fakeHash, then use the real hash from error
    # ============================================================
    npmDepsHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

    # Build settings
    npmFlags = [ "--legacy-peer-deps" ]; # Common for older packages
    dontCheckNoBrokenSymlinks = true;

    # Native dependencies (if needed)
    nativeBuildInputs = with pkgs; [
      python3
      pkg-config
    ];

    buildInputs = with pkgs; [
      # Add native libs here, e.g.:
      # libsecret  # For keyring access
    ];

    meta = {
      description = "PACKAGE_NAME description";
      homepage = "https://github.com/ORG/REPO";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
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
