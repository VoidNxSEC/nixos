# Neoland Agent Configuration — escalation thresholds e personalidades
# Gerado como /etc/neoland/agents.toml consumido pelo control plane Rust

{ config, lib, ... }:

let
  cfg = config.services.neoland-agents;
in
{
  options.services.neoland-agents = {
    escalation = {
      juniorConfidenceWarnThreshold = lib.mkOption {
        type = lib.types.float;
        default = 0.4;
        description = "Abaixo deste valor, Junior output é sinalizado (pipeline continua)";
      };
      techLeaderDeferTtlHours = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Horas que um decision=defer é válido antes de re-escalar";
      };
    };

    rag = {
      topK = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Número de documentos RAG injetados no contexto do Junior";
      };
      maxCharsPerDoc = lib.mkOption {
        type = lib.types.int;
        default = 500;
        description = "Limite de caracteres por documento RAG (evita context overflow)";
      };
    };

    pipeline = {
      timeoutSecs = lib.mkOption {
        type = lib.types.int;
        default = 120;
        description = "Timeout do pipeline DSPy (Rust espera este tempo antes de circuit break)";
      };
    };
  };

  config.environment.etc."neoland/agents.toml".text = ''
    [agents.escalation]
    junior_confidence_warn_threshold = ${lib.strings.floatToString cfg.escalation.juniorConfidenceWarnThreshold}
    tech_leader_defer_ttl_hours      = ${toString cfg.escalation.techLeaderDeferTtlHours}

    [agents.rag]
    top_k            = ${toString cfg.rag.topK}
    max_chars_per_doc = ${toString cfg.rag.maxCharsPerDoc}

    [agents.pipeline]
    timeout_secs = ${toString cfg.pipeline.timeoutSecs}
  '';
}
