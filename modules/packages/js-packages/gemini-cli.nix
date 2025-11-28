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
      (pkgs.stdenv.mkDerivation rec {
        pname = "gemini-cli";
        version = "0.19.0-preview.0";

        # Use locally stored standalone JavaScript bundle
        src = pkgs.fetchurl {
          url = "file://${./storage/gemini.js}";
          sha256 = "afb3b417531f19c07542ab218467853b6b8684c745ad523e02ca84f0a4be0af8";
        };

        dontUnpack = true;
        dontBuild = true;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          mkdir -p $out/bin $out/lib

          # Install the standalone JavaScript bundle
          cp $src $out/lib/gemini.js
          chmod +x $out/lib/gemini.js

          # Create wrapper script that ensures Node.js is available
          makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gemini \
            --add-flags "$out/lib/gemini.js"
        '';

        meta = with lib; {
          description = "CLI tool for Google's Gemini Generative AI API (Preview/Nightly Build)";
          homepage = "https://github.com/google-gemini/gemini-cli";
          license = licenses.asl20;
          maintainers = [ "marcosfpina" ];
          platforms = platforms.all;
          mainProgram = "gemini";
        };
      })
    ];
  };
}
