{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.gemini-cli;
in
{
  options.kernelcore.packages.gemini-cli = {
    enable = mkEnableOption "Google Gemini CLI tool";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.buildNpmPackage rec {
        pname = "gemini-cli";
        version = "0.15.0-nightly.20251107.cd27cae8";

        # Use locally stored tarball for reproducible builds
        src = pkgs.fetchurl {
          url = "file://${./storage/gemini-cli-v0.15.0-nightly.20251107.cd27cae8.tar.gz}";
          sha256 = "a760b24312bb30b0f30a8fde932cd30fc8bb09b3f6dcca67f8fe0c4d5f798702";
        };

        # This hash will be calculated on first build
        # If build fails with hash mismatch, update with the correct hash from error message
        npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

        # Skip tests to speed up build
        npmFlags = [ "--legacy-peer-deps" ];

        meta = with lib; {
          description = "CLI tool for Google's Gemini Generative AI API";
          homepage = "https://github.com/google-gemini/gemini-cli";
          license = licenses.asl20;
          maintainers = [ ];
          platforms = platforms.all;
        };
      })
    ];
  };
}
