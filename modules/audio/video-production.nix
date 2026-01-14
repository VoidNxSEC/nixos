{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.audio.videoProduction;
in
{
  options.modules.audio.videoProduction = {
    enable = mkEnableOption "Ambiente profissional de produção de vídeo com OBS e NVIDIA";

    enableNVENC = mkOption {
      type = types.bool;
      default = true;
      description = "Habilitar encoding NVENC (requer NVIDIA GPU)";
    };

    fixHeadphoneMute = mkOption {
      type = types.bool;
      default = true;
      description = "Corrigir problema de mute quando microfone P2 é plugado";
    };

    lowLatency = mkOption {
      type = types.bool;
      default = true;
      description = "Configuração de baixa latência para streaming";
    };
  };

  config = mkIf cfg.enable {
    # ═══════════════════════════════════════════════════════════════
    # PACOTES DE PRODUÇÃO DE VÍDEO
    # ═══════════════════════════════════════════════════════════════
    environment.systemPackages =
      with pkgs;
      [
        # OBS Studio (principal) - configurado via programs.obs-studio

        # Editores de Vídeo
        kdePackages.kdenlive # Editor profissional
        shotcut # Editor leve e rápido

        # Gravação de tela
        wf-recorder # Wayland screen recorder
        gpu-screen-recorder # GPU-accelerated recorder (NVIDIA)

        # Conversão e processamento
        ffmpeg-full # Com todos codecs incluindo NVENC
        handbrake # Encoder com GUI

        # Áudio
        pavucontrol # Controle de volume avançado
        helvum # Patchbay visual para PipeWire
        easyeffects # Processamento de áudio em tempo real

        # Utilitários
        mediainfo # Análise de mídia
        playerctl # Controle de mídia via CLI

        # Streaming
        streamlink # CLI para streams

        # OBS NVENC wrapper - força uso da GPU NVIDIA em laptops híbridos
        # IMPORTANTE: Evita crash do sistema ao fechar OBS
        (writeShellScriptBin "obs-nvenc" ''
          # Cleanup function to ensure NVENC resources are released properly
          cleanup() {
            echo "[obs-nvenc] Cleaning up GPU resources..."
            # Give NVENC time to release encoder
            sleep 0.5
          }
          trap cleanup EXIT

          # Run OBS with NVIDIA GPU for NVENC encoding
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only

          # Add NVIDIA driver libraries to path (required for libnvidia-encode.so.1)
          export LD_LIBRARY_PATH="/run/opengl-driver/lib:''${LD_LIBRARY_PATH:-}"

          # Disable NVIDIA dynamic power management during OBS session
          # Prevents GPU from trying to suspend while encoder is active
          export __GL_THREADED_OPTIMIZATIONS=1
          export __GL_SYNC_TO_VBLANK=0

          unset LIBVA_DRIVER_NAME  # Remove to avoid VAAPI interference

          echo "[obs-nvenc] Starting OBS with NVIDIA NVENC..."
          obs "$@"
          OBS_EXIT=$?

          echo "[obs-nvenc] OBS exited with code $OBS_EXIT"
          exit $OBS_EXIT
        '')

        # OBS NVENC test - valida disponibilidade dos encoders
        (writeShellScriptBin "obs-test-nvenc" ''
          echo "╔═══════════════════════════════════════════════════════════╗"
          echo "║         OBS NVENC Availability Test                   ║"
          echo "╚═══════════════════════════════════════════════════════════╝"
          echo ""

          echo "[1] Testing NVIDIA GPU..."
          nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
          echo ""

          echo "[2] Available NVENC encoders in ffmpeg:"
          ffmpeg -hide_banner -encoders 2>/dev/null | grep nvenc
          echo ""

          echo "[3] NVIDIA Encoder Libraries:"
          find /run/opengl-driver -name "*nvidia-encode*" -o -name "*nvenc*" 2>/dev/null
          echo ""

          echo "[4] VAAPI drivers (fallback):"
          vainfo 2>/dev/null || echo "VAAPI not available (expected on NVIDIA-only)"
          echo ""

          echo "╔═══════════════════════════════════════════════════════════╗"
          echo "║ Use 'obs-nvenc' to launch OBS with NVENC support     ║"
          echo "╚═══════════════════════════════════════════════════════════╝"
        '')
      ]
      # NVENC/CUDA tools
      ++ optionals cfg.enableNVENC [
        cudatoolkit
        nvtopPackages.nvidia # Monitor GPU
      ];

    # ═══════════════════════════════════════════════════════════════
    # OBS STUDIO - CONFIGURAÇÃO PROFISSIONAL COM NVIDIA
    # ═══════════════════════════════════════════════════════════════
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;

      # CRITICAL: Override package with CUDA support for NVENC
      package = pkgs.obs-studio.override { cudaSupport = true; };

      plugins = with pkgs.obs-studio-plugins; [
        # ═══════════════════════════════════════════════════════
        # IA E REMOÇÃO DE FUNDO
        # ═══════════════════════════════════════════════════════
        obs-backgroundremoval # Remove fundo via IA (substituto Nvidia Broadcast)

        # ═══════════════════════════════════════════════════════
        # CAPTURA DE ÁUDIO
        # ═══════════════════════════════════════════════════════
        obs-pipewire-audio-capture # Captura áudio do sistema via PipeWire

        # ═══════════════════════════════════════════════════════
        # CAPTURA DE VÍDEO/JOGOS
        # ═══════════════════════════════════════════════════════
        obs-vkcapture # Captura Vulkan/OpenGL com alta performance
        obs-vaapi # Aceleração de hardware VA-API (fallback quando NVENC não disponível)
        wlrobs # Captura nativa Wayland/wlroots

        # ═══════════════════════════════════════════════════════
        # STREAMING E MULTI-PLATAFORMA
        # ═══════════════════════════════════════════════════════
        obs-websocket # Controle remoto/automação via WebSocket
        obs-multi-rtmp # Stream simultâneo múltiplas plataformas (Twitch+YouTube+etc)

        # ═══════════════════════════════════════════════════════
        # TRANSIÇÕES E EFEITOS VISUAIS
        # ═══════════════════════════════════════════════════════
        obs-move-transition # Transições suaves entre cenas
        # obs-3d-effect - REMOVED: crashes on GL/Vulkan switching
        # obs-composite-blur - REMOVED: crashes with hardware accel preview
        obs-freeze-filter # Congela frame (útil para highlights)
        obs-gradient-source # Gradientes para backgrounds
        obs-retro-effects # Filtros retro (VHS, CRT, etc)

        # ═══════════════════════════════════════════════════════
        # FERRAMENTAS AVANÇADAS
        # ═══════════════════════════════════════════════════════
        advanced-scene-switcher # Troca automática de cenas (baseado em janelas/eventos)
        obs-command-source # Executa comandos/scripts
        obs-replay-source # Instant replay (captura retroativa)

        # ═══════════════════════════════════════════════════════
        # INTEGRAÇÕES
        # ═══════════════════════════════════════════════════════
        obs-gstreamer # Integração GStreamer (codecs adicionais)
      ];
    };

    # ═══════════════════════════════════════════════════════════════
    # CONFIGURAÇÕES GLOBAIS (SPEECH-DISPATCHER + WIREPLUMBER)
    # ═══════════════════════════════════════════════════════════════
    environment.etc = mkMerge [
      # SPEECH-DISPATCHER - Módulos mínimos para evitar zumbis
      {
        "speech-dispatcher/modules/espeak-ng.conf".text = ''
          GenericExecuteSynth "echo \'$DATA\' | espeak-ng -v $VOICE --stdin"
          GenericStripPunctChars ""
          GenericRecodeFallback "UTF-8"
          AddVoice "en" "MALE1" "en"
        '';
      }

      # WIREPLUMBER - Configuração conservadora (apenas se fixHeadphoneMute ativo)
      (mkIf cfg.fixHeadphoneMute {
        "wireplumber/main.lua.d/53-speaker-priority.lua".text = ''
          -- Prioridade elevada para speaker (mas não extrema)
          rule = {
            matches = {
              {
                { "node.name", "matches", "*Speaker*" },
              },
            },
            apply_properties = {
              ["priority.driver"] = 1000,  -- Reduzido de 2000 para 1000
              ["priority.session"] = 1000,
            },
          }
          table.insert(alsa_monitor.rules, rule)
        '';
      })
    ];

    # ═══════════════════════════════════════════════════════════════
    # PIPEWIRE - BAIXA LATÊNCIA PARA STREAMING
    # ═══════════════════════════════════════════════════════════════
    services.pipewire = mkIf cfg.lowLatency {
      extraConfig.pipewire = {
        "10-video-production" = {
          "context.properties" = {
            # Sample rate padrão
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              96000
            ];

            # ULTRA LOW LATENCY: 128 samples = ~2.7ms @ 48kHz (optimized for streaming)
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 64;
            "default.clock.max-quantum" = 1024;

            # Performance optimizations
            "link.max-buffers" = 16; # Reduce buffer latency
            "log.level" = 0; # Disable verbose logging for performance
          };

          # Stream properties for minimal latency
          "stream.properties" = {
            "node.latency" = "128/48000"; # ~2.7ms latency
            "resample.quality" = 4; # Balance between quality and CPU usage
          };
        };
      };
    };

    # ═══════════════════════════════════════════════════════════════
    # ALIASES PARA PRODUÇÃO DE VÍDEO
    # ═══════════════════════════════════════════════════════════════
    environment.shellAliases = {
      # Recording
      "rec-screen" = "wf-recorder -f ~/Videos/$(date +%Y%m%d_%H%M%S).mp4";
      "rec-screen-audio" = "wf-recorder --audio -f ~/Videos/$(date +%Y%m%d_%H%M%S).mp4";
      "rec-gpu" =
        "gpu-screen-recorder -w screen -f 60 -a default_output -o ~/Videos/$(date +%Y%m%d_%H%M%S).mp4";

      # OBS (usar obs-nvenc para NVENC encoding em laptops híbridos)
      "obs-start" = "obs --startstreaming";
      "obs-record" = "obs --startrecording";
      "obs-nvidia" = "obs-nvenc"; # Alias alternativo para obs-nvenc

      # Audio control
      "audio-fix" =
        "wpctl set-default $(wpctl status | grep Speaker | grep -oP '\\d+' | head -1) && echo 'Speaker set as default'";
      "audio-status" = "wpctl status | head -40";
      "audio-mixer" = "helvum &";
      "audio-effects" = "easyeffects &";

      # NVIDIA monitoring (using mkDefault to avoid conflicts)
      "gpu-watch" = mkDefault "watch -n 1 nvidia-smi";
      "nvtop" = mkDefault "nvtop";

      # Encoding
      "to-h264-nvenc" = "ffmpeg -hwaccel cuda -i";
      "to-h265-nvenc" = "ffmpeg -hwaccel cuda -c:v hevc_nvenc -i";
    };

    # ═══════════════════════════════════════════════════════════════
    # VARIÁVEIS DE AMBIENTE
    # ═══════════════════════════════════════════════════════════════
    environment.variables = mkIf cfg.enableNVENC {
      # NVIDIA NVENC/CUDA
      CUDA_PATH = "${pkgs.cudatoolkit}";

      # OBS optimizations
      OBS_USE_EGL = "1";

      # Preview crash prevention (hybrid GPU fixes)
      # Using mkDefault to avoid conflicts with system defaults
      QT_XCB_GL_INTEGRATION = mkDefault "xcb_egl"; # Force consistent GL backend
      __GL_GSYNC_ALLOWED = mkDefault "0"; # Disable G-Sync (can cause preview hang)
      __GL_VRR_ALLOWED = mkDefault "0"; # Disable VRR (Variable Refresh Rate)

      # LIBVA_DRIVER_NAME removed - causes VAAPI detection issues on hybrid GPUs
      # Use obs-nvenc wrapper instead for NVIDIA encoding
    };

    # ═══════════════════════════════════════════════════════════════
    # LIMITES DE SISTEMA
    # ═══════════════════════════════════════════════════════════════
    security.pam.loginLimits = [
      # Permite uso de tempo real para áudio/vídeo
      {
        domain = "@video";
        item = "rtprio";
        type = "-";
        value = "95";
      }
      {
        domain = "@video";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
    ];

    # Adicionar usuário ao grupo video
    users.groups.video.members = [ "kernelcore" ];
  };
}
