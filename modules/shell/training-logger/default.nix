# ============================================================
# TRAINING LOGGER MODULE
# ============================================================
# Módulo para captura e logging de sessões longas de treinamento
# Fornece funções e aliases para gravar outputs de terminal
# ============================================================
# Phase 5 split:
# - default.nix         → options, packages, logrotate, tmpfiles
# - shell-functions.nix → /etc/profile.d/training-logger.sh (train-log-* helpers)
# - docs.nix            → /etc/training-logger/README.md
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

{
  # ============================================================
  # OPTIONS
  # ============================================================

  options.kernelcore.shell.trainingLogger = {
    enable = mkEnableOption "Training session logger utilities";

    logDirectory = mkOption {
      type = types.str;
      default = "/var/log/training-sessions";
      description = "Directory to store training session logs";
    };

    userLogDirectory = mkOption {
      type = types.str;
      default = "\${HOME}/.training-logs";
      description = "User-specific log directory (expandable)";
    };

    autoTimestamp = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically add timestamps to log filenames";
    };

    maxLogSize = mkOption {
      type = types.str;
      default = "1G";
      description = "Maximum log file size before rotation";
    };
  };

  # ============================================================
  # CONFIGURATION
  # ============================================================

  config = mkIf config.kernelcore.shell.trainingLogger.enable {

    # Pacotes necessários
    environment.systemPackages = with pkgs; [
      # script vem de util-linux (já instalado no sistema)
      tmux # Multiplexer com logging integrado
      screen # Alternativa ao tmux
      # tee vem de coreutils (já instalado no sistema)
      ccze # Colorir logs
      multitail # Visualizar múltiplos logs
      lnav # Log navigator com análise
      grc # Generic colouriser para comandos
    ];

    # ============================================================
    # SISTEMA DE ROTAÇÃO DE LOGS (logrotate)
    # ============================================================

    services.logrotate = {
      enable = true;
      settings = {
        "${config.kernelcore.shell.trainingLogger.logDirectory}" = {
          rotate = 5;
          size = config.kernelcore.shell.trainingLogger.maxLogSize;
          compress = true;
          delaycompress = true;
          missingok = true;
          notifempty = true;
        };
      };
    };

    # ============================================================
    # PERMISSÕES
    # ============================================================

    # Criar diretório de logs do sistema se não existir
    systemd.tmpfiles.rules = [
      "d ${config.kernelcore.shell.trainingLogger.logDirectory} 0755 root root -"
    ];
  };

  imports = [
    ./shell-functions.nix
    ./docs.nix
  ];
}
