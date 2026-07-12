{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.gemini-cli;

  # ═══════════════════════════════════════════════════════════════
  # FHS ENVIRONMENT - Solução para npm ENOTCACHED
  # ═══════════════════════════════════════════════════════════════
  # Gemini CLI já tem bubblewrap interno, só precisamos do FHS
  # para npm funcionar corretamente

  gemini-fhs = pkgs.buildFHSEnv {
    name = "gemini";

    # Dependências necessárias no ambiente FHS
    targetPkgs =
      pkgs: with pkgs; [
        nodejs_22
        python313
        git
        libsecret
        pkg-config
        stdenv.cc.cc.lib
      ];

    # Dependências multi-arch (32-bit support se necessário)
    multiPkgs =
      pkgs: with pkgs; [
        libsecret
      ];

    # Profile setup - configuração do ambiente
    profile = ''
      export GEMINI_HOME="$HOME/.local/share/gemini-cli"
      export NODE_PATH="$GEMINI_HOME/node_modules"
      export PATH="$GEMINI_HOME/node_modules/.bin:$PATH"
    '';

    # Script principal que roda quando você executa 'gemini'
    runScript = pkgs.writeShellScript "gemini-fhs-wrapper" ''
      # ══════════════════════════════════════════════════════════
      # CRITICAL: cd to HOME as FIRST operation (before set -e)
      # ══════════════════════════════════════════════════════════
      # Gemini's internal bubblewrap captures $PWD at execution time
      # FHS env doesn't expose /etc/nixos or arbitrary filesystem paths
      # MUST change directory BEFORE any other operations or error handling
      cd "$HOME" || exit 1

      set -e

      GEMINI_VERSION="0.24.0-nightly.20251231"
      GEMINI_HOME="$HOME/.local/share/gemini-cli"
      GEMINI_INSTALL_MARKER="$GEMINI_HOME/.installed-$GEMINI_VERSION"

      # ══════════════════════════════════════════════════════════
      # INSTALAÇÃO AUTOMÁTICA (primeira execução)
      # ══════════════════════════════════════════════════════════
      if [ ! -f "$GEMINI_INSTALL_MARKER" ]; then
        echo "🔧 Gemini CLI: First run installation..."
        mkdir -p "$GEMINI_HOME"
        cd "$GEMINI_HOME"

        # Download e extração
        echo "📦 Downloading Gemini CLI v$GEMINI_VERSION..."
        curl -L "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v$GEMINI_VERSION.05049b5ab.tar.gz" \
          | tar xz --strip-components=1

        # Instalação de dependências via npm (sem restrições de cache)
        echo "📚 Installing dependencies..."
        npm install --legacy-peer-deps

        # Marker de instalação completa
        touch "$GEMINI_INSTALL_MARKER"
        echo "✅ Gemini CLI installed successfully at $GEMINI_HOME"
        echo ""
      fi

      # ══════════════════════════════════════════════════════════
      # EXECUÇÃO
      # ══════════════════════════════════════════════════════════
      cd "$GEMINI_HOME"

      # Executa o CLI (bubblewrap já está interno no Gemini)
      exec node packages/cli/dist/index.js "$@"
    '';

    meta = {
      description = "Google Gemini CLI (FHS Environment)";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
      maintainers = [ ];
    };
  };

in
{
  options.kernelcore.packages.gemini-cli = {
    enable = lib.mkEnableOption "Google Gemini CLI (FHS Environment)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ gemini-fhs ];

    # Informação para o usuário
    environment.etc."gemini-cli-info.txt".text = ''
      Gemini CLI - FHS Environment Installation

      Location: ~/.local/share/gemini-cli

      First run will automatically:
      - Download Gemini CLI source
      - Install npm dependencies
      - Configure environment

      Subsequent runs use cached installation.

      To update: rm -rf ~/.local/share/gemini-cli
      Then run 'gemini' again to reinstall.
    '';
  };
}
