#!/usr/bin/env bash
# MCP Knowledge Helper - Comandos rápidos para interagir com MCP
# Uso: source este script ou chame funções diretamente

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Funções Helper
# ============================================================================

mcp_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                     MCP Knowledge Helper - v1.0.0                        ║
╚══════════════════════════════════════════════════════════════════════════╝

📚 COMANDOS DISPONÍVEIS:

  Sessions:
    mcp-sessions              Lista últimas 20 sessões
    mcp-session-load <ID>     Carrega sessão específica
    mcp-session-create <msg>  Cria nova sessão

  Knowledge:
    mcp-search <query>        Busca no knowledge base
    mcp-recent [N]            Mostra últimas N entradas (padrão: 20)
    mcp-save <tipo> <msg>     Salva conhecimento
                              Tipos: insight, decision, code, reference

  Database:
    mcp-db-info              Info sobre database
    mcp-db-backup            Backup do database
    mcp-db-query <SQL>       Query SQL direta (avançado)

  System:
    mcp-health               Verifica saúde do MCP server
    mcp-config               Mostra configuração
    mcp-help                 Este help

💡 EXEMPLOS:

  # Ver sessões recentes
  mcp-sessions

  # Carregar sessão específica
  mcp-session-load sess_c18130d20c39e3ba0ca49120780e2259

  # Buscar conhecimento
  mcp-search "refatoramento ML"

  # Ver conhecimento recente
  mcp-recent 10

  # Backup database
  mcp-db-backup

📚 Documentação completa: /etc/nixos/docs/MCP-QUICK-REFERENCE.md

EOF
}

# ============================================================================
# Session Commands
# ============================================================================

mcp-sessions() {
    local limit="${1:-20}"
    echo -e "${BLUE}📋 Últimas $limit sessões MCP:${NC}\n"

    sqlite3 /var/lib/mcp-knowledge/knowledge.db << EOF
.mode column
.headers on
.width 40 20 50
SELECT
    session_id,
    created_at,
    COALESCE(summary, '(sem resumo)') as summary
FROM sessions
ORDER BY created_at DESC
LIMIT $limit;
EOF
}

mcp-session-load() {
    local session_id="$1"

    if [[ -z "$session_id" ]]; then
        echo -e "${RED}❌ Erro: Forneça o session_id${NC}"
        echo "Uso: mcp-session-load <session_id>"
        return 1
    fi

    echo -e "${BLUE}📂 Carregando sessão: $session_id${NC}\n"

    sqlite3 /var/lib/mcp-knowledge/knowledge.db << EOF
.mode column
.headers on

-- Session info
SELECT '=== SESSION INFO ===' as '';
SELECT
    session_id,
    created_at,
    COALESCE(summary, '(sem resumo)') as summary
FROM sessions
WHERE session_id = '$session_id';

-- Entries
SELECT '' as '';
SELECT '=== ENTRIES ===' as '';
SELECT
    id,
    entry_type,
    priority,
    timestamp,
    substr(content, 1, 80) || '...' as content_preview
FROM knowledge_entries
WHERE session_id = '$session_id'
ORDER BY timestamp ASC;
EOF

    echo -e "\n${GREEN}✅ Para ver conteúdo completo, peça ao Claude:${NC}"
    echo "   Claude, carregue a sessão $session_id"
}

mcp-session-create() {
    local summary="$*"

    if [[ -z "$summary" ]]; then
        echo -e "${YELLOW}⚠️  Criando sessão sem resumo${NC}"
        summary="Nova sessão $(date +%Y-%m-%d)"
    fi

    echo -e "${GREEN}✅ Para criar sessão, peça ao Claude:${NC}"
    echo "   Claude, crie uma nova sessão MCP: \"$summary\""
}

# ============================================================================
# Knowledge Commands
# ============================================================================

mcp-search() {
    local query="$*"

    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Erro: Forneça uma query de busca${NC}"
        echo "Uso: mcp-search <palavras-chave>"
        return 1
    fi

    echo -e "${BLUE}🔍 Buscando: \"$query\"${NC}\n"

    # Busca simples (FTS5 pode ter issues com caracteres especiais)
    sqlite3 /var/lib/mcp-knowledge/knowledge.db << EOF
.mode column
.headers on
.width 10 15 12 60

SELECT
    id,
    session_id,
    entry_type,
    substr(content, 1, 60) || '...' as content_preview
FROM knowledge_entries
WHERE content LIKE '%$query%'
ORDER BY timestamp DESC
LIMIT 10;
EOF

    echo -e "\n${GREEN}💡 Para busca completa via FTS5, peça ao Claude:${NC}"
    echo "   Claude, busque no knowledge: \"$query\""
}

mcp-recent() {
    local limit="${1:-20}"
    echo -e "${BLUE}📚 Últimas $limit entradas de conhecimento:${NC}\n"

    sqlite3 /var/lib/mcp-knowledge/knowledge.db << EOF
.mode column
.headers on
.width 10 40 15 12 60

SELECT
    id,
    session_id,
    entry_type,
    priority,
    substr(content, 1, 60) || '...' as content_preview
FROM knowledge_entries
ORDER BY timestamp DESC
LIMIT $limit;
EOF
}

mcp-save() {
    local tipo="$1"
    shift
    local conteudo="$*"

    if [[ -z "$tipo" ]] || [[ -z "$conteudo" ]]; then
        echo -e "${RED}❌ Erro: Forneça tipo e conteúdo${NC}"
        echo "Uso: mcp-save <tipo> <conteúdo>"
        echo "Tipos: insight, decision, code, reference, question, answer"
        return 1
    fi

    echo -e "${GREEN}✅ Para salvar, peça ao Claude:${NC}"
    echo "   Claude, salve este $tipo: \"$conteudo\""
}

# ============================================================================
# Database Commands
# ============================================================================

mcp-db-info() {
    echo -e "${BLUE}🗄️  Informações do Database MCP:${NC}\n"

    local db_path="/var/lib/mcp-knowledge/knowledge.db"

    if [[ ! -f "$db_path" ]]; then
        echo -e "${RED}❌ Database não encontrado: $db_path${NC}"
        return 1
    fi

    echo "📍 Localização: $db_path"
    echo "📏 Tamanho: $(du -h "$db_path" | cut -f1)"
    echo "📅 Modificado: $(stat -c %y "$db_path" | cut -d'.' -f1)"
    echo ""

    sqlite3 "$db_path" << 'EOF'
.mode column
.headers on

SELECT 'ESTATÍSTICAS' as '';
SELECT
    (SELECT COUNT(*) FROM sessions) as total_sessoes,
    (SELECT COUNT(*) FROM knowledge_entries) as total_entradas,
    (SELECT COUNT(DISTINCT session_id) FROM knowledge_entries) as sessoes_com_entradas;

SELECT '' as '';
SELECT 'ENTRADAS POR TIPO' as '';
SELECT
    entry_type,
    COUNT(*) as quantidade
FROM knowledge_entries
GROUP BY entry_type
ORDER BY quantidade DESC;

SELECT '' as '';
SELECT 'ENTRADAS POR PRIORIDADE' as '';
SELECT
    priority,
    COUNT(*) as quantidade
FROM knowledge_entries
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
        ELSE 4
    END;
EOF
}

mcp-db-backup() {
    local db_path="/var/lib/mcp-knowledge/knowledge.db"
    local backup_dir="/backup/mcp-knowledge"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$backup_dir/knowledge-$timestamp.db"

    echo -e "${BLUE}💾 Criando backup do MCP Knowledge Database...${NC}\n"

    if [[ ! -f "$db_path" ]]; then
        echo -e "${RED}❌ Database não encontrado: $db_path${NC}"
        return 1
    fi

    # Criar diretório de backup se não existir
    sudo mkdir -p "$backup_dir"

    # Backup
    sudo cp "$db_path" "$backup_file"

    echo -e "${GREEN}✅ Backup criado:${NC}"
    echo "   $backup_file"
    echo "   Tamanho: $(du -h "$backup_file" | cut -f1)"
    echo ""

    # Listar backups existentes
    echo -e "${BLUE}📚 Backups existentes:${NC}"
    ls -lht "$backup_dir" | head -6
}

mcp-db-query() {
    local query="$*"

    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Erro: Forneça uma query SQL${NC}"
        echo "Uso: mcp-db-query <SQL>"
        return 1
    fi

    echo -e "${BLUE}🔧 Executando query:${NC} $query\n"

    sqlite3 -column -header /var/lib/mcp-knowledge/knowledge.db "$query"
}

# ============================================================================
# System Commands
# ============================================================================

mcp-health() {
    echo -e "${BLUE}🏥 Verificando saúde do MCP Server...${NC}\n"

    if [[ -f /etc/nixos/scripts/mcp-health-check.sh ]]; then
        bash /etc/nixos/scripts/mcp-health-check.sh
    else
        echo -e "${YELLOW}⚠️  Script mcp-health-check.sh não encontrado${NC}"
        echo "Verificando manualmente..."

        # Check database
        if [[ -f /var/lib/mcp-knowledge/knowledge.db ]]; then
            echo -e "${GREEN}✅${NC} Database: OK"
        else
            echo -e "${RED}❌${NC} Database: NOT FOUND"
        fi

        # Check MCP server binary
        if command -v securellm-mcp &>/dev/null; then
            echo -e "${GREEN}✅${NC} MCP Server: OK ($(which securellm-mcp))"
        else
            echo -e "${RED}❌${NC} MCP Server: NOT FOUND"
        fi
    fi
}

mcp-config() {
    echo -e "${BLUE}⚙️  Configuração MCP:${NC}\n"

    local config_file="$HOME/.config/VSCodium/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"

    if [[ -f "$config_file" ]]; then
        echo "📍 Config: $config_file"
        echo ""
        cat "$config_file" | jq '.' 2>/dev/null || cat "$config_file"
    else
        echo -e "${YELLOW}⚠️  Config não encontrado: $config_file${NC}"
    fi
}

# ============================================================================
# Main
# ============================================================================

# Se executado diretamente (não sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        mcp_help
    else
        command="$1"
        shift

        case "$command" in
            sessions|session-list)
                mcp-sessions "$@"
                ;;
            session-load|load)
                mcp-session-load "$@"
                ;;
            session-create|create)
                mcp-session-create "$@"
                ;;
            search)
                mcp-search "$@"
                ;;
            recent)
                mcp-recent "$@"
                ;;
            save)
                mcp-save "$@"
                ;;
            db-info|info)
                mcp-db-info
                ;;
            db-backup|backup)
                mcp-db-backup
                ;;
            db-query|query)
                mcp-db-query "$@"
                ;;
            health)
                mcp-health
                ;;
            config)
                mcp-config
                ;;
            help|--help|-h)
                mcp_help
                ;;
            *)
                echo -e "${RED}❌ Comando desconhecido: $command${NC}"
                echo ""
                mcp_help
                exit 1
                ;;
        esac
    fi
fi
