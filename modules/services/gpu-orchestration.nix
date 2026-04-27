{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.services.gpu-orchestration = {
      enable = mkEnableOption "Enable GPU resource orchestration for managing VRAM allocation";

      defaultMode = mkOption {
        type = types.enum [
          "local"
          "docker"
          "auto"
        ];
        default = "docker";
        description = ''
          Default GPU allocation mode:
          - docker: Docker containers get GPU
          - auto: Automatically manage based on usage
        '';
      };
    };
  };

  config = mkIf config.kernelcore.services.gpu-orchestration.enable {
    ##########################################################################
    # GPU Resource Orchestration
    # Manages VRAM allocation between systemd services and Docker containers
    ##########################################################################

    # ═══════════════════════════════════════════════════════════
    # Systemd Targets for GPU Modes
    # ═══════════════════════════════════════════════════════════

    systemd.targets.gpu-local-mode = {
      description = "GPU Local Mode - Systemd services active";
      wants = [
        "llamacpp-swap.service"
      ];
      conflicts = [ "gpu-docker-mode.target" ];
    };

    systemd.targets.gpu-docker-mode = {
      description = "GPU Docker Mode - Docker containers get GPU priority";
      conflicts = [
        "gpu-local-mode.target"
        "llamacpp-swap.service"
      ];
    };

    # ═══════════════════════════════════════════════════════════
    # Service Modifications for GPU Management
    # ═══════════════════════════════════════════════════════════

    # Modify llamacpp-swap to support GPU modes
    systemd.services.llamacpp-swap = mkIf config.services.llamacpp-swap.enable {
      conflicts = [ "gpu-docker-mode.target" ];
      partOf = [ "gpu-local-mode.target" ];

      serviceConfig = {
        TimeoutStopSec = "30s";
        KillMode = "mixed";
      };
    };

    # ═══════════════════════════════════════════════════════════
    # Helper Scripts for GPU Mode Switching
    # ═══════════════════════════════════════════════════════════

    environment.systemPackages = with pkgs; [
      # Switch to local mode (systemd services)
      (writeScriptBin "gpu-mode-local" ''
        #!${pkgs.bash}/bin/bash
        set -e

        echo "🔄 Switching to GPU Local Mode (systemd services)..."
        echo ""

        # Stop Docker containers that use GPU
        if ${pkgs.docker}/bin/docker ps --format "{{.Names}}" | grep -qE "gpu-api|jupyter-gpu|koboldcpp|comfyui"; then
          echo "⏹️  Stopping GPU Docker containers..."
          cd ~/Dev/Docker.Base/sql
          ${pkgs.docker}/bin/docker-compose stop gpu-api jupyter-gpu koboldcpp comfyui 2>/dev/null || true
        fi

        # Start GPU local mode
        echo "▶️  Starting systemd GPU services..."
        sudo ${pkgs.systemd}/bin/systemctl start gpu-local-mode.target
        sudo ${pkgs.systemd}/bin/systemctl start llamacpp-swap.service

        sleep 3

        echo ""
        echo "✅ GPU Local Mode Active"
        echo ""
        echo "Services:"
        sudo ${pkgs.systemd}/bin/systemctl status llamacpp-swap.service --no-pager -l | head -3

        echo ""
        echo "Access:"
        echo "  - LlamaCPP: http://127.0.0.1:8081"

      '')

      # Switch to docker mode
      (writeScriptBin "gpu-mode-docker" ''
        #!${pkgs.bash}/bin/bash
        set -e

        echo "🔄 Switching to GPU Docker Mode (containers)..."
        echo ""

        # Stop systemd GPU services
        echo "⏹️  Stopping systemd GPU services..."
        sudo ${pkgs.systemd}/bin/systemctl stop llamacpp-swap.service 2>/dev/null || true
        sudo ${pkgs.systemd}/bin/systemctl stop gpu-local-mode.target 2>/dev/null || true

        # Wait for GPU to be released
        sleep 3

        # Start GPU docker mode
        echo "▶️  Starting Docker GPU containers..."
        cd ~/Dev/Docker.Base/sql
        ${pkgs.docker}/bin/docker-compose up -d

        sleep 5

        echo ""
        echo "✅ GPU Docker Mode Active"
        echo ""
        echo "Containers:"
        ${pkgs.docker}/bin/docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "gpu-api|jupyter|koboldcpp|comfyui"
        echo ""
        echo "Access:"
        echo "  - GPU API: http://localhost:8000"
        echo "  - Jupyter: http://localhost:8888"
        echo "  - KoboldCPP: http://localhost:5001"
        echo "  - ComfyUI: http://localhost:8188"

      '')

      # Show GPU status
      (writeScriptBin "gpu-status" ''
        #!${pkgs.bash}/bin/bash

        echo "═══════════════════════════════════════════════════════════"
        echo "  GPU Status & Memory Allocation"
        echo "═══════════════════════════════════════════════════════════"
        echo ""

        # Show nvidia-smi
        if command -v nvidia-smi &> /dev/null; then
          ${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv,noheader,nounits | \
            awk -F, '{printf "GPU: %s\nTotal VRAM: %d MiB\nUsed: %d MiB (%.1f%%)\nFree: %d MiB\n\n", $1, $2, $3, ($3/$2)*100, $4}'
        fi

        # Show active mode
        echo "───────────────────────────────────────────────────────────"
        echo "Active Mode:"
        if sudo ${pkgs.systemd}/bin/systemctl is-active llamacpp-swap.service &>/dev/null; then
          echo "  🟢 GPU Local Mode (systemd services)"
          echo ""
          echo "  Running services:"
          sudo ${pkgs.systemd}/bin/systemctl is-active llamacpp-swap.service &>/dev/null && echo "    - llamacpp ✓"
        elif ${pkgs.docker}/bin/docker ps | grep -qE "gpu-api|jupyter-gpu|koboldcpp"; then
          echo "  🐳 GPU Docker Mode (containers)"
          echo ""
          echo "  Running containers:"
          ${pkgs.docker}/bin/docker ps --format "    - {{.Names}} {{.Status}}" | grep -E "gpu-api|jupyter|koboldcpp|comfyui" || true
        else
          echo "  ⚠️  No GPU mode active"
        fi

        echo ""
        echo "───────────────────────────────────────────────────────────"
        echo "GPU Processes:"
        if command -v nvidia-smi &> /dev/null; then
          ${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader | \
            awk -F, '{printf "  PID %s: %s (%s MiB)\n", $1, $2, $3}'
        fi
        echo ""

        echo "Commands:"
        echo "  gpu-mode-local   - Switch to systemd services mode"
        echo "  gpu-mode-docker  - Switch to Docker containers mode"
        echo "═══════════════════════════════════════════════════════════"
      '')

      # Auto-switch based on usage (optional)
      (writeScriptBin "gpu-mode-auto" ''
        #!${pkgs.bash}/bin/bash

        echo "🤖 Auto GPU Mode Selection..."

        # Check if any Docker containers are running
        if ${pkgs.docker}/bin/docker ps -q | grep -q .; then
          echo "  Docker containers detected"
          gpu-mode-docker
        else
          echo "  No Docker containers, defaulting to local mode"
          gpu-mode-local
        fi
      '')
    ];

    # ═══════════════════════════════════════════════════════════
    # Set Default Mode on Boot
    # ═══════════════════════════════════════════════════════════

    systemd.services.gpu-orchestration-init = {
      description = "Initialize GPU orchestration mode on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Default to docker mode (containers get GPU priority)
        ${pkgs.systemd}/bin/systemctl stop llamacpp-swap.service || true

        echo "GPU Orchestration: Defaulting to Docker mode (containers get GPU)"
        echo "Use 'gpu-mode-local' to switch to systemd services mode"
      '';
    };
  };
}
