# ═══════════════════════════════════════════════════════════════
# ADR LEDGER — Audit Log Integrity
# ═══════════════════════════════════════════════════════════════
# Adotado de adr-ledger/nix/iam/audit.nix, que era órfão E não
# parseava: a linha
#     CHAINED="${LAST_HASH}:${CURRENT_HASH}:$(date -u +%s)"
# usava ${...} dentro de string Nix '' '', onde isso é interpolação
# do Nix e não do shell. O arquivo falhava com "undefined variable
# 'LAST_HASH'" — invisível porque nada o importava.
#
# Mudanças na adoção: escape ''${ para as variáveis de shell,
# mkEnableOption, e intervalo/diretório como opções.
#
# Decisão: ADR-0090 (adr-ledger).
#
# Opções:
#   kernelcore.blockchain.ledger.audit.enable   = true/false
#   kernelcore.blockchain.ledger.audit.interval = "*:0/15"
#   kernelcore.blockchain.ledger.audit.auditDir = "/var/lib/..."
# ═══════════════════════════════════════════════════════════════

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.blockchain.ledger.audit;
in
{
  options.kernelcore.blockchain.ledger.audit = {
    enable = lib.mkEnableOption "verificação de integridade do audit log do ADR Ledger";

    auditDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/adr-ledger/audit";
      description = "Raiz do audit trail. As decisões ficam em <auditDir>/decisions.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/15";
      description = "Calendário systemd da verificação. Padrão: a cada 15 minutos.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "agent-auditor";
      description = "Usuário que executa a verificação.";
    };

    owner = lib.mkOption {
      type = lib.types.str;
      default = "agent-governance";
      description = "Dono dos diretórios de audit.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "adr-auditor";
      description = "Grupo dos diretórios de audit.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.auditDir} 0750 ${cfg.owner} ${cfg.group} -"
      "d ${cfg.auditDir}/decisions 0750 ${cfg.owner} ${cfg.group} -"
    ];

    systemd.services.adr-audit-integrity = {
      description = "ADR Ledger Audit Log Integrity Check";
      startAt = cfg.interval;

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = pkgs.writeShellScript "adr-audit-integrity" ''
          set -eu
          AUDIT_DIR="${cfg.auditDir}/decisions"
          HASH_CHAIN="${cfg.auditDir}/hash_chain"

          # Hash encadeado (tamper-evident). As chaves abaixo são escapadas
          # com ''${ para serem do shell e não interpolação do Nix — era
          # exatamente aqui que o módulo de origem falhava.
          LAST_HASH=$(tail -1 "$HASH_CHAIN" 2>/dev/null || echo "genesis")
          CURRENT_HASH=$(find "$AUDIT_DIR" -newer "$HASH_CHAIN" -type f \
            | sort | xargs cat | sha256sum | cut -d' ' -f1)

          CHAINED="''${LAST_HASH}:''${CURRENT_HASH}:$(date -u +%s)"
          echo "$CHAINED" | sha256sum >> "$HASH_CHAIN"
        '';
      };
    };
  };
}
