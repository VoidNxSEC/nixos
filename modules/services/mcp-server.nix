{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.securellm-mcp;

  # Generate .mcp.json configuration
  mcpConfig = {
    mcpServers = {
      securellm-bridge = {
        command = "nix";
        args = [
          "run"
          "${config.users.users.${cfg.user}.home}/.config/nixpkgs#securellm-mcp"
          "--"
        ];
        env = {
          KNOWLEDGE_DB_PATH = "${cfg.dataDir}/knowledge.db";
          ENABLE_KNOWLEDGE = "true";
        };
      };
    };
  };

in
{
  options.services.securellm-mcp = {
    enable = mkEnableOption "SecureLLM Bridge MCP Server";

    user = mkOption {
      type = types.str;
      default = "kernelcore";
      description = "User to run the MCP server as";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/mcp-knowledge";
      description = "Directory for MCP knowledge database";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.securellm-mcp or (throw "securellm-mcp package not found in pkgs");
      description = "The SecureLLM MCP package to use";
    };

    autoConfigureClaudeDesktop = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically configure Claude Desktop with .mcp.json";
    };
  };

  config = mkIf cfg.enable {
    # Install the MCP server package system-wide
    environment.systemPackages = [
      cfg.package

      # Helper script to manage MCP
      (pkgs.writeShellScriptBin "mcp-server" ''
        #!/usr/bin/env bash
        # SecureLLM MCP Server Manager

        CYAN='\033[0;36m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        RED='\033[0;31m'
        BOLD='\033[1m'
        NC='\033[0m'

        show_help() {
          cat << EOF
        ╔══════════════════════════════════════════════════════════════╗
        ║         SecureLLM MCP Server - System Manager                ║
        ╚══════════════════════════════════════════════════════════════╝

        ''${CYAN}USAGE:''${NC}
          mcp-server <command>

        ''${YELLOW}COMMANDS:''${NC}

          ''${BOLD}status''${NC}        - Check MCP server status and configuration
          ''${BOLD}test''${NC}          - Test MCP server connectivity
          ''${BOLD}config''${NC}        - Show current MCP configuration
          ''${BOLD}db-info''${NC}       - Show knowledge database information
          ''${BOLD}db-backup''${NC}     - Backup knowledge database
          ''${BOLD}rebuild''${NC}       - Rebuild MCP server package
          ''${BOLD}version''${NC}       - Show MCP server version

        ''${CYAN}EXAMPLES:''${NC}

          # Check status
          mcp-server status

          # Test connection
          mcp-server test

          # Backup database
          mcp-server db-backup

        ''${CYAN}LOCATIONS:''${NC}

          Package:   ${cfg.package}
          Binary:    ${cfg.package}/bin/securellm-mcp
          Database:  ${cfg.dataDir}/knowledge.db
          Config:    ~/.config/Claude/.mcp.json

        EOF
        }

        case "''${1:-help}" in
          status)
            echo -e "''${CYAN}''${BOLD}SecureLLM MCP Server Status''${NC}"
            echo ""
            echo -e "''${GREEN}✓ Package installed''${NC}: ${cfg.package}"
            echo -e "''${GREEN}✓ Binary available''${NC}: $(which securellm-mcp)"
            echo ""
            if [ -f "${cfg.dataDir}/knowledge.db" ]; then
              echo -e "''${GREEN}✓ Knowledge DB exists''${NC}: ${cfg.dataDir}/knowledge.db"
              echo "  Size: $(du -h ${cfg.dataDir}/knowledge.db | cut -f1)"
            else
              echo -e "''${YELLOW}⚠ Knowledge DB not created yet''${NC}"
            fi
            echo ""
            if [ -f "$HOME/.config/Claude/.mcp.json" ]; then
              echo -e "''${GREEN}✓ Claude Desktop configured''${NC}"
            else
              echo -e "''${YELLOW}⚠ Claude Desktop not configured''${NC}"
            fi
            ;;

          test)
            echo -e "''${CYAN}Testing MCP Server...''${NC}"
            echo ""
            if command -v securellm-mcp &> /dev/null; then
              echo -e "''${GREEN}✓ Command available''${NC}: securellm-mcp"
              echo ""
              echo "Note: Full functionality test requires Claude Desktop connection"
            else
              echo -e "''${RED}✗ Command not found''${NC}"
              exit 1
            fi
            ;;

          config)
            echo -e "''${CYAN}Current MCP Configuration:''${NC}"
            echo ""
            if [ -f "$HOME/.config/Claude/.mcp.json" ]; then
              cat "$HOME/.config/Claude/.mcp.json" | ${pkgs.jq}/bin/jq .
            else
              echo -e "''${YELLOW}No configuration found''${NC}"
              echo "Expected location: $HOME/.config/Claude/.mcp.json"
            fi
            ;;

          db-info)
            if [ -f "${cfg.dataDir}/knowledge.db" ]; then
              echo -e "''${CYAN}Knowledge Database Info:''${NC}"
              echo ""
              echo "Location: ${cfg.dataDir}/knowledge.db"
              echo "Size: $(du -h ${cfg.dataDir}/knowledge.db | cut -f1)"
              echo ""
              ${pkgs.sqlite}/bin/sqlite3 ${cfg.dataDir}/knowledge.db \
                "SELECT 'Sessions: ' || COUNT(*) FROM sessions UNION ALL \
                 SELECT 'Entries: ' || COUNT(*) FROM knowledge_entries;"
            else
              echo -e "''${YELLOW}Database not found''${NC}: ${cfg.dataDir}/knowledge.db"
            fi
            ;;

          db-backup)
            BACKUP_FILE="${cfg.dataDir}/knowledge-backup-$(date +%Y%m%d-%H%M%S).db"
            if [ -f "${cfg.dataDir}/knowledge.db" ]; then
              cp "${cfg.dataDir}/knowledge.db" "$BACKUP_FILE"
              echo -e "''${GREEN}✓ Backup created''${NC}: $BACKUP_FILE"
            else
              echo -e "''${RED}✗ Database not found''${NC}"
              exit 1
            fi
            ;;

          rebuild)
            echo -e "''${CYAN}Rebuilding MCP Server...''${NC}"
            cd /etc/nixos && nix build .#securellm-mcp
            echo -e "''${GREEN}✓ Build complete''${NC}"
            echo "Run 'sudo nixos-rebuild switch' to update system"
            ;;

          version)
            echo "SecureLLM MCP Server"
            echo "Package: ${cfg.package}"
            ;;

          help|--help|-h)
            show_help
            ;;

          *)
            echo -e "''${RED}Unknown command: $1''${NC}"
            echo ""
            show_help
            exit 1
            ;;
        esac
      '')
    ];

    # Create data directory with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${cfg.user} users -"
    ];

    # Configure Claude Desktop automatically
    environment.etc = mkIf cfg.autoConfigureClaudeDesktop {
      "skel/.config/Claude/.mcp.json" = {
        text = builtins.toJSON mcpConfig;
        mode = "0644";
      };
    };

    # Add shell aliases for convenience
    environment.shellAliases = {
      mcp = "mcp-server";
      mcp-status = "mcp-server status";
      mcp-test = "mcp-server test";
    };

    # Shell initialization message
    environment.interactiveShellInit = ''
      # MCP Server available: run 'mcp-server' for help
    '';
  };
}
