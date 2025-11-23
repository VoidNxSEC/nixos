{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# MCP (Model Context Protocol) Aliases
# ============================================================
# Helper aliases para trabalhar com MCP Knowledge System
# Script principal: /etc/nixos/scripts/mcp-helper.sh
# Documentação: /etc/nixos/docs/MCP-QUICK-REFERENCE.md

{
  environment.shellAliases = {
    # ========================================
    # MCP Session Management
    # ========================================

    # Listar sessões recentes
    "mcp-sessions" = "bash /etc/nixos/scripts/mcp-helper.sh sessions";
    "mcps" = "bash /etc/nixos/scripts/mcp-helper.sh sessions";

    # Carregar sessão (requires session_id as argument)
    "mcp-load" = "bash /etc/nixos/scripts/mcp-helper.sh session-load";
    "mcpl" = "bash /etc/nixos/scripts/mcp-helper.sh session-load";

    # ========================================
    # MCP Knowledge Search
    # ========================================

    # Buscar no knowledge base
    "mcp-search" = "bash /etc/nixos/scripts/mcp-helper.sh search";
    "mcpf" = "bash /etc/nixos/scripts/mcp-helper.sh search";

    # Ver conhecimento recente
    "mcp-recent" = "bash /etc/nixos/scripts/mcp-helper.sh recent";
    "mcpr" = "bash /etc/nixos/scripts/mcp-helper.sh recent";

    # ========================================
    # MCP Database Management
    # ========================================

    # Info sobre database
    "mcp-db" = "bash /etc/nixos/scripts/mcp-helper.sh db-info";
    "mcpdb" = "bash /etc/nixos/scripts/mcp-helper.sh db-info";

    # Backup do knowledge database
    "mcp-backup" = "bash /etc/nixos/scripts/mcp-helper.sh db-backup";
    "mcpb" = "bash /etc/nixos/scripts/mcp-helper.sh db-backup";

    # Query SQL direta (avançado)
    "mcp-query" = "bash /etc/nixos/scripts/mcp-helper.sh db-query";

    # ========================================
    # MCP System Health
    # ========================================

    # Verificar saúde do MCP server
    "mcp-health" = "bash /etc/nixos/scripts/mcp-helper.sh health";
    "mcph" = "bash /etc/nixos/scripts/mcp-helper.sh health";

    # Mostrar configuração MCP
    "mcp-config" = "bash /etc/nixos/scripts/mcp-helper.sh config";
    "mcpc" = "bash /etc/nixos/scripts/mcp-helper.sh config";

    # ========================================
    # MCP Help & Documentation
    # ========================================

    # Help do mcp-helper
    "mcp-help" = "bash /etc/nixos/scripts/mcp-helper.sh help";
    "mcphelp" = "bash /etc/nixos/scripts/mcp-helper.sh help";

    # Abrir documentação (requer editor)
    "mcp-docs" = "cat /etc/nixos/docs/MCP-QUICK-REFERENCE.md";

    # ========================================
    # MCP Quick Access (atalhos ultra-curtos)
    # ========================================

    # m = mcp (namespace)
    "ms" = "bash /etc/nixos/scripts/mcp-helper.sh sessions"; # sessions
    "mr" = "bash /etc/nixos/scripts/mcp-helper.sh recent 20"; # recent
    "mi" = "bash /etc/nixos/scripts/mcp-helper.sh db-info"; # info
    "mh" = "bash /etc/nixos/scripts/mcp-helper.sh health"; # health

    # ========================================
    # Database Direct Access (SQLite)
    # ========================================

    # Abrir database no sqlite3 (shell interativo)
    "mcp-sqlite" = "sqlite3 /var/lib/mcp-knowledge/knowledge.db";

    # Ver schema do database
    "mcp-schema" = "sqlite3 /var/lib/mcp-knowledge/knowledge.db '.schema'";

    # ========================================
    # Workflow Helpers
    # ========================================

    # Quick session summary (últimas 5 sessões)
    "mcp-quick" = "bash /etc/nixos/scripts/mcp-helper.sh sessions 5";

    # Quick knowledge summary (últimas 10 entradas)
    "mcp-last" = "bash /etc/nixos/scripts/mcp-helper.sh recent 10";

    # Estatísticas completas
    "mcp-stats" = "bash /etc/nixos/scripts/mcp-helper.sh db-info";
  };

  # ========================================
  # Shell Initialization
  # ========================================
  # Mensagem informativa ao abrir shell (opcional)

  environment.interactiveShellInit = ''
    # MCP Helper disponível
    # Para ver comandos: mcp-help ou mcphelp
  '';
}
