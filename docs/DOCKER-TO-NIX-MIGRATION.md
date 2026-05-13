# Docker to Nix Migration Guide

Guia completo para migrar containers Docker/Docker Compose para NixOS containers ou imagens Nix.

## Estratégias de Migração

### 1. Docker Compose → NixOS Container (Recomendado)

Converte serviços do docker-compose.yml para containers NixOS declarativos.

#### Exemplo: Ollama

**Antes (docker-compose.yml):**
```yaml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - /var/lib/ollama:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

**Depois (NixOS):**
```nix
containers.ollama = {
  autoStart = true;
  privateNetwork = true;
  hostAddress = "192.168.200.10";
  localAddress = "192.168.200.11";

  bindMounts = {
    "/var/lib/ollama" = {
      hostPath = "/var/lib/ollama";
      isReadOnly = false;
    };
    "/dev/nvidia0" = {
      hostPath = "/dev/nvidia0";
      isReadOnly = false;
    };
  };

  allowedDevices = [
    { node = "/dev/nvidia0"; modifier = "rw"; }
  ];

  config = { config, pkgs, ... }: {
    networking.firewall.allowedTCPPorts = [ 11434 ];

    services.ollama = {
      enable = true;
      acceleration = "cuda";
      host = "0.0.0.0";
      port = 11434;
    };

    environment.systemPackages = [ pkgs.ollama ];
    system.stateVersion = "25.05";
  };
};
```

### 2. Docker Image → Nix Docker Image

Replique uma imagem Docker existente usando `pkgs.dockerTools`.

#### Exemplo: Replicar postgres:16

**Imagem original:**
```bash
docker pull postgres:16
```

**Replicar em Nix:**
```nix
# lib/packages.nix
image-postgres = pkgs.dockerTools.buildImage {
  name = "ghcr.io/voidnxlabs/postgres";
  tag = "16";

  copyToRoot = pkgs.buildEnv {
    name = "postgres-root";
    paths = with pkgs; [
      bash
      coreutils
      postgresql_16
      su
    ];
    pathsToLink = [ "/bin" "/lib" "/share" ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    mkdir -p /var/lib/postgresql/data
    chown -R postgres:postgres /var/lib/postgresql
  '';

  config = {
    User = "postgres";
    Env = [
      "PATH=/bin"
      "PGDATA=/var/lib/postgresql/data"
      "POSTGRES_USER=postgres"
      "POSTGRES_DB=postgres"
    ];
    ExposedPorts = {
      "5432/tcp" = {};
    };
    Cmd = [
      "${pkgs.postgresql_16}/bin/postgres"
      "-D"
      "/var/lib/postgresql/data"
    ];
  };
};
```

### 3. Dockerfile → Nix Expression

Converte Dockerfile para expressão Nix.

#### Exemplo: Node.js App

**Antes (Dockerfile):**
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**Depois (Nix):**
```nix
# lib/packages.nix
image-nodejs-app = pkgs.dockerTools.buildLayeredImage {
  name = "my-nodejs-app";
  tag = "latest";

  contents = with pkgs; [
    nodejs_22
    nodePackages.npm
    bash
    coreutils
  ];

  config = {
    WorkingDir = "/app";
    Env = [
      "NODE_ENV=production"
      "PATH=/bin"
    ];
    ExposedPorts = {
      "3000/tcp" = {};
    };
    Cmd = [
      "${pkgs.nodejs_22}/bin/npm"
      "start"
    ];
  };
};
```

### 4. Import Docker Image Diretamente

Use `dockerTools.pullImage` para importar imagens existentes.

```nix
# lib/packages.nix
let
  redis-upstream = pkgs.dockerTools.pullImage {
    imageName = "redis";
    imageDigest = "sha256:...";
    sha256 = "sha256-...";
    finalImageTag = "7-alpine";
  };
in
{
  # Usar imagem upstream diretamente
  image-redis-imported = redis-upstream;

  # Ou customizar
  image-redis-custom = pkgs.dockerTools.buildImage {
    name = "redis-custom";
    fromImage = redis-upstream;

    config = {
      Env = [ "REDIS_CUSTOM=true" ];
    };
  };
}
```

## Ferramentas de Conversão Automática

### Script: docker-compose-to-nix.sh

```bash
#!/usr/bin/env bash
# Converte docker-compose.yml para módulo NixOS

set -euo pipefail

COMPOSE_FILE="${1:-docker-compose.yml}"
OUTPUT_FILE="${2:-docker-compose.nix}"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Erro: $COMPOSE_FILE não encontrado"
    exit 1
fi

echo "Convertendo $COMPOSE_FILE para $OUTPUT_FILE..."

# Parse YAML e gere Nix (simplificado)
cat > "$OUTPUT_FILE" <<'EOF'
# Auto-generated from docker-compose.yml
{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    # TODO: Add options
  };

  config = {
    containers = {
      # TODO: Add container definitions
    };
  };
}
EOF

echo "Template criado em $OUTPUT_FILE"
echo "ATENÇÃO: Você precisa completar manualmente a conversão"
```

### Tool: compose2nix

```bash
# Instalar compose2nix (se existir no nixpkgs)
nix-shell -p compose2nix

# Converter
compose2nix docker-compose.yml > docker-compose.nix
```

## Casos de Uso Comuns

### Migrar Stack Completa

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  app:
    image: node:22
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    depends_on:
      - db
      - redis

  db:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  pgdata:
```

**Convertido para NixOS:**
```nix
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-app+" ];
  };

  # App container
  containers.app = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.220.10";
    localAddress = "192.168.220.11";

    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 3000 ];

      environment.systemPackages = with pkgs; [
        nodejs_22
        nodePackages.npm
      ];

      environment.variables = {
        DATABASE_URL = "postgresql://user:pass@192.168.220.12:5432/mydb";
        REDIS_URL = "redis://192.168.220.13:6379";
      };

      system.stateVersion = "25.05";
    };
  };

  # PostgreSQL container
  containers.db = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.220.10";
    localAddress = "192.168.220.12";

    bindMounts."/var/lib/postgresql/data" = {
      hostPath = "/var/lib/app-stack/pgdata";
      isReadOnly = false;
    };

    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 5432 ];

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_16;
        enableTCPIP = true;
        authentication = ''
          host all all 192.168.220.0/24 md5
        '';
        initialScript = pkgs.writeText "init.sql" ''
          CREATE USER user WITH PASSWORD 'pass';
          CREATE DATABASE mydb OWNER user;
        '';
      };

      system.stateVersion = "25.05";
    };
  };

  # Redis container
  containers.redis = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.220.10";
    localAddress = "192.168.220.13";

    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 6379 ];

      services.redis.servers."" = {
        enable = true;
        bind = "0.0.0.0";
        port = 6379;
      };

      system.stateVersion = "25.05";
    };
  };
}
```

## Tabela de Conversão Rápida

| Docker Compose | NixOS Container | Notas |
|----------------|-----------------|-------|
| `image: name:tag` | `environment.systemPackages = [ pkgs.name ]` | Ou `services.name.enable` |
| `ports: - "8080:80"` | `networking.firewall.allowedTCPPorts = [ 80 ]` | Port mapping via NAT |
| `volumes: - ./data:/data` | `bindMounts."/data" = { hostPath = "./data"; }` | Bind mount |
| `environment: - VAR=value` | `environment.variables.VAR = "value"` | Environment vars |
| `depends_on: - service` | Gerenciado via systemd | Automático |
| `restart: always` | `autoStart = true` | Auto-start |
| `networks: - mynet` | `privateNetwork = true` | Private network |
| `deploy.resources.limits` | `systemd.services.*.serviceConfig` | Via systemd |

## Migração Híbrida

Você pode manter alguns serviços no Docker e outros no NixOS:

```nix
{
  # Docker para serviços complexos
  virtualisation.docker.enable = true;

  # NixOS containers para serviços simples
  containers.app = { ... };

  # Networking compartilhado
  networking.bridges.br0.interfaces = [ ];
  networking.interfaces.br0.ipv4.addresses = [{
    address = "192.168.100.1";
    prefixLength = 24;
  }];
}
```

## Build e Test

### Testar conversão

```bash
# Build container NixOS
sudo nixos-rebuild test --flake .#

# Verificar container
nixos-container status app
nixos-container list

# Testar conectividade
curl http://192.168.220.11:3000

# Logs
journalctl -u container@app -f
```

### Build imagem Docker

```bash
# Build
nix build .#image-app

# Load
docker load < result

# Test
docker run -it ghcr.io/voidnxlabs/app:latest

# Compare com original
docker images | grep app
```

## Best Practices

1. **Comece simples**: Migre um serviço por vez
2. **Use NixOS services quando disponível**: `services.postgresql.enable` é melhor que container
3. **Bind mounts para dados**: Persistência de dados
4. **Private networks**: Isolamento entre containers
5. **Teste antes de commit**: Use `nixos-rebuild test`

## Troubleshooting

### Container não inicia

```bash
# Check systemd
systemctl status container@app

# Check logs
journalctl -u container@app -xe

# Rebuild verbose
sudo nixos-rebuild switch --show-trace
```

### Networking não funciona

```bash
# Verify NAT
iptables -t nat -L -n -v

# Ping test
nixos-container run app -- ping 8.8.8.8

# Check interfaces
ip addr show | grep ve-
```

### Package não encontrado

```bash
# Search package
nix search nixpkgs nodejs

# Check if available
nix-env -qaP nodejs

# Use unstable if needed
environment.systemPackages = [
  pkgs.unstable.nodejs_22
];
```

## Ferramentas Úteis

```nix
# Helper para debug
environment.systemPackages = with pkgs; [
  nixos-container  # Gerenciar containers
  docker-compose   # Comparar com compose
  jq               # Parse JSON
  yq               # Parse YAML
];
```

## Exemplos Reais

### WordPress Stack

```nix
# WordPress + MySQL + Nginx
containers = {
  wordpress = { ... };  # PHP + WordPress
  mysql = { ... };      # MySQL database
  nginx = { ... };      # Reverse proxy
};
```

### Monitoring Stack

```nix
# Prometheus + Grafana + Node Exporter
containers = {
  prometheus = { ... };
  grafana = { ... };
  node-exporter = { ... };
};
```

### Development Stack

```nix
# App + DB + Cache + Queue
containers = {
  app = { ... };        # Your app
  postgres = { ... };   # Database
  redis = { ... };      # Cache
  rabbitmq = { ... };   # Message queue
};
```

## Próximos Passos

1. Identifique serviços críticos para migrar
2. Converta um serviço de teste primeiro
3. Teste extensivamente
4. Migre gradualmente outros serviços
5. Documente configurações específicas
6. Automatize builds com CI/CD

## Recursos

- [NixOS Containers Manual](https://nixos.org/manual/nixos/stable/#ch-containers)
- [dockerTools Documentation](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
- [Compose2Nix Project](https://github.com/aksiksi/compose2nix)
