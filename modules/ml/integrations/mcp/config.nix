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
    agentCfg:
    pkgs.runCommand "mcp-config.json" {
      nativeBuildInputs = [ pkgs.jq ];
      jsonContent = builtins.toJSON {
        mcpServers = {
          securellm-bridge = {
            command = "${pkgs.nodejs}/bin/node";
            args = [ "${cfg.mcpServerPath}/build/src/index.js" ];
            env = {
              PROJECT_ROOT = agentCfg.projectRoot;
              KNOWLEDGE_DB_PATH = cfg.knowledgeDbPath;
              ENABLE_KNOWLEDGE = "true";
            } // agentCfg.extraEnv;
          };
        };
      };
      passAsFile = [ "jsonContent" ];
    } ''
      jq . "$jsonContentPath" > $out
    '';

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

            extraEnv = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Extra environment variables (e.g. API keys)";
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
    # NOTE: Users must manually add themselves to mcp-shared group in their user configuration
    # Example: extraGroups = [ "mcp-shared" ];
    users.groups.mcp-shared = { };

    # Setup knowledge database and agent configs
    systemd.tmpfiles.rules = [
      # Knowledge DB directory and file (create if missing)
      "d /var/lib/mcp-knowledge 0770 root mcp-shared -"
      "f ${cfg.knowledgeDbPath} 0660 root mcp-shared -"
      # Fix ownership/permissions if the directory or DB already exist (handles legacy mcp-shar group)
      "z /var/lib/mcp-knowledge 0770 root mcp-shared -"
      "z ${cfg.knowledgeDbPath} 0660 root mcp-shared -"
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
          "L+ ${agentCfg.configPath} - - - - ${generateMcpConfig agentCfg}"
        ]
      ) cfg.agents
    ));

    # Repair legacy permissions/ownership on activation (handles mcp-shar -> mcp-shared)
    system.activationScripts.mcpKnowledgePerms = ''
      set -e
      db_dir=${dirOf cfg.knowledgeDbPath}
      if [ -d "$db_dir" ]; then
        chown root:mcp-shared "$db_dir" || true
        chmod 0770 "$db_dir" || true
      fi
      for f in "${cfg.knowledgeDbPath}" "$db_dir/knowledge.db-wal" "$db_dir/knowledge.db-shm"; do
        if [ -e "$f" ]; then
          chown root:mcp-shared "$f" || true
          chmod 0660 "$f" || true
        fi
      done
    '';
  };
}
