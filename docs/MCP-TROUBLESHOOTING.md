# MCP Server - Guia de Troubleshooting

Este guia detalha problemas comuns com o MCP (Model Context Protocol) server e suas soluções.

## Índice

1. [Problemas de Inicialização](#problemas-de-inicialização)
2. [Problemas de Knowledge Database](#problemas-de-knowledge-database)
3. [Problemas de Tools](#problemas-de-tools)
4. [Problemas de Configuração](#problemas-de-configuração)
5. [Problemas de Permissões](#problemas-de-permissões)
6. [Comandos de Diagnóstico](#comandos-de-diagnóstico)

---

## Problemas de Inicialização

### MCP Server não aparece nas extensões

**Sintomas:**
- Extensão Roo-Code ou Claude-Code não lista o server "securellm-bridge"
- Sem output no log "MCP: securellm-bridge"

**Diagnóstico:**

```bash
# 1. Verificar se arquivo de build existe
ls -la /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js

# 2. Verificar configurações
cat /etc/nixos/.roo/mcp.json
cat /etc/nixos/.claude/settings.local.json

# 3. Testar server manualmente
node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js
# Deve iniciar sem erros e aguardar input
```

**Soluções:**

1. **Server não buildado:**
```bash
cd /etc/nixos/modules/ml/unified-llm/mcp-server
npm run build
```

2. **Config vazia ou incorreta:**
```bash
# Copiar config do template
cat > /etc/nixos/.roo/mcp.json << 'EOF'
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
EOF
```

3. **Claude-Code não vê server:**
```bash
# Verificar se enableAllProjectMcpServers está habilitado
cat /etc/nixos/.claude/settings.local.json
# Deve ter: "enableAllProjectMcpServers": true
```

4. **Reiniciar VSCodium:**
```bash
# Após mudanças em configs, sempre reiniciar
pkill -9 codium
# Reabrir VSCodium
```

### Server inicia mas não responde

**Sintomas:**
- Server aparece na lista mas não responde a comandos
- Timeout ao tentar usar tools

**Diagnóstico:**

```bash
# Ver logs do server
# VSCodium: Output > MCP: securellm-bridge

# Testar comunicação manual
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}},"id":1}' | \
  node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js
```

**Soluções:**

1. **Erro no código TypeScript:**
```bash
# Verificar erros de build
cd /etc/nixos/modules/ml/unified-llm/mcp-server
npm run build 2>&1 | grep -i error
```

2. **Dependências faltando:**
```bash
cd /etc/nixos/modules/ml/unified-llm/mcp-server
npm install
```

---

## Problemas de Knowledge Database

### "Cannot open database because the directory does not exist"

**Sintomas:**
```
TypeError: Cannot open database because the directory does not exist
    at Database.<anonymous> (/etc/nixos/modules/ml/unified-llm/mcp-server/src/knowledge/database.ts:22:27)
```

**Diagnóstico:**

```bash
# 1. Verificar se diretório existe
ls -la /var/lib/mcp-knowledge/

# 2. Verificar permissões
stat /var/lib/mcp-knowledge/

# 3. Verificar ownership
ls -ld /var/lib/mcp-knowledge/
# Deve ser: drwxr-xr-x kernelcore users
```

**Soluções:**

1. **Diretório não existe (solução correta via NixOS):**

Adicionar em [`hosts/kernelcore/configuration.nix`](../hosts/kernelcore/configuration.nix):

```nix
# Knowledge database directory
systemd.tmpfiles.rules = [
  "d /var/lib/mcp-knowledge 0755 kernelcore users -"
];
```

Rebuild:
```bash
sudo nixos-rebuild switch --flake .#kernelcore
```

2. **Permissões incorretas:**
```bash
# Fix temporário (não sobrevive reboot)
sudo mkdir -p /var/lib/mcp-knowledge
sudo chown kernelcore:users /var/lib/mcp-knowledge
sudo chmod 755 /var/lib/mcp-knowledge
```

3. **Variável de ambiente incorreta:**
```bash
# Verificar em .roo/mcp.json ou mcp-server-config.json
# Deve ter: "KNOWLEDGE_DB_PATH": "/var/lib/mcp-knowledge/knowledge.db"
```

### Database corrupted

**Sintomas:**
- "database disk image is malformed"
- Server não inicia

**Soluções:**

```bash
# 1. Backup do database
sudo cp /var/lib/mcp-knowledge/knowledge.db /var/lib/mcp-knowledge/knowledge.db.backup

# 2. Tentar recuperar
sqlite3 /var/lib/mcp-knowledge/knowledge.db "PRAGMA integrity_check;"

# 3. Se irrecuperável, recriar
sudo rm /var/lib/mcp-knowledge/knowledge.db
# Server recriará automaticamente ao iniciar
```

### Full-text search não funciona

**Sintomas:**
- Searches não retornam resultados
- Erro: "no such module: fts5"

**Diagnóstico:**

```bash
# Verificar se FTS5 está habilitado
sqlite3 /var/lib/mcp-knowledge/knowledge.db "PRAGMA compile_options;" | grep FTS5
```

**Soluções:**

```bash
# SQLite no Nix deve ter FTS5 por padrão
# Se não tiver, rebuild do MCP server com better-sqlite3 correto
cd /etc/nixos/modules/ml/unified-llm/mcp-server
rm -rf node_modules
npm install
npm run build
```

---

## Problemas de Tools

### Package Debugger tools não funcionam

**Sintomas:**
- `package_diagnose` não encontra arquivos
- `package_download` falha ao baixar
- `package_configure` não gera config correta

**Diagnóstico:**

```bash
# 1. Verificar PROJECT_ROOT
# Deve ser /etc/nixos, não /etc/nixos/modules/ml/unified-llm
cat /etc/nixos/.roo/mcp.json | grep PROJECT_ROOT

# 2. Verificar estrutura de packages
ls -la /etc/nixos/modules/packages/tar-packages/
ls -la /etc/nixos/modules/packages/deb-packages/
ls -la /etc/nixos/modules/packages/js-packages/

# 3. Testar package_diagnose manualmente
# Via Roo-Code: usar comando "package_diagnose"
```

**Soluções:**

1. **PROJECT_ROOT incorreto:**

Corrigir em `.roo/mcp.json`:
```json
{
  "mcpServers": {
    "securellm-bridge": {
      "env": {
        "PROJECT_ROOT": "/etc/nixos"
      }
    }
  }
}
```

2. **Permissões de leitura:**
```bash
# Verificar se user tem acesso aos módulos
ls -la /etc/nixos/modules/packages/
# Deve ser readable pelo user
```

### Tools retornam "command not found"

**Sintomas:**
- `nix build` não encontrado
- `nix fmt` não encontrado

**Diagnóstico:**

```bash
# Verificar se Nix está no PATH do server
which nix
echo $PATH
```

**Soluções:**

1. **Adicionar Nix ao PATH no spawn:**

Em `.roo/mcp.json`:
```json
{
  "mcpServers": {
    "securellm-bridge": {
      "env": {
        "PATH": "/run/current-system/sw/bin:/usr/bin:/bin"
      }
    }
  }
}
```

2. **Usar caminhos absolutos:**
```typescript
// No código dos tools
const nixBuild = '/run/current-system/sw/bin/nix';
```

---

## Problemas de Configuração

### Configs dessincronizadas

**Sintomas:**
- Server funciona em Roo-Code mas não em Claude-Code
- Diferenças de comportamento entre extensões

**Diagnóstico:**

```bash
# Comparar todas as configs
diff <(jq -S . ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json) \
     <(jq -S . /etc/nixos/.roo/mcp.json)

diff <(jq -S . /etc/nixos/.roo/mcp.json) \
     <(jq -S . /etc/nixos/modules/ml/unified-llm/mcp-server-config.json)
```

**Soluções:**

1. **Sincronizar todas configs:**

Ver [`docs/MCP-ARCHITECTURE-ACCESS.md`](./MCP-ARCHITECTURE-ACCESS.md) seção "Sincronização de Configurações".

```bash
# Script helper
./scripts/generate-mcp-config.sh
```

2. **Usar config única:**

Criar symlinks:
```bash
# Não recomendado - melhor manter configs separadas
# mas consistentes
```

### Environment variables não propagam

**Sintomas:**
- `process.env.PROJECT_ROOT` é undefined no server
- Knowledge database não encontrado

**Diagnóstico:**

```bash
# Verificar se env vars estão no spawn
# Ver logs: Output > MCP: securellm-bridge
# Procurar por: "Environment: PROJECT_ROOT=/etc/nixos"
```

**Soluções:**

1. **Adicionar env vars explicitamente:**

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "env": {
        "PROJECT_ROOT": "/etc/nixos",
        "KNOWLEDGE_DB_PATH": "/var/lib/mcp-knowledge/knowledge.db",
        "ENABLE_KNOWLEDGE": "true"
      }
    }
  }
}
```

2. **Verificar code do server:**

Em [`src/knowledge/database.ts`](../modules/ml/unified-llm/mcp-server/src/knowledge/database.ts):
```typescript
const dbPath = process.env.KNOWLEDGE_DB_PATH || 
  join(process.env.PROJECT_ROOT || process.cwd(), 'knowledge.db');
```

---

## Problemas de Permissões

### "EACCES: permission denied"

**Sintomas:**
- Server não consegue escrever em `/var/lib/mcp-knowledge/`
- Erro ao criar knowledge.db

**Diagnóstico:**

```bash
# Verificar owner e permissions
ls -la /var/lib/mcp-knowledge/
stat /var/lib/mcp-knowledge/knowledge.db

# Verificar usuário que roda o server
ps aux | grep "node.*mcp-server"
```

**Soluções:**

1. **Fix via NixOS config (correto):**

[`hosts/kernelcore/configuration.nix`](../hosts/kernelcore/configuration.nix:374):
```nix
systemd.tmpfiles.rules = [
  "d /var/lib/mcp-knowledge 0755 kernelcore users -"
];
```

2. **Fix manual (temporário):**
```bash
sudo chown -R kernelcore:users /var/lib/mcp-knowledge
sudo chmod -R 755 /var/lib/mcp-knowledge
```

### "Operation not permitted" em /nix/store

**Sintomas:**
- Não consegue modificar arquivos no Nix store
- Package tools falham ao escrever

**Explicação:**
- `/nix/store` é read-only por design
- Packages devem ser buildados via `nix build`

**Soluções:**

1. **Usar storage directory correto:**
```bash
# Para packages, usar:
/etc/nixos/modules/packages/tar-packages/storage/
/etc/nixos/modules/packages/deb-packages/storage/
```

2. **Build via Nix:**
```bash
nix build .#lynis-patched
# Resultado em ./result -> /nix/store/...-lynis-patched
```

---

## Comandos de Diagnóstico

### Health Check Completo

```bash
#!/bin/bash
# Script de health check do MCP server

echo "=== MCP Server Health Check ==="
echo

# 1. Server build
echo "1. Verificando build do server..."
if [ -f "/etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js" ]; then
    echo "✅ Server buildado"
else
    echo "❌ Server NÃO buildado"
    echo "   Executar: cd /etc/nixos/modules/ml/unified-llm/mcp-server && npm run build"
fi
echo

# 2. Knowledge database
echo "2. Verificando knowledge database..."
if [ -d "/var/lib/mcp-knowledge" ]; then
    echo "✅ Diretório existe"
    ls -ld /var/lib/mcp-knowledge
    if [ -f "/var/lib/mcp-knowledge/knowledge.db" ]; then
        echo "✅ Database existe"
        ls -lh /var/lib/mcp-knowledge/knowledge.db
    else
        echo "⚠️  Database não existe (será criado ao iniciar)"
    fi
else
    echo "❌ Diretório NÃO existe"
    echo "   Adicionar systemd.tmpfiles.rules em configuration.nix"
fi
echo

# 3. Configurações
echo "3. Verificando configurações..."
if [ -f "/etc/nixos/.roo/mcp.json" ]; then
    echo "✅ .roo/mcp.json existe"
    if jq -e '.mcpServers."securellm-bridge"' /etc/nixos/.roo/mcp.json > /dev/null 2>&1; then
        echo "✅ Server configurado"
    else
        echo "❌ Server NÃO configurado"
    fi
else
    echo "❌ .roo/mcp.json NÃO existe"
fi

if [ -f "/etc/nixos/.claude/settings.local.json" ]; then
    echo "✅ .claude/settings.local.json existe"
    if jq -e '.enableAllProjectMcpServers' /etc/nixos/.claude/settings.local.json | grep -q true; then
        echo "✅ Claude-Code habilitado para MCP servers"
    else
        echo "⚠️  enableAllProjectMcpServers não está true"
    fi
else
    echo "⚠️  .claude/settings.local.json não existe"
fi
echo

# 4. Teste manual
echo "4. Testando server manualmente..."
timeout 2s node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js <<< '{"jsonrpc":"2.0","method":"ping"}' 2>&1 | head -5
echo

echo "=== Fim do Health Check ==="
```

Salvar como `scripts/mcp-health-check.sh` e executar:
```bash
bash scripts/mcp-health-check.sh
```

### Quick Tests

```bash
# Testar build
node /etc/nixos/modules/ml/unified-llm/mcp-server/build/index.js <<< '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}},"id":1}'

# Testar database
sqlite3 /var/lib/mcp-knowledge/knowledge.db "SELECT COUNT(*) FROM knowledge_entries;"

# Testar configs
jq . /etc/nixos/.roo/mcp.json
jq . /etc/nixos/.claude/settings.local.json

# Ver processos ativos
ps aux | grep -i mcp
ps aux | grep "node.*mcp-server"

# Ver logs em tempo real
# VSCodium: Output > MCP: securellm-bridge
# ou journalctl se rodando como service
```

### Debug Mode

Para habilitar debug logging no server, adicionar em config:

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "env": {
        "DEBUG": "mcp:*",
        "LOG_LEVEL": "debug"
      }
    }
  }
}
```

---

## Recursos Adicionais

- [MCP Architecture Access](./MCP-ARCHITECTURE-ACCESS.md) - Arquitetura completa de acesso
- [Package Debugger Architecture](../modules/ml/unified-llm/mcp-server/docs/PACKAGE-DEBUGGER-ARCHITECTURE.md) - Detalhes dos package tools
- [Knowledge DB Fix](./MCP-KNOWLEDGE-DB-FIX.md) - Fix do database de conhecimento
- [MCP Tools Usage Guide](./MCP-TOOLS-USAGE-GUIDE.md) - Como usar os tools

## Suporte

Se o problema persistir:

1. Coletar logs completos (Output > MCP: securellm-bridge)
2. Executar health check: `bash scripts/mcp-health-check.sh`
3. Criar issue no repositório com:
   - Output do health check
   - Logs relevantes
   - Passos para reproduzir
   - Ambiente (NixOS version, VSCodium version, etc.)