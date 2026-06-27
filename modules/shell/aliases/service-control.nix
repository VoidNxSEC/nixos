{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.kernelcore.shell.serviceControl = {
    enable = mkEnableOption "Enable service control aliases for GPU/ML optimization";
  };

  config = mkIf config.kernelcore.shell.serviceControl.enable {
    environment.systemPackages = [
      # ============================================================
      # NIX DAEMON CONTROL (MASTER)
      # ============================================================
      (pkgs.writeShellScriptBin "nix-kill" ''
        #!/usr/bin/env bash
        echo "🔪 KILLING NIX DAEMON AND ALL BUILDS..."
        sudo systemctl stop nix-daemon.service
        pkill -9 nix-daemon 2>/dev/null || true
        pkill -9 'nix.*build' 2>/dev/null || true
        pkill -9 nix 2>/dev/null || true
        echo "✅ Nix daemon killed"
        free -h
      '')

      (pkgs.writeShellScriptBin "nix-restart" ''
        #!/usr/bin/env bash
        echo "🔄 RESTARTING NIX DAEMON..."
        sudo systemctl stop nix-daemon.service && \
        pkill -9 nix-daemon 2>/dev/null || true && \
        pkill -9 'nix.*build' 2>/dev/null || true && \
        pkill -9 nix 2>/dev/null || true && \
        sudo systemctl start nix-daemon.service && \
        sudo systemctl status nix-daemon.service --no-pager
        echo "✅ Nix daemon restarted"
        free -h
      '')

      (pkgs.writeShellScriptBin "nix-stop" ''
        #!/usr/bin/env bash
        echo "⏸️  STOPPING NIX DAEMON..."
        sudo systemctl stop nix-daemon.service
        echo "✅ Nix daemon stopped"
        free -h
      '')

      (pkgs.writeShellScriptBin "nix-start" ''
        #!/usr/bin/env bash
        echo "▶️  STARTING NIX DAEMON..."
        sudo systemctl start nix-daemon.service
        sudo systemctl status nix-daemon.service --no-pager
      '')

      (pkgs.writeShellScriptBin "nix-status" ''
        #!/usr/bin/env bash
        sudo systemctl status nix-daemon.service --no-pager
      '')

      # ============================================================
      # OLLAMA CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "ollama-start" ''
        #!/usr/bin/env bash
        echo "▶️  STARTING OLLAMA..."
        sudo systemctl start ollama.service
        sleep 1
        sudo systemctl status ollama.service --no-pager | head -15
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true
      '')

      (pkgs.writeShellScriptBin "ollama-stop" ''
        #!/usr/bin/env bash
        echo "⏸️  STOPPING OLLAMA..."
        sudo systemctl stop ollama.service
        echo "✅ Ollama stopped"
        free -h
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true
      '')

      (pkgs.writeShellScriptBin "ollama-restart" ''
        #!/usr/bin/env bash
        echo "🔄 RESTARTING OLLAMA..."
        sudo systemctl restart ollama.service
        sleep 1
        sudo systemctl status ollama.service --no-pager | head -15
      '')

      (pkgs.writeShellScriptBin "ollama-kill" ''
        #!/usr/bin/env bash
        echo "🔪 KILLING OLLAMA (FORCE)..."
        sudo systemctl stop ollama.service
        pkill -9 ollama 2>/dev/null || true
        echo "✅ Ollama killed"
        free -h
      '')

      (pkgs.writeShellScriptBin "ollama-status" ''
        #!/usr/bin/env bash
        sudo systemctl status ollama.service --no-pager
      '')

      # ============================================================
      # LLAMA.CPP TURBO CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "llama-start" ''
        #!/usr/bin/env bash
        echo "▶️  STARTING LLAMA.CPP TURBO..."
        sudo systemctl start llamacpp-swap.service
        sleep 2
        sudo systemctl status llamacpp-swap.service --no-pager | head -15
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true
      '')

      (pkgs.writeShellScriptBin "llama-stop" ''
        #!/usr/bin/env bash
        echo "⏸️  STOPPING LLAMA.CPP TURBO..."
        sudo systemctl stop llamacpp-swap.service
        echo "✅ LLama.cpp Swap stopped"
        free -h
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true
      '')

      (pkgs.writeShellScriptBin "llama-restart" ''
        #!/usr/bin/env bash
        echo "🔄 RESTARTING LLAMA.CPP TURBO..."
        sudo systemctl restart llamacpp-swap.service
        sleep 2
        sudo systemctl status llamacpp-swap.service --no-pager | head -15
      '')

      (pkgs.writeShellScriptBin "llama-kill" ''
        #!/usr/bin/env bash
        echo "🔪 KILLING LLAMA.CPP TURBO (FORCE)..."
        sudo systemctl stop llamacpp-swap.service
        pkill -9 llama 2>/dev/null || true
        pkill -9 llama-server 2>/dev/null || true
        echo "✅ LLama.cpp Swap killed"
        free -h
      '')

      (pkgs.writeShellScriptBin "llama-status" ''
        #!/usr/bin/env bash
        sudo systemctl status llamacpp-swap.service --no-pager
        echo ""
        echo "=== Health Check ==="
        curl -s http://localhost:8081/health 2>/dev/null | jq . || echo "Server not responding"
      '')

      (pkgs.writeShellScriptBin "llama-bench" ''
        #!/usr/bin/env bash
        echo "🔥 LLAMA.CPP TURBO BENCHMARK"
        echo ""
        echo "=== Health ==="
        curl -s http://localhost:8081/health | jq .
        echo ""
        echo "=== Model Info ==="
        curl -s http://localhost:8081/props | jq '{model, n_ctx, n_gpu_layers, n_threads}'
        echo ""
        echo "=== Quick Generation Test ==="
        time curl -s -X POST http://localhost:8081/v1/chat/completions \
          -H "Content-Type: application/json" \
          -d '{"model":"default","messages":[{"role":"user","content":"Hello"}],"max_tokens":10}' | jq '.choices[0].message.content'
      '')

      # ============================================================
      # ML OFFLOAD CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "ml-offload-start" ''
        #!/usr/bin/env bash
        echo "▶️  STARTING ML OFFLOAD API..."
        sudo systemctl start ml-offload-api.service
        sudo systemctl start ml-vram-monitor.service
        sleep 1
        sudo systemctl status ml-offload-api.service --no-pager | head -15
      '')

      (pkgs.writeShellScriptBin "ml-offload-stop" ''
        #!/usr/bin/env bash
        echo "⏸️  STOPPING ML OFFLOAD..."
        sudo systemctl stop ml-offload-api.service
        sudo systemctl stop ml-vram-monitor.service
        echo "✅ ML Offload stopped"
        free -h
      '')

      (pkgs.writeShellScriptBin "ml-offload-restart" ''
        #!/usr/bin/env bash
        echo "🔄 RESTARTING ML OFFLOAD..."
        sudo systemctl restart ml-offload-api.service
        sudo systemctl restart ml-vram-monitor.service
        sleep 1
        sudo systemctl status ml-offload-api.service --no-pager | head -15
      '')

      (pkgs.writeShellScriptBin "ml-offload-status" ''
        #!/usr/bin/env bash
        echo "=== ML OFFLOAD API ==="
        sudo systemctl status ml-offload-api.service --no-pager | head -15
        echo ""
        echo "=== VRAM MONITOR ==="
        sudo systemctl status ml-vram-monitor.service --no-pager | head -15
      '')

      # ============================================================
      # DOCKER CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "docker-kill" ''
        #!/usr/bin/env bash
        echo "🔪 KILLING DOCKER..."
        sudo systemctl stop docker.service
        pkill -9 dockerd 2>/dev/null || true
        pkill -9 containerd 2>/dev/null || true
        echo "✅ Docker killed"
        free -h
      '')

      (pkgs.writeShellScriptBin "docker-restart" ''
        #!/usr/bin/env bash
        echo "🔄 RESTARTING DOCKER..."
        sudo systemctl restart docker.service
        sleep 2
        sudo systemctl status docker.service --no-pager | head -15
      '')

      # ============================================================
      # CLAMAV CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "clamav-kill" ''
        #!/usr/bin/env bash
        echo "🔪 KILLING CLAMAV..."
        sudo systemctl stop clamav-daemon.service
        sudo systemctl stop clamav-updater.service
        pkill -9 clamd 2>/dev/null || true
        pkill -9 freshclam 2>/dev/null || true
        echo "✅ ClamAV killed - RAM freed: ~2.7GB"
        free -h
      '')

      (pkgs.writeShellScriptBin "clamav-start" ''
        #!/usr/bin/env bash
        echo "▶️  STARTING CLAMAV..."
        sudo systemctl start clamav-daemon.service
        sudo systemctl start clamav-updater.service
        sleep 2
        sudo systemctl status clamav-daemon.service --no-pager | head -15
      '')

      (pkgs.writeShellScriptBin "clamav-stop" ''
        #!/usr/bin/env bash
        echo "⏸️  STOPPING CLAMAV..."
        sudo systemctl stop clamav-daemon.service
        sudo systemctl stop clamav-updater.service
        echo "✅ ClamAV stopped - RAM freed: ~2.7GB"
        free -h
      '')

      # ============================================================
      # LIBVIRTD CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "libvirt-kill" ''
        #!/usr/bin/env bash
        echo "🔪 KILLING LIBVIRTD..."
        sudo systemctl stop libvirtd.service
        pkill -9 libvirtd 2>/dev/null || true
        echo "✅ Libvirtd killed"
        free -h
      '')

      (pkgs.writeShellScriptBin "libvirt-start" ''
        #!/usr/bin/env bash
        echo "▶️  STARTING LIBVIRTD..."
        sudo systemctl start libvirtd.service
        sudo systemctl status libvirtd.service --no-pager | head -15
      '')

      # ============================================================
      # COMBINED GPU CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "gpu-free" ''
        #!/usr/bin/env bash
        echo "🚀 FREEING ALL GPU RESOURCES..."
        echo ""
        echo "Stopping Ollama..."
        sudo systemctl stop ollama.service 2>/dev/null || true
        pkill -9 ollama 2>/dev/null || true
        echo ""
        echo "Stopping LLama.cpp Swap..."
        sudo systemctl stop llamacpp-swap.service 2>/dev/null || true
        pkill -9 llama 2>/dev/null || true
        pkill -9 llama-server 2>/dev/null || true
        echo ""
        echo "Stopping ML Offload..."
        sudo systemctl stop ml-offload-api.service 2>/dev/null || true
        sudo systemctl stop ml-vram-monitor.service 2>/dev/null || true
        echo ""
        echo "✅ ALL GPU SERVICES STOPPED"
        echo ""
        nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"
        free -h
      '')

      (pkgs.writeShellScriptBin "gpu-start" ''
        #!/usr/bin/env bash
        echo "🚀 STARTING GPU SERVICES..."
        echo ""
        echo "Starting LLama.cpp Swap..."
        sudo systemctl start llamacpp-swap.service
        sleep 2
        echo ""
        echo "Starting ML Offload..."
        sudo systemctl start ml-offload-api.service
        sudo systemctl start ml-vram-monitor.service
        echo ""
        echo "✅ GPU SERVICES STARTED"
        echo ""
        nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"
      '')

      (pkgs.writeShellScriptBin "gpu-status" ''
        #!/usr/bin/env bash
        echo "=== GPU STATUS ==="
        nvidia-smi 2>/dev/null || echo "nvidia-smi not available"
        echo ""
        echo "=== GPU SERVICES ==="
        echo "Ollama: $(systemctl is-active ollama.service)"
        echo "LLama.cpp Swap: $(systemctl is-active llamacpp-swap.service)"
        echo "ML Offload API: $(systemctl is-active ml-offload-api.service)"
        echo "VRAM Monitor: $(systemctl is-active ml-vram-monitor.service)"
      '')

      # ============================================================
      # COMBINED RAM OPTIMIZATION
      # ============================================================
      (pkgs.writeShellScriptBin "ram-free" ''
        #!/usr/bin/env bash
        echo "🧹 FREEING MAXIMUM RAM..."
        echo ""

        echo "1️⃣  Stopping heavy services..."
        sudo systemctl stop clamav-daemon.service 2>/dev/null || true
        sudo systemctl stop clamav-updater.service 2>/dev/null || true
        sudo systemctl stop libvirtd.service 2>/dev/null || true
        sudo systemctl stop systemd-oomd.service 2>/dev/null || true

        echo "2️⃣  Killing processes..."
        pkill -9 clamd 2>/dev/null || true
        pkill -9 freshclam 2>/dev/null || true
        pkill -9 libvirtd 2>/dev/null || true

        echo "3️⃣  Dropping caches..."
        sync
        sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

        echo "4️⃣  Compacting memory..."
        sudo sh -c 'echo 1 > /proc/sys/vm/compact_memory' 2>/dev/null || true

        echo ""
        echo "✅ RAM OPTIMIZATION COMPLETE"
        echo "Expected RAM freed: ~3-4GB"
        echo ""
        free -h
      '')

      (pkgs.writeShellScriptBin "ram-restore" ''
        #!/usr/bin/env bash
        echo "🔄 RESTORING SERVICES..."
        sudo systemctl start clamav-daemon.service 2>/dev/null || true
        sudo systemctl start libvirtd.service 2>/dev/null || true
        echo "✅ Services restored"
        free -h
      '')

      # ============================================================
      # MONITORING
      # ============================================================
      (pkgs.writeShellScriptBin "monitor-gpu" ''
        #!/usr/bin/env bash
        watch -n 1 'nvidia-smi && echo "" && echo "=== GPU Services ===" && \
        echo "Ollama: $(systemctl is-active ollama.service)" && \
        echo "LLama.cpp Swap: $(systemctl is-active llamacpp-swap.service)" && \
        echo "ML Offload: $(systemctl is-active ml-offload-api.service)"'
      '')

      (pkgs.writeShellScriptBin "monitor-ram" ''
        #!/usr/bin/env bash
        watch -n 1 'free -h && echo "" && echo "=== Top RAM Consumers ===" && \
        ps aux --sort=-%mem | head -11'
      '')

      (pkgs.writeShellScriptBin "monitor-services" ''
        #!/usr/bin/env bash
        echo "=== SYSTEM SERVICES STATUS ==="
        echo ""
        echo "📦 Nix Daemon: $(systemctl is-active nix-daemon.service)"
        echo "🦙 Ollama: $(systemctl is-active ollama.service)"
        echo "🦙 LLama.cpp Swap: $(systemctl is-active llamacpp-swap.service)"
        echo "🤖 ML Offload API: $(systemctl is-active ml-offload-api.service)"
        echo "📊 VRAM Monitor: $(systemctl is-active ml-vram-monitor.service)"
        echo "🐳 Docker: $(systemctl is-active docker.service)"
        echo "🦠 ClamAV: $(systemctl is-active clamav-daemon.service)"
        echo "💾 Libvirtd: $(systemctl is-active libvirtd.service)"
        echo "📈 Prometheus: $(systemctl is-active prometheus.service)"
        echo "📊 Grafana: $(systemctl is-active grafana.service)"
        echo ""
        echo "=== RESOURCES ==="
        free -h
        echo ""
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "GPU: N/A"
      '')

      # ============================================================
      # EMERGENCY THROTTLE CONTROL
      # ============================================================
      (pkgs.writeShellScriptBin "emergency-free" ''
        #!/usr/bin/env bash
        echo "🚨 EMERGENCY RAM/GPU CLEANUP"
        echo "This will stop ALL non-essential services"
        echo ""
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "🔪 KILLING EVERYTHING..."

          # GPU services
          sudo systemctl stop ollama.service llamacpp-swap.service ml-offload-api.service ml-vram-monitor.service 2>/dev/null || true
          pkill -9 ollama llama llama-server 2>/dev/null || true

          # Heavy RAM services
          sudo systemctl stop clamav-daemon.service libvirtd.service 2>/dev/null || true
          pkill -9 clamd libvirtd 2>/dev/null || true

          # Nix builds
          pkill -9 nix-daemon 'nix.*build' nix 2>/dev/null || true

          # Drop caches
          sync
          sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

          echo ""
          echo "✅ EMERGENCY CLEANUP COMPLETE"
          echo ""
          free -h
          nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null || true
        fi
      '')

      # ============================================================
      # HELP MENU
      # ============================================================
      (pkgs.writeShellScriptBin "service-help" ''
                #!/usr/bin/env bash
                cat << 'EOF'
        ╔══════════════════════════════════════════════════════════════╗
        ║           SERVICE CONTROL ALIASES - QUICK REFERENCE          ║
        ╚══════════════════════════════════════════════════════════════╝

        🔧 NIX DAEMON (Master Control)
          nix-kill      - Kill all Nix processes (force)
          nix-restart   - Full restart of Nix daemon
          nix-stop      - Stop Nix daemon gracefully
          nix-start     - Start Nix daemon
          nix-status    - Check Nix daemon status

        🦙 OLLAMA CONTROL
          ollama-start  - Start Ollama service
          ollama-stop   - Stop Ollama service
          ollama-restart - Restart Ollama
          ollama-kill   - Force kill Ollama
          ollama-status - Check Ollama status

        🦙 LLAMA.CPP TURBO CONTROL
          llama-start   - Start llama.cpp turbo service
          llama-stop    - Stop llama.cpp turbo service
          llama-restart - Restart llama.cpp turbo
          llama-kill    - Force kill llama.cpp turbo
          llama-status  - Check llama.cpp turbo status + health
          llama-bench   - Run quick benchmark

        🤖 ML OFFLOAD CONTROL
          ml-offload-start   - Start ML Offload API + VRAM Monitor
          ml-offload-stop    - Stop ML Offload services
          ml-offload-restart - Restart ML Offload
          ml-offload-status  - Check ML Offload status

        🐳 DOCKER CONTROL
          docker-kill    - Force kill Docker daemon
          docker-restart - Restart Docker

        🦠 CLAMAV CONTROL
          clamav-kill   - Kill ClamAV (frees ~2.7GB RAM)
          clamav-start  - Start ClamAV
          clamav-stop   - Stop ClamAV gracefully

        💾 LIBVIRT CONTROL
          libvirt-kill  - Kill libvirtd
          libvirt-start - Start libvirtd

        🎮 GPU COMBINED CONTROL
          gpu-free      - Stop ALL GPU services (Ollama + Llama + ML Offload)
          gpu-start     - Start GPU services (Llama + ML Offload)
          gpu-status    - Show GPU and services status

        🧹 RAM OPTIMIZATION
          ram-free      - Free maximum RAM (~3-4GB)
          ram-restore   - Restore stopped services
          emergency-free - EMERGENCY cleanup (interactive)

        📊 MONITORING
          monitor-gpu      - Watch GPU usage in real-time
          monitor-ram      - Watch RAM usage in real-time
          monitor-services - Show all services status

        💡 EXAMPLES:
          # Free RAM for heavy build:
          ram-free && nix-restart

          # Free GPU for gaming:
          gpu-free

          # Emergency cleanup:
          emergency-free

          # Monitor everything:
          monitor-services
        EOF
      '')
    ];

    # Shell aliases for quick access
    programs.zsh.shellAliases = {
      # Quick shortcuts
      "svc" = "monitor-services";
      "gpu" = "gpu-status";
      "ramfree" = "ram-free";
      "gpufree" = "gpu-free";
      "nixkill" = "nix-kill";
      "emergency" = "emergency-free";
      "svchelp" = "service-help";
    };

    programs.bash.shellAliases = {
      # Quick shortcuts
      "svc" = "monitor-services";
      "gpu" = "gpu-status";
      "ramfree" = "ram-free";
      "gpufree" = "gpu-free";
      "nixkill" = "nix-kill";
      "emergency" = "emergency-free";
      "svchelp" = "service-help";
    };
  };
}
