# ML Integrations Layer

External integrations: MCP servers, editor plugins, and development tools.

## Components

### mcp/

Model Context Protocol integration for IDE support.

**Purpose**: Provide AI assistant tools for development (Roo Code, Cline, Claude Desktop).

#### server/

TypeScript MCP server with ML operations and knowledge management.

**Tools Available**:
- **Security**: provider_test, security_audit, rate_limit_check, build_and_test, provider_config_validate, crypto_key_generate
- **Knowledge**: create_session, save_knowledge, search_knowledge, load_session, list_sessions, get_recent_knowledge

**Build**:
```bash
cd /etc/nixos/modules/ml/integrations/mcp/server
npm install
npm run build
```

**Run**:
```bash
node build/index.js
```

**Configuration** (Roo Code/Cline):
```bash
~/.config/VSCodium/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

**Example cline_mcp_settings.json**:
```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "node",
      "args": [
        "/etc/nixos/modules/ml/integrations/mcp/server/build/index.js"
      ],
      "env": {
        "PROJECT_ROOT": "/etc/nixos/modules/ml"
      }
    }
  }
}
```

#### config.nix

MCP configuration module.

**Configuration**:
```nix
kernelcore.ml.mcp = {
  enable = true;
  mcpServerPath = "/etc/nixos/modules/ml/integrations/mcp/server";
  knowledgeDbPath = "/var/lib/mcp-knowledge/knowledge.db";
};
```

**Auto-creates**:
- Knowledge database directory
- MCP server configuration files

#### Knowledge Management

The MCP server includes a SQLite knowledge base with FTS5 search.

**Session Management**:
```typescript
// Create session
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "create_session",
  arguments: {
    summary: "Working on ML modules restructure",
    metadata: { project: "nixos-ml" }
  }
});

// Save knowledge
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "save_knowledge",
  arguments: {
    content: "ML modules reorganized into layers",
    type: "insight",
    tags: ["ml", "restructure"]
  }
});

// Search knowledge
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "search_knowledge",
  arguments: {
    query: "restructure AND ml"
  }
});
```

**Database Schema**:
```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  created_at TEXT,
  summary TEXT,
  metadata TEXT
);

CREATE TABLE knowledge_entries (
  id TEXT PRIMARY KEY,
  session_id TEXT,
  created_at TEXT,
  type TEXT,
  content TEXT,
  tags TEXT,
  metadata TEXT
);

CREATE VIRTUAL TABLE knowledge_fts USING fts5(content);
```

#### Tools Reference

**Security Tools**:
- `provider_test`: Test LLM provider connectivity
- `security_audit`: Run security checks on configuration
- `rate_limit_check`: Check current rate limit status
- `build_and_test`: Build project and run tests
- `provider_config_validate`: Validate provider configuration
- `crypto_key_generate`: Generate TLS certificates

**Knowledge Tools**:
- `create_session`: Create a new knowledge session
- `save_knowledge`: Save information to knowledge base
- `search_knowledge`: Full-text search with boolean operators
- `load_session`: Load previous session context
- `list_sessions`: List recent sessions
- `get_recent_knowledge`: Get recent entries

### neovim/

Neovim integration for ML operations.

**Location**: `integrations/neovim/README.md`

**Planned Features**:
- Inline ML inference
- Model switching from editor
- VRAM monitoring in status line
- Knowledge base search

## Usage

### MCP Server (Cline/Roo Code)

1. **Build Server**:
   ```bash
   cd /etc/nixos/modules/ml/integrations/mcp/server
   npm install
   npm run build
   ```

2. **Configure Cline**:
   ```bash
   mkdir -p ~/.config/VSCodium/User/globalStorage/saoudrizwan.claude-dev/settings/
   # Copy config (see above)
   ```

3. **Test in Cline**:
   - Open VSCodium with Cline extension
   - Use MCP tools in conversation
   - Check MCP server logs

### Knowledge Base

**Create Session**:
```bash
# Via MCP tool in Cline
create_session("Debugging ML offload", {project: "ml"})
```

**Save Insights**:
```bash
save_knowledge("VRAM scheduler needs priority queue", "insight", ["vram", "todo"])
```

**Search**:
```bash
search_knowledge("vram AND scheduler")
```

**Load Session**:
```bash
load_session("session-abc123")
```

## Development

### Adding MCP Tools

1. Create tool in `server/src/tools/my-tool.ts`:
   ```typescript
   export const myTool: Tool = {
     name: "my_tool",
     description: "Does something useful",
     inputSchema: {
       type: "object",
       properties: {
         param1: { type: "string" }
       },
       required: ["param1"]
     }
   };

   export async function handleMyTool(args: any): Promise<ToolResponse> {
     // Implementation
     return {
       content: [{ type: "text", text: "Result" }]
     };
   }
   ```

2. Register in `server/src/index.ts`:
   ```typescript
   import { myTool, handleMyTool } from './tools/my-tool.js';

   server.setRequestHandler(ListToolsRequestSchema, async () => ({
     tools: [myTool, /* ... */]
   }));

   server.setRequestHandler(CallToolRequestSchema, async (request) => {
     if (request.params.name === "my_tool") {
       return await handleMyTool(request.params.arguments);
     }
     // ...
   });
   ```

3. Rebuild and test:
   ```bash
   npm run build
   node build/index.js
   ```

### Testing MCP Server

```bash
# Echo test
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node build/index.js

# Expected output
{"jsonrpc":"2.0","id":1,"result":{"tools":[...]}}
```

## Troubleshooting

### MCP Server Not Found

```bash
# Verify path
ls -la /etc/nixos/modules/ml/integrations/mcp/server/build/index.js

# Check permissions
chmod +x /etc/nixos/modules/ml/integrations/mcp/server/build/index.js
```

### Knowledge Database Errors

```bash
# Check database
sqlite3 /var/lib/mcp-knowledge/knowledge.db ".tables"

# Reset database
rm /var/lib/mcp-knowledge/knowledge.db
# Restart MCP server (will recreate)
```

### Cline Can't Connect

```bash
# Check Cline logs
# VSCodium → Output → Select "Cline" from dropdown

# Verify config
cat ~/.config/VSCodium/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json

# Test server manually
cd /etc/nixos/modules/ml/integrations/mcp/server
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node build/index.js
```

## See Also

- Parent: [modules/ml/README.md](../README.md)
- Applications: [applications/README.md](../applications/README.md)
- MCP Specification: https://spec.modelcontextprotocol.io/
- Cline Extension: https://github.com/cline/cline
