{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.gemini-cli;

  package = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "unstable-2026-01-02"; # ou usa uma data/git rev

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "main"; # ou um commit específico pra fixar: git rev-parse HEAD do main
      hash = "sha256-ApzyT+TLnd8WjVB4dYcYAUulJ1uimlNGBjH5ztgcWcE="; # fake pra pegar o hash real
    };

    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # fake também

    npmFlags = [ "--legacy-peer-deps" ];
    makeCacheWritable = true;

    nativeBuildInputs = with pkgs; [
      pkg-config
      python3
      git
      makeBinaryWrapper
    ];

    buildInputs = with pkgs; [
      libsecret
    ];

    # Build só o pacote cli (o que interessa)
    npmWorkspace = "packages/cli";
    npmBuildScript = "build"; # assuming tem "build" no package.json do cli

    # Se precisar de flags extras no build:
    # npmBuildFlags = [ "--workspace=packages/cli" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gemini-cli $out/bin

      # Copia o built do cli
      cp -r packages/cli/dist $out/lib/gemini-cli/

      # Copia node_modules se precisar (normalmente o buildNpmPackage já cuida)
      cp -r node_modules $out/lib/gemini-cli/ || true

      # Limpa symlinks quebrados
      find $out/lib/gemini-cli -xtype l -delete 2>/dev/null || true
      find $out/lib/gemini-cli -type l -lname '/build/*' -delete 2>/dev/null || true

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gemini \
        --add-flags "$out/lib/gemini-cli/dist/index.js" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libsecret ]} \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.git
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.xdg-utils
          ]
        }

      runHook postInstall
    '';

    meta = {
      description = "CLI tool for Google's Gemini Generative AI API";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
      mainProgram = "gemini";
    };
  };

in
{
  options.kernelcore.packages.gemini-cli = {
    enable = lib.mkEnableOption "Google Gemini CLI";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
