# MCP Server - Arquitetura de Acesso e Integração

Este documento detalha como o MCP (Model Context Protocol) server está configurado e integrado com as diferentes extensões VSCodium.

## Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────┐
│                    VSCodium Extensions                       │
├──────────────────────────┬──────────────────────────────────┤
│   Roo-Code Extension     │   Claude-Code Extension          │
│   (rooveterinaryinc)     │   (Anthropic)                    │
└────────────┬─────────────┴──────────────┬───────────────────┘
             │                            │
             │ Lê                         │ Lê
             ▼                            ▼
┌─────────────────────────┐  ┌────────────────────────────────┐
│  .roo/mcp.json          │  │ .claude/settings.local.json    │
│  (Project-level)        │  │ enableAllProjectMcpServers     │
└────────────┬────────────┘  └────────────┬───────────────────┘
             │                            │
             │ Pode ler também            │ Pode ler também
             ▼                            ▼
┌──────────────────────────────────────────────────────────────┐
│  modules/ml/unified-llm/mcp-server-config.json               │
│  (Configuração alternativa do server)                        │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             │ Spawn Process
                             ▼
┌──────────────────────────────────────────────────────────────┐
│            MCP Server (securellm-bridge)                     │
│  modules/ml/unified-llm/mcp-server/build/index.js            │
├──────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Package Tools  │  │ Knowledge Base  │  │ Other Tools  │ │
│  │ - diagnose     │  │ SQLite + FTS5   │  │ - filesystem │ │
│  │ - download     │  │ /var/lib/mcp-   │  │ - prompts    │ │
│  │ - configure    │  │   knowledge/    │  │              │ │
│  └────────────────┘  └─────────────────┘  └──────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

## Arquivos de Configuração

### 1. Roo-Code Extension Config

**Localização:** `~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json`

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

**Características:**
- Config global da extensão Roo-Code
- Carregado automaticamente ao abrir VSCodium
- Prioridade: configs locais sobrescrevem

### 2. Project-Level Config (Roo-Code)

**Localização:** `.roo/mcp.json`

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

**Características:**
- Específico do projeto (commitable no git)
- Sobrescreve configuração global
- Permite configs diferentes por projeto

### 3. Claude-Code Extension Config

**Localização:** `.claude/settings.local.json`

```json
{
  "permissions": {
    "allow": ["..."],
    "deny": [],
    "ask": []
  },
  "enableAllProjectMcpServers": true
}
```

**Características:**
- `enableAllProjectMcpServers: true` = lê MCP servers do projeto
- Busca em `.roo/mcp.json` e `mcp-server-config.json`
- Permissões granulares para comandos

### 4. Alternative Server Config

**Localização:** `modules/ml/unified-llm/mcp-server-config.json`

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
      },
      "disabled": false,
      "alwaysAllow": []
    }
  }
}
```

**Características:**
- Config alternativa dentro do módulo
- Pode ser usada por Claude-Code se `.roo/mcp.json` não existir
- Mantém consistência de configuração

## Variáveis de Ambiente

### Variáveis Críticas

| Variável | Valor | Propósito |
|----------|-------|-----------|
| `PROJECT_ROOT` | `/etc/nixos` | Raiz do projeto NixOS |
| `KNOWLEDGE_DB_PATH` | `/var/lib/mcp-knowledge/knowledge.db` | Caminho do banco SQLite |
| `ENABLE_KNOWLEDGE` | `"true"` | Habilita sistema de conhecimento |

### Por que `/etc/nixos` e não `/etc/nixos/modules/ml/unified-llm`?

O `PROJECT_ROOT` deve apontar para a raiz do repositório porque:

1. **Tools de Package Debugger** precisam acessar:
   - `modules/packages/tar-packages/`
   - `modules/packages/deb-packages/`
   - `modules/packages/js-packages/`

2. **Knowledge System** indexa todo o repositório:
   - `modules/`
   - `hosts/`
   - `docs/`
   - `flake.nix`, etc.

3. **Filesystem Tools** navegam a partir da raiz do projeto

## Fluxo de Inicialização

### 1. VSCodium Startup

```
VSCodium abre
  ↓
Extensions carregam
  ↓
Roo-Code lê ~/.config/VSCodium/.../mcp_settings.json
  ↓
Roo-Code lê .roo/mcp.json (se existe)
  ↓
Claude-Code lê .claude/settings.local.json
  ↓
Se enableAllProjectMcpServers = true:
  Claude-Code busca .roo/mcp.json ou mcp-server-config.json
```

### 2. MCP Server Spawn

```
Extension encontra config "securellm-bridge"
  ↓
Spawn process: node build/index.js
  ↓
Env vars passadas:
  - PROJECT_ROOT=/etc/nixos
  - KNOWLEDGE_DB_PATH=/var/lib/mcp-knowledge/knowledge.db
  - ENABLE_KNOWLEDGE=true
  ↓
Server inicializa:
  1. Carrega Knowledge Database
  2. Registra tools (package_diagnose, etc.)
  3. Aguarda requisições via stdio
```

### 3. Tool Execution

```
Extension envia request via stdio
  ↓
{
  "method": "tools/call",
  "params": {
    "name": "package_diagnose",
    "arguments": {...}
  }
}
  ↓
Server processa request
  ↓
Tool executa (ex: analisa config NixOS)
  ↓
Server retorna response
  ↓
{
  "result": {
    "content": [{
      "type": "text",
      "text": "Analysis results..."
    }]
  }
}
  ↓
Extension exibe resultado ao usuário
```

## Sincronização de Configurações

### Estado Atual (SINCRONIZADO ✅)

Todos os arquivos de configuração agora têm:
- ✅ Mesmo `command` e `args`
- ✅ Mesmas variáveis de ambiente
- ✅ `PROJECT_ROOT=/etc/nixos` (consistente)
- ✅ Knowledge database habilitado

### Checklist de Sincronização

Para manter configs sincronizadas ao modificar:

```bash
# 1. Atualizar config global Roo-Code
code ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json

# 2. Atualizar config do projeto
code /etc/nixos/.roo/mcp.json

# 3. Atualizar config alternativa
code /etc/nixos/modules/ml/unified-llm/mcp-server-config.json

# 4. Verificar se Claude-Code está habilitado
code /etc/nixos/.claude/settings.local.json
# Deve ter: "enableAllProjectMcpServers": true
```

## Troubleshooting

Ver [`docs/MCP-TROUBLESHOOTING.md`](./MCP-TROUBLESHOOTING.md) para guia completo.

### Quick Checks

```bash
# 1. Verificar se server está buildado
ls -la /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js

# 2. Verificar database
ls -la /var/lib/mcp-knowledge/knowledge.db

# 3. Testar server manualmente
node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js

# 4. Ver logs do MCP server
# Roo-Code: Output > MCP: securellm-bridge
# Claude-Code: Output > MCP Servers
```

## Próximos Passos

1. **Rebuild MCP server** após modificações no código
2. **Reiniciar VSCodium** para recarregar configs
3. **Testar tools** via Roo-Code e Claude-Code
4. **Monitorar logs** para garantir funcionamento correto

## Referências

- [MCP Protocol Spec](https://modelcontextprotocol.io/)
- [Package Debugger Architecture](../modules/ml/unified-llm/mcp-server/docs/PACKAGE-DEBUGGER-ARCHITECTURE.md)
- [Knowledge Database Fix](./MCP-KNOWLEDGE-DB-FIX.md)
- [MCP Health Report](./MCP-SERVER-HEALTH-REPORT.md)