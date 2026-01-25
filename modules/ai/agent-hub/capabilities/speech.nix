# Agent Hub - Speech Capabilities Module
#
# Integra F5-TTS (text-to-speech) e Whisper (speech-to-text) como capabilities
# disponíveis para agentes via gRPC e event streaming (Kafka/Redpanda)
#
# Arquitetura:
#   1. Agentes enviam eventos "tts.request" para Kafka
#   2. Speech Gateway processa via F5-TTS
#   3. Audio gerado é publicado como evento "tts.completed"
#   4. STT (Whisper) processa audio input → texto para automação
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.ai.agent-hub.capabilities.speech;

  # Speech Gateway - Bridge entre Kafka e F5-TTS/Whisper
  speech-gateway = pkgs.writeShellApplication {
    name = "speech-gateway";
    runtimeInputs = with pkgs; [
      python313
      jq
      kafkacat
    ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🎤 Speech Gateway: Listening for TTS requests on Kafka..."

      # Consume TTS requests from Kafka topic: agent.tts.requests
      kafkacat -C -b localhost:9092 -t agent.tts.requests -o end | while read -r message; do
        echo "📨 TTS Request: $message"

        # Extract text from JSON message
        text=$(echo "$message" | jq -r '.text')
        agent_id=$(echo "$message" | jq -r '.agent_id')
        request_id=$(echo "$message" | jq -r '.request_id')

        # Generate audio using F5-TTS
        output_file="/tmp/tts-$request_id.wav"

        # Call F5-TTS CLI
        ${pkgs.python313.withPackages (ps: [ ps.f5-tts ])}/bin/python -m f5_tts.infer.infer_cli \
          --text "$text" \
          --output "$output_file" \
          --model-name "F5-TTS" \
          --ref-audio "${cfg.referenceVoice}" \
          --ref-text "${cfg.referenceText}"

        # Publish completion event to Kafka
        echo "{\"request_id\":\"$request_id\",\"agent_id\":\"$agent_id\",\"status\":\"completed\",\"audio_path\":\"$output_file\"}" | \
          kafkacat -P -b localhost:9092 -t agent.tts.completed

        echo "✅ TTS Completed: $request_id → $output_file"
      done
    '';
  };

  # Whisper STT Service for bidirectional speech automation
  whisper-gateway = pkgs.writeShellApplication {
    name = "whisper-gateway";
    runtimeInputs = with pkgs; [
      python313Packages.openai-whisper
      python313Packages.torch
      kafkacat
      jq
    ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🎧 Whisper Gateway: Listening for STT requests on Kafka..."

      # Consume STT requests from Kafka topic: agent.stt.requests
      kafkacat -C -b localhost:9092 -t agent.stt.requests -o end | while read -r message; do
        echo "📨 STT Request: $message"

        audio_path=$(echo "$message" | jq -r '.audio_path')
        agent_id=$(echo "$message" | jq -r '.agent_id')
        request_id=$(echo "$message" | jq -r '.request_id')

        # Transcribe audio using Whisper
        text=$(whisper "$audio_path" --model ${cfg.whisperModel} --language pt --output_format txt --output_dir /tmp)

        # Publish transcription to Kafka
        echo "{\"request_id\":\"$request_id\",\"agent_id\":\"$agent_id\",\"status\":\"completed\",\"text\":\"$text\"}" | \
          kafkacat -P -b localhost:9092 -t agent.stt.completed

        echo "✅ STT Completed: $request_id"
      done
    '';
  };

in
{
  options.kernelcore.ai.agent-hub.capabilities.speech = {
    enable = lib.mkEnableOption "Speech capabilities (TTS + STT) for Agent Hub";

    enableTTS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable F5-TTS text-to-speech capability";
    };

    enableSTT = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Whisper speech-to-text capability";
    };

    referenceVoice = lib.mkOption {
      type = lib.types.path;
      default = ./assets/reference-voice.wav;
      description = "Reference voice audio for F5-TTS voice cloning";
    };

    referenceText = lib.mkOption {
      type = lib.types.str;
      default = "Olá, eu sou o assistente de inteligência artificial do Agent Hub.";
      description = "Reference text matching the reference voice audio";
    };

    whisperModel = lib.mkOption {
      type = lib.types.enum [
        "tiny"
        "base"
        "small"
        "medium"
        "large"
      ];
      default = "base";
      description = "Whisper model size (larger = more accurate but slower)";
    };

    kafkaTopics = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ttsRequests = "agent.tts.requests";
        ttsCompleted = "agent.tts.completed";
        sttRequests = "agent.stt.requests";
        sttCompleted = "agent.stt.completed";
      };
      description = "Kafka topics for speech event streaming";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable F5-TTS package
    kernelcore.packages.f5-tts.enable = lib.mkIf cfg.enableTTS true;

    # Install Whisper for STT
    environment.systemPackages = lib.mkIf cfg.enableSTT [
      pkgs.python313Packages.openai-whisper
      pkgs.ffmpeg
    ];

    # Speech Gateway Service (TTS)
    systemd.services.speech-gateway-tts = lib.mkIf cfg.enableTTS {
      description = "Agent Hub Speech Gateway - TTS (F5-TTS)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "redpanda.service"
      ];
      requires = [ "redpanda.service" ];

      serviceConfig = {
        Type = "simple";
        User = "kernelcore";
        Group = "users";
        ExecStart = "${speech-gateway}/bin/speech-gateway";
        Restart = "on-failure";
        RestartSec = "10s";

        # Security
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/tmp" ];

        # CUDA support if enabled
        DeviceAllow = lib.mkIf config.kernelcore.nvidia.enable [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
        ];
      };

      environment = {
        PYTHONPATH = "${pkgs.python313.withPackages (ps: [ ps.f5-tts ])}/${pkgs.python313.sitePackages}";
      }
      // lib.optionalAttrs config.kernelcore.nvidia.enable {
        CUDA_VISIBLE_DEVICES = "0";
      };
    };

    # Whisper Gateway Service (STT)
    systemd.services.speech-gateway-stt = lib.mkIf cfg.enableSTT {
      description = "Agent Hub Speech Gateway - STT (Whisper)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "redpanda.service"
      ];
      requires = [ "redpanda.service" ];

      serviceConfig = {
        Type = "simple";
        User = "kernelcore";
        Group = "users";
        ExecStart = "${whisper-gateway}/bin/whisper-gateway";
        Restart = "on-failure";
        RestartSec = "10s";

        # Security
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/tmp" ];

        # CUDA support if enabled
        DeviceAllow = lib.mkIf config.kernelcore.nvidia.enable [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
        ];
      };

      environment = lib.optionalAttrs config.kernelcore.nvidia.enable {
        CUDA_VISIBLE_DEVICES = "0";
      };
    };

    # Create Kafka topics for speech events
    systemd.services.speech-topics-init = {
      description = "Initialize Kafka topics for Agent Hub Speech";
      wantedBy = [ "multi-user.target" ];
      after = [ "redpanda.service" ];
      requires = [ "redpanda.service" ];
      serviceConfig.Type = "oneshot";

      script = ''
        # Wait for Redpanda to be ready
        sleep 5

        # Create topics
        ${pkgs.apacheKafka}/bin/kafka-topics.sh --create \
          --bootstrap-server localhost:9092 \
          --topic ${cfg.kafkaTopics.ttsRequests} \
          --partitions 1 \
          --replication-factor 1 \
          --if-not-exists

        ${pkgs.apacheKafka}/bin/kafka-topics.sh --create \
          --bootstrap-server localhost:9092 \
          --topic ${cfg.kafkaTopics.ttsCompleted} \
          --partitions 1 \
          --replication-factor 1 \
          --if-not-exists

        ${pkgs.apacheKafka}/bin/kafka-topics.sh --create \
          --bootstrap-server localhost:9092 \
          --topic ${cfg.kafkaTopics.sttRequests} \
          --partitions 1 \
          --replication-factor 1 \
          --if-not-exists

        ${pkgs.apacheKafka}/bin/kafka-topics.sh --create \
          --bootstrap-server localhost:9092 \
          --topic ${cfg.kafkaTopics.sttCompleted} \
          --partitions 1 \
          --replication-factor 1 \
          --if-not-exists

        echo "✅ Speech topics initialized"
      '';
    };
  };
}
