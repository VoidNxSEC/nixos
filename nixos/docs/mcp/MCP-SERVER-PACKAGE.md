# MCP Server Package Guide

## Overview

O servidor MCP SecureLLM Bridge está empacotado como um derivação Nix para facilitar a integração com o flake e garantir builds reproduzíveis.

## Build do Pacote

```bash
# Build do servidor MCP empacotado
nix build .#securellm-mcp

# Executar diretamente
nix run .#securellm-mcp

# O binário também está disponível em:
./result/bin/securellm-mcp
```

## Integração com Claude Desktop

O arquivo `.mcp.json` na raiz do projeto está configurado para usar o pacote empacotado:

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "nix",
      "args": [
        "run",
        ".#securellm-mcp",
        "--"
      ],
      "env": {
        "KNOWLEDGE_DB_PATH": "${HOME}/.local/share/securellm/knowledge.db",
        "ENABLE_KNOWLEDGE": "true"
      }
    }
  }
}
```

### Alternativa: Uso Direto do Binário

Se preferir apontar diretamente para o binário no Nix store:

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "/nix/store/<hash>-securellm-bridge-mcp-2.0.0/bin/securellm-mcp",
      "env": {
        "KNOWLEDGE_DB_PATH": "${HOME}/.local/share/securellm/knowledge.db",
        "ENABLE_KNOWLEDGE": "true"
      }
    }
  }
}
```

Obtenha o caminho exato com:
```bash
readlink -f result/bin/securellm-mcp
```

## Workflow de Desenvolvimento

### Desenvolvimento Local (TypeScript)

Para desenvolvimento ativo com hot-reload:

```bash
cd modules/ml/unified-llm/mcp-server

# Instalar dependências
npm install

# Build TypeScript
npm run build

# Watch mode para desenvolvimento
npm run watch
```

### Configuração do Claude Desktop para Desenvolvimento

Durante o desenvolvimento, aponte para o build local:

```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "/run/current-system/sw/bin/node",
      "args": [
        "/etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js"
      ],
      "env": {
        "KNOWLEDGE_DB_PATH": "${HOME}/.local/share/securellm/knowledge.db",
        "ENABLE_KNOWLEDGE": "true"
      }
    }
  }
}
```

### Build e Deploy

Quando as mudanças estiverem prontas:

1. **Commitar mudanças no TypeScript**
   ```bash
   cd modules/ml/unified-llm/mcp-server
   npm run build
   git add src/ build/
   git commit -m "feat: nova funcionalidade no MCP server"
   ```

2. **Rebuild do pacote Nix**
   ```bash
   cd /etc/nixos
   nix build .#securellm-mcp
   ```

3. **Atualizar configuração do Claude Desktop para produção**
   - Alterar `.mcp.json` para usar `nix run .#securellm-mcp`

4. **Validar integração**
   ```bash
   # Verificar que o package está nos checks
   nix flake check
   ```

## Estrutura do Pacote

```
lib/packages.nix
├── securellm-mcp (buildNpmPackage)
    ├── src: modules/ml/unified-llm/mcp-server
    ├── npmDepsHash: "sha256-u0xDEW8vlMcyJtnMEPuVDhJv/piK6lUHKPlkAU5H6+8="
    ├── nativeBuildInputs: python3, node-gyp
    ├── buildInputs: sqlite
    └── output: $out/bin/securellm-mcp (wrapper script)
```

## Troubleshooting

### Build Falha com npm

Se o build falhar devido a dependências npm:

1. Deletar `package-lock.json` local
2. Regenerar com `npm install`
3. Atualizar `npmDepsHash` em `lib/packages.nix`:
   ```bash
   nix build .#securellm-mcp 2>&1 | grep "got:"
   # Copiar o hash e atualizar no packages.nix
   ```

### Better-sqlite3 Compilation Errors

O pacote já inclui as dependências nativas necessárias:
- `python3` para node-gyp
- `sqlite` para better-sqlite3

Se houver erros, verifique que estas estão em `buildInputs`.

### Puppeteer Download Fails

O pacote já configura:
```nix
PUPPETEER_SKIP_DOWNLOAD = "1";
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "1";
```

Puppeteer não fará download do Chromium durante o build.

## Continuous Integration

O pacote está incluído nos checks do flake:

```nix
# flake.nix
checks = {
  mcp-server = self.packages.${system}.securellm-mcp;
};
```

Isso garante que o MCP server builda corretamente em CI.

## Versionamento

A versão é definida em dois lugares:
1. `modules/ml/unified-llm/mcp-server/package.json` - Versão npm
2. `lib/packages.nix` - Versão do pacote Nix

Mantenha ambas sincronizadas ao fazer releases.