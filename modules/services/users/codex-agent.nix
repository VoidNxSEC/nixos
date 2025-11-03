{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.users.codex-agent;

  defaultCommand = [
    "${pkgs.codex}/bin/codex"
    "agent"
    "serve"
    "--config"
    cfg.configFile
  ];

  execCommand = if cfg.execCommand == [ ] then defaultCommand else cfg.execCommand;

  commandString = concatStringsSep " " (map escapeShellArg execCommand);

  runScript = pkgs.writeShellScript "codex-agent-service" ''
    export CODEX_AGENT_HOME=${escapeShellArg cfg.homeDirectory}
    export CODEX_AGENT_WORKDIR=${escapeShellArg cfg.workDirectory}
    exec ${commandString}
  '';
in
{
  options.kernelcore.services.users.codex-agent = {
    enable = mkEnableOption "Enable Codex agent user and systemd service";

    userName = mkOption {
      type = types.str;
      default = "codex";
      description = "System user that owns the Codex agent service.";
    };

    homeDirectory = mkOption {
      type = types.str;
      default = "/var/lib/codex";
      description = "Home directory managed for the Codex agent user.";
    };

    workDirectory = mkOption {
      type = types.str;
      default = "/var/lib/codex/agents";
      description = "Working directory used by the Codex agent service.";
    };

    configFile = mkOption {
      type = types.str;
      default = "/etc/codex/agents.toml";
      description = "Configuration file passed to the Codex agent command.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional EnvironmentFile consumed by systemd for secrets.";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra environment variables injected into the service.";
    };

    execCommand = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Override the command executed by the Codex agent service.
        Leave empty to use the built-in `codex agent serve --config …` invocation.
      '';
    };

    wantedBy = mkOption {
      type = types.listOf types.str;
      default = [ "multi-user.target" ];
      description = "Targets that want the Codex agent service.";
    };
  };

  config = mkIf cfg.enable {
    users.groups.${cfg.userName} = { };

    users.users.${cfg.userName} = {
      isSystemUser = true;
      group = cfg.userName;
      home = cfg.homeDirectory;
      createHome = true;
      description = "Codex CLI automation user";
      shell = pkgs.bash;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.homeDirectory} 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/logs 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.workDirectory} 0750 ${cfg.userName} ${cfg.userName} -"
    ];

    systemd.services.codex-agent = {
      description = "Codex Agents Service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = cfg.wantedBy;

      environment = {
        CODEX_AGENT_USER = cfg.userName;
        CODEX_AGENT_HOME = cfg.homeDirectory;
        CODEX_AGENT_WORKDIR = cfg.workDirectory;
      }
      // cfg.extraEnvironment;

      path = with pkgs; [
        codex
        git
        nix
        coreutils
        findutils
      ];

      serviceConfig = {
        Type = "simple";
        User = cfg.userName;
        Group = cfg.userName;
        WorkingDirectory = cfg.workDirectory;
        ExecStart = runScript;
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
      }
      // optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };
  };
}
