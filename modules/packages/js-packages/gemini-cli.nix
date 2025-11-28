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
        version = "0.19.0-nightly.20251124.e177314a4";

        # Use locally stored tarball for reproducible builds
        src = pkgs.fetchurl {
          url = "file://${./storage/gemini-cli-0.19.0-nightly.20251124.e177314a4.tar.gz}";
          sha256 = "3d5cffc5a3df3c9430fb9f742424656442c07951a0b8a5a1532a033376786ded";
        };

        # Hash calculated from first build
        npmDepsHash = "sha256-N2GI/G5CzuO8USGg2OEGHDTp+J6nfvz6gUm3Y9f03gc=";

        nodeLinker = "pnpm";

        # Native dependencies required for building keytar (password management)
        nativeBuildInputs = with pkgs; [
          pkg-config
          python3
        ];

        buildInputs = with pkgs; [
          libsecret
        ];

        # Skip tests to speed up build
        npmFlags = [ "--legacy-peer-deps" ];

        # Disable broken symlinks check since this is a monorepo with internal packages
        # that aren't included in the release tarball
        dontCheckNoBrokenSymlinks = true;

        # Clean up broken symlinks intelligently - only remove symlinks that point to nowhere
        postInstall = ''
          echo "Cleaning up broken symlinks in Gemini CLI..."

          # Find and remove only broken symlinks (symlinks that don't resolve)
          find $out/lib/node_modules/@google/gemini-cli/node_modules -type l 2>/dev/null | while read -r link; do
            if [ ! -e "$link" ]; then
              echo "Removing broken symlink: $link"
              rm -f "$link"
            fi
          done

          # Ensure the main executable exists and is correctly linked
          if [ ! -f "$out/bin/gemini" ]; then
            echo "Creating main gemini executable symlink..."
            mkdir -p $out/bin
            ln -sf $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js $out/bin/gemini
          fi

          echo "Gemini CLI post-install cleanup complete"
        '';

        meta = with lib; {
          description = "CLI tool for Google's Gemini Generative AI API";
          homepage = "https://github.com/google-gemini/gemini-cli";
          license = licenses.asl20;
          maintainers = [ marcosfpina ];
          platforms = platforms.all;
        };
      })
    ];
  };
}
