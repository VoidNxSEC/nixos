# Cerebro — Semantic Reranker for RAG
# Reranks RAG results before injection into agent context

{ config, lib, ... }:

let
  cfg = config.services.cerebro;
in
{
  options.services.cerebro = {
    enable = lib.mkEnableOption "Cerebro semantic reranker";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8016;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "cross-encoder/ms-marco-MiniLM-L-6-v2";
      description = "Reranker model (HuggingFace cross-encoder)";
    };

    topK = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Number of documents to return after reranking";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "cerebro";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ "services.cerebro: stub — implement service before enabling." ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };
  };
}
