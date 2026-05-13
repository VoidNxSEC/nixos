# Neoland ADR Ledger Subscriber — Ciclo 1 Fase C
#
# Binário Rust do adr-ledger que:
#   1. Assina `nats.subscribe("neoland.task.completed.v1")`
#   2. Filtra decisões finais (accepted | rejected) do Tech-Leader
#   3. Assina com secp256k1 (chave em sops-nix)
#   4. Persiste na Merkle chain — tabela `adr_merkle_chain` no PostgreSQL
#
# Migração futura: trocar `signingKeyFile` por interface de hardware ledger
# sem mudar nada neste módulo (o binário implementa o trait Signer de forma abstrata).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neoland-ledger-subscriber;
in
{
  options.services.neoland-ledger-subscriber = {
    enable = lib.mkEnableOption "Neoland ADR ledger subscriber (secp256k1 + Merkle chain)";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The ledger-subscriber binary package";
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      description = "PostgreSQL connection string (via sops-nix)";
    };

    natsUrl = lib.mkOption {
      type = lib.types.str;
      default = "nats://localhost:4222";
      description = "NATS server URL";
    };

    # ── IAM — chave secp256k1 via sops-nix ────────────────────────────────
    # Futuro: substituir por `hardwareLedger = { device = "/dev/trezor0"; }`
    signingKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/audit/signing_key";
      description = ''
        Path para o arquivo com a chave privada secp256k1 (hex, 64 chars).
        Deve ser decriptado pelo sops-nix antes do serviço iniciar.
        Owner: ledger-subscriber. Mode: 0400.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "ledger-subscriber";
      description = "Usuário do sistema para o serviço (deve ter acesso ao signingKeyFile)";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = "RUST_LOG level (trace, debug, info, warn, error)";
    };

    resources = {
      memoryMb = lib.mkOption {
        type = lib.types.int;
        default = 128;
        description = "Memory limit in MB — o subscriber é leve (sem ML)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.neoland-ledger-subscriber = {
      description = "Neoland ADR Ledger Subscriber (secp256k1 + PostgreSQL Merkle chain)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
        "neoland-control-plane.service"
      ];

      environment = {
        DATABASE_URL = cfg.databaseUrl;
        NATS_URL = cfg.natsUrl;
        ADR_LEDGER_SIGNING_KEY = cfg.signingKeyFile;
        RUST_LOG = cfg.logLevel;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ledger-subscriber";
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "10s";

        MemoryMax = "${toString cfg.resources.memoryMb}M";

        # Hardening — o subscriber não precisa de filesystem além dos secrets
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        # Acesso read-only ao arquivo de chave (sops decripta antes do start)
        ReadOnlyPaths = [ cfg.signingKeyFile ];
      };
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      description = "Neoland ledger subscriber daemon";
    };
    users.groups.${cfg.user} = { };
  };
}
