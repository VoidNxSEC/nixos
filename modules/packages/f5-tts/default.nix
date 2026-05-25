# F5-TTS - Text-to-Speech System for Music Production & Video
#
# Self-contained package for F5-TTS with Gradio web interface
# Supports NVIDIA CUDA acceleration for audio generation
# Usage: f5-tts_infer-gradio (web UI) or f5-tts_infer-cli (CLI)
#
# Source: https://github.com/SWivid/F5-TTS
# Version: 1.1.15
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.f5-tts;

  # Python environment with F5-TTS from PyPI
  f5-tts-python = pkgs.python313.withPackages (
    ps: with ps; [
      # Install F5-TTS from PyPI
      (ps.buildPythonPackage rec {
        pname = "f5_tts";
        version = "1.1.15";
        format = "wheel";

        src = ps.fetchPypi {
          inherit pname version;
          format = "wheel";
          python = "py3";
          dist = "py3";
          sha256 = "sha256-7FgP0mGYJa6f/mKvRzPo8yT5A0oc8gi9smKOPCrnjQw=";
        };

        doCheck = false;
        pythonImportsCheck = [ ]; # deps fornecidas no env runtime, não no build
      })

      # Core ML frameworks
      torch-bin
      torchaudio-bin

      # Gradio for web interface
      gradio
    ]
  );

  # Wrapper script for Gradio web interface
  f5-tts-gradio = pkgs.writeShellScriptBin "f5-tts-gradio" ''
    export PYTHONPATH="${f5-tts-python}/${f5-tts-python.sitePackages}:$PYTHONPATH"

    # Enable CUDA if available
    ${lib.optionalString config.kernelcore.nvidia.enable ''
      export CUDA_VISIBLE_DEVICES=''${CUDA_VISIBLE_DEVICES:-0}
    ''}

    # Run Gradio interface
    exec ${f5-tts-python}/bin/python -m f5_tts.infer.infer_gradio "$@"
  '';

  # Wrapper script for CLI interface
  f5-tts-cli = pkgs.writeShellScriptBin "f5-tts-cli" ''
    export PYTHONPATH="${f5-tts-python}/${f5-tts-python.sitePackages}:$PYTHONPATH"

    # Enable CUDA if available
    ${lib.optionalString config.kernelcore.nvidia.enable ''
      export CUDA_VISIBLE_DEVICES=''${CUDA_VISIBLE_DEVICES:-0}
    ''}

    # Run CLI interface
    exec ${f5-tts-python}/bin/python -m f5_tts.infer.infer_cli "$@"
  '';

  # Combined package with all tools
  f5-tts-package = pkgs.symlinkJoin {
    name = "f5-tts";
    paths = [
      f5-tts-python
      f5-tts-gradio
      f5-tts-cli
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Add ffmpeg to PATH for audio processing
      for prog in $out/bin/*; do
        wrapProgram $prog \
          --prefix PATH : ${lib.makeBinPath [ pkgs.ffmpeg ]}
      done
    '';
  };

in
{
  options.kernelcore.packages.f5-tts = {
    enable = lib.mkEnableOption "F5-TTS text-to-speech system for music production and video";

    enableService = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable F5-TTS as a systemd service with Gradio web interface";
    };

    servicePort = lib.mkOption {
      type = lib.types.port;
      default = 7860;
      description = "Port for F5-TTS Gradio web interface";
    };

    serviceAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address for F5-TTS Gradio web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install F5-TTS package
    environment.systemPackages = [ f5-tts-package ];

    # Ensure FFmpeg is available for audio processing
    #programs.ffmpeg.enable = true;

    # Optional: Run as systemd service
    systemd.services.f5-tts = lib.mkIf cfg.enableService {
      description = "F5-TTS Text-to-Speech Gradio Web Interface";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = config.system.user.username;
        Group = "users";
        ExecStart = "${f5-tts-gradio}/bin/f5-tts-gradio --server_name ${cfg.serviceAddress} --server_port ${toString cfg.servicePort}";
        Restart = "on-failure";
        RestartSec = "10s";

        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";

        # Allow access to CUDA devices if NVIDIA is enabled
        DeviceAllow = lib.mkIf config.kernelcore.nvidia.enable [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-modeset rw"
          "/dev/nvidia-uvm rw"
        ];
      };

      environment = {
        PYTHONPATH = "${f5-tts-python}/${f5-tts-python.sitePackages}";
      }
      // lib.optionalAttrs config.kernelcore.nvidia.enable {
        CUDA_VISIBLE_DEVICES = "0";
      };
    };

    # Firewall configuration for service
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.enableService [ cfg.servicePort ];
  };
}
