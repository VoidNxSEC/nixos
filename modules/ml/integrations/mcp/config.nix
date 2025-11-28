{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.ml.mcp;

  # Template para gerar mcp.json personalizado por agente
  generateMcpConfig =
    projectRoot:
    pkgs.writeText "mcp-config.json" (
      builtins.toJSON {
        mcpServers = {
          securellm-bridge = {
            command = "node";
            args = [ "${cfg.mcpServerPath}/build/src/index.js" ];
            env = {
              PROJECT_ROOT = projectRoot;
              KNOWLEDGE_DB_PATH = cfg.knowledgeDbPath;
              ENABLE_KNOWLEDGE = "true";
            };
          };
        };
      }
    );

in
{
  options.kernelcore.ml.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) configuration";

    mcpServerPath = mkOption {
      type = types.str;
      default = "/etc/nixos/modules/ml/integrations/mcp/server";
      description = "Path to MCP server installation";
    };

    knowledgeDbPath = mkOption {
      type = types.str;
      default = "/var/lib/mcp-knowledge/knowledge.db";
      description = "Path to shared knowledge database";
    };

    agents = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkEnableOption "MCP for this agent";

            projectRoot = mkOption {
              type = types.str;
              description = "Project root directory (workspace) for this agent";
              example = "/home/user/workspace";
            };

            configPath = mkOption {
              type = types.str;
              description = "Path where mcp.json will be installed";
              example = "/home/user/.roo/mcp.json";
            };

            user = mkOption {
              type = types.str;
              description = "System user that owns this agent";
              example = "kernelcore";
            };
          };
        }
      );
      default = { };
      description = "Per-agent MCP configuration";
    };
  };

  config = mkIf cfg.enable {
    # Create shared group for knowledge DB access
    users.groups.mcp-shared = { };
    # Setup knowledge database and agent configs
    systemd.tmpfiles.rules = [
      # Knowledge DB directory and file
      "d /var/lib/mcp-knowledge 0770 root mcp-shared -"
      "f ${cfg.knowledgeDbPath} 0660 root mcp-shared -"
    ]
    ++ (flatten (
      mapAttrsToList (
        name: agentCfg:
        optionals agentCfg.enable [
          # Create workspace directory
          "d ${agentCfg.projectRoot} 0750 ${agentCfg.user} ${agentCfg.user} -"
          # Create config directory (extract directory from configPath)
          "d ${dirOf agentCfg.configPath} 0750 ${agentCfg.user} ${agentCfg.user} -"
          # Install mcp.json as symlink
          "L+ ${agentCfg.configPath} - - - - ${generateMcpConfig agentCfg.projectRoot}"
        ]
      ) cfg.agents
    ));
  };
}
