# Módulo de Produção Musical

Módulo NixOS completo para produção musical com Ardour, plugins, sintetizadores e ferramentas de áudio.

## Estrutura

```
/etc/nixos/modules/audio/
├── production.nix          # Módulo principal
└── README.md              # Esta documentação

/etc/audio-helpers/         # Scripts helper (criados automaticamente)
├── youtube-to-flac.sh
├── batch-convert.sh
├── audio-metadata.sh
├── normalize-audio.sh
├── split-audio.sh
└── README.md
```

## Ativação

### 1. Importar o módulo

Adicione ao seu `/etc/nixos/configuration.nix`:

```nix
{
  imports = [
    # ... outros imports
    ./modules/audio/production.nix
  ];

  # Ativar o módulo
  modules.audio.production.enable = true;
}
```

### 2. Configuração Completa (Recomendado)

```nix
{
  imports = [
    ./modules/audio/production.nix
  ];

  modules.audio.production = {
    enable = true;
    jackAudio = true;        # JACK Audio Connection Kit
    plugins = true;          # Plugins LV2/LADSPA/VST
    synthesizers = true;     # Sintetizadores (Helm, ZynAddSubFX, Yoshimi)
    downloaders = true;      # yt-dlp, ffmpeg-full
  };
}
```

### 3. Aplicar Configuração

```bash
sudo nixos-rebuild switch
```

## Ferramentas Incluídas

### DAW e Editores
- **Ardour**: DAW profissional multipista
- **Audacity**: Editor de áudio

### Plugins (quando `plugins = true`)
- **LSP Plugins**: Suite completa de plugins profissionais
- **Calf Studio Gear**: Efeitos e processadores
- **EQ10Q**: Equalizador paramétrico 10 bandas
- **Guitarix**: Amplificadores e efeitos de guitarra
- **GX Plugins**: Plugins adicionais

### Sintetizadores (quando `synthesizers = true`)
- **Helm**: Sintetizador polifônico moderno
- **ZynAddSubFX**: Sintetizador poderoso
- **Yoshimi**: Fork otimizado do ZynAddSubFX

### Download e Conversão (quando `downloaders = true`)
- **yt-dlp**: Download de áudio/vídeo
- **ffmpeg-full**: Conversão e processamento completo

### Sistema de Áudio (quando `jackAudio = true`)
- **JACK2**: Sistema de áudio de baixa latência
- **qjackctl**: Interface gráfica para JACK

### Utilitários Sempre Incluídos
- **Sox**: Swiss Army knife de áudio
- **Sonic Visualiser**: Análise e visualização
- **Conversores**: FLAC, LAME, Vorbis, Opus, WavPack
- **Sistema**: ALSA Utils, PavuControl, PulseAudio
- **Python**: Mutagen, Pydub

## Comandos e Aliases

### Scripts Helper (disponíveis globalmente)

```bash
# Download de áudio do YouTube em FLAC
youtube-to-flac 'https://www.youtube.com/watch?v=...'
youtube-to-flac 'https://www.youtube.com/watch?v=...' ~/Music

# Conversão em batch
batch-convert flac ~/Music/samples
batch-convert mp3 .

# Metadados de áudio
audio-metadata musica.flac

# Normalizar volume
normalize-audio musica.flac
normalize-audio musica.flac -14

# Dividir áudio
split-audio podcast.mp3 300
```

### Aliases de Shell

#### DAW
```bash
daw                    # Abrir Ardour
```

#### Download
```bash
ytdl-audio <URL>       # Download (melhor qualidade)
ytdl-flac <URL>        # Download em FLAC
ytdl-mp3 <URL>         # Download em MP3
ytdl-opus <URL>        # Download em Opus
```

#### Conversão
```bash
to-flac input.mp3 output.flac
to-mp3 input.flac output.mp3
to-wav input.mp3 output.wav
to-opus input.flac output.opus
```

#### Análise
```bash
audio-info arquivo.flac        # Informações detalhadas
audio-analyze arquivo.flac     # Abrir Sonic Visualiser
```

#### JACK Audio
```bash
jack-start             # Iniciar qjackctl
jack-status            # Status das conexões
jack-connections       # Listar conexões ativas
```

#### Utilitários do Sistema
```bash
list-audio-devices     # Listar dispositivos
list-audio-cards       # Listar placas de som
audio-monitor          # Abrir PavuControl
```

## Configurações Automáticas

### Variáveis de Ambiente para Plugins
```bash
LADSPA_PATH           # Plugins LADSPA
LV2_PATH              # Plugins LV2
VST_PATH              # Plugins VST
DSSI_PATH             # Plugins DSSI
```

### PipeWire (Baixa Latência)
```
Sample Rate: 48000 Hz
Allowed Rates: 44100, 48000, 88200, 96000 Hz
Quantum: 128 samples
Min Quantum: 128 samples
Max Quantum: 2048 samples
```

### Permissões de Áudio em Tempo Real
- Memlock: unlimited
- RT Priority: 99
- Open Files: 99999

### Grupos do Usuário
Usuário automaticamente adicionado aos grupos:
- `audio`
- `jackaudio`

## Exemplos de Uso

### Workflow de Download e Edição

```bash
# 1. Baixar música do YouTube em FLAC
youtube-to-flac 'https://www.youtube.com/watch?v=OSih-PC-GbM' ~/Music

# 2. Ver metadados
audio-metadata ~/Music/nome-da-musica.flac

# 3. Normalizar volume para Spotify (-16 LUFS)
normalize-audio ~/Music/nome-da-musica.flac -16

# 4. Abrir no Ardour
daw
```

### Conversão em Batch

```bash
# Converter todos os MP3 de uma pasta para FLAC
batch-convert flac ~/Music/collection

# Resultado em: ~/Music/collection/converted_flac/
```

### Produção Musical

```bash
# Iniciar JACK
jack-start

# Abrir Ardour
daw

# Em outra sessão: monitorar áudio
audio-monitor
```

## Troubleshooting

### Plugins não aparecem no Ardour
Verifique as variáveis de ambiente:
```bash
echo $LV2_PATH
echo $LADSPA_PATH
```

Reinicie o Ardour após aplicar a configuração.

### JACK não inicia
```bash
# Verificar dispositivos de áudio
list-audio-devices

# Ajustar configuração no qjackctl:
# - Sample Rate: 48000
# - Frames/Period: 128 ou 256
# - Periods/Buffer: 2
```

### Problemas de Latência
Adicione ao `configuration.nix`:
```nix
powerManagement.cpuFreqGovernor = "performance";
```

### Permissões de Áudio
Verifique se está no grupo audio:
```bash
groups | grep audio
```

Se não estiver, reaplique a configuração:
```bash
sudo nixos-rebuild switch
```

E faça logout/login.

## Configurações Opcionais

### Desabilitar PulseAudio (usar apenas JACK)
```nix
hardware.pulseaudio.enable = false;
services.pipewire.enable = false;
```

### Habilitar Realtime Kernel
```nix
boot.kernelPackages = pkgs.linuxPackages_rt_latest;
```

### Aumentar Prioridade do Áudio
```nix
security.rtkit.enable = true;
```

## Desinstalação

Para desabilitar o módulo:

```nix
modules.audio.production.enable = false;
```

E aplicar:
```bash
sudo nixos-rebuild switch
```

Os scripts em `/etc/audio-helpers/` serão removidos automaticamente.

## Suporte

Para mais informações sobre as ferramentas:
- Ardour: https://ardour.org/
- JACK: https://jackaudio.org/
- yt-dlp: https://github.com/yt-dlp/yt-dlp
- NixOS: https://nixos.org/manual/

## Licença

Scripts e configurações para uso pessoal. Ferramentas incluídas têm suas próprias licenças.
