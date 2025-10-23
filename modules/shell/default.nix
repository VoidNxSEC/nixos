# ============================================================
# SHELL MODULE - Orquestrador
# ============================================================
# Módulo central para gerenciamento de aliases, scripts e shell
# Integra: GPU flags, Docker, Python automation
# ============================================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./gpu-flags.nix
    ./aliases/docker-build.nix
    ./aliases/gcloud-k8s.nix
  ];

  # ============================================================
  # OPTIONS (para outros módulos acessarem)
  # ============================================================

  options.shell = {
    enableGpuMonitor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GPU monitor daemon (systemd service)";
    };

    pythonScriptsPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos-shell/scripts";
      description = "Path to Python automation scripts";
      readOnly = true;
    };
  };

  # ============================================================
  # CONFIGURATION
  # ============================================================

  config = {

    # ============================================================
    # PACOTES NECESSÁRIOS
    # ============================================================

    environment.systemPackages = with pkgs; [
      # Docker & Container Tools
      docker
      docker-compose
      docker-buildx

      # GPU & NVIDIA
      nvidia-docker

      # Python para scripts
      python3
      python3Packages.pip

      # Utilitários
      jq
      curl
      wget
      git
      git-lfs
    ];

    # ============================================================
    # SCRIPTS PYTHON - Instalação System-wide
    # ============================================================

    environment.etc = {
      # GPU Monitor
      "nixos-shell/scripts/gpu_monitor.py" = {
        source = ./scripts/python/gpu_monitor.py;
        mode = "0755";
      };

      # Model Manager
      "nixos-shell/scripts/model_manager.py" = {
        source = ./scripts/python/model_manager.py;
        mode = "0755";
      };
    };

    # ============================================================
    # ALIASES PARA SCRIPTS PYTHON
    # ============================================================

    environment.shellAliases = {
      # GPU Monitor
      gpu-monitor = "python3 /etc/nixos-shell/scripts/gpu_monitor.py";
      gpu-monitor-json = "python3 /etc/nixos-shell/scripts/gpu_monitor.py json";
      gpu-monitor-summary = "python3 /etc/nixos-shell/scripts/gpu_monitor.py summary";

      # Model Manager
      model-search = "python3 /etc/nixos-shell/scripts/model_manager.py search";
      model-install = "python3 /etc/nixos-shell/scripts/model_manager.py install";
      model-list = "python3 /etc/nixos-shell/scripts/model_manager.py list";
      model-remove = "python3 /etc/nixos-shell/scripts/model_manager.py remove";
      model-cache-info = "python3 /etc/nixos-shell/scripts/model_manager.py cache-info";
      model-cache-clean = "python3 /etc/nixos-shell/scripts/model_manager.py cache-clean";
    };

    # ============================================================
    # CONFIGURAÇÃO DE GRUPOS E PERMISSÕES
    # ============================================================

    # Adiciona usuário ao grupo docker (já existente em aliases.nix)
    users.users.kernelcore = {
      extraGroups = [
        "docker"
        "video"
      ];
    };

    # ============================================================
    # PROFILE INITIALIZATION
    # ============================================================

    environment.etc."profile.d/shell-init.sh" = {
      text = ''
              # ══════════════════════════════════════════════════════
              # NixOS Shell Environment - Initialization
              # ══════════════════════════════════════════════════════

              # GPU Flags (disponível como variável de ambiente)
              export DOCKER_GPU_FLAGS="${config.shell.gpu.dockerFlags}"
              export PYTORCH_IMAGE="${config.shell.gpu.images.pytorch}"

              # Python scripts path
              export NIXOS_SHELL_SCRIPTS="/etc/nixos-shell/scripts"

              # ══════════════════════════════════════════════════════
              # HELPER FUNCTIONS
              # ══════════════════════════════════════════════════════

              # Quick help for shell commands
              shell-help() {
                  cat << 'EOF'
        ╔════════════════════════════════════════════════════════╗
        ║           NixOS Shell Commands                         ║
        ╚════════════════════════════════════════════════════════╝

        🐳 DOCKER BUILD & RUN:
          dbuild              - Docker build with cache
          dbuild-clean        - Build without cache
          dbuild-gpu          - Build with CUDA args
          drun-gpu            - Run with GPU flags
          drun-gpu-workspace  - Run GPU + mount workspace
          dgpu-test           - Test GPU access

          Functions:
            dbuild-tag <name>           - Build with timestamp tag
            drun-gpu-port <port> <img>  - Run GPU with port mapping
            dinfo <container>           - Container detailed info

        📊 GPU MONITORING:
          gpu-monitor         - Real-time GPU monitor
          gpu-monitor-json    - JSON output
          gpu-monitor-summary - Quick summary

        🤖 MODEL MANAGEMENT:
          model-search <query>    - Search models (HF/Ollama)
          model-install <model>   - Install model
          model-list              - List installed
          model-remove <model>    - Remove model
          model-cache-clean       - Clean cache

        🔧 SYSTEM:
          shell-help          - Show this help
          shell-info          - Show environment info

        For detailed Docker commands, see: /etc/nixos/modules/shell/aliases/docker-build.nix
        EOF
              }

              # Show environment info
              shell-info() {
                  echo "╔════════════════════════════════════════╗"
                  echo "║    Shell Environment Info             ║"
                  echo "╚════════════════════════════════════════╝"
                  echo ""
                  echo "GPU Flags: $DOCKER_GPU_FLAGS"
                  echo "PyTorch Image: $PYTORCH_IMAGE"
                  echo "Scripts Path: $NIXOS_SHELL_SCRIPTS"
                  echo ""
                  echo "GPU Status:"
                  nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "  No GPU detected"
                  echo ""
                  echo "Docker Version:"
                  docker --version 2>/dev/null || echo "  Docker not running"
              }

              # Export functions
              export -f shell-help
              export -f shell-info

              # ══════════════════════════════════════════════════════
              # WELCOME MESSAGE (comentado por padrão)
              # ══════════════════════════════════════════════════════

              # Uncomment to show welcome message on shell start
              # echo "✓ NixOS Shell Environment loaded. Type 'shell-help' for commands."
      '';
      mode = "0644";
    };

    # ============================================================
    # SYSTEMD SERVICES (Opcional - para monitoramento contínuo)
    # ============================================================

    # Serviço opcional para monitoramento GPU em background
    # Descomentado se necessário

    # systemd.services.gpu-monitor-daemon = {
    #   description = "GPU Monitor Daemon";
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.python3}/bin/python3 /etc/nixos-shell/scripts/gpu_monitor.py json";
    #     Restart = "always";
    #     RestartSec = "10s";
    #   };
    # };

    # ============================================================
    # DOCUMENTATION
    # ============================================================

    environment.etc."nixos-shell/README.md" = {
      text = ''
        # NixOS Shell Module

        Sistema modular de aliases, scripts e automação para NixOS.

        ## Estrutura

        ```
        /etc/nixos/modules/shell/
        ├── default.nix                 # Este arquivo (orquestrador)
        ├── gpu-flags.nix               # Flags GPU testadas
        ├── aliases/
        │   └── docker-build.nix        # Aliases Docker
        └── scripts/
            └── python/
                ├── gpu_monitor.py      # Monitor GPU
                └── model_manager.py    # Gerenciador modelos
        ```

        ## Uso

        ### GPU Flags
        Flags testadas e documentadas em `gpu-flags.nix`:
        ```bash
        --device=nvidia.com/gpu=all
        --ipc=host
        --ulimit stack=67108864
        --shm-size=8g
        ```

        ### Docker Build/Run
        ```bash
        # Build com tag automática
        dbuild-tag myapp

        # Run com GPU
        drun-gpu pytorch/pytorch:latest

        # Test GPU
        dgpu-test
        ```

        ### GPU Monitoring
        ```bash
        # Monitor interativo
        gpu-monitor

        # JSON output
        gpu-monitor-json

        # Summary
        gpu-monitor-summary
        ```

        ### Model Management
        ```bash
        # Buscar modelos
        model-search llama

        # Instalar
        model-install llama3.2        # Ollama
        model-install meta-llama/Llama-2-7b  # HuggingFace

        # Listar
        model-list

        # Remover
        model-remove llama3.2
        ```

        ## Customização

        Para adicionar novos aliases, edite:
        - `aliases/docker-build.nix` para Docker
        - `default.nix` para aliases gerais

        Para adicionar scripts Python:
        1. Adicione em `scripts/python/`
        2. Registre em `environment.etc` no `default.nix`
        3. Crie alias em `environment.shellAliases`

        ## Flags GPU - Referência

        Documentação completa: `gpu-flags.nix`

        Problemas comuns e soluções:
        - CUDA out of memory → Aumentar `--shm-size`
        - DataLoader crashes → Adicionar `--ipc=host`
        - Stack overflow → `--ulimit stack=67108864` obrigatório

        ## Suporte

        Arquivos de log:
        - Docker: `docker logs <container>`
        - System: `journalctl -u docker`
        - GPU: `nvidia-smi dmon`
      '';
      mode = "0644";
    };
  };
}
