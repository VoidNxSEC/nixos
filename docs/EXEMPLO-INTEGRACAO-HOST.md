# Exemplo: Integração do MCP Server no Host

Este documento mostra exemplos práticos de como integrar o servidor MCP no seu host NixOS.

## Método 1: Adicionar no configuration.nix do Host

Edite `hosts/kernelcore/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./default.nix
    # ... outros imports
  ];

  # Habilitar servidor MCP
  services.securellm-mcp = {
    enable = true;
    user = "kernelcore";
    dataDir = "/var/lib/mcp-knowledge";
    autoConfigureClaudeDesktop = true;
  };

  # Resto da configuração...
}
```

## Método 2: Adicionar no default.nix do Host

Edite `hosts/kernelcore/default.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/services/mcp-server.nix
    # ... outros módulos
  ];

  # Habilitar servidor MCP
  services.securellm-mcp = {
    enable = true;
    user = config.users.users.kernelcore.name;  # Usa o usuário configurado
    dataDir = "/var/lib/mcp-knowledge";
    autoConfigureClaudeDesktop = true;
  };

  # ... resto da config
}
```

## Método 3: Apenas o Pacote (Sem Módulo)

Se você só quer o binário disponível sem o módulo de serviço:

```nix
{ config, pkgs, ... }:

let
  mcpPackages = import ../../lib/packages.nix { inherit pkgs; self = {}; };
in
{
  environment.systemPackages = [
    mcpPackages.securellm-mcp
  ];
}
```

## Método 4: Overlay Global

Para disponibilizar em todo o sistema, adicione ao flake.nix:

```nix
{
  nixpkgs.overlays = [
    (final: prev: {
      securellm-mcp = (import ./lib/packages.nix { 
        pkgs = final; 
        self = self; 
      }).securellm-mcp;
    })
  ];

  # Agora pode usar em qualquer lugar:
  environment.systemPackages = [ pkgs.securellm-mcp ];
}
```

## Rebuild do Sistema

Depois de adicionar ao seu host:

```bash
# Preview das mudanças (dry run)
sudo nixos-rebuild dry-build --flake .#kernelcore

# Build sem ativar
sudo nixos-rebuild build --flake .#kernelcore

# Ativar as mudanças
sudo nixos-rebuild switch --flake .#kernelcore
```

## Verificação Pós-Instalação

```bash
# Verificar se o binário está disponível
which securellm-mcp

# Ver status do MCP (se usando o módulo)
mcp-server status

# Testar execução
securellm-mcp --version 2>&1 || echo "Binary executável"

# Verificar configuração do Claude
cat ~/.config/Claude/.mcp.json
```

## Configurações Avançadas

### Banco de Dados Personalizado

```nix
services.securellm-mcp = {
  enable = true;
  user = "kernelcore";
  dataDir = "/home/kernelcore/.local/share/mcp";  # Localização customizada
  autoConfigureClaudeDesktop = true;
};
```

### Múltiplos Usuários

```nix
services.securellm-mcp = {
  enable = true;
  user = "kernelcore";
  dataDir = "/var/lib/mcp-knowledge";
};

# Dar permissão para outros usuários
users.users.outro-usuario.extraGroups = [ "users" ];
```

### Sem Auto-Configuração

```nix
services.securellm-mcp = {
  enable = true;
  user = "kernelcore";
  dataDir = "/var/lib/mcp-knowledge";
  autoConfigureClaudeDesktop = false;  # Configure manualmente
};
```

## Próximos Passos

Após rebuild:

1. **Reinicie o Claude Desktop** (se estiver rodando)
2. **Verifique o status**: `mcp-server status`
3. **Teste a conexão**: `mcp-server test`
4. **Abra o Claude Desktop** - O servidor MCP estará ativo

## Troubleshooting

### Módulo não encontrado

Se você ver erro `module not found`:

```bash
# Verifique que o módulo existe
ls -la modules/services/mcp-server.nix

# Verifique o import path no seu host
grep -r "mcp-server.nix" hosts/kernelcore/
```

### Package não disponível

Se você ver erro `securellm-mcp not found`:

```bash
# Verifique que o package foi buildado
nix build .#securellm-mcp

# Adicione ao overlay ou importe diretamente
```

### Permissões do Banco de Dados

```bash
# Criar diretório manualmente
sudo mkdir -p /var/lib/mcp-knowledge
sudo chown $USER:users /var/lib/mcp-knowledge
sudo chmod 755 /var/lib/mcp-knowledge
```
