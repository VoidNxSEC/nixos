# Integração MCP com Codex Agent

## 📋 Visão Geral

Configuração do **Codex Agent** para se conectar ao **SecureLLM Bridge MCP Server** via stdio, habilitando acesso a ferramentas avançadas de desenvolvimento, pacotes Nix, e knowledge base compartilhada.

## 🎯 Objetivos

1. ✅ Codex acessa MCP server via stdio (mesmo modelo que Roo/Claude Code)
2. ✅ Compartilha knowledge base com outros agentes
3. ✅ Acesso a ferramentas Nix (package-diagnose, package-download, etc.)
4. ✅ Configuração declarativa via NixOS
5. ✅ Isolamento de segurança mantido

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      Codex Agent Process                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Codex Runtime                                         │ │
│  │  - Reads: /var/lib/codex/.codex/mcp.json             │ │
│  │  - Environment: PROJECT_ROOT, KNOWLEDGE_DB_PATH       │ │
│  └────────────────────┬───────────────────────────────────┘ │
└────────────────────────┼───────────────────────────────────┘
                         │ stdio (stdin/stdout)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              SecureLLM Bridge MCP Server                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Node Process                                          │ │
│  │  - Entry: /etc/nixos/modules/ml/unified-llm/          │ │
│  │           mcp-server/build/src/index.js               │ │
│  │  - Tools: package-*, provider-test, crypto-*, etc.    │ │
│  │  - Resources: config://, logs://, metrics://, docs:// │ │
│  └────────────────────┬───────────────────────────────────┘ │
└────────────────────────┼───────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Shared Knowledge Base                     │
│              /var/lib/mcp-knowledge/knowledge.db            │
│  - Sessions: organize work context                          │
│  - Entries: insights, code, decisions, references           │
│  - Search: full-text with boolean operators                 │
│  - Shared: Claude Code + Codex + Gemini                    │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Estrutura de Arquivos

### 1. Configuração MCP do Codex
**Localização:** `/var/lib/codex/.codex/mcp.json`

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "node",
      "args": [
        "/etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js"
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

### 2. Módulo NixOS Atualizado
**Localização:** `modules/services/users/codex-agent.nix`

**Mudanças necessárias:**
- ✅ Criar diretório `.codex` no home do usuário
- ✅ Instalar arquivo `mcp.json` via `systemd.tmpfiles`
- ✅ Adicionar variáveis de ambiente MCP
- ✅ Adicionar `nodejs` ao PATH
- ✅ Garantir permissões corretas

### 3. Permissões e Diretórios

```
/var/lib/codex/
├── .codex/
│   └── mcp.json              # 0640 codex:codex
├── agents/                   # workdir
└── logs/                     # logs do serviço

/var/lib/mcp-knowledge/
└── knowledge.db              # 0660 mcp-knowledge:mcp-shared
```

## 🔧 Implementação

### Passo 1: Atualizar `codex-agent.nix`

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.users.codex-agent;
  
  # MCP configuration
  mcpConfig = pkgs.writeText "codex-mcp.json" (builtins.toJSON {
    mcpServers = {
      securellm-bridge = {
        command = "node";
        args = [
          "/etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js"
        ];
        env = {
          PROJECT_ROOT = "/etc/nixos";
          KNOWLEDGE_DB_PATH = "/var/lib/mcp-knowledge/knowledge.db";
          ENABLE_KNOWLEDGE = "true";
        };
      };
    };
  });

  # ... rest of config ...
in
{
  # ... existing options ...

  config = mkIf cfg.enable {
    # ... existing config ...

    # Add Node.js to PATH
    systemd.services.codex-agent = {
      # ... existing service config ...
      
      path = [
        cfg.package
        pkgs.nodejs_22  # Add Node.js for MCP
      ]
      ++ (with pkgs; [
        git
        nix
        coreutils
        findutils
      ]);

      environment = {
        CODEX_AGENT_USER = cfg.userName;
        CODEX_AGENT_HOME = cfg.homeDirectory;
        CODEX_AGENT_WORKDIR = cfg.workDirectory;
        # MCP environment variables
        PROJECT_ROOT = "/etc/nixos";
        KNOWLEDGE_DB_PATH = "/var/lib/mcp-knowledge/knowledge.db";
        ENABLE_KNOWLEDGE = "true";
      }
      // cfg.extraEnvironment;
    };

    # Create MCP config directory and file
    systemd.tmpfiles.rules = [
      "d ${cfg.homeDirectory} 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/.codex 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/logs 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.workDirectory} 0750 ${cfg.userName} ${cfg.userName} -"
      "L+ ${cfg.homeDirectory}/.codex/mcp.json - - - - ${mcpConfig}"
    ];

    # Ensure codex user is in mcp-shared group for DB access
    users.users.${cfg.userName} = {
      # ... existing user config ...
      extraGroups = [ "mcp-shared" ];
    };
  };
}
```

### Passo 2: Garantir Knowledge DB Compartilhado

O knowledge DB já está configurado em `modules/services/users/claude-code.nix`:

```nix
# Create shared group for knowledge DB access
users.groups.mcp-shared = {};

# Setup knowledge database
systemd.tmpfiles.rules = [
  "d /var/lib/mcp-knowledge 0770 claude-code mcp-shared -"
  "f /var/lib/mcp-knowledge/knowledge.db 0660 claude-code mcp-shared -"
];
```

Apenas precisamos adicionar o usuário `codex` ao grupo `mcp-shared`.

## 🔍 Validação

### 1. Verificar Configuração
```bash
# Check MCP config exists
ls -la /var/lib/codex/.codex/mcp.json
cat /var/lib/codex/.codex/mcp.json

# Verify group membership
id codex
# Should show: groups=codex,mcp-shared

# Check knowledge DB permissions
ls -la /var/lib/mcp-knowledge/knowledge.db
# Should be: -rw-rw---- claude-code mcp-shared
```

### 2. Testar Serviço
```bash
# Check service status
systemctl status codex-agent

# View logs
journalctl -u codex-agent -f

# Test MCP connection (when codex supports it)
# codex agent test-mcp
```

### 3. Verificar MCP Tools
Uma vez conectado, Codex terá acesso a:

**Ferramentas Disponíveis:**
- `provider_test` - Test LLM provider connectivity
- `security_audit` - Run security checks
- `rate_limit_check` - Check rate limits
- `build_and_test` - Build and test project
- `package_diagnose` - Diagnose package issues
- `package_download` - Download packages with hash
- `package_configure` - Generate package configs
- `crypto_key_generate` - Generate TLS keys
- `create_session` - Create knowledge session
- `save_knowledge` - Save to knowledge base
- `search_knowledge` - Search knowledge base
- `load_session` - Load previous session

**Recursos Disponíveis:**
- `config://current` - Current configuration
- `logs://audit` - Audit logs
- `metrics://usage` - Usage statistics
- `docs://api` - API documentation

## 🔒 Segurança

### Isolamento Mantido
1. ✅ Codex roda como usuário dedicado `codex:codex`
2. ✅ Home directory isolado: `/var/lib/codex`
3. ✅ MCP config acessível apenas por `codex`
4. ✅ Knowledge DB compartilhado via grupo `mcp-shared`
5. ✅ Comunicação MCP via stdio (sem rede)

### Permissões
```
/var/lib/codex/.codex/mcp.json      → 0640 codex:codex
/var/lib/mcp-knowledge/knowledge.db → 0660 claude-code:mcp-shared
/etc/nixos/                         → 0755 root:root (read-only para codex)
```

## 📊 Benefícios

### Para Codex
- ✅ Acesso a ferramentas Nix avançadas
- ✅ Diagnóstico e configuração de pacotes
- ✅ Knowledge base compartilhado
- ✅ Acesso a métricas e logs do sistema
- ✅ Teste de provedores LLM
- ✅ Geração de chaves criptográficas

### Para o Sistema
- ✅ Consistência entre agentes (Claude Code, Codex, Gemini)
- ✅ Knowledge base unificado
- ✅ Ferramentas padronizadas
- ✅ Configuração declarativa (NixOS)
- ✅ Rollback fácil via gerações

## 🚀 Próximos Passos

1. **Implementação** (switch to code mode)
   - Atualizar `codex-agent.nix`
   - Rebuild do sistema
   - Verificar arquivos criados

2. **Validação**
   - Testar serviço codex-agent
   - Verificar permissões
   - Confirmar acesso ao knowledge DB

3. **Documentação**
   - Atualizar README principal
   - Adicionar exemplos de uso
   - Documentar troubleshooting

## 📝 Troubleshooting

### Problema: MCP config não encontrado
```bash
# Verificar tmpfiles
systemd-tmpfiles --create
ls -la /var/lib/codex/.codex/
```

### Problema: Permission denied no knowledge DB
```bash
# Verificar grupo
id codex | grep mcp-shared

# Corrigir permissões
sudo chown claude-code:mcp-shared /var/lib/mcp-knowledge/knowledge.db
sudo chmod 0660 /var/lib/mcp-knowledge/knowledge.db
```

### Problema: Node não encontrado
```bash
# Verificar PATH do serviço
systemctl show codex-agent | grep PATH

# Testar manualmente
sudo -u codex node --version
```

## 🔗 Referências

- MCP Protocol: https://modelcontextprotocol.io
- Roo Config: `.roo/mcp.json`
- MCP Server: `modules/ml/unified-llm/mcp-server/`
- Knowledge DB: `docs/MCP-KNOWLEDGE-STABILIZATION.md`
- Claude Code Config: `modules/services/users/claude-code.nix`

---

**Status:** 🟡 Design completo - Pronto para implementação

**Última atualização:** 2025-01-20
