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
    version = "0.24.0-nightly.20251227";

    src = pkgs.fetchzip {
      url = "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v0.24.0-nightly.20251227.37be16243.tar.gz";
      hash = "sha256-Js6D/qdIbJFeWqgJKoCwAT3+HOylPPYSQT+msyRAUI4="; # Run build to get real hash
    };

    npmDepsHash = "sha256-UidGkH05tU/Bd9F9dT845WU3XhrVtGWgeENkEqJp/IY="; # Run build to get real hash

    # Dependências de compilação (necessárias apenas para construir o pacote)
    nativeBuildInputs = with pkgs; [
      pkg-config
      python313
      git
      makeBinaryWrapper
    ];

    # Dependências de biblioteca (libsecret para keytar)
    buildInputs = with pkgs; [
      libsecret
    ];

    npmFlags = [ "--legacy-peer-deps" ];
    dontNpmInstall = true;

    # Desabilitar autopatchelf - gemini-cli é JavaScript, não binário ELF
    dontAutoPatchelf = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gemini-cli $out/bin

      # Copia os pacotes do monorepo
      cp -r packages $out/lib/gemini-cli/

      # Copia node_modules dereferenciando links simbólicos
      cp -rL node_modules $out/lib/gemini-cli/ || cp -r node_modules $out/lib/gemini-cli/

      # Remove symlinks quebrados que apontam para /build
      find $out/lib/gemini-cli -xtype l -delete 2>/dev/null || true
      find $out/lib/gemini-cli -type l -lname '/build/*' -delete 2>/dev/null || true

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
