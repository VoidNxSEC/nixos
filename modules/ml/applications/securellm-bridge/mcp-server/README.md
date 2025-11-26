# SecureLLM Bridge MCP Server

Model Context Protocol (MCP) server for SecureLLM Bridge development in Cline/VSCodium.

## Features

### Tools (6)
1. **provider_test** - Test LLM provider connectivity
2. **security_audit** - Run security checks on configurations
3. **rate_limit_check** - Check rate limit status
4. **build_and_test** - Build project and run tests
5. **provider_config_validate** - Validate provider configurations
6. **crypto_key_generate** - Generate TLS certificates

### Resources (4)
1. **config://current** - Current configuration
2. **logs://audit** - Audit logs
3. **metrics://usage** - Usage metrics
4. **docs://api** - API documentation

## Installation

### 1. Build the MCP Server

```bash
cd mcp-server
npm install
npm run build
```

This creates `build/index.js` which is the MCP server executable.

### 2. Configure for Cline in VSCodium

**Option A: Project-specific (Recommended)**

Copy `mcp-server-config.json` to VSCodium settings:

```bash
# For VSCodium
mkdir -p ~/.config/VSCodium/User/globalStorage/saoudrizwan.claude-dev/
cp ../mcp-server-config.json ~/.config/VSCodium/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

**Option B: Claude Desktop Integration**

If using Claude Desktop alongside VSCodium:

```bash
mkdir -p ~/.config/Claude/
cp ../mcp-server-config.json ~/.config/Claude/claude_desktop_config.json
```

### 3. Restart VSCodium/Cline

After configuration, restart VSCodium to load the MCP server.

## Usage in Cline

Once configured, you can use MCP tools directly in Cline:

### Test a Provider
```
Use the provider_test tool to test DeepSeek with prompt "Hello, world!"
```

### Security Audit
```
Use the security_audit tool to check config.toml for security issues
```

### Build and Test
```
Use the build_and_test tool to run all tests
```

### Generate TLS Certificates
```
Use the crypto_key_generate tool to generate server certificates in ./certs/
```

## Configuration

The MCP server uses these environment variables:

- `PROJECT_ROOT` - Project root directory (auto-configured in mcp-server-config.json)

## Troubleshooting

### MCP Server Not Loading

1. Check if TypeScript compiled successfully:
   ```bash
   ls -la mcp-server/build/index.js
   ```

2. Verify the path in configuration matches your system:
   ```bash
   cat mcp-server-config.json | grep args
   ```

3. Check Cline logs in VSCodium:
   - Open Command Palette (Ctrl+Shift+P)
   - Search for "Cline: Show Logs"

### Tool Execution Failures

1. Ensure PROJECT_ROOT environment variable is set correctly
2. Verify cargo/rust toolchain is available:
   ```bash
   cargo --version
   ```

3. Check if config.toml exists in project root

### Permission Issues

If you get permission errors:
```bash
chmod +x mcp-server/build/index.js
```

## Development

### Watch Mode
```bash
npm run watch
```

### Rebuild
```bash
npm run build
```

### Testing the Server Manually

You can test the MCP server with stdio transport:

```bash
cd mcp-server
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node build/index.js
```

## Architecture

```
┌─────────────────────────────────────┐
│      Cline in VSCodium              │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   MCP Client (Cline)        │   │
│  └──────────┬──────────────────┘   │
│             │ stdio                 │
└─────────────┼─────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│    SecureLLM Bridge MCP Server      │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Tool Handlers              │   │
│  │  - provider_test            │   │
│  │  - security_audit           │   │
│  │  - rate_limit_check         │   │
│  │  - build_and_test           │   │
│  │  - provider_config_validate │   │
│  │  - crypto_key_generate      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Resource Handlers          │   │
│  │  - config://current         │   │
│  │  - logs://audit             │   │
│  │  - metrics://usage          │   │
│  │  - docs://api               │   │
│  └─────────────────────────────┘   │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│   SecureLLM Bridge Project          │
│   - cargo build/test                │
│   - config.toml                     │
│   - Provider implementations        │
└─────────────────────────────────────┘
```

## Security Considerations

- The MCP server runs with your user permissions
- It can execute cargo commands and access project files
- API keys are read from environment variables, never hardcoded
- Configuration files are validated before processing
- TLS certificates are generated using OpenSSL

## Contributing

To add new tools or resources, edit `src/index.ts` and rebuild.

## License

MIT License - See parent project for details.
