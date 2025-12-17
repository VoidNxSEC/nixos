{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.gemini-cli;

  package = pkgs.buildNpmPackage {
    pname = "gemini-cli";
    version = "0.21.0-nightly.20251216";

    src = pkgs.fetchzip {
      url = "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v0.21.0-nightly.20251217.db643e916.tar.gz";
      hash = "sha256-k57rmQB7LdNh73o8p1M0w8HqH5JkvmXU65g8lQFmZyY="; # Run build to get real hash
    };

    npmDepsHash = "sha256-Z9dlZEEM3q6pRIVEn/uR6j2d0vjFBETb2FuQBosaCyM="; # Run build to get real hash

    # Dependências de compilação (necessárias apenas para construir o pacote)
    nativeBuildInputs = with pkgs; [
      pkg-config
      python3
      git
      makeBinaryWrapper
    ];

    # Dependências de biblioteca (libsecret para keytar)
    buildInputs = with pkgs; [
      libsecret
    ];

    npmFlags = [ "--legacy-peer-deps" ];
    dontNpmInstall = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gemini-cli $out/bin

      # Copia os pacotes do monorepo
      cp -r packages $out/lib/gemini-cli/

      # Copia node_modules dereferenciando links simbólicos
      cp -rL node_modules $out/lib/gemini-cli/ || cp -r node_modules $out/lib/gemini-cli/

      # CRIAR WRAPPER ROBUSTO
      # Aqui está a correção dos erros de grep/git:
      # 1. Definimos o script JS alvo.
      # 2. Injetamos o LD_LIBRARY_PATH para o libsecret funcionar.
      # 3. Injetamos o PATH com git, grep, coreutils e xdg-open (para abrir o navegador).

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gemini \
        --add-flags "$out/lib/gemini-cli/packages/cli/dist/index.js" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libsecret ]} \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.git # Para comandos git internos
            pkgs.gnugrep # Para o erro de grep que você viu
            pkgs.coreutils # Comandos básicos (ls, cat, etc)
            pkgs.xdg-utils # Para 'gemini login' conseguir abrir o navegador
          ]
        }

      runHook postInstall
    '';

    dontCheckNoBrokenSymlinks = true;

    meta = {
      description = "CLI tool for Google's Gemini Generative AI API";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
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
