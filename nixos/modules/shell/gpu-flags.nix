# ============================================================
# GPU FLAGS - GOLD STANDARD (Testado e Funcional)
# ============================================================
# Este módulo centraliza as flags NVIDIA GPU que foram testadas
# e funcionam corretamente em /etc/nixos/modules/services/scripts.nix
# ============================================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ============================================================
  # CONSTANTES - FLAGS GPU TESTADAS
  # ============================================================

  # Flags base para docker run com GPU
  options.shell.gpu = {
    # Flags completas como string (para usar em aliases)
    dockerFlags = lib.mkOption {
      type = lib.types.str;
      default = "--device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g";
      description = "Flags Docker testadas para acesso GPU NVIDIA";
      readOnly = true;
    };

    # Flags como lista (para programação)
    dockerFlagsList = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--device=nvidia.com/gpu=all" # Acesso a todas GPUs NVIDIA
        "--ipc=host" # IPC shared memory
        "--ulimit"
        "stack=67108864" # Stack size limit (64MB)
        "--shm-size=8g" # Shared memory 8GB
      ];
      description = "Flags Docker como lista para manipulação programática";
      readOnly = true;
    };

    # Flags individuais (para composição customizada)
    flags = {
      device = lib.mkOption {
        type = lib.types.str;
        default = "--device=nvidia.com/gpu=all";
        description = "Device flag para acesso GPU";
        readOnly = true;
      };

      ipc = lib.mkOption {
        type = lib.types.str;
        default = "--ipc=host";
        description = "IPC mode flag";
        readOnly = true;
      };

      ulimit = lib.mkOption {
        type = lib.types.str;
        default = "--ulimit stack=67108864";
        description = "Stack size ulimit";
        readOnly = true;
      };

      shmSize = lib.mkOption {
        type = lib.types.str;
        default = "--shm-size=8g";
        description = "Shared memory size";
        readOnly = true;
      };
    };

    # Comandos base testados
    baseCommands = {
      dockerRun = lib.mkOption {
        type = lib.types.str;
        default = "docker run --rm";
        description = "Comando base docker run";
        readOnly = true;
      };

      dockerRunInteractive = lib.mkOption {
        type = lib.types.str;
        default = "docker run --rm -it";
        description = "Comando base docker run interativo";
        readOnly = true;
      };
    };

    # Imagens testadas
    images = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Container images testadas com GPU";
    };

    # Aliases de referência
    referenceAliases = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Aliases originais de scripts.nix para referência";
    };

    # Documentação
    docs = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Documentação sobre GPU flags e troubleshooting";
    };
  };

  # ============================================================
  # IMAGENS TESTADAS
  # ============================================================
  config.shell.gpu.images = {
    pytorch = "nvcr.io/nvidia/pytorch:25.09-py3";
    tgi = "ghcr.io/huggingface/text-generation-inference:latest";
    tensorflow = "nvcr.io/nvidia/tensorflow:25.09-tf2-py3";
  };

  # ============================================================
  # ALIASES DE REFERÊNCIA (originais de scripts.nix)
  # ============================================================
  config.shell.gpu.referenceAliases = {
    tgi = "docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g ghcr.io/huggingface/text-generation-inference:latest";

    pytorch = "docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g nvcr.io/nvidia/pytorch:25.09-py3";

    jupMl = ''
      docker run --rm \
        --device=nvidia.com/gpu=all \
        --ipc=host \
        --ulimit stack=67108864 \
        --shm-size=8g
    '';
  };

  # ============================================================
  # VALIDAÇÃO E DOCUMENTAÇÃO
  # ============================================================
  config.shell.gpu.docs = {
    flagsExplanation = ''
      FLAGS GPU - EXPLICAÇÃO:

      --device=nvidia.com/gpu=all
        └─ Expõe todas GPUs NVIDIA disponíveis no host para o container
        └─ Requer: nvidia-docker2 ou Docker com CDI support

      --ipc=host
        └─ Compartilha namespace IPC com host
        └─ Necessário: comunicação inter-processo para PyTorch DataLoader

      --ulimit stack=67108864
        └─ Define limite de stack para 64MB
        └─ Necessário: modelos grandes (CUDA stack overflow sem isso)

      --shm-size=8g
        └─ Define shared memory para 8GB
        └─ Necessário: DataLoaders com num_workers > 0
        └─ Sem isso: "OSError: [Errno 28] No space left on device"
    '';

    commonIssues = ''
      PROBLEMAS COMUNS E SOLUÇÕES:

      1. "CUDA out of memory"
         → Aumentar --shm-size ou reduzir batch_size

      2. "docker: Error response from daemon: could not select device driver"
         → Verificar: nvidia-docker2 instalado
         → Comando: systemctl status docker

      3. "RuntimeError: DataLoader worker exited unexpectedly"
         → Adicionar --ipc=host
         → Ou usar num_workers=0

      4. "CUDA stack overflow"
         → Flags --ulimit stack=67108864 obrigatória
    '';

    testingProcedure = ''
      PROCEDIMENTO DE TESTE:

      # 1. Teste básico CUDA
      docker run --rm --device=nvidia.com/gpu=all \\
        nvcr.io/nvidia/pytorch:25.09-py3 \\
        python -c "import torch; print(torch.cuda.is_available())"

      # 2. Teste com flags completas
      docker run --rm --device=nvidia.com/gpu=all --ipc=host \\
        --ulimit stack=67108864 --shm-size=8g \\
        nvcr.io/nvidia/pytorch:25.09-py3 \\
        python -c "import torch; print(torch.cuda.get_device_name(0))"

      # 3. Teste DataLoader (requer --ipc=host + --shm-size)
      docker run --rm --device=nvidia.com/gpu=all --ipc=host \\
        --ulimit stack=67108864 --shm-size=8g \\
        -v $(pwd):/workspace \\
        nvcr.io/nvidia/pytorch:25.09-py3 \\
        python /workspace/test_dataloader.py
    '';
  };
}
