# ═══════════════════════════════════════════════════════════════
# ADR LEDGER — Facade
# ═══════════════════════════════════════════════════════════════
# Superfície kernelcore.* para os módulos que o flake do adr-ledger
# exporta. Não contém lógica própria: traduz opções deste repositório
# para as opções services.adr-ledger* declaradas lá.
#
# Por que existe: os módulos vêm do flake com namespace services.*,
# enquanto este repositório padroniza kernelcore.*. Sem o facade o
# nixos teria dois namespaces concorrentes para a mesma coisa.
#
# Decisão: ADR-0090 (adr-ledger) — consumir o flake, não copiar módulo.
#
# Opções:
#   kernelcore.blockchain.ledger.enable        = true/false
#   kernelcore.blockchain.ledger.ledgerPath    = "/var/lib/adr-ledger"
#   kernelcore.blockchain.ledger.autoSync      = true/false
#   kernelcore.blockchain.ledger.agents.enable = true/false
#   kernelcore.blockchain.ledger.ml.enable     = true/false
# ═══════════════════════════════════════════════════════════════

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.kernelcore.blockchain.ledger;
in
{
  options.kernelcore.blockchain.ledger = {
    enable = lib.mkEnableOption "ADR Ledger (anchoring de decisões, via flake adr-ledger)";

    package = lib.mkOption {
      type = lib.types.package;
      # Lazy: só é forçado se cfg.enable, então consumidores externos
      # que não tenham o input não quebram na avaliação.
      default = inputs.adr-ledger.packages.${pkgs.stdenv.hostPlatform.system}.adr-cli;
      defaultText = lib.literalExpression "inputs.adr-ledger.packages.\${system}.adr-cli";
      description = "Binário do CLI `adr` usado pelos serviços do ledger.";
    };

    ledgerPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/adr-ledger";
      description = ''
        Raiz do repositório do ADR Ledger no sistema de arquivos.
        `services.adr-ledger.ledgerPath` não tem default no módulo de origem —
        este é o valor que o repositório adota.
      '';
    };

    autoSync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Sincroniza a knowledge base por timer diário.";
    };

    agents = {
      enable = lib.mkEnableOption "daemons de agente do ADR Ledger (backed by securellm-mcp)";
    };

    ml = {
      enable = lib.mkEnableOption "integração ADR Ledger ↔ IntelAgent";

      llamacppUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8080";
        description = "Endpoint OpenAI-compatible do llama.cpp.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.adr-ledger = {
      enable = true;
      ledgerPath = cfg.ledgerPath;
      autoSync = cfg.autoSync;
    };

    # `package` do módulo de agentes é o securellm-mcp, não o adr-cli —
    # deixado no default do módulo de origem de propósito.
    services.adr-ledger-agents = lib.mkIf cfg.agents.enable {
      enable = true;
      ledgerRoot = cfg.ledgerPath;
    };

    services.adr-ledger-ml = lib.mkIf cfg.ml.enable {
      enable = true;
      adrRoot = cfg.ledgerPath;
      llamacpUrl = cfg.ml.llamacppUrl;
    };

    environment.systemPackages = [ cfg.package ];
  };
}
