{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.audio.production;
in
{
  options.modules.audio.production = {
    enable = mkEnableOption "Ambiente de produção musical completo";

    jackAudio = mkOption {
      type = types.bool;
      default = true;
      description = "Habilitar JACK Audio Connection Kit";
    };

    plugins = mkOption {
      type = types.bool;
      default = true;
      description = "Instalar plugins de áudio (LV2, LADSPA, VST)";
    };

    synthesizers = mkOption {
      type = types.bool;
      default = true;
      description = "Instalar sintetizadores";
    };

    downloaders = mkOption {
      type = types.bool;
      default = true;
      description = "Ferramentas de download e conversão de áudio";
    };
  };

  config = mkIf cfg.enable {
    # Pacotes principais
    environment.systemPackages =
      with pkgs;
      [
        # DAW
        ardour
        audacity

        # Editores e utilitários
        sonic-visualiser
        sox

        # Conversores de formato
        flac
        lame
        vorbis-tools
        opusTools
        wavpack

        # Ferramentas de sistema
        alsa-utils
        pavucontrol
        pulseaudio

        # Python para scripts
        python3
        python3Packages.mutagen
        python3Packages.pydub
      ]
      ++ optionals cfg.jackAudio [
        jack2
        qjackctl
      ]
      ++ optionals cfg.plugins [
        lsp-plugins
        calf
        eq10q
        guitarix
        gxplugins-lv2
      ]
      ++ optionals cfg.synthesizers [
        helm
        zynaddsubfx
        yoshimi
      ]
      ++ optionals cfg.downloaders [
        yt-dlp
        ffmpeg-full
      ];

    # Aliases e helpers para shell
    environment.shellAliases = {
      # DAW
      "ardour" = "ardour";
      "daw" = "ardour";

      # Download de áudio
      "ytdl-audio" = "yt-dlp --extract-audio --audio-format best --audio-quality 0";
      "ytdl-flac" = "yt-dlp --extract-audio --audio-format flac --audio-quality 0";
      "ytdl-mp3" = "yt-dlp --extract-audio --audio-format mp3 --audio-quality 0";
      "ytdl-opus" = "yt-dlp --extract-audio --audio-format opus --audio-quality 0";

      # Conversão de áudio
      "to-flac" = "ffmpeg -i";
      "to-mp3" = "ffmpeg -i";
      "to-wav" = "ffmpeg -i";
      "to-opus" = "ffmpeg -i";

      # Análise de áudio
      "audio-info" = "ffprobe -hide_banner";
      "audio-analyze" = "sonic-visualiser";

      # JACK
      "jack-start" = "qjackctl &";
      "jack-status" = "jack_lsp -c";
      "jack-connections" = "jack_lsp -c";

      # Utilitários
      "list-audio-devices" = "aplay -l";
      "list-audio-cards" = "cat /proc/asound/cards";
      "audio-monitor" = "pavucontrol";
    };

    # Scripts helper em /etc/nixos/modules/audio/scripts
    environment.etc = {
      "audio-helpers/youtube-to-flac.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Helper script para download de áudio do YouTube em FLAC

          set -euo pipefail

          usage() {
            cat <<EOF
          Uso: youtube-to-flac <URL> [DIRETÓRIO]

          Download de áudio do YouTube em formato FLAC de máxima qualidade.

          Argumentos:
            URL         URL do vídeo do YouTube
            DIRETÓRIO   Diretório de saída (padrão: diretório atual)

          Exemplos:
            youtube-to-flac 'https://www.youtube.com/watch?v=...'
            youtube-to-flac 'https://www.youtube.com/watch?v=...' ~/Music

          Características:
            - Formato: FLAC (lossless)
            - Qualidade: Máxima disponível
            - Metadados: Incluídos automaticamente
            - Compatível: Ardour, Audacity e outros DAWs
          EOF
            exit 1
          }

          if [ $# -lt 1 ]; then
            usage
          fi

          URL="$1"
          OUTPUT_DIR="''${2:-.}"

          mkdir -p "$OUTPUT_DIR"

          echo "=========================================="
          echo "Download de Áudio do YouTube para FLAC"
          echo "=========================================="
          echo "URL: $URL"
          echo "Diretório: $OUTPUT_DIR"
          echo "Formato: FLAC (qualidade máxima)"
          echo "=========================================="
          echo

          ${pkgs.yt-dlp}/bin/yt-dlp \
            --extract-audio \
            --audio-format flac \
            --audio-quality 0 \
            --format bestaudio \
            --embed-thumbnail \
            --add-metadata \
            --output "$OUTPUT_DIR/%(title)s.%(ext)s" \
            --no-playlist \
            --progress \
            "$URL"

          echo
          echo "=========================================="
          echo "Download concluído!"
          echo "Arquivo pronto para uso no Ardour"
          echo "=========================================="
        '';
        mode = "0755";
      };

      "audio-helpers/batch-convert.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Conversão em batch de arquivos de áudio

          set -euo pipefail

          usage() {
            cat <<EOF
          Uso: batch-convert <formato> <diretório>

          Converte todos os arquivos de áudio em um diretório para o formato especificado.

          Formatos suportados:
            flac, mp3, wav, opus, ogg, m4a

          Exemplos:
            batch-convert flac ~/Music/samples
            batch-convert mp3 .
          EOF
            exit 1
          }

          if [ $# -lt 2 ]; then
            usage
          fi

          FORMAT="$1"
          DIR="$2"

          case "$FORMAT" in
            flac) EXT="flac"; OPTS="-c:a flac -compression_level 12" ;;
            mp3)  EXT="mp3";  OPTS="-c:a libmp3lame -q:a 0" ;;
            wav)  EXT="wav";  OPTS="-c:a pcm_s16le" ;;
            opus) EXT="opus"; OPTS="-c:a libopus -b:a 320k" ;;
            ogg)  EXT="ogg";  OPTS="-c:a libvorbis -q:a 10" ;;
            m4a)  EXT="m4a";  OPTS="-c:a aac -b:a 320k" ;;
            *) echo "Erro: Formato não suportado: $FORMAT"; usage ;;
          esac

          OUTPUT_DIR="$DIR/converted_$FORMAT"
          mkdir -p "$OUTPUT_DIR"

          echo "Convertendo arquivos para $FORMAT..."
          echo "Diretório de entrada: $DIR"
          echo "Diretório de saída: $OUTPUT_DIR"
          echo

          count=0
          for file in "$DIR"/*.{mp3,flac,wav,ogg,opus,m4a,aac,wma} 2>/dev/null; do
            [ -f "$file" ] || continue

            basename="$(basename "$file")"
            filename="''${basename%.*}"
            output="$OUTPUT_DIR/$filename.$EXT"

            echo "Convertendo: $basename -> $filename.$EXT"
            ${pkgs.ffmpeg-full}/bin/ffmpeg -i "$file" $OPTS "$output" -y -hide_banner -loglevel error
            ((count++))
          done

          echo
          echo "=========================================="
          echo "Conversão concluída!"
          echo "Total de arquivos: $count"
          echo "Diretório: $OUTPUT_DIR"
          echo "=========================================="
        '';
        mode = "0755";
      };

      "audio-helpers/audio-metadata.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Exibir metadados de arquivos de áudio

          set -euo pipefail

          if [ $# -lt 1 ]; then
            echo "Uso: audio-metadata <arquivo>"
            exit 1
          fi

          FILE="$1"

          if [ ! -f "$FILE" ]; then
            echo "Erro: Arquivo não encontrado: $FILE"
            exit 1
          fi

          echo "=========================================="
          echo "Metadados de Áudio"
          echo "=========================================="
          echo "Arquivo: $FILE"
          echo

          ${pkgs.ffmpeg-full}/bin/ffprobe \
            -hide_banner \
            -show_format \
            -show_streams \
            -print_format json \
            "$FILE" | ${pkgs.jq}/bin/jq '
              {
                format: .format.format_long_name,
                duration: (.format.duration | tonumber | floor),
                bitrate: (.format.bit_rate | tonumber / 1000 | floor | tostring + " kbps"),
                size: (.format.size | tonumber / 1024 / 1024 | floor | tostring + " MB"),
                audio: .streams[0] | {
                  codec: .codec_long_name,
                  sample_rate: (.sample_rate + " Hz"),
                  channels: .channels,
                  channel_layout: .channel_layout,
                  bit_depth: .bits_per_sample
                },
                tags: .format.tags
              }
            '

          echo
          echo "=========================================="
        '';
        mode = "0755";
      };

      "audio-helpers/normalize-audio.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Normalizar volume de arquivos de áudio

          set -euo pipefail

          usage() {
            cat <<EOF
          Uso: normalize-audio <arquivo> [target_lufs]

          Normaliza o volume de um arquivo de áudio usando loudness normalization.

          Argumentos:
            arquivo      Arquivo de áudio para normalizar
            target_lufs  LUFS alvo (padrão: -16, range: -70 a -5)

          Exemplos:
            normalize-audio musica.flac
            normalize-audio musica.flac -14

          LUFS comuns:
            -23 LUFS: EBU R128 (broadcast)
            -16 LUFS: Spotify, YouTube
            -14 LUFS: Apple Music, TIDAL
            -9 LUFS:  Club/DJ sets
          EOF
            exit 1
          }

          if [ $# -lt 1 ]; then
            usage
          fi

          FILE="$1"
          TARGET_LUFS="''${2:--16}"

          if [ ! -f "$FILE" ]; then
            echo "Erro: Arquivo não encontrado: $FILE"
            exit 1
          fi

          BASENAME="$(basename "$FILE")"
          FILENAME="''${BASENAME%.*}"
          EXT="''${BASENAME##*.}"
          OUTPUT="''${FILENAME}_normalized.$EXT"

          echo "=========================================="
          echo "Normalização de Áudio"
          echo "=========================================="
          echo "Arquivo: $FILE"
          echo "Target: $TARGET_LUFS LUFS"
          echo "Output: $OUTPUT"
          echo "=========================================="
          echo

          ${pkgs.ffmpeg-full}/bin/ffmpeg \
            -i "$FILE" \
            -af "loudnorm=I=$TARGET_LUFS:TP=-1.5:LRA=11:print_format=summary" \
            -ar 48000 \
            "$OUTPUT" \
            -y

          echo
          echo "=========================================="
          echo "Normalização concluída!"
          echo "Arquivo salvo: $OUTPUT"
          echo "=========================================="
        '';
        mode = "0755";
      };

      "audio-helpers/split-audio.sh" = {
        text = ''
          #!/usr/bin/env bash
          # Dividir arquivo de áudio em partes iguais

          set -euo pipefail

          usage() {
            cat <<EOF
          Uso: split-audio <arquivo> <duração_segundos>

          Divide um arquivo de áudio em partes de duração especificada.

          Exemplos:
            split-audio musica.flac 60     # Partes de 60 segundos
            split-audio podcast.mp3 300    # Partes de 5 minutos
          EOF
            exit 1
          }

          if [ $# -lt 2 ]; then
            usage
          fi

          FILE="$1"
          DURATION="$2"

          if [ ! -f "$FILE" ]; then
            echo "Erro: Arquivo não encontrado: $FILE"
            exit 1
          fi

          BASENAME="$(basename "$FILE")"
          FILENAME="''${BASENAME%.*}"
          EXT="''${BASENAME##*.}"

          echo "=========================================="
          echo "Dividindo arquivo de áudio"
          echo "=========================================="
          echo "Arquivo: $FILE"
          echo "Duração por parte: $DURATION segundos"
          echo "=========================================="
          echo

          ${pkgs.ffmpeg-full}/bin/ffmpeg \
            -i "$FILE" \
            -f segment \
            -segment_time "$DURATION" \
            -c copy \
            "''${FILENAME}_part%03d.$EXT" \
            -y

          echo
          echo "=========================================="
          echo "Divisão concluída!"
          echo "=========================================="
        '';
        mode = "0755";
      };

      "audio-helpers/README.md" = {
        text = ''
          # Audio Production Helpers

          Scripts helper para produção musical no NixOS.

          ## Scripts Disponíveis

          ### youtube-to-flac
          Download de áudio do YouTube em formato FLAC de máxima qualidade.
          ```bash
          /etc/audio-helpers/youtube-to-flac.sh <URL> [DIRETÓRIO]
          ```

          ### batch-convert
          Conversão em batch de arquivos de áudio.
          ```bash
          /etc/audio-helpers/batch-convert.sh <formato> <diretório>
          ```
          Formatos: flac, mp3, wav, opus, ogg, m4a

          ### audio-metadata
          Exibir metadados detalhados de arquivos de áudio.
          ```bash
          /etc/audio-helpers/audio-metadata.sh <arquivo>
          ```

          ### normalize-audio
          Normalizar volume usando loudness normalization.
          ```bash
          /etc/audio-helpers/normalize-audio.sh <arquivo> [target_lufs]
          ```

          ### split-audio
          Dividir arquivo de áudio em partes iguais.
          ```bash
          /etc/audio-helpers/split-audio.sh <arquivo> <duração_segundos>
          ```

          ## Aliases Disponíveis

          ### DAW
          - `daw` - Abrir Ardour

          ### Download
          - `ytdl-audio` - Download de áudio (melhor qualidade)
          - `ytdl-flac` - Download em FLAC
          - `ytdl-mp3` - Download em MP3
          - `ytdl-opus` - Download em Opus

          ### Conversão
          - `to-flac` - Converter para FLAC
          - `to-mp3` - Converter para MP3
          - `to-wav` - Converter para WAV
          - `to-opus` - Converter para Opus

          ### Análise
          - `audio-info` - Informações do arquivo (ffprobe)
          - `audio-analyze` - Abrir Sonic Visualiser

          ### JACK
          - `jack-start` - Iniciar qjackctl
          - `jack-status` - Status das conexões
          - `jack-connections` - Listar conexões

          ### Utilitários
          - `list-audio-devices` - Listar dispositivos de áudio
          - `list-audio-cards` - Listar placas de som
          - `audio-monitor` - Abrir PavuControl

          ## Ativação

          Adicione ao seu `configuration.nix`:
          ```nix
          modules.audio.production.enable = true;
          ```

          Opções adicionais:
          ```nix
          modules.audio.production = {
            enable = true;
            jackAudio = true;        # JACK Audio Connection Kit
            plugins = true;          # Plugins LV2/LADSPA/VST
            synthesizers = true;     # Sintetizadores
            downloaders = true;      # yt-dlp, ffmpeg
          };
          ```
        '';
        mode = "0644";
      };
    };

    # Adicionar scripts ao PATH via wrapper
    environment.systemPackages = with pkgs; [
      (writeScriptBin "youtube-to-flac" ''
        exec /etc/audio-helpers/youtube-to-flac.sh "$@"
      '')
      (writeScriptBin "batch-convert" ''
        exec /etc/audio-helpers/batch-convert.sh "$@"
      '')
      (writeScriptBin "audio-metadata" ''
        exec /etc/audio-helpers/audio-metadata.sh "$@"
      '')
      (writeScriptBin "normalize-audio" ''
        exec /etc/audio-helpers/normalize-audio.sh "$@"
      '')
      (writeScriptBin "split-audio" ''
        exec /etc/audio-helpers/split-audio.sh "$@"
      '')
    ];

    # Configurar JACK se habilitado
    services.jack = mkIf cfg.jackAudio {
      jackd = {
        enable = false; # Geralmente iniciado manualmente ou via qjackctl
      };
    };

    # Configurar PulseAudio/PipeWire para baixa latência
    services.pipewire = mkIf config.services.pipewire.enable {
      extraConfig.pipewire = {
        "10-audio-production" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
            ];
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 128;
            "default.clock.max-quantum" = 2048;
          };
        };
      };
    };

    # Limites de sistema para áudio em tempo real
    security.pam.loginLimits = [
      {
        domain = "@audio";
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
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
    ];

    # Variáveis de ambiente para plugins
    environment.variables = {
      LADSPA_PATH = "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
      LV2_PATH = "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
      VST_PATH = "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
      DSSI_PATH = "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
    };
  };
}
