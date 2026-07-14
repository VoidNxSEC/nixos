# Training Logger — user documentation installed into
# /etc/training-logger/README.md (part of the training-logger/ split;
# see ./default.nix).
{ config, lib, ... }:

with lib;

{
  config = mkIf config.kernelcore.shell.trainingLogger.enable {
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
          kernelcore.shell.trainingLogger = {
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
