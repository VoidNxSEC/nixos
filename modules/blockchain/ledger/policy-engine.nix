# ═══════════════════════════════════════════════════════════════
# ADR LEDGER — OPA Policy Engine
# ═══════════════════════════════════════════════════════════════
# Adotado de adr-ledger/nix/iam/policy-engine.nix, que era órfão:
# nenhum flake ou módulo o importava, e por isso subia o OPA em
# localhost:8181 de forma incondicional, sem chave de desligar.
#
# Mudanças na adoção: mkEnableOption (nasce desligado), endereço,
# bundle e usuário viram opções. Hardening preservado do original.
#
# Decisão: ADR-0090 (adr-ledger).
#
# Opções:
#   kernelcore.blockchain.ledger.policyEngine.enable     = true/false
#   kernelcore.blockchain.ledger.policyEngine.addr       = "localhost:8181"
#   kernelcore.blockchain.ledger.policyEngine.bundlePath = "/var/lib/..."
# ═══════════════════════════════════════════════════════════════

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.blockchain.ledger.policyEngine;
in
{
  options.kernelcore.blockchain.ledger.policyEngine = {
    enable = lib.mkEnableOption "OPA policy engine do ADR Ledger";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.open-policy-agent;
      defaultText = lib.literalExpression "pkgs.open-policy-agent";
      description = "Pacote do Open Policy Agent.";
    };

    addr = lib.mkOption {
      type = lib.types.str;
      default = "localhost:8181";
      description = "Endereço de escuta do servidor OPA. Mantido em localhost por padrão.";
    };

    bundlePath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/adr-ledger/policies/bundle";
      description = "Bundle de policies servido pelo OPA, montado somente-leitura.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/opa";
      description = "Diretório de trabalho do OPA (único caminho gravável do serviço).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "agent-governance";
      description = "Usuário do serviço. Deve existir — ver services.adr-ledger-agents.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "adr-admin";
      description = "Grupo do serviço.";
    };

    installTooling = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instala opa e conftest no sistema (conftest é usado para validar policies em CI).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkIf cfg.installTooling [
      cfg.package
      pkgs.conftest
    ];

    systemd.services.opa-adr-ledger = {
      description = "OPA Policy Engine for ADR Ledger";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${cfg.package}/bin/opa run"
          "--server"
          "--addr ${cfg.addr}"
          "--log-level info"
          "--log-format json"
          "--bundle ${cfg.bundlePath}"
          "--watch"
        ];
        User = cfg.user;
        Group = cfg.group;

        # Hardening — preservado do módulo de origem
        ProtectSystem = "strict";
        ReadOnlyPaths = [ (builtins.dirOf cfg.bundlePath) ];
        ReadWritePaths = [ cfg.dataDir ];
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];
  };
}
