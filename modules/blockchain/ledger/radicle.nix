# ═══════════════════════════════════════════════════════════════
# ADR LEDGER — Radicle (git p2p)
# ═══════════════════════════════════════════════════════════════
# Consolida três versões que existiam no ecossistema:
#
#   adr-ledger/nix/iam/radicle.nix   services.radicle-node — órfão, e
#                                    NÃO BUILDA: sha256 = lib.fakeSha256,
#                                    compilando radicle-node 1.1.0 do fonte
#   voidnxchain/radicle-demo.nix     services.radicle-demo — funciona,
#                                    usa pkgs.radicle, node + httpd
#   nixpkgs                          radicle-node 1.9.1 + radicle-httpd
#
# Aqui: pkgs.radicle-node e pkgs.radicle-httpd do nixpkgs. O build
# from-source é descartado — era oito versões menores atrás e não tinha
# hash real. Nota: NÃO existe atributo pkgs.radicle neste nixpkgs; os
# pacotes são separados. voidnxchain/radicle-demo.nix usa pkgs.radicle e
# portanto também não avalia.
#
# Substrato do forge definido pelo ADR-0089.
# Decisão: ADR-0090 (adr-ledger).
#
# Opções:
#   kernelcore.blockchain.ledger.radicle.enable       = true/false
#   kernelcore.blockchain.ledger.radicle.p2pPort      = 8776
#   kernelcore.blockchain.ledger.radicle.httpd.enable = true/false
# ═══════════════════════════════════════════════════════════════

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.blockchain.ledger.radicle;
in
{
  options.kernelcore.blockchain.ledger.radicle = {
    enable = lib.mkEnableOption "nó Radicle para sync de policies e patches do ledger";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.radicle-node;
      defaultText = lib.literalExpression "pkgs.radicle-node";
      description = "Pacote do nó Radicle (rad, radicle-node).";
    };

    radHome = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/adr-ledger/radicle";
      description = "RAD_HOME — identidade e repositórios replicados.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "agent-governance";
      description = "Usuário do nó. Deve existir — ver services.adr-ledger-agents.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "adr-admin";
    };

    p2pPort = lib.mkOption {
      type = lib.types.port;
      default = 8776;
      description = "Porta p2p do radicle-node.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Endereço de escuta p2p.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Abre a porta p2p no firewall. Default false — o módulo de origem
        abria incondicionalmente.
      '';
    };

    extraReadWritePaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ "/var/lib/adr-ledger/policies" ];
      description = "Caminhos graváveis além do RAD_HOME.";
    };

    httpd = {
      enable = lib.mkEnableOption "radicle-httpd (API REST e UI local)";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.radicle-httpd;
        defaultText = lib.literalExpression "pkgs.radicle-httpd";
        description = "Pacote do radicle-httpd — separado do nó no nixpkgs.";
      };

      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Mantido em loopback por padrão.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.httpd.enable cfg.httpd.package;

    systemd.tmpfiles.rules = [
      "d ${cfg.radHome} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.radicle-node = {
      description = "Radicle Node — ADR Ledger policy sync";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/radicle-node --listen ${cfg.listenAddress}:${toString cfg.p2pPort}";
        User = cfg.user;
        Group = cfg.group;

        Environment = [
          "RAD_HOME=${cfg.radHome}"
          "RAD_PASSPHRASE=" # chave sem passphrase, protegida por permissão de filesystem
        ];

        # Hardening — preservado do módulo de origem
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [ cfg.radHome ] ++ cfg.extraReadWritePaths;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.radicle-httpd = lib.mkIf cfg.httpd.enable {
      description = "Radicle HTTP daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "radicle-node.service" ];
      wants = [ "radicle-node.service" ];

      serviceConfig = {
        ExecStart = "${cfg.httpd.package}/bin/radicle-httpd --listen ${cfg.httpd.listenAddress}:${toString cfg.httpd.port}";
        User = cfg.user;
        Group = cfg.group;
        Environment = [ "RAD_HOME=${cfg.radHome}" ];

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [ cfg.radHome ];

        Restart = "on-failure";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.p2pPort ];
  };
}
