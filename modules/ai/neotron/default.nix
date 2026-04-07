# Neotron — Guardrails + Agent Orchestration
# Status: stub (implementação futura)
# Papel: interceptar e validar decisões do pipeline multi-agent (guardrails)

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neotron;
in
{
  options.services.neotron = {
    enable = lib.mkEnableOption "Neotron guardrails and agent orchestration";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8010;
    };

    # Guardrail policies (declarative, versionable)
    guardrails = {
      blockOnHighRisk = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Block pipeline decisions when Junior risk_level=high and no Architect review";
      };
      requireArchitectOnHigh = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Force Architect stage when risk_level=high regardless of Senior decision";
      };
      maxDeferralChain = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Max consecutive defer decisions before escalating to human review";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "neotron";
    };
  };

  config = lib.mkIf cfg.enable {
    # Placeholder — service definition added when neotron is implemented
    warnings = [ "services.neotron is enabled but not yet implemented. Guardrails will be inactive." ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };
  };
}
