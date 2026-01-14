# Guia de Integração do Servidor MCP

Este guia mostra como integrar o servidor MCP SecureLLM Bridge ao seu sistema NixOS.

## 📦 Instalação Rápida

### Opção 1: Usando o Módulo de Serviço (Recomendado)

Adicione ao seu `hosts/kernelcore/configuration.nix` ou `default.nix`:

```nix
{
  imports = [
    ../../modules/services/mcp-server.nix
  ];

  # Habilitar o servidor MCP
  services.securellm-mcp = {
    enable = true;
    user = "kernelcore";  # Seu usuário
    dataDir = "/var/lib/mcp-knowledge";
    autoConfigureClaudeDesktop = true;
  };
}
```

Depois rebuild:
```bash
sudo nixos-rebuild switch --flake .#kernelcore
```

### Opção 2: Instalação Manual (Apenas o Pacote)

Adicione ao `environment.systemPackages`:

```nix
{
  environment.systemPackages = [
    (pkgs.callPackage ../../lib/packages.nix {}).securellm-mcp
  ];
}
```

## 🚀 Uso

### Com o Módulo de Serviço

Após habilitar o módulo, você terá acesso aos seguintes comandos:

```bash
# Ver status do servidor MCP
mcp-server status
# ou simplesmente
mcp status

# Testar conexão
mcp-server test

# Ver configuração atual
mcp-server config

# Informações do banco de conhecimento
mcp-server db-info

# Backup do banco
mcp-server db-backup

# Rebuild do pacote
mcp-server rebuild

# Help completo
mcp-server help
```

### Comandos Disponíveis

#### Status e Diagnóstico
```bash
mcp-server status     # Status completo do sistema
mcp-server test       # Testa conectividade
mcp-server config     # Mostra configuração atual
```

#### Gerenciamento do Banco de Dados
```bash
mcp-server db-info    # Info do knowledge database
mcp-server db-backup  # Criar backup
```

#### Desenvolvimento
```bash
mcp-server rebuild    # Rebuild do pacote MCP
mcp-server version    # Versão do servidor
```

## 🔧 Configuração do Claude Desktop

### Automática (Com Módulo)

Se você habilitou `autoConfigureClaudeDesktop = true`, o arquivo `.mcp.json` será criado automaticamente em `~/.config/Claude/.mcp.json`.

### Manual

Crie ou edite `~/.config/Claude/.mcp.json`:

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

Ou use o caminho direto do Nix store:

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

Obtenha o caminho do store com:
```bash
readlink -f $(which securellm-mcp)
```

## 📍 Localizações Importantes

| Item | Localização |
|------|-------------|
| **Binário MCP** | `/nix/store/<hash>-securellm-bridge-mcp-2.0.0/bin/securellm-mcp` |
| **Banco de Dados** | `/var/lib/mcp-knowledge/knowledge.db` (padrão do módulo) |
| **Config Claude** | `~/.config/Claude/.mcp.json` |
| **Source TypeScript** | `/etc/nixos/modules/ml/unified-llm/mcp-server/` |
| **Package Nix** | `/etc/nixos/lib/packages.nix` |

## 🛠️ Desenvolvimento Local

### Workflow Completo

1. **Editar código TypeScript**
   ```bash
   cd /etc/nixos/modules/ml/unified-llm/mcp-server
   # Edite arquivos em src/
   ```

2. **Compilar TypeScript**
   ```bash
   npm run build
   # Ou para watch mode:
   npm run watch
   ```

3. **Testar localmente (opcional)**
   - Aponte o `.mcp.json` para o build local:
   ```json
   {
     "mcpServers": {
       "securellm-bridge": {
         "command": "/run/current-system/sw/bin/node",
         "args": [
           "/etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js"
         ]
       }
     }
   }
   ```

4. **Rebuild do pacote Nix**
   ```bash
   cd /etc/nixos
   nix build .#securellm-mcp
   ```

5. **Atualizar sistema**
   ```bash
   sudo nixos-rebuild switch --flake .#kernelcore
   ```

6. **Voltar config para produção**
   - Restaure o `.mcp.json` para usar `nix run .#securellm-mcp`

## 🔍 Troubleshooting

### MCP Server não inicia

```bash
# Verificar se o binário existe
which securellm-mcp

# Verificar permissões do banco
ls -la /var/lib/mcp-knowledge/

# Testar execução direta
securellm-mcp

# Ver logs do Claude Desktop (se disponível)
journalctl --user -u claude-desktop
```

### Banco de dados não encontrado

```bash
# Criar diretório manualmente
sudo mkdir -p /var/lib/mcp-knowledge
sudo chown $USER:users /var/lib/mcp-knowledge

# Ou usar localização no home
export KNOWLEDGE_DB_PATH="$HOME/.local/share/securellm/knowledge.db"
mkdir -p "$HOME/.local/share/securellm"
```

### Build falha

```bash
# Limpar build cache
nix-collect-garbage

# Rebuild from scratch
cd /etc/nixos
nix build .#securellm-mcp --rebuild

# Ver logs completos
nix log $(nix-store -qd $(nix-build .#securellm-mcp))
```

### Claude Desktop não vê o servidor

1. Verifique o `.mcp.json` está em `~/.config/Claude/`
2. Reinicie o Claude Desktop completamente
3. Verifique os logs do Claude (varia por plataforma)

## 📊 Monitoramento

### Ver estatísticas do banco

```bash
sqlite3 /var/lib/mcp-knowledge/knowledge.db <<EOF
SELECT 'Total Sessions:', COUNT(*) FROM sessions;
SELECT 'Total Entries:', COUNT(*) FROM knowledge_entries;
SELECT 'Database Size:', (page_count * page_size) / 1024 / 1024 || ' MB' 
  FROM pragma_page_count(), pragma_page_size();
EOF
```

### Backup automatizado

Adicione ao seu `configuration.nix`:

```nix
systemd.services.mcp-backup = {
  description = "Backup MCP Knowledge Database";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.bash}/bin/bash -c 'cp /var/lib/mcp-knowledge/knowledge.db /var/lib/mcp-knowledge/backups/knowledge-$(date +%Y%m%d).db'";
    User = "kernelcore";
  };
};

systemd.timers.mcp-backup = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};
```

## 🎯 Próximos Passos

1. **Verifique a instalação**
   ```bash
   mcp-server status
   ```

2. **Teste a conexão**
   ```bash
   mcp-server test
   ```

3. **Configure o Claude Desktop**
   - Reinicie o Claude Desktop
   - Verifique se o servidor MCP aparece

4. **Use no Claude**
   - Abra o Claude Desktop
   - Os tools do MCP estarão disponíveis automaticamente

## 📚 Documentação Adicional

- [MCP Server Package Guide](./MCP-SERVER-PACKAGE.md) - Detalhes do empacotamento
- [MCP Extended Tools Design](./MCP-EXTENDED-TOOLS-DESIGN.md) - Arquitetura das tools
- [Repository Guidelines](../AGENTS.md) - Padrões do projeto

## 🆘 Suporte

- Consulte os logs: `journalctl --user`
- Use o MCP helper: `mcp-server help`
- Verifique a documentação do projeto
