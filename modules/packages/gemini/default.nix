{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.gemini-cli;

  # DEFINIÇÃO SEGURA: Build isolado em Sandbox
  package = pkgs.buildNpmPackage {
    pname = "gemini-cli";
    version = "0.24.0-nightly.20251231";

    src = pkgs.fetchzip {
      url = "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v0.24.0-nightly.20251231.05049b5ab.tar.gz";
      hash = "sha256-WxR6kr0U8uRA0F3vhhJayoH6yZI0HIPsD5i0y4ox7Fo=";
    };

    # 🛑 PASSO CRÍTICO DE SEGURANÇA:
    # Usamos um hash falso propositalmente.
    # Isso forçará o Nix a falhar e nos dizer o hash REAL das dependências.
    npmDepsHash = lib.fakeSha256;

    # Dependências de compilação
    nativeBuildInputs = with pkgs; [
      pkg-config
      python313
      git
      makeBinaryWrapper
    ];

    # Dependências de runtime (Library Path)
    buildInputs = with pkgs; [
      libsecret
    ];

    npmFlags = [ "--legacy-peer-deps" ];
    makeCacheWritable = true;
    dontNpmInstall = true; # Mantemos seu install manual pois é um monorepo complexo

    dontAutoPatchelf = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gemini-cli $out/bin

      # Cópia manual para garantir estrutura do monorepo
      cp -r packages $out/lib/gemini-cli/

      # Copia node_modules resolvendo symlinks
      cp -rL node_modules $out/lib/gemini-cli/ || cp -r node_modules $out/lib/gemini-cli/

      # Limpeza de artefatos de build
      find $out/lib/gemini-cli -xtype l -delete 2>/dev/null || true
      find $out/lib/gemini-cli -type l -lname '/build/*' -delete 2>/dev/null || true

      # WRAPPER DE SEGURANÇA
      # Injeta apenas os binários permitidos no PATH do processo
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gemini \
        --add-flags "$out/lib/gemini-cli/packages/cli/dist/index.js" \
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
