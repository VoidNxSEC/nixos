# ============================================================
# DOCKER BUILD & RUN ALIASES
# ============================================================
# Aliases inteligentes para docker build e run com suporte GPU
# Usa flags testadas de gpu-flags.nix
# ============================================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Importa flags GPU do módulo centralizado
  gpuFlags =
    config.shell.gpu.dockerFlags
      or "--device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g";
  pytorchImage = config.shell.gpu.images.pytorch or "nvcr.io/nvidia/pytorch:25.09-py3";

in
{
  # ============================================================
  # DOCKER BUILD ALIASES
  # ============================================================

  environment.shellAliases = {
    # ──────────────────────────────────────────────────────
    # BUILD BÁSICO
    # ──────────────────────────────────────────────────────

    # Build com cache inline (BuildKit)
    dbuild = "docker build --build-arg BUILDKIT_INLINE_CACHE=1";

    # Build sem cache (clean build)
    dbuild-clean = "docker build --no-cache --pull";

    # Build com progress plain (CI/CD friendly)
    dbuild-plain = "docker build --progress=plain";

    # Build com target específico (multi-stage)
    dbuild-target = "docker build --target";

    # ──────────────────────────────────────────────────────
    # BUILD AVANÇADO
    # ──────────────────────────────────────────────────────

    # BuildX multi-platform
    dbuildx = "docker buildx build --platform linux/amd64,linux/arm64";

    # BuildX com push direto
    dbuildx-push = "docker buildx build --platform linux/amd64,linux/arm64 --push";

    # Build com squash (reduz layers)
    dbuild-squash = "docker build --squash";

    # ──────────────────────────────────────────────────────
    # BUILD GPU-SPECIFIC
    # ──────────────────────────────────────────────────────

    # Build com args CUDA
    dbuild-gpu = ''
      docker build \
        --build-arg CUDA_VERSION=12.1.0 \
        --build-arg CUDNN_VERSION=8 \
        --build-arg PYTORCH_VERSION=2.5.0
    '';

    # Build PyTorch GPU otimizado
    dbuild-pytorch = ''
      docker build \
        --build-arg BASE_IMAGE=nvcr.io/nvidia/pytorch:25.09-py3 \
        --build-arg CUDA_ARCH_LIST="7.5;8.0;8.6;9.0" \
        -f Dockerfile.pytorch
    '';

    # ──────────────────────────────────────────────────────
    # DOCKER RUN ALIASES
    # ──────────────────────────────────────────────────────

    # Run básico interativo
    drun = "docker run --rm -it";

    # Run com cleanup automático
    drun-clean = "docker run --rm";

    # Run em background
    drun-d = "docker run -d";

    # ──────────────────────────────────────────────────────
    # DOCKER RUN GPU (FLAGS TESTADAS)
    # ──────────────────────────────────────────────────────

    # Run GPU base (flags completas)
    drun-gpu = "docker run --rm -it ${gpuFlags}";

    # Run GPU com workspace montado
    drun-gpu-workspace = "docker run --rm -it ${gpuFlags} -v $(pwd):/workspace -w /workspace";

    # Run GPU com network host (para APIs)
    drun-gpu-net = "docker run --rm -it ${gpuFlags} --network host";

    # Run GPU em background
    drun-gpu-d = "docker run -d ${gpuFlags}";

    # ──────────────────────────────────────────────────────
    # DOCKER RUN - IMAGENS ESPECÍFICAS
    # ──────────────────────────────────────────────────────

    # PyTorch shell interativo
    drun-pytorch = "docker run --rm -it ${gpuFlags} -v $(pwd):/workspace ${pytorchImage}";

    # PyTorch com Jupyter
    drun-pytorch-jupyter = ''
      docker run --rm -it ${gpuFlags} \
        -v $(pwd):/workspace \
        -p 8888:8888 \
        ${pytorchImage} \
        jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser
    '';

    # TensorFlow GPU shell
    drun-tensorflow = "docker run --rm -it ${gpuFlags} -v $(pwd):/workspace nvcr.io/nvidia/tensorflow:25.09-tf2-py3";

    # ──────────────────────────────────────────────────────
    # DOCKER COMPOSE ALIASES
    # ──────────────────────────────────────────────────────

    # Compose up com rebuild
    dcup-rebuild = "docker compose up -d --build --force-recreate";

    # Compose com profile específico
    dcup-profile = "docker compose --profile";

    # Compose logs com follow
    dclogs = "docker compose logs -f --tail=100";

    # Compose restart serviço específico
    dcrestart = "docker compose restart";

    # Compose pull todas imagens
    dcpull = "docker compose pull";

    # ──────────────────────────────────────────────────────
    # DOCKER UTILITIES
    # ──────────────────────────────────────────────────────

    # Inspeção e debug
    dexec = "docker exec -it";
    dlogs = "docker logs -f --tail=100";
    dinspect = "docker inspect";

    # Stats e monitoring
    dstats = "docker stats --no-stream";
    dstats-live = "docker stats";

    # Network e volumes
    dnet-ls = "docker network ls";
    dvol-ls = "docker volume ls";

    # Cleanup
    dclean = "docker container prune -f";
    dclean-images = "docker image prune -a -f";
    dclean-all = "docker system prune -a --volumes -f";
  };

  # ============================================================
  # FUNÇÕES BASH AVANÇADAS
  # ============================================================

  environment.etc."profile.d/docker-functions.sh" = {
    text = ''
            # ──────────────────────────────────────────────────────
            # DOCKER BUILD FUNCTIONS
            # ──────────────────────────────────────────────────────

            # Build com tag automática (timestamp)
            dbuild-tag() {
                if [ -z "$1" ]; then
                    echo "Usage: dbuild-tag <image-name> [dockerfile]"
                    echo "Example: dbuild-tag myapp Dockerfile"
                    return 1
                fi

                local name="$1"
                local dockerfile="''${2:-Dockerfile}"
                local timestamp=$(date +%Y%m%d-%H%M%S)
                local tag="''${name}:''${timestamp}"

                echo "🔨 Building: $tag"
                docker build -t "$tag" -t "''${name}:latest" -f "$dockerfile" .

                if [ $? -eq 0 ]; then
                    echo "✓ Built successfully:"
                    echo "  - $tag"
                    echo "  - ''${name}:latest"
                else
                    echo "✗ Build failed"
                    return 1
                fi
            }

            # Build GPU com validação
            dbuild-gpu-validate() {
                if [ -z "$1" ]; then
                    echo "Usage: dbuild-gpu-validate <image-name>"
                    return 1
                fi

                local image="$1"

                echo "🔨 Building GPU image: $image"
                docker build \
                    --build-arg CUDA_VERSION=12.1.0 \
                    --build-arg CUDNN_VERSION=8 \
                    -t "$image" .

                if [ $? -ne 0 ]; then
                    echo "✗ Build failed"
                    return 1
                fi

                echo "🧪 Testing CUDA availability..."
                docker run --rm ${gpuFlags} "$image" \
                    python -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'; print('✓ CUDA OK')"

                if [ $? -eq 0 ]; then
                    echo "✓ Image validated: $image"
                else
                    echo "✗ CUDA validation failed"
                    return 1
                fi
            }

            # Build multi-stage com seleção de target
            dbuild-stage() {
                if [ $# -lt 2 ]; then
                    echo "Usage: dbuild-stage <target> <image-name>"
                    echo "Example: dbuild-stage production myapp:prod"
                    return 1
                fi

                local target="$1"
                local image="$2"

                echo "🔨 Building stage '$target' → $image"
                docker build --target "$target" -t "$image" .
            }

            # ──────────────────────────────────────────────────────
            # DOCKER RUN FUNCTIONS
            # ──────────────────────────────────────────────────────

            # Run GPU com port mapping flexível
            drun-gpu-port() {
                if [ -z "$1" ]; then
                    echo "Usage: drun-gpu-port <port> <image> [command]"
                    echo "Example: drun-gpu-port 8888 jupyter/pytorch"
                    return 1
                fi

                local port="$1"
                local image="$2"
                shift 2

                docker run --rm -it ${gpuFlags} \
                    -p "''${port}:''${port}" \
                    -v $(pwd):/workspace \
                    "$image" "$@"
            }

            # Run GPU com env vars customizadas
            drun-gpu-env() {
                if [ -z "$1" ]; then
                    echo "Usage: drun-gpu-env <image> [env_file]"
                    echo "Example: drun-gpu-env myapp .env.dev"
                    return 1
                fi

                local image="$1"
                local env_file="''${2:-.env}"

                if [ -f "$env_file" ]; then
                    docker run --rm -it ${gpuFlags} \
                        --env-file "$env_file" \
                        -v $(pwd):/workspace \
                        "$image"
                else
                    echo "✗ Env file not found: $env_file"
                    return 1
                fi
            }

            # Run PyTorch com script Python
            drun-pytorch-script() {
                if [ -z "$1" ]; then
                    echo "Usage: drun-pytorch-script <script.py> [args...]"
                    return 1
                fi

                local script="$1"
                shift

                if [ ! -f "$script" ]; then
                    echo "✗ Script not found: $script"
                    return 1
                fi

                docker run --rm ${gpuFlags} \
                    -v $(pwd):/workspace \
                    -w /workspace \
                    ${pytorchImage} \
                    python "$script" "$@"
            }

            # ──────────────────────────────────────────────────────
            # DOCKER COMPOSE FUNCTIONS
            # ──────────────────────────────────────────────────────

            # Compose com arquivo específico
            dcomp() {
                if [ -z "$1" ]; then
                    echo "Usage: dcomp <compose-file.yml> [command]"
                    echo "Example: dcomp docker-compose.dev.yml up -d"
                    return 1
                fi

                local compose_file="$1"
                shift
                docker compose -f "$compose_file" "$@"
            }

            # Compose logs de serviço específico
            dcomp-logs() {
                if [ -z "$1" ]; then
                    echo "Usage: dcomp-logs <service> [lines]"
                    return 1
                fi

                local service="$1"
                local lines="''${2:-100}"
                docker compose logs -f --tail="$lines" "$service"
            }

            # ──────────────────────────────────────────────────────
            # DOCKER INFO & DEBUG
            # ──────────────────────────────────────────────────────

            # Informações completas de container
            dinfo() {
                if [ -z "$1" ]; then
                    echo "Usage: dinfo <container-name|id>"
                    return 1
                fi

                local container="$1"

                echo "╔════════════════════════════════════════╗"
                echo "║      Container Information            ║"
                echo "╚════════════════════════════════════════╝"
                echo ""

                echo "📦 Basic Info:"
                docker inspect "$container" --format '  Name: {{.Name}}
        Image: {{.Config.Image}}
        Status: {{.State.Status}}
        Started: {{.State.StartedAt}}'
                echo ""

                echo "🌐 Network:"
                docker inspect "$container" --format '{{range $k, $v := .NetworkSettings.Networks}}  {{$k}}: {{$v.IPAddress}}{{end}}'
                echo ""

                echo "💾 Volumes:"
                docker inspect "$container" --format '{{range .Mounts}}  {{.Source}} → {{.Destination}}{{end}}'
                echo ""

                echo "⚙️  Environment:"
                docker inspect "$container" --format '{{range .Config.Env}}  {{.}}{{end}}' | head -10
            }

            # Teste rápido GPU
            dgpu-test() {
                echo "🧪 Testing GPU access..."
                docker run --rm ${gpuFlags} ${pytorchImage} python -c "
      import torch
      print(f'CUDA available: {torch.cuda.is_available()}')
      if torch.cuda.is_available():
          print(f'GPU: {torch.cuda.get_device_name(0)}')
          print(f'CUDA version: {torch.version.cuda}')
          print(f'PyTorch version: {torch.__version__}')
      else:
          print('✗ CUDA not available')
          exit(1)
      "
            }

            # Export functions
            export -f dbuild-tag
            export -f dbuild-gpu-validate
            export -f dbuild-stage
            export -f drun-gpu-port
            export -f drun-gpu-env
            export -f drun-pytorch-script
            export -f dcomp
            export -f dcomp-logs
            export -f dinfo
            export -f dgpu-test
    '';
    mode = "0755";
  };
}
