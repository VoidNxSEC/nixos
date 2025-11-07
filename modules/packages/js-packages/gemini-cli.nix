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

        # Hash calculated from first build
        npmDepsHash = "sha256-FHA51ftpowmcS1zys+iFN9DLNKOg6UHRJ7dHxml2tOA=";

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

        # Clean up broken symlinks that point to missing workspace packages
        postInstall = ''
          # Remove symlinks to missing workspace packages
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/@google/gemini-cli-a2a-server
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/@google/gemini-cli-test-utils
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/@google/gemini-cli-core
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/@google/gemini-cli
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/gemini-cli-vscode-ide-companion
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/.bin/gemini-cli-a2a-server
          rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/.bin/gemini

          # Ensure the main executable symlink exists
          mkdir -p $out/bin
          ln -sf $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js $out/bin/gemini
        '';

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
