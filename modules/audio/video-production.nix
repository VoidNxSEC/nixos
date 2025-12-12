{ config, lib, pkgs, ... }:

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
    environment.systemPackages = with pkgs; [
      # OBS Studio (principal) - configurado via programs.obs-studio
      
      # Editores de Vídeo
      kdePackages.kdenlive  # Editor profissional
      shotcut               # Editor leve e rápido
      
      # Gravação de tela
      wf-recorder        # Wayland screen recorder
      gpu-screen-recorder # GPU-accelerated recorder (NVIDIA)
      
      # Conversão e processamento
      ffmpeg-full        # Com todos codecs incluindo NVENC
      handbrake          # Encoder com GUI
      
      # Áudio
      pavucontrol        # Controle de volume avançado
      helvum             # Patchbay visual para PipeWire
      easyeffects        # Processamento de áudio em tempo real
      
      # Utilitários
      mediainfo          # Análise de mídia
      playerctl          # Controle de mídia via CLI
      
      # Streaming
      streamlink         # CLI para streams
    ]
    # NVENC/CUDA tools
    ++ optionals cfg.enableNVENC [
      cudatoolkit
      nvtopPackages.nvidia   # Monitor GPU
    ];

    # ═══════════════════════════════════════════════════════════════
    # OBS STUDIO - CONFIGURAÇÃO PROFISSIONAL COM NVIDIA
    # ═══════════════════════════════════════════════════════════════
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      
      plugins = with pkgs.obs-studio-plugins; [
        # IA e remoção de fundo
        obs-backgroundremoval      # Remove fundo via IA (substituto Nvidia Broadcast)
        
        # Captura de áudio
        obs-pipewire-audio-capture # Captura áudio do sistema
        
        # Captura de vídeo/jogos
        obs-vkcapture              # Captura Vulkan/OpenGL com alta performance
        obs-vaapi                  # Aceleração de hardware VA-API
        
        # Streaming
        obs-websocket              # Controle remoto/automação
        
        # Efeitos visuais
        obs-move-transition        # Transições suaves
        wlrobs                     # Captura nativa Wayland/wlroots
      ];
    };

    # ═══════════════════════════════════════════════════════════════
    # WIREPLUMBER - FIX PARA MICROFONE P2 MUTANDO SPEAKER
    # ═══════════════════════════════════════════════════════════════
    environment.etc = mkIf cfg.fixHeadphoneMute {
      # Regra 1: Desabilitar troca automática de perfil quando mic é plugado
      "wireplumber/main.lua.d/51-disable-auto-switch-profile.lua".text = ''
        -- Desabilita troca automática de perfil quando dispositivo é plugado
        -- Isso previne que o speaker seja mutado quando mic P2 é conectado
        
        rule = {
          matches = {
            {
              { "device.name", "matches", "alsa_card.pci-0000_00_1f.3*" },
            },
          },
          apply_properties = {
            -- Desabilita auto-switching de perfil
            ["api.alsa.ignore-dB"] = false,
            ["api.acp.auto-port"] = false,
            ["api.acp.auto-profile"] = false,
            -- Força soft-mixer para evitar hardware mute
            ["api.alsa.soft-mixer"] = true,
            ["api.alsa.soft-dB"] = true,
          },
        }
        table.insert(alsa_monitor.rules, rule)
      '';
      
      # Regra 2: NUNCA usar "Pro 7" como default sink (é o mic headset fake)
      "wireplumber/main.lua.d/52-disable-pro7-as-default.lua".text = ''
        -- Quando mic headset é plugado, aparece "cAVS Pro 7" como sink
        -- Mas é só mic, não tem output real - NUNCA usar como default
        
        rule = {
          matches = {
            {
              { "node.name", "matches", "*Pro*7*" },
            },
            {
              { "node.description", "matches", "*Pro 7*" },
            },
          },
          apply_properties = {
            -- Desabilita como default
            ["priority.driver"] = 0,
            ["priority.session"] = 0,
            -- Marca como não-preferido
            ["node.plugged"] = -1,
          },
        }
        table.insert(alsa_monitor.rules, rule)
      '';
      
      # Regra 3: Manter speaker SEMPRE como prioridade máxima
      "wireplumber/main.lua.d/53-speaker-priority.lua".text = ''
        -- Garante que speaker interno sempre tenha prioridade máxima
        
        rule = {
          matches = {
            {
              { "node.name", "matches", "*Speaker*" },
            },
          },
          apply_properties = {
            ["priority.driver"] = 2000,
            ["priority.session"] = 2000,
            ["node.pause-on-idle"] = false,
          },
        }
        table.insert(alsa_monitor.rules, rule)
      '';
      
      # Regra 4: Desabilitar auto-switch global para sinks
      "wireplumber/wireplumber.conf.d/50-no-auto-switch.conf".text = ''
        # Desabilita troca automática de sink quando dispositivo é plugado
        wireplumber.settings = {
          bluetooth.autoswitch-to-headset-profile = false
          
          # Stream settings - NÃO trocar automaticamente
          stream.restore-default-targets = true
          
          # Device settings
          device.restore-default-target = true
        }
      '';
    };

    # ═══════════════════════════════════════════════════════════════
    # PIPEWIRE - BAIXA LATÊNCIA PARA STREAMING
    # ═══════════════════════════════════════════════════════════════
    services.pipewire = mkIf cfg.lowLatency {
      extraConfig.pipewire = {
        "10-video-production" = {
          "context.properties" = {
            # Sample rate padrão
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 44100 48000 96000 ];
            
            # Quantum baixo para baixa latência (256 samples = ~5.3ms @ 48kHz)
            "default.clock.quantum" = 256;
            "default.clock.min-quantum" = 128;
            "default.clock.max-quantum" = 1024;
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
      "rec-gpu" = "gpu-screen-recorder -w screen -f 60 -a default_output -o ~/Videos/$(date +%Y%m%d_%H%M%S).mp4";
      
      # OBS
      "obs-start" = "obs --startstreaming";
      "obs-record" = "obs --startrecording";
      
      # Audio control
      "audio-fix" = "wpctl set-default $(wpctl status | grep Speaker | grep -oP '\\d+' | head -1) && echo 'Speaker set as default'";
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
      
      # VA-API fallback
      LIBVA_DRIVER_NAME = "nvidia";
    };

    # ═══════════════════════════════════════════════════════════════
    # LIMITES DE SISTEMA
    # ═══════════════════════════════════════════════════════════════
    security.pam.loginLimits = [
      # Permite uso de tempo real para áudio/vídeo
      { domain = "@video"; item = "rtprio"; type = "-"; value = "95"; }
      { domain = "@video"; item = "memlock"; type = "-"; value = "unlimited"; }
      { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
      { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    ];

    # Adicionar usuário ao grupo video
    users.groups.video.members = [ "kernelcore" ];
  };
}
