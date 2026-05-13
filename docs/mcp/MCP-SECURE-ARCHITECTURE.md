# Arquitetura MCP Segura - Multi-Agent

## 🚨 Problemas Identificados

### 1. Risco de Segurança Crítico
**Problema:** MCP server atualmente expõe `/etc/nixos` como PROJECT_ROOT
```json
"env": {
  "PROJECT_ROOT": "/etc/nixos",  // ❌ PERIGOSO: Acesso root ao NixOS
  "KNOWLEDGE_DB_PATH": "/var/lib/mcp-knowledge/knowledge.db"
}
```

**Risco:**
- Agentes AI com acesso completo ao sistema NixOS
- Modificações não intencionais em configurações críticas
- Potencial para quebrar o sistema inteiro
- Violação do princípio de menor privilégio

### 2. Gemini: Symlinks Quebrados
**Problema:** `postInstall` em [`gemini-cli.nix`](modules/packages/js-packages/gemini-cli.nix:53) remove symlinks de forma agressiva

```nix
postInstall = ''
  # Remove symlinks to missing workspace packages
  rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/@google/*
  rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/.bin/*
  
  # Recria o executável principal
  mkdir -p $out/bin
  ln -sf $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js $out/bin/gemini
''
```

**Efeito:** Comportamento instável e erros de módulos não encontrados

### 3. Codex: Sem MCP
**Problema:** Codex (FHS) não tem configuração MCP, limitando funcionalidades

## 🎯 Solução: Arquitetura HOME-Based Segura

### Princípios de Design
1. ✅ **Isolamento**: Cada agente trabalha em seu próprio `$HOME`
2. ✅ **Compartilhamento Seletivo**: Apenas knowledge DB compartilhado
3. ✅ **Sem Acesso Root**: PROJECT_ROOT aponta para workspace do usuário
4. ✅ **Configuração Centralizada**: Módulo único para gerenciar MCP

### Arquitetura Visual

```
┌─────────────────────────────────────────────────────────────────┐
│                      MCP Configuration Module                    │
│                  modules/ml/mcp-config/default.nix               │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Gera configs personalizados para cada agente:            │  │
│  │ - Roo/Claude Code → /home/kernelcore/.roo/mcp.json      │  │
│  │ - Codex           → /var/lib/codex/.codex/mcp.json      │  │
│  │ - Gemini          → /var/lib/gemini-agent/.gemini/mcp.json│  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Individual Agent Configs                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Roo/Claude Code                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PROJECT_ROOT: /home/kernelcore/workspace                 │  │
│  │ HOME: /home/kernelcore                                   │  │
│  │ MCP Config: ~/.roo/mcp.json                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Codex Agent (FHS)                                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PROJECT_ROOT: /var/lib/codex/workspace                   │  │
│  │ HOME: /var/lib/codex                                     │  │
│  │ MCP Config: ~/.codex/mcp.json                            │  │
│  │ FHS Packages: [ nodejs_22 ]                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Gemini Agent                                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PROJECT_ROOT: /var/lib/gemini-agent/workspace            │  │
│  │ HOME: /var/lib/gemini-agent                              │  │
│  │ MCP Config: ~/.gemini/mcp.json                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              SecureLLM Bridge MCP Server (Shared)                │
│                          stdio connection                         │
│                                                                   │
│  Tools: package-*, provider-test, crypto-*, security-audit, etc.│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Shared Knowledge Database                     │
│              /var/lib/mcp-knowledge/knowledge.db                │
│                   Group: mcp-shared (0660)                       │
│                                                                   │
│  Members: claude-code, codex, gemini-agent                      │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Plano de Implementação

### Task 1: Criar Módulo MCP Centralizado ⭐
**Arquivo:** `modules/ml/mcp-config/default.nix`

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.kernelcore.ml.mcp;
  
  # Template para gerar mcp.json
  generateMcpConfig = projectRoot: pkgs.writeText "mcp-config.json" (builtins.toJSON {
    mcpServers = {
      securellm-bridge = {
        command = "node";
        args = [
          "${cfg.mcpServerPath}/build/src/index.js"
        ];
        env = {
          PROJECT_ROOT = projectRoot;
          KNOWLEDGE_DB_PATH = cfg.knowledgeDbPath;
          ENABLE_KNOWLEDGE = "true";
        };
      };
    };
  });

in {
  options.kernelcore.ml.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) configuration";
    
    mcpServerPath = mkOption {
      type = types.str;
      default = "/etc/nixos/modules/ml/unified-llm/mcp-server";
      description = "Path to MCP server installation";
    };
    
    knowledgeDbPath = mkOption {
      type = types.str;
      default = "/var/lib/mcp-knowledge/knowledge.db";
      description = "Path to shared knowledge database";
    };
    
    agents = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "MCP for this agent";
          
          projectRoot = mkOption {
            type = types.str;
            description = "Project root directory (workspace) for this agent";
          };
          
          configPath = mkOption {
            type = types.str;
            description = "Path where mcp.json will be installed";
          };
          
          user = mkOption {
            type = types.str;
            description = "System user that owns this agent";
          };
        };
      });
      default = {};
      description = "Per-agent MCP configuration";
    };
  };
  
  config = mkIf cfg.enable {
    # Create shared knowledge DB
    users.groups.mcp-shared = {};
    
    systemd.tmpfiles.rules = [
      "d /var/lib/mcp-knowledge 0770 root mcp-shared -"
      "f ${cfg.knowledgeDbPath} 0660 root mcp-shared -"
    ] ++ (flatten (mapAttrsToList (name: agentCfg: 
      mkIf agentCfg.enable [
        # Create config directory
        "d $(dirname ${agentCfg.configPath}) 0750 ${agentCfg.user} ${agentCfg.user} -"
        # Install mcp.json
        "L+ ${agentCfg.configPath} - - - - ${generateMcpConfig agentCfg.projectRoot}"
      ]
    ) cfg.agents));
    
    # Add all agent users to mcp-shared group
    users.users = mapAttrs' (name: agentCfg:
      nameValuePair agentCfg.user {
        extraGroups = [ "mcp-shared" ];
      }
    ) (filterAttrs (_: a: a.enable) cfg.agents);
  };
}
```

### Task 2: Fix Gemini Symlinks
**Arquivo:** `modules/packages/js-packages/gemini-cli.nix`

**Problema Atual:**
```nix
postInstall = ''
  # Remove TODOS os symlinks - muito agressivo! ❌
  rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/@google/*
  rm -f $out/lib/node_modules/@google/gemini-cli/node_modules/.bin/*
```

**Solução: Remover apenas symlinks quebrados**
```nix
postInstall = ''
  # Remove apenas symlinks quebrados (apontando para nowhere)
  find $out/lib/node_modules/@google/gemini-cli/node_modules -type l | while read link; do
    if [ ! -e "$link" ]; then
      echo "Removing broken symlink: $link"
      rm -f "$link"
    fi
  done
  
  # Garante que o executável principal existe
  if [ ! -f "$out/bin/gemini" ]; then
    mkdir -p $out/bin
    ln -sf $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js $out/bin/gemini
  fi
''
```

### Task 3: Configurar Agentes

#### 3.1 Roo/Claude Code
**Arquivo:** `modules/services/users/claude-code.nix`

```nix
# Add to claude-code.nix config section
kernelcore.ml.mcp.agents.roo = {
  enable = true;
  projectRoot = "/home/kernelcore/workspace";
  configPath = "/home/kernelcore/.roo/mcp.json";
  user = "kernelcore";
};
```

#### 3.2 Codex Agent
**Arquivo:** `modules/services/users/codex-agent.nix`

```nix
# Add to codex-agent.nix config section
kernelcore.ml.mcp.agents.codex = {
  enable = true;
  projectRoot = "/var/lib/codex/workspace";
  configPath = "/var/lib/codex/.codex/mcp.json";
  user = "codex";
};

# Add Node.js to FHS packages for Codex
# Modificar builder.nix para suportar fhsExtraPackages
# OU adicionar via extraEnvironment + PATH
```

#### 3.3 Gemini Agent
**Arquivo:** `modules/services/users/gemini-agent.nix`

```nix
# Add to gemini-agent.nix config section
kernelcore.ml.mcp.agents.gemini = {
  enable = true;
  projectRoot = "/var/lib/gemini-agent/workspace";
  configPath = "/var/lib/gemini-agent/.gemini/mcp.json";
  user = "gemini-agent";
};
```

### Task 4: Atualizar Codex FHS

**Opção A: Modificar builder.nix (Mais Robusto)**
```nix
# Em modules/packages/tar-packages/builder.nix
# Adicionar suporte a fhsExtraPackages

targetPkgs = ps: with ps; [
  bash
  coreutils
  # ... existing packages ...
] ++ (pkg.fhsExtraPackages or []);
```

**Opção B: Via Environment (Mais Simples)**
```nix
# Em codex-agent.nix
systemd.services.codex-agent = {
  environment = {
    NODE_PATH = "${pkgs.nodejs_22}/bin";
    # ... outras vars
  };
  
  path = [ pkgs.nodejs_22 ] ++ existing_path;
};
```

## 🔒 Modelo de Segurança

### Permissões por Agente

```
Roo/Claude Code (kernelcore)
├── Workspace: ~/workspace (0750 kernelcore:kernelcore)
├── MCP Config: ~/.roo/mcp.json (0640 kernelcore:kernelcore)
└── Knowledge DB: /var/lib/mcp-knowledge/knowledge.db (read/write via mcp-shared)

Codex (codex)
├── Workspace: /var/lib/codex/workspace (0750 codex:codex)
├── MCP Config: /var/lib/codex/.codex/mcp.json (0640 codex:codex)
└── Knowledge DB: /var/lib/mcp-knowledge/knowledge.db (read/write via mcp-shared)

Gemini (gemini-agent)
├── Workspace: /var/lib/gemini-agent/workspace (0750 gemini-agent:gemini-agent)
├── MCP Config: /var/lib/gemini-agent/.gemini/mcp.json (0640 gemini-agent:gemini-agent)
└── Knowledge DB: /var/lib/mcp-knowledge/knowledge.db (read/write via mcp-shared)
```

### O Que Cada Agente PODE Fazer
- ✅ Ler/escrever em seu próprio workspace
- ✅ Acessar MCP tools (package-*, provider-test, etc.)
- ✅ Compartilhar knowledge via database
- ✅ Ler configurações do sistema (read-only)

### O Que Cada Agente NÃO PODE Fazer
- ❌ Modificar `/etc/nixos` diretamente
- ❌ Acessar workspace de outros agentes
- ❌ Modificar MCP config de outros agentes
- ❌ Escrever em diretórios do sistema

## 🧪 Validação

### 1. Verificar Estrutura
```bash
# Check MCP configs
ls -la /home/kernelcore/.roo/mcp.json
ls -la /var/lib/codex/.codex/mcp.json
ls -la /var/lib/gemini-agent/.gemini/mcp.json

# Check workspace directories
ls -la /home/kernelcore/workspace
ls -la /var/lib/codex/workspace
ls -la /var/lib/gemini-agent/workspace

# Check knowledge DB
ls -la /var/lib/mcp-knowledge/knowledge.db
# Should be: -rw-rw---- root mcp-shared

# Verify group membership
id kernelcore | grep mcp-shared
id codex | grep mcp-shared
id gemini-agent | grep mcp-shared
```

### 2. Testar MCP Connection
```bash
# Test each agent can access MCP server
sudo -u codex node /etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js --test
sudo -u gemini-agent node /etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js --test
```

### 3. Verificar Gemini Symlinks
```bash
# No more broken symlinks
find $(nix-build -A gemini-cli)/lib -type l -exec test ! -e {} \; -print
# Should be empty
```

## 📊 Benefícios

### Segurança
- ✅ Princípio de menor privilégio
- ✅ Isolamento entre agentes
- ✅ Sem acesso root ao NixOS
- ✅ Audit trail via knowledge DB

### Manutenibilidade
- ✅ Configuração centralizada
- ✅ Declarativa (NixOS modules)
- ✅ Fácil rollback via gerações
- ✅ Documentação clara

### Funcionalidade
- ✅ MCP tools compartilhados
- ✅ Knowledge base unificado
- ✅ Configuração por agente
- ✅ Extensível para novos agentes

## 🚀 Ordem de Implementação

1. **[Fase 1]** Criar `modules/ml/mcp-config/default.nix`
2. **[Fase 2]** Fix Gemini symlinks em `gemini-cli.nix`
3. **[Fase 3]** Configurar Roo/Claude Code
4. **[Fase 4]** Configurar Gemini Agent
5. **[Fase 5]** Configurar Codex Agent (+ FHS Node.js)
6. **[Fase 6]** Rebuild e validação
7. **[Fase 7]** Documentação e testes

---

**Status:** 🎯 Arquitetura completa - Pronto para implementação

**Próximo passo:** Switch to code mode e implementar Fase 1

**Última atualização:** 2025-01-20