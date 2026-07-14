# Laptop Defense — mcp-log-extract: pulls MCP/agent history for evidence.
# Part of the flake.nix split; see ../flake.nix.
{ pkgs }:

pkgs.writeShellApplication {
  name = "mcp-log-extract";
  runtimeInputs = with pkgs; [
    curl
    jq
    sqlite
  ];

  text = ''
            set -e

            OUTPUT_DIR="/tmp/mcp-evidence-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$OUTPUT_DIR"

            echo "🔍 Extracting MCP knowledge database..."
            echo ""

            # SQLite local knowledge database
            if [ -f "/var/lib/mcp-knowledge/knowledge.db" ]; then
              echo "📂 Found MCP knowledge database"

              sqlite3 /var/lib/mcp-knowledge/knowledge.db <<'SQL' > "$OUTPUT_DIR/recent-knowledge.json"
    SELECT json_group_array(
      json_object(
        'id', id,
        'timestamp', timestamp,
        'entry_type', entry_type,
        'content', content,
        'tags', tags
      )
    )
    FROM knowledge_entries
    WHERE timestamp > datetime('now', '-7 days')
    ORDER BY timestamp DESC;
    SQL

              echo "✅ Extracted recent knowledge entries"

              # Extract rebuild/thermal related
              sqlite3 /var/lib/mcp-knowledge/knowledge.db <<'SQL' > "$OUTPUT_DIR/rebuild-knowledge.json"
    SELECT json_group_array(
      json_object(
        'id', id,
        'timestamp', timestamp,
        'entry_type', entry_type,
        'content', substr(content, 1, 200)
      )
    )
    FROM knowledge_entries
    WHERE content LIKE '%rebuild%' OR content LIKE '%thermal%' OR content LIKE '%freeze%'
    ORDER BY timestamp DESC
    LIMIT 50;
    SQL

              echo "✅ Extracted rebuild/thermal related entries"
            else
              echo "⚠️  MCP knowledge database not found"
            fi

            # Parse for relevant snippets
            echo ""
            echo "📊 Analyzing knowledge base for evidence..."

            if [ -f "$OUTPUT_DIR/rebuild-knowledge.json" ]; then
              jq -r '.[] | select(.content | contains("panic") or contains("freeze") or contains("thermal")) | .id' \
                "$OUTPUT_DIR/rebuild-knowledge.json" > "$OUTPUT_DIR/relevant-entry-ids.txt" 2>/dev/null || true
            fi

            echo "✅ Evidence extracted to: $OUTPUT_DIR"

            tar czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
            echo "📦 Archive: $OUTPUT_DIR.tar.gz"
  '';
}
