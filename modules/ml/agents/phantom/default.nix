# Phantom — Security Scan / Secret Detection
# Intercepta outputs do pipeline e escaneia por secrets/PII antes de persistir

{ config, lib, ... }:

let
  cfg = config.services.phantom;
in
{
  options.services.phantom = {
    enable = lib.mkEnableOption "Phantom security scanner";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8008;
    };

    scanTargets = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "pipeline-output"
          "checkpoints"
          "rag-docs"
        ]
      );
      default = [
        "pipeline-output"
        "checkpoints"
      ];
      description = "What to scan: agent pipeline outputs, checkpoint ADRs, RAG documents";
    };

    blockOnDetection = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Block pipeline progression when secrets/PII detected";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "phantom";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ "services.phantom: stub — implement service before enabling." ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };
  };
}
