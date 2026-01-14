# ============================================================
# TRAINING LOGGER MODULE
# ============================================================
# Módulo para captura e logging de sessões longas de treinamento
# Fornece funções e aliases para gravar outputs de terminal
# ============================================================

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

  options.shell.trainingLogger = {
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

  config = mkIf config.shell.trainingLogger.enable {

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
    # SHELL FUNCTIONS & ALIASES
    # ============================================================

    environment.etc."profile.d/training-logger.sh" = {
      text = ''
                # ══════════════════════════════════════════════════════
                # Training Logger - Shell Functions
                # ══════════════════════════════════════════════════════

                # Diretório de logs (usa variável do NixOS config)
                TRAINING_LOG_DIR="${config.shell.trainingLogger.userLogDirectory}"
                TRAINING_LOG_DIR="''${TRAINING_LOG_DIR//\$\{HOME\}/$HOME}"  # Expande $HOME

                # Criar diretório se não existir
                mkdir -p "$TRAINING_LOG_DIR"

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Iniciar sessão de logging
                # ══════════════════════════════════════════════════════
                # Uso: train-log-start <nome-do-treinamento> [comando]
                # Exemplo: train-log-start llama3-finetune python train.py

                train-log-start() {
                    if [ -z "$1" ]; then
                        echo "❌ Erro: Forneça um nome para a sessão"
                        echo "Uso: train-log-start <nome> [comando]"
                        echo "Exemplo: train-log-start llama3-finetune python train.py"
                        return 1
                    fi

                    local session_name="$1"
                    shift

                    # Timestamp
                    local timestamp=$(date +%Y%m%d_%H%M%S)
                    local log_file="$TRAINING_LOG_DIR/''${session_name}_''${timestamp}.log"

                    echo "╔════════════════════════════════════════════════════════╗"
                    echo "║  Training Session Logger - STARTED                    ║"
                    echo "╚════════════════════════════════════════════════════════╝"
                    echo ""
                    echo "📝 Sessão: $session_name"
                    echo "📁 Log: $log_file"
                    echo "⏰ Início: $(date)"
                    echo ""

                    # Se comando fornecido, executa com tee
                    if [ $# -gt 0 ]; then
                        echo "🚀 Executando: $@"
                        echo ""
                        echo "═══════════════════════════════════════════════════════" | tee -a "$log_file"
                        echo "Training Session: $session_name" | tee -a "$log_file"
                        echo "Started: $(date)" | tee -a "$log_file"
                        echo "Command: $@" | tee -a "$log_file"
                        echo "═══════════════════════════════════════════════════════" | tee -a "$log_file"
                        echo "" | tee -a "$log_file"

                        # Executa comando com tee para duplicar output
                        "$@" 2>&1 | tee -a "$log_file"

                        local exit_code=$?
                        echo "" | tee -a "$log_file"
                        echo "═══════════════════════════════════════════════════════" | tee -a "$log_file"
                        echo "Session ended: $(date)" | tee -a "$log_file"
                        echo "Exit code: $exit_code" | tee -a "$log_file"
                        echo "═══════════════════════════════════════════════════════" | tee -a "$log_file"

                        return $exit_code
                    else
                        # Inicia script para gravar toda a sessão interativa
                        echo "🎬 Gravando sessão interativa..."
                        echo "   Use 'exit' ou Ctrl+D para finalizar"
                        echo ""

                        script -f "$log_file" -c "$SHELL"
                    fi
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Anexar output a log existente
                # ══════════════════════════════════════════════════════
                # Uso: train-log-append <arquivo-log> <comando>

                train-log-append() {
                    if [ -z "$1" ] || [ -z "$2" ]; then
                        echo "❌ Erro: Forneça o arquivo de log e comando"
                        echo "Uso: train-log-append <log-file> <comando>"
                        return 1
                    fi

                    local log_file="$1"
                    shift

                    echo "" | tee -a "$log_file"
                    echo "═══════════════════════════════════════════════════════" | tee -a "$log_file"
                    echo "Appended: $(date)" | tee -a "$log_file"
                    echo "Command: $@" | tee -a "$log_file"
                    echo "═══════════════════════════════════════════════════════" | tee -a "$log_file"
                    echo "" | tee -a "$log_file"

                    "$@" 2>&1 | tee -a "$log_file"
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Listar sessões de treinamento
                # ══════════════════════════════════════════════════════

                train-log-list() {
                    echo "╔════════════════════════════════════════════════════════╗"
                    echo "║  Training Sessions Log Files                          ║"
                    echo "╚════════════════════════════════════════════════════════╝"
                    echo ""

                    if [ ! -d "$TRAINING_LOG_DIR" ] || [ -z "$(ls -A $TRAINING_LOG_DIR 2>/dev/null)" ]; then
                        echo "⚠️  Nenhum log encontrado em: $TRAINING_LOG_DIR"
                        return 0
                    fi

                    ls -lht "$TRAINING_LOG_DIR"/*.log 2>/dev/null | \
                    awk 'BEGIN {
                        printf "%-10s %-20s %-50s\n", "Size", "Date", "Filename"
                        printf "%-10s %-20s %-50s\n", "----", "----", "--------"
                    }
                    {
                        printf "%-10s %-20s %-50s\n", $5, $6" "$7" "$8, $9
                    }'
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Visualizar log com cores
                # ══════════════════════════════════════════════════════

                train-log-view() {
                    if [ -z "$1" ]; then
                        echo "❌ Erro: Forneça o nome/caminho do arquivo de log"
                        echo "Uso: train-log-view <log-file>"
                        echo ""
                        echo "Logs disponíveis:"
                        train-log-list
                        return 1
                    fi

                    local log_file="$1"

                    # Se não for caminho completo, busca no diretório de logs
                    if [[ "$log_file" != /* ]]; then
                        log_file="$TRAINING_LOG_DIR/$log_file"
                    fi

                    if [ ! -f "$log_file" ]; then
                        echo "❌ Erro: Arquivo não encontrado: $log_file"
                        return 1
                    fi

                    # Usa lnav se disponível, senão less com cores
                    if command -v lnav &> /dev/null; then
                        lnav "$log_file"
                    else
                        less -R "$log_file"
                    fi
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Acompanhar log em tempo real
                # ══════════════════════════════════════════════════════

                train-log-tail() {
                    if [ -z "$1" ]; then
                        echo "❌ Erro: Forneça o nome/caminho do arquivo de log"
                        echo "Uso: train-log-tail <log-file> [linhas]"
                        return 1
                    fi

                    local log_file="$1"
                    local lines="''${2:-100}"

                    # Se não for caminho completo, busca no diretório de logs
                    if [[ "$log_file" != /* ]]; then
                        log_file="$TRAINING_LOG_DIR/$log_file"
                    fi

                    if [ ! -f "$log_file" ]; then
                        echo "❌ Erro: Arquivo não encontrado: $log_file"
                        return 1
                    fi

                    echo "📡 Acompanhando log: $log_file"
                    echo "   (Ctrl+C para sair)"
                    echo ""

                    # Usa ccze para colorir se disponível
                    if command -v ccze &> /dev/null; then
                        tail -n "$lines" -f "$log_file" | ccze -A
                    else
                        tail -n "$lines" -f "$log_file"
                    fi
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Procurar nos logs
                # ══════════════════════════════════════════════════════

                train-log-search() {
                    if [ -z "$1" ]; then
                        echo "❌ Erro: Forneça um termo de busca"
                        echo "Uso: train-log-search <termo> [arquivo]"
                        return 1
                    fi

                    local search_term="$1"
                    local log_file="''${2:-$TRAINING_LOG_DIR/*.log}"

                    echo "🔍 Buscando '$search_term' nos logs..."
                    echo ""

                    if command -v grc &> /dev/null; then
                        grc grep -n -i --color=always "$search_term" $log_file
                    else
                        grep -n -i --color=always "$search_term" $log_file
                    fi
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Limpar logs antigos
                # ══════════════════════════════════════════════════════

                train-log-clean() {
                    local days="''${1:-30}"

                    echo "🗑️  Removendo logs com mais de $days dias..."
                    echo "   Diretório: $TRAINING_LOG_DIR"
                    echo ""

                    find "$TRAINING_LOG_DIR" -name "*.log" -type f -mtime +$days -print -delete

                    echo ""
                    echo "✅ Limpeza concluída"
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Estatísticas de log
                # ══════════════════════════════════════════════════════

                train-log-stats() {
                    if [ -z "$1" ]; then
                        echo "❌ Erro: Forneça o nome/caminho do arquivo de log"
                        echo "Uso: train-log-stats <log-file>"
                        return 1
                    fi

                    local log_file="$1"

                    # Se não for caminho completo, busca no diretório de logs
                    if [[ "$log_file" != /* ]]; then
                        log_file="$TRAINING_LOG_DIR/$log_file"
                    fi

                    if [ ! -f "$log_file" ]; then
                        echo "❌ Erro: Arquivo não encontrado: $log_file"
                        return 1
                    fi

                    echo "╔════════════════════════════════════════════════════════╗"
                    echo "║  Log Statistics                                       ║"
                    echo "╚════════════════════════════════════════════════════════╝"
                    echo ""
                    echo "📁 Arquivo: $log_file"
                    echo "📊 Tamanho: $(du -h "$log_file" | cut -f1)"
                    echo "📝 Linhas: $(wc -l < "$log_file")"
                    echo "📅 Modificado: $(stat -c %y "$log_file" 2>/dev/null || stat -f %Sm "$log_file")"
                    echo ""
                    echo "🔍 Palavras mais frequentes:"
                    cat "$log_file" | tr '[:space:]' '\n' | grep -v "^$" | sort | uniq -c | sort -rn | head -10
                }

                # ══════════════════════════════════════════════════════
                # FUNÇÃO: Help
                # ══════════════════════════════════════════════════════

                train-log-help() {
                    cat << 'EOF'
        ╔════════════════════════════════════════════════════════╗
        ║           Training Logger - Help                      ║
        ╚════════════════════════════════════════════════════════╝

        📝 INICIAR LOGGING:
          train-log-start <nome> [comando]
            Inicia uma nova sessão de logging

            Exemplos:
              train-log-start llama3-finetune python train.py --epochs 100
              train-log-start bert-training ./run_training.sh
              train-log-start interactive  (modo interativo)

        📎 ANEXAR A LOG EXISTENTE:
          train-log-append <log-file> <comando>
            Adiciona output ao final de um log existente

            Exemplo:
              train-log-append llama3_20250109_143022.log python validate.py

        📋 LISTAR LOGS:
          train-log-list
            Lista todos os logs de treinamento com tamanho e data

        👁️  VISUALIZAR LOG:
          train-log-view <log-file>
            Abre log em visualizador (lnav ou less)

            Exemplo:
              train-log-view llama3_20250109_143022.log

        📡 ACOMPANHAR EM TEMPO REAL:
          train-log-tail <log-file> [linhas]
            Acompanha log em tempo real (como tail -f)

            Exemplo:
              train-log-tail llama3_20250109_143022.log 200

        🔍 BUSCAR NOS LOGS:
          train-log-search <termo> [arquivo]
            Busca termo em logs (case insensitive)

            Exemplo:
              train-log-search "error"
              train-log-search "epoch" llama3_20250109_143022.log

        🗑️  LIMPAR LOGS ANTIGOS:
          train-log-clean [dias]
            Remove logs com mais de N dias (padrão: 30)

            Exemplo:
              train-log-clean 60

        📊 ESTATÍSTICAS:
          train-log-stats <log-file>
            Mostra estatísticas do arquivo de log

        ❓ AJUDA:
          train-log-help
            Mostra esta mensagem de ajuda

        ═══════════════════════════════════════════════════════

        📁 Logs salvos em: $TRAINING_LOG_DIR

        Dica: Use tmux/screen para sessões persistentes que continuam
              mesmo se você desconectar do terminal.

        EOF
                }

                # ══════════════════════════════════════════════════════
                # Exportar funções
                # ══════════════════════════════════════════════════════

                export -f train-log-start
                export -f train-log-append
                export -f train-log-list
                export -f train-log-view
                export -f train-log-tail
                export -f train-log-search
                export -f train-log-clean
                export -f train-log-stats
                export -f train-log-help

                # ══════════════════════════════════════════════════════
                # Aliases convenientes
                # ══════════════════════════════════════════════════════

                alias tlog='train-log-start'
                alias tlog-ls='train-log-list'
                alias tlog-view='train-log-view'
                alias tlog-tail='train-log-tail'
                alias tlog-help='train-log-help'
      '';
      mode = "0644";
    };

    # ============================================================
    # SISTEMA DE ROTAÇÃO DE LOGS (logrotate)
    # ============================================================

    services.logrotate = {
      enable = true;
      settings = {
        "${config.shell.trainingLogger.logDirectory}" = {
          rotate = 5;
          size = config.shell.trainingLogger.maxLogSize;
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
      "d ${config.shell.trainingLogger.logDirectory} 0755 root root -"
    ];

    # ============================================================
    # DOCUMENTAÇÃO
    # ============================================================

    environment.etc."training-logger/README.md" = {
      text = ''
        # Training Logger Module

        Sistema completo de logging para sessões longas de treinamento ML/DL.

        ## Recursos

        ✅ Logging automático com timestamps
        ✅ Gravação de sessões interativas
        ✅ Visualização com cores e navegação
        ✅ Busca em múltiplos logs
        ✅ Rotação automática de logs grandes
        ✅ Estatísticas e análise de logs
        ✅ Limpeza automática de logs antigos

        ## Instalação

        No seu configuration.nix:

        ```nix
        {
          shell.trainingLogger = {
            enable = true;
            userLogDirectory = "''${HOME}/.training-logs";  # Customizável
            maxLogSize = "1G";  # Rotação automática
          };
        }
        ```

        ## Uso Rápido

        ```bash
        # Iniciar treinamento com logging
        train-log-start meu-modelo python train.py --epochs 100

        # Listar logs
        train-log-list

        # Visualizar log
        train-log-view meu-modelo_20250109_143022.log

        # Acompanhar em tempo real
        train-log-tail meu-modelo_20250109_143022.log

        # Buscar erros
        train-log-search "error"

        # Ver ajuda completa
        train-log-help
        ```

        ## Integração com TMUX/Screen

        Para sessões persistentes que continuam mesmo após desconexão:

        ```bash
        # Com tmux
        tmux new -s treinamento
        train-log-start meu-modelo python train.py
        # Ctrl+B, D para detach

        # Reconectar
        tmux attach -t treinamento

        # Com screen
        screen -S treinamento
        train-log-start meu-modelo python train.py
        # Ctrl+A, D para detach

        # Reconectar
        screen -r treinamento
        ```

        ## Estrutura de Logs

        ```
        ~/.training-logs/
        ├── modelo-bert_20250109_100530.log
        ├── modelo-bert_20250109_100530.log.1.gz  (rotacionado)
        ├── llama-finetune_20250109_143022.log
        └── gpt2-train_20250108_093045.log
        ```

        ## Aliases Disponíveis

        - `tlog` → `train-log-start`
        - `tlog-ls` → `train-log-list`
        - `tlog-view` → `train-log-view`
        - `tlog-tail` → `train-log-tail`
        - `tlog-help` → `train-log-help`

        ## Ferramentas Incluídas

        - **script**: Gravação de sessões de terminal
        - **tmux/screen**: Multiplexers para sessões persistentes
        - **tee**: Duplicação de output
        - **ccze**: Colorização de logs
        - **lnav**: Navegador avançado de logs
        - **multitail**: Visualização de múltiplos logs
        - **grc**: Colorização genérica

        ## Exemplos Práticos

        ### 1. Treinamento Simples
        ```bash
        train-log-start bert-base python train.py \
          --model bert-base-uncased \
          --epochs 10 \
          --batch-size 32
        ```

        ### 2. Pipeline Completo
        ```bash
        # Pré-processamento
        train-log-start data-prep python preprocess.py

        # Treinamento
        train-log-start training python train.py

        # Avaliação (anexar ao mesmo log)
        train-log-append training_*.log python evaluate.py
        ```

        ### 3. Monitoramento em Tempo Real
        ```bash
        # Terminal 1: Executar treinamento
        train-log-start llama-finetune python train.py

        # Terminal 2: Monitorar log
        train-log-tail llama-finetune_*.log
        ```

        ### 4. Análise Pós-Treinamento
        ```bash
        # Ver estatísticas
        train-log-stats llama-finetune_20250109_143022.log

        # Buscar métricas específicas
        train-log-search "accuracy" llama-finetune_20250109_143022.log
        train-log-search "loss" llama-finetune_20250109_143022.log
        ```

        ## Manutenção

        ```bash
        # Limpar logs com mais de 30 dias
        train-log-clean 30

        # Limpar logs com mais de 7 dias
        train-log-clean 7
        ```

        ## Localização dos Logs

        - **Usuário**: `~/.training-logs/` (padrão)
        - **Sistema**: `/var/log/training-sessions/`
        - **Customizável**: Via opção `userLogDirectory`

        ## Suporte

        - Ver ajuda: `train-log-help`
        - Listar comandos: `compgen -A function | grep train-log`
        - Documentação NixOS: `/etc/nixos/modules/shell/training-logger.nix`
      '';
      mode = "0644";
    };
  };
}
