# ═══════════════════════════════════════════════════════════════
# ADR LEDGER — Secrets (sops-nix)
# ═══════════════════════════════════════════════════════════════
# Adotado de adr-ledger/nix/iam/secrets.nix, que era órfão e tinha
# dois defeitos que impediam a avaliação sob flake:
#
#   1. imports = [ <sops-nix/modules/sops> ]  — sintaxe NIX_PATH,
#      proibida em pure eval. Aqui não é reimportado: o flake deste
#      repositório já carrega sops-nix.nixosModules.sops por host.
#   2. defaultSopsFile = ./secrets/adr-ledger.yaml — caminho que não
#      existe em lugar nenhum do adr-ledger.  `sopsFile` passa a ser
#      opção SEM default: o módulo não avalia sem declaração explícita,
#      em vez de apontar em silêncio para arquivo inexistente.
#
# Decisão: ADR-0090 (adr-ledger).
#
# Opções:
#   kernelcore.blockchain.ledger.secrets.enable   = true/false
#   kernelcore.blockchain.ledger.secrets.sopsFile = <obrigatório>
# ═══════════════════════════════════════════════════════════════

{
  config,
  lib,
  ...
}:

let
  cfg = config.kernelcore.blockchain.ledger.secrets;
in
{
  options.kernelcore.blockchain.ledger.secrets = {
    enable = lib.mkEnableOption "segredos do ADR Ledger via sops-nix";

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Arquivo sops com os segredos do ledger. Obrigatório — sem default
        de propósito, ver cabeçalho do módulo.
      '';
      example = lib.literalExpression "./secrets/adr-ledger.yaml";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sops-nix/key.txt";
      description = "Chave age usada para decriptar.";
    };

    agentTokens = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            owner = lib.mkOption { type = lib.types.str; };
            group = lib.mkOption {
              type = lib.types.str;
              default = "adr-agents";
            };
          };
        }
      );
      default = {
        "agents/drafter/token" = {
          owner = "agent-drafter";
        };
        "agents/reviewer/token" = {
          owner = "agent-reviewer";
        };
        "agents/governance/token" = {
          owner = "agent-governance";
          group = "adr-admin";
        };
      };
      description = "Tokens por agente. Chave = caminho dentro do arquivo sops.";
    };

    signingKey = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Provisiona a chave secp256k1 do ledger-subscriber.";
      };

      path = lib.mkOption {
        type = lib.types.path;
        default = "/run/secrets/audit/signing_key";
        description = ''
          Destino da chave decriptada. Casa com o default de
          kernelcore.ml.neoland.ledgerSubscriber.signingKeyFile.
          Futuro: migrar para hardware (YubiKey / Ledger Nano / HSM).
        '';
      };

      owner = lib.mkOption {
        type = lib.types.str;
        default = "ledger-subscriber";
      };
    };

    opaToken = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Provisiona o bearer token do OPA.";
      };

      owner = lib.mkOption {
        type = lib.types.str;
        default = "agent-governance";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.age.keyFile = cfg.ageKeyFile;

    sops.secrets =
      (lib.mapAttrs (_name: t: {
        inherit (cfg) sopsFile;
        inherit (t) owner group;
        mode = "0400";
      }) cfg.agentTokens)
      // (lib.optionalAttrs cfg.signingKey.enable {
        "audit/signing_key" = {
          inherit (cfg) sopsFile;
          inherit (cfg.signingKey) owner path;
          group = "adr-admin";
          mode = "0400";
        };
      })
      // (lib.optionalAttrs cfg.opaToken.enable {
        "opa/auth_token" = {
          inherit (cfg) sopsFile;
          inherit (cfg.opaToken) owner;
          mode = "0400";
        };
      });
  };
}
