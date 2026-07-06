{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.users.codex-agent;

  tarCodexPackage =
    if config.kernelcore.packages.tar.resolvedPackages ? codex then
      config.kernelcore.packages.tar.resolvedPackages.codex
    else
      null;

  packageDefault = if tarCodexPackage != null then tarCodexPackage else pkgs.codex;

  codexBinary = "${cfg.package}/bin/${cfg.binaryName}";

  defaultCommand = [
    codexBinary
    "agent"
    "serve"
    "--config"
    cfg.configFile
  ];

  fallbackCommand = [
    codexBinary
    "mcp-server"
  ];

  commandString = cmds: concatStringsSep " " (map escapeShellArg cmds);

  runScript = pkgs.writeShellScript "codex-agent-service" ''
    set -euo pipefail

    export CODEX_AGENT_HOME=${escapeShellArg cfg.homeDirectory}
    export CODEX_AGENT_WORKDIR=${escapeShellArg cfg.workDirectory}

    if [ "${boolToString (cfg.execCommand != [ ])}" = "true" ]; then
      exec ${commandString cfg.execCommand}
    fi

    if ${codexBinary} --help 2>/dev/null | grep -Fq "agent serve"; then
      exec ${commandString defaultCommand}
    fi

    if ${codexBinary} --help 2>/dev/null | grep -Fq "mcp-server"; then
      echo "codex-agent: 'codex agent serve' unavailable, falling back to 'codex mcp-server'" >&2
      exec ${commandString fallbackCommand}
    fi

    echo "codex-agent: no supported codex subcommand available (expected 'agent serve' or 'mcp-server')" >&2
    exit 1
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

    package = mkOption {
      type = types.package;
      default = packageDefault;
      description = "Derivation that provides the Codex CLI binary executed by the agent.";
    };

    binaryName = mkOption {
      type = types.str;
      default = "codex";
      description = "Binary name within the package used for ExecStart.";
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
        Leave empty to prefer `codex agent serve --config …` when available, or
        fall back to `codex mcp-server` on newer Codex CLI versions.
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
      extraGroups = [ "mcp-shared" ]; # For shared knowledge DB access
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
        # MCP Server configuration path - enables codex to discover and use MCP tools
        MCP_CONFIG_PATH = "${cfg.homeDirectory}/.codex/mcp.json";
      }
      // cfg.extraEnvironment;

      path = [
        cfg.package
        pkgs.nodejs_22 # Required for MCP server stdio connection
      ]
      ++ (with pkgs; [
        git
        nix
        coreutils
        findutils
      ]);

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
