{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.gemini-cli;

  # Definição manual já que o _sources/generated.nix foi "arquivado"
  geminiVersion = "0.24.0-nightly.20251231";

  # O "Nix Way" de lidar com arquivos locais grandes sem sujar o store desnecessariamente
  # Certifique-se que o arquivo existe neste caminho relativo!
  geminiSrc = ./storage/gemini-cli-0.24.0-nightly.20251231.05049b5ab.tar.gz;
in
{
  options.kernelcore.packages.gemini-cli = {
    enable = mkEnableOption "Google Gemini CLI tool (Nightly Build)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.buildNpmPackage rec {
        pname = "gemini-cli";
        version = geminiVersion;
        src = geminiSrc;

        # O hash que estava no arquivo 'State of the Art'.
        # Se falhar, o Nix vai cuspir o hash novo e você atualiza aqui.
        npmDepsHash = "";

        # Performance & Compatibilidade
        nodeLinker = "pnpm"; # Mais rápido e eficiente em disco
        npmFlags = [ "--legacy-peer-deps" ]; # Essencial para nightlies instáveis

        # Dependências Nativas (recuperadas do gemini-cli.nix)
        nativeBuildInputs = with pkgs; [
          pkg-config
          python3
        ];

        # Dependências de Runtime (Keytar/Libsecret)
        buildInputs = with pkgs; [
          libsecret
        ];

        # O Grande Truque: Monorepos costumam ter symlinks internos que o Nix odeia.
        # Desativamos a checagem padrão e fazemos a limpeza manual cirúrgica.
        dontCheckNoBrokenSymlinks = true;

        postInstall = ''
          echo "🧹 Cleaning up broken symlinks in Gemini CLI..."

          # Remove apenas symlinks que apontam para o nada (common em builds parciais de monorepo)
          find $out/lib/node_modules/@google/gemini-cli/node_modules -type l 2>/dev/null |
          while read -r link; do
            if [ ! -e "$link" ]; then
              rm -f "$link"
            fi
          done

          # Garante que o binário está no $PATH
          if [ ! -f "$out/bin/gemini" ]; then
            echo "🔗 Linking main gemini executable..."
            mkdir -p $out/bin
            ln -sf $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js $out/bin/gemini
          fi
        '';

        meta = {
          description = "CLI tool for Google's Gemini Generative AI API (Nightly)";
          homepage = "https://github.com/google-gemini/gemini-cli";
          license = licenses.asl20;
          maintainers = [ "kernelcore" ];
          mainProgram = "gemini";
        };
      })
    ];
  };
}
