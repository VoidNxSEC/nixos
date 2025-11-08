# MCP Server Integration Guide

**Last Updated**: 2025-11-08
**Version**: 2.0.0
**Status**: Production Ready

---

## Overview

This guide explains how to integrate the SecureLLM Bridge MCP server with various AI coding assistants. The MCP server provides 12 tools for provider testing, security auditing, knowledge management, and package debugging.

### Supported Clients

1. **Roo Code** (VSCodium/VS Code extension)
2. **Claude Desktop** (Anthropic's desktop app)
3. **Cline** (formerly Claude Dev)
4. **Any MCP-compatible client**

---

## Quick Start

### 1. Generate Configuration

The easiest way to set up MCP integration is using our automated script:

```bash
# For Roo Code only
/etc/nixos/scripts/generate-mcp-config.sh roo

# For Claude Desktop only
/etc/nixos/scripts/generate-mcp-config.sh claude

# For both clients
/etc/nixos/scripts/generate-mcp-config.sh both
```

### 2. Load API Keys

```bash
# Load API keys into environment
source /etc/load-api-keys.sh

# Verify keys are loaded
echo $ANTHROPIC_API_KEY | cut -c1-15
```

### 3. Reload Your IDE

- **Roo Code**: Reload VSCodium window (Ctrl+Shift+P → "Developer: Reload Window")
- **Claude Desktop**: Restart the application

### 4. Verify MCP Tools

Open your AI assistant and verify these tools are available:

**Security Tools**:
- `provider_test` - Test LLM provider connectivity
- `security_audit` - Run security checks on configs
- `rate_limit_check` - Check provider rate limits
- `build_and_test` - Build and run tests
- `provider_config_validate` - Validate provider configs
- `crypto_key_generate` - Generate TLS certificates

**Knowledge Tools**:
- `create_session` - Create knowledge session
- `save_knowledge` - Save knowledge entries
- `search_knowledge` - Search knowledge base
- `load_session` - Load previous session
- `list_sessions` - List all sessions
- `get_recent_knowledge` - Get recent entries

**Package Tools**:
- `package_diagnose` - Diagnose package build issues
- `package_download` - Download packages with hash calculation
- `package_configure` - Generate intelligent package configs

---

## Manual Configuration

### Roo Code Configuration

**Location**: `~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json`

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "node",
      "args": [
        "/etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js"
      ],
      "env": {
        "PROJECT_ROOT": "/etc/nixos",
        "KNOWLEDGE_DB_PATH": "/var/lib/mcp-knowledge/knowledge.db",
        "ENABLE_KNOWLEDGE": "true",
        "ANTHROPIC_API_KEY": "",
        "OPENAI_API_KEY": "",
        "DEEPSEEK_API_KEY": "",
        "GEMINI_API_KEY": "",
        "OPENROUTER_API_KEY": "",
        "GROQ_API_KEY": "",
        "MISTRAL_API_KEY": "",
        "NVIDIA_API_KEY": "",
        "REPLICATE_API_TOKEN": ""
      }
    }
  }
}
```

**Note**: Leave API key values empty in the JSON. They will be loaded from `/run/secrets/` at runtime via the shell environment.

### Claude Desktop Configuration

**Location**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "node",
      "args": [
        "/etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js"
      ],
      "env": {
        "PROJECT_ROOT": "/etc/nixos",
        "KNOWLEDGE_DB_PATH": "/var/lib/mcp-knowledge/knowledge.db",
        "ENABLE_KNOWLEDGE": "true"
      }
    }
  }
}
```

---

## Environment Variables

The MCP server uses these environment variables:

### Required

| Variable | Description | Default |
|----------|-------------|---------|
| `PROJECT_ROOT` | NixOS configuration root | `/etc/nixos` |
| `KNOWLEDGE_DB_PATH` | SQLite database path | `/var/lib/mcp-knowledge/knowledge.db` |
| `ENABLE_KNOWLEDGE` | Enable knowledge tools | `true` |

### Provider API Keys (Optional)

These are loaded from SOPS-decrypted secrets in `/run/secrets/`:

| Variable | Provider | Loaded From |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic Claude | `/run/secrets/anthropic_api_key` |
| `OPENAI_API_KEY` | OpenAI GPT | `/run/secrets/openai_api_key` |
| `DEEPSEEK_API_KEY` | DeepSeek | `/run/secrets/deepseek_api_key` |
| `GEMINI_API_KEY` | Google Gemini | `/run/secrets/gemini_api_key` |
| `OPENROUTER_API_KEY` | OpenRouter | `/run/secrets/openrouter_api_key` |
| `GROQ_API_KEY` | Groq | `/run/secrets/groq_api_key` |
| `MISTRAL_API_KEY` | Mistral AI | `/run/secrets/mistral_api_key` |
| `NVIDIA_API_KEY` | NVIDIA NIM | `/run/secrets/nvidia_api_key` |
| `REPLICATE_API_TOKEN` | Replicate | `/run/secrets/replicate_api_key` |

---

## Adding New Providers

### 1. Add API Key to Secrets

Edit `/etc/nixos/secrets/api.yaml`:

```yaml
# Add new provider key
newprovider_api_key: your-encrypted-key-here
```

### 2. Update SOPS Configuration

Edit `/etc/nixos/modules/secrets/api-keys.nix`:

```nix
sops.secrets = {
  # ... existing secrets ...

  "newprovider_api_key" = {
    sopsFile = ../../secrets/api.yaml;
    mode = "0440";
    owner = config.users.users.kernelcore.name;
    group = "users";
  };
};
```

### 3. Update Load Script

Edit `/etc/nixos/modules/secrets/api-keys.nix` (line 118):

```bash
export NEWPROVIDER_API_KEY="$(cat /run/secrets/newprovider_api_key 2>/dev/null || echo "")"
```

### 4. Update MCP Server

Edit `/etc/nixos/modules/ml/unified-llm/mcp-server/src/index.ts`:

```typescript
const API_KEYS = {
  // ... existing keys ...
  newprovider: process.env.NEWPROVIDER_API_KEY || "",
};
```

### 5. Rebuild and Regenerate

```bash
# Rebuild NixOS to decrypt new secret
sudo nixos-rebuild switch

# Rebuild MCP server
cd /etc/nixos/modules/ml/unified-llm/mcp-server
npm run build

# Regenerate MCP configs
/etc/nixos/scripts/generate-mcp-config.sh both

# Reload IDE
```

---

## Testing MCP Connection

### Test MCP Protocol

```bash
# Test tools list
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
  node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js

# Test resources list
echo '{"jsonrpc":"2.0","id":2,"method":"resources/list"}' | \
  node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js
```

### Test Provider Tool

```bash
# Load API keys
source /etc/load-api-keys.sh

# Test DeepSeek provider
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"provider_test","arguments":{"provider":"deepseek","prompt":"Hello!"}}}' | \
  node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js
```

### Test Knowledge Tools

```bash
# Create session
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"create_session","arguments":{"summary":"Test session"}}}' | \
  node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js

# Save knowledge
echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"save_knowledge","arguments":{"content":"Test knowledge","type":"insight"}}}' | \
  node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js
```

---

## Troubleshooting

### MCP Tools Not Showing

**Symptoms**: Tools don't appear in IDE

**Solutions**:
1. Verify MCP server is built:
   ```bash
   ls -lh /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js
   ```

2. Check config file exists:
   ```bash
   cat ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json
   ```

3. Reload IDE window

4. Check IDE logs for MCP errors

### Provider Test Fails

**Symptoms**: `provider_test` tool returns errors

**Solutions**:
1. Verify API keys are loaded:
   ```bash
   source /etc/load-api-keys.sh
   echo "DeepSeek: ${DEEPSEEK_API_KEY:0:15}..."
   ```

2. Check secrets are decrypted:
   ```bash
   ls -la /run/secrets/
   cat /run/secrets/deepseek_api_key
   ```

3. Verify NixOS configuration:
   ```bash
   sudo nixos-rebuild switch
   ```

### Knowledge Database Issues

**Symptoms**: Knowledge tools fail with database errors

**Solutions**:
1. Check database directory exists:
   ```bash
   sudo mkdir -p /var/lib/mcp-knowledge
   sudo chown $USER:users /var/lib/mcp-knowledge
   ```

2. Verify permissions:
   ```bash
   ls -la /var/lib/mcp-knowledge/
   ```

3. Initialize database manually:
   ```bash
   sqlite3 /var/lib/mcp-knowledge/knowledge.db "VACUUM;"
   ```

### API Keys Not Loading

**Symptoms**: MCP server shows "No API keys loaded" warning

**Solutions**:
1. Check SOPS configuration:
   ```bash
   sudo systemctl restart sops-nix
   ```

2. Verify age key exists:
   ```bash
   ls -la ~/.config/sops/age/keys.txt
   ```

3. Test manual decryption:
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
     sops -d /etc/nixos/secrets/api.yaml
   ```

4. Regenerate MCP config:
   ```bash
   source /etc/load-api-keys.sh
   /etc/nixos/scripts/generate-mcp-config.sh both
   ```

---

## Architecture

### MCP Server Flow

```
┌─────────────────────────────────────────┐
│         IDE (Roo Code/Claude)           │
└───────────────┬─────────────────────────┘
                │ JSON-RPC 2.0 (stdio)
┌───────────────▼─────────────────────────┐
│         MCP Server (Node.js)            │
│  - 12 Tools (security, knowledge, pkg)  │
│  - 4 Resources (config, logs, metrics)  │
│  - Environment: API keys from SOPS      │
└───────────────┬─────────────────────────┘
                │
    ┌───────────┴───────────┬──────────────┐
    │                       │              │
┌───▼────────┐   ┌──────────▼─────┐   ┌──▼──────────┐
│ Provider   │   │   Knowledge     │   │   Package   │
│ Tools      │   │   Database      │   │   Tools     │
│ (Testing)  │   │   (SQLite)      │   │   (Nix)     │
└────────────┘   └─────────────────┘   └─────────────┘
```

### API Key Loading Flow

```
┌─────────────────────────────────────────┐
│   SOPS-Encrypted Secrets (.yaml)       │
│   /etc/nixos/secrets/api.yaml          │
└───────────────┬─────────────────────────┘
                │ Age decryption
┌───────────────▼─────────────────────────┐
│   Decrypted Runtime Secrets             │
│   /run/secrets/*_api_key                │
└───────────────┬─────────────────────────┘
                │ Read by load script
┌───────────────▼─────────────────────────┐
│   Shell Environment Variables           │
│   ANTHROPIC_API_KEY=sk-...              │
└───────────────┬─────────────────────────┘
                │ Inherited by Node.js
┌───────────────▼─────────────────────────┐
│   MCP Server (process.env)              │
│   Available to all tools                │
└─────────────────────────────────────────┘
```

---

## Security Considerations

### API Key Security

1. **Never hardcode keys**: Always use SOPS-encrypted secrets
2. **Minimal exposure**: Keys only exist in `/run/secrets/` at runtime
3. **No disk storage**: MCP config has empty strings, keys loaded from env
4. **Masked logging**: Keys shown as `provider(sk-12345...)`

### Permission Model

```
Secrets:      root:root (600)  → SOPS decrypts
/run/secrets: kernelcore:users (440) → Runtime access
Environment:  kernelcore (process) → MCP server
```

### Best Practices

1. **Rotate keys regularly**: Update SOPS secrets and rebuild
2. **Monitor access**: Check audit logs for provider usage
3. **Principle of least privilege**: Only enable needed providers
4. **Separate dev/prod**: Use different keys for testing

---

## Related Documentation

- **MCP Architecture**: `/etc/nixos/docs/MCP-ARCHITECTURE-ACCESS.md`
- **API Keys Setup**: `/etc/nixos/docs/guides/SECRETS.md`
- **SOPS Configuration**: `/etc/nixos/docs/guides/SETUP-SOPS-FINAL.md`
- **SecureLLM Bridge**: `/etc/nixos/modules/ml/unified-llm/CLAUDE.md`

---

## Support

### Report Issues

Issues with MCP integration? Check:

1. IDE logs (VSCodium: Help → Toggle Developer Tools → Console)
2. MCP server logs (stderr output)
3. NixOS journal: `journalctl -u sops-nix.service -f`

### Community

- NixOS Config: `/etc/nixos/`
- Maintainer: kernelcore
- Version: 2.0.0

---

**Last Updated**: 2025-11-08
**Status**: Production Ready ✅
