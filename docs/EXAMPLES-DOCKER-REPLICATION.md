# Exemplos Práticos: Replicando Containers Docker

Exemplos reais de como replicar containers do seu docker-hub para Nix.

## Exemplo 1: Replicar Ollama do Docker Compose

### Passo 1: Inspecionar Container Existente

```bash
# Se o container está rodando
docker ps | grep ollama

# Usar o script de conversão
/etc/nixos/scripts/docker-inspect-to-nix.sh ollama

# Resultado: ollama.nix gerado
```

### Passo 2: Usar Módulo Pronto

Como Ollama já está no módulo `ml-containers.nix`, é só habilitar:

```nix
# hosts/kernelcore/configuration.nix
{
  kernelcore.containers.ml.ollama = {
    enable = true;
    port = 11434;
    modelsPath = "/var/lib/ollama/models";
  };
}
```

### Passo 3: Rebuild e Testar

```bash
# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Verificar
ml-ollama-status

# Testar API
curl http://192.168.200.11:11434/api/tags
```

## Exemplo 2: Replicar ComfyUI

### Do Docker Hub para Nix

**Seu setup atual (docker-compose.yml):**
```yaml
services:
  comfyui:
    image: comfyui/comfyui:latest
    ports:
      - "8188:8188"
    volumes:
      - ./ComfyUI:/workspace
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

**Já está no módulo ml-containers.nix:**
```nix
{
  kernelcore.containers.ml.comfyui = {
    enable = true;
    port = 8188;
  };
}
```

## Exemplo 3: Replicar Chat-UI Customizado

### Se você tem um container customizado

```bash
# Inspecionar container rodando
docker inspect sillytavern

# Ou usar o script
/etc/nixos/scripts/docker-inspect-to-nix.sh sillytavern
```

Isso gera um template que você pode ajustar:

```nix
# sillytavern.nix (gerado + ajustado)
{ config, lib, pkgs, ... }:

{
  containers.sillytavern = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.240.10";
    localAddress = "192.168.240.11";

    bindMounts = {
      "/app/data" = {
        hostPath = "/home/kernelcore/dev/low-level/docker-hub/ml-clusters/sillytavern/data";
        isReadOnly = false;
      };
    };

    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 8000 ];

      environment.systemPackages = with pkgs; [
        nodejs_22
        nodePackages.npm
        git
      ];

      # Clone SillyTavern
      systemd.services.sillytavern-setup = {
        description = "Setup SillyTavern";
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          if [ ! -d /app/SillyTavern ]; then
            ${pkgs.git}/bin/git clone https://github.com/SillyTavern/SillyTavern.git /app/SillyTavern
            cd /app/SillyTavern
            ${pkgs.nodejs_22}/bin/npm install
          fi
        '';
      };

      # Run SillyTavern
      systemd.services.sillytavern = {
        description = "SillyTavern Server";
        after = [ "network.target" "sillytavern-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          WorkingDirectory = "/app/SillyTavern";
          ExecStart = "${pkgs.nodejs_22}/bin/node server.js";
          Restart = "always";
        };
      };

      system.stateVersion = "25.05";
    };
  };
}
```

## Exemplo 4: Build Imagem Docker a partir do Container

### Cenário: Você quer uma imagem Docker, não container NixOS

```bash
# 1. Build a imagem
nix build .#image-python-ml

# 2. Load no Docker
docker load < result

# 3. Rodar como faria normalmente
docker run -it --rm \
  -p 8888:8888 \
  -v $(pwd)/notebooks:/workspace \
  ghcr.io/voidnxlabs/python-ml:latest
```

### Customizar imagem existente

```nix
# lib/packages.nix - adicionar nova imagem baseada em existente
image-python-ml-custom = pkgs.dockerTools.buildImage {
  name = "ghcr.io/voidnxlabs/python-ml-custom";
  tag = "latest";

  fromImage = self.packages.${system}.image-python-ml;

  copyToRoot = pkgs.buildEnv {
    name = "custom-packages";
    paths = with pkgs; [
      # Adicionar mais pacotes
      python313Packages.opencv4
      python313Packages.plotly
      ffmpeg
    ];
  };

  config = {
    Env = [
      "PATH=/bin"
      "CUSTOM_VAR=value"
    ];
  };
};
```

## Exemplo 5: Migrar Stack Completa do ml-clusters

### Seu ml-clusters/docker-compose.yml atual

```yaml
services:
  ollama:
    image: ollama/ollama
    ports: ["11434:11434"]

  jupyter:
    image: jupyter/scipy-notebook
    ports: ["8888:8888"]

  postgres:
    image: postgres:16
    ports: ["5432:5432"]
```

### Migrado para Nix (tudo declarativo)

```nix
# hosts/kernelcore/configuration.nix
{
  # ML Stack
  kernelcore.containers.ml = {
    enable = true;
    ollama.enable = true;
    jupyter.enable = true;
  };

  # Dev Stack
  kernelcore.containers.dev = {
    enable = true;
    postgres.enable = true;
  };
}
```

**Benefícios:**
- ✅ Tudo em um rebuild: `sudo nixos-rebuild switch`
- ✅ Versionado no Git (flake.lock)
- ✅ Rollback fácil: `nixos-rebuild switch --rollback`
- ✅ Reproduzível em qualquer máquina

## Exemplo 6: Replicar Imagem do Docker Hub

### Importar imagem oficial

```nix
# lib/packages.nix
let
  # Pull imagem oficial do Redis
  redis-official = pkgs.dockerTools.pullImage {
    imageName = "redis";
    imageDigest = "sha256:abcd1234...";
    sha256 = "sha256-xyz...";  # nix-prefetch-docker redis latest
    finalImageTag = "7-alpine";
  };
in
{
  # Usar diretamente
  image-redis-official = redis-official;

  # Ou customizar
  image-redis-custom = pkgs.dockerTools.buildImage {
    name = "redis-custom";
    fromImage = redis-official;

    copyToRoot = pkgs.buildEnv {
      name = "redis-tools";
      paths = [ pkgs.redis pkgs.bash ];
    };

    config = {
      Env = [ "REDIS_CUSTOM_CONFIG=true" ];
    };
  };
}
```

### Get image hash

```bash
# Usar nix-prefetch-docker
nix-shell -p nix-prefetch-docker

# Fetch Redis
nix-prefetch-docker --image-name redis --image-tag 7-alpine
```

## Exemplo 7: Converter Dockerfile para Nix

### Seu Dockerfile

```dockerfile
FROM python:3.13-slim
WORKDIR /app
RUN pip install fastapi uvicorn
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]
```

### Equivalente em Nix

```nix
# lib/packages.nix
image-fastapi-app = pkgs.dockerTools.buildLayeredImage {
  name = "my-fastapi-app";
  tag = "latest";

  contents = with pkgs; [
    python313
    python313Packages.fastapi
    python313Packages.uvicorn
    bash
    coreutils
  ];

  extraCommands = ''
    mkdir -p app
    # Copy your app files here
    # cp ${./app}/* app/
  '';

  config = {
    WorkingDir = "/app";
    Env = [
      "PATH=/bin"
      "PYTHONUNBUFFERED=1"
    ];
    ExposedPorts = {
      "8000/tcp" = {};
    };
    Cmd = [
      "${pkgs.python313Packages.uvicorn}/bin/uvicorn"
      "main:app"
      "--host"
      "0.0.0.0"
    ];
  };
};
```

**Vantagens sobre Dockerfile:**
- ✅ Builds cacheadas por Nix (mais rápido)
- ✅ Layers otimizadas automaticamente
- ✅ Reproduzível (hash-based)
- ✅ Não precisa de Docker daemon para build

## Exemplo 8: Setup Híbrido (Docker + NixOS Containers)

### Melhor dos dois mundos

```nix
{
  # Docker para casos complexos (ex: imagens proprietárias)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Aliases para docker-compose atual
  environment.shellAliases = {
    ml-docker-up = "cd ~/dev/low-level/docker-hub/ml-clusters && docker-compose up -d";
  };

  # NixOS containers para serviços novos
  kernelcore.containers.ml = {
    enable = true;
    ollama.enable = true;  # Migrado para Nix
    jupyter.enable = true; # Migrado para Nix
  };

  # Ainda usa Docker para ComfyUI (imagem complexa)
  # Mantém em docker-compose por enquanto
}
```

## Exemplo 9: CI/CD - Build e Push Automático

### GitHub Actions

```yaml
# .github/workflows/build-images.yml
name: Build and Push Nix Images

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: cachix/install-nix-action@v24
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Build images
        run: |
          nix build .#image-ollama
          nix build .#image-python-ml

      - name: Login to GHCR
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Load and push
        run: |
          docker load < result
          docker push ghcr.io/voidnxlabs/ollama:latest
```

## Exemplo 10: Test Drive - Comparação Lado a Lado

### Setup para testar ambos

```bash
# Terminal 1: Docker original
cd ~/dev/low-level/docker-hub/ml-clusters
docker-compose up ollama

# Terminal 2: NixOS container
sudo nixos-rebuild switch
ml-ollama-start

# Terminal 3: Comparar performance
# Docker
time curl http://localhost:11434/api/tags

# NixOS container
time curl http://192.168.200.11:11434/api/tags
```

## Resumo de Comandos Úteis

```bash
# Converter container Docker existente
/etc/nixos/scripts/docker-inspect-to-nix.sh <container-name>

# Build imagem Nix
nix build .#image-<name>

# Load em Docker
docker load < result

# Build todas as imagens
/etc/nixos/scripts/build-container-images.sh --all

# Listar imagens disponíveis
/etc/nixos/scripts/build-container-images.sh --list

# Enable ML containers
# Edit configuration.nix, then:
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Gerenciar containers
ml-status-all       # Status de todos ML containers
ml-ollama-enter     # Entrar no container
ml-ollama-logs      # Ver logs (via journalctl)
```

## Decisão: Docker vs NixOS Container vs Nix Image?

| Caso de Uso | Recomendação |
|-------------|--------------|
| Imagem oficial complexa (ex: TensorFlow) | Docker compose |
| Serviço com NixOS module (Postgres, Redis) | NixOS container |
| App customizado simples | NixOS container |
| Precisa rodar em outro host | Nix Docker image |
| Desenvolvimento rápido | Docker compose |
| Produção declarativa | NixOS container |
| CI/CD build | Nix Docker image |

## Próximos Passos

1. **Teste um container simples**: Comece com Redis ou Postgres
2. **Migre gradualmente**: Um serviço por vez
3. **Compare performance**: Lado a lado com Docker
4. **Documente diferenças**: Ajuste configs conforme necessário
5. **Automatize**: Setup CI/CD quando estabilizar

Quer testar agora? Escolha um container do seu ml-clusters e vamos converter!
