#!/usr/bin/env bash
#
# Voice Capture Agent - Frontend para o Agent Hub
#
# Captura áudio do microfone e envia para o pipeline de STT (Whisper) via Kafka.
#

set -euo pipefail

# Configurações
KAFKA_BROKER="localhost:9092"
TOPIC="agent.stt.requests"
AGENT_ID="desktop-user-input"
TMP_DIR="/tmp/agent-hub/speech"
mkdir -p "$TMP_DIR"

# Dependências: sox (rec), kcat, jq
if ! command -v rec &> /dev/null || ! command -v kcat &> /dev/null;
    echo "❌ Erro: sox e kcat são necessários."
    exit 1
fi

REQUEST_ID=$(uuidgen | cut -d'-' -f1)
AUDIO_FILE="$TMP_DIR/rec-$REQUEST_ID.wav"

echo "🎤 Gravando... (Fale agora, o script para automaticamente após silêncio)"

# Grava áudio:
# -r 16000: Sample rate ideal para Whisper
# silence 1 0.1 1% 1 1.0 1%: Para após 1s de silêncio
rec -r 16000 -c 1 -b 16 "$AUDIO_FILE" silence 1 0.1 1% 1 1.0 1% 2>/dev/null

if [ ! -f "$AUDIO_FILE" ] || [ ! -s "$AUDIO_FILE" ]; then
    echo "⚠️  Nenhum áudio capturado."
    exit 0
fi

echo "✅ Áudio capturado: $AUDIO_FILE"

# Prepara o payload JSON
PAYLOAD=$(jq -n \
    --arg aid "$AGENT_ID" \
    --arg rid "$REQUEST_ID" \
    --arg path "$AUDIO_FILE" \
    '{agent_id: $aid, request_id: $rid, audio_path: $path}')

# Envia para o Kafka
echo "$PAYLOAD" | kcat -P -b "$KAFKA_BROKER" -t "$TOPIC"

echo "🚀 Request enviado ao pipeline: $REQUEST_ID"
