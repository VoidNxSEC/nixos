# F5-TTS - Text-to-Speech for Music Production & Video

Flow Matching Text-to-Speech synthesis system with Gradio web interface.

## Overview

F5-TTS is a state-of-the-art text-to-speech system using:
- **Diffusion Transformer** with ConvNeXt V2
- **Sway Sampling** for inference optimization
- **Multi-speaker support** with voice cloning
- **CUDA acceleration** for NVIDIA GPUs

Perfect for:
- Music production (voiceovers, narration)
- Video content creation
- Voice cloning and synthesis
- Audio book production

## Installation

Add to your NixOS configuration:

```nix
{
  kernelcore.packages.f5-tts.enable = true;
}
```

## Usage

### Web Interface (Gradio)

Launch the web UI on http://localhost:7860:

```bash
f5-tts-gradio
```

Features:
- Basic TTS generation
- Multi-speaker voice cloning
- Voice chat interface
- Real-time audio playback

### Command Line Interface

Generate speech from command line:

```bash
f5-tts-cli \
  --ref_audio reference.wav \
  --ref_text "Reference text" \
  --gen_text "Text to synthesize" \
  --output output.wav
```

## Systemd Service

Run F5-TTS as a background service:

```nix
{
  kernelcore.packages.f5-tts = {
    enable = true;
    enableService = true;
    servicePort = 7860;
    serviceAddress = "127.0.0.1";  # Change to "0.0.0.0" for network access
  };
}
```

Access at: http://localhost:7860

## Configuration Options

### Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable F5-TTS package |
| `enableService` | bool | false | Run as systemd service |
| `servicePort` | port | 7860 | Gradio web interface port |
| `serviceAddress` | string | "127.0.0.1" | Bind address |

### Example Configuration

```nix
{
  # Install F5-TTS for local use
  kernelcore.packages.f5-tts.enable = true;

  # Optional: Run as service with network access
  kernelcore.packages.f5-tts = {
    enable = true;
    enableService = true;
    servicePort = 8080;
    serviceAddress = "0.0.0.0";
  };

  # Firewall is automatically configured when service is enabled
}
```

## GPU Acceleration

F5-TTS automatically detects and uses NVIDIA CUDA if available:

```nix
{
  # Ensure NVIDIA drivers are enabled
  hardware.nvidia.enable = true;

  # F5-TTS will use CUDA automatically
  kernelcore.packages.f5-tts.enable = true;
}
```

Check GPU usage:
```bash
watch -n 1 nvidia-smi
```

## Requirements

- **Python**: 3.11
- **GPU**: NVIDIA with CUDA support (optional but recommended)
- **RAM**: 4GB minimum, 8GB+ recommended
- **Storage**: ~5GB for models and dependencies

## Performance

RTF (Real Time Factor): 0.0394 on L20 GPU
- Can generate speech ~25x faster than real-time
- Batch processing for multiple samples

## Troubleshooting

### Missing dependencies

If you see import errors, verify Python packages:
```bash
nix-shell -p python311Packages.pytorch-bin --run "python -c 'import torch; print(torch.__version__)'"
```

### CUDA not detected

Check NVIDIA drivers:
```bash
nvidia-smi
```

Verify CUDA visibility:
```bash
echo $CUDA_VISIBLE_DEVICES
```

### Service not starting

Check service logs:
```bash
journalctl -u f5-tts -f
```

Check service status:
```bash
systemctl status f5-tts
```

## Resources

- **GitHub**: https://github.com/SWivid/F5-TTS
- **Paper**: Flow Matching for Generative Modeling
- **Gradio Demo**: Included in package

## Version

- **Package Version**: 1.1.15
- **Last Updated**: 2026-01-23
- **NixOS Module**: modules/packages/f5-tts

## License

MIT License - See upstream repository for details
