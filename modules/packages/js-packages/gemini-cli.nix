{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.gemini-cli;
  sources = pkgs.callPackage ../_sources/generated.nix { };
in
{
  options.kernelcore.packages.gemini-cli = {
    enable = mkEnableOption "Google Gemini CLI tool";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.buildNpmPackage rec {
        pname = "gemini-cli";
        version = sources.gemini-cli.version;

        src = sources.gemini-cli.src;

        # Hash to be updated after first build attempt
        # npmDepsHash = lib.fakeHash; # Removed, using actual hash below
        npmDepsHash = "sha256-OCSYOxMyBkb4ygeys4GhNwVKOWRGhgmao4QBrpFpt74=";

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