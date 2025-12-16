#!/bin/bash
# ============================================================
# Multimodal AI Stack Aliases
# ============================================================

# ============================================================
# 🚀 STACK MANAGEMENT
# ============================================================

# Sobe stack completa
alias ai-up='docker-compose -f ~/Base/docker-compose-multimodal.yml up -d'

# Para stack
alias ai-down='docker-compose -f ~/Base/docker-compose-multimodal.yml down'

# Restart stack
alias ai-restart='docker-compose -f ~/Base/docker-compose-multimodal.yml restart'

# Status dos serviços
alias ai-status='docker-compose -f ~/Base/docker-compose-multimodal.yml ps'

# Logs de todos os serviços
alias ai-logs='docker-compose -f ~/Base/docker-compose-multimodal.yml logs -f'

# ============================================================
# ============================================================


# Lista modelos instalados

# Chat interativo com modelo

# Remove modelo

# Puxa modelos populares

# ============================================================
# 🎨 STABLE DIFFUSION
# ============================================================

# Acessa WebUI (abre browser)
alias sd-open='xdg-open http://localhost:7860'

# Logs do SD
alias sd-logs='docker logs -f sd-webui'

# Restart SD
alias sd-restart='docker restart sd-webui'

# ============================================================
# 🗣️ WHISPER (Speech-to-Text)
# ============================================================

# Transcreve arquivo de áudio
whisper-transcribe() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-transcribe <audio_file>"
        return 1
    fi

    curl -F "audio_file=@$1" http://localhost:9000/asr?task=transcribe
}

# Traduz áudio para inglês
whisper-translate() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-translate <audio_file>"
        return 1
    fi

    curl -F "audio_file=@$1" http://localhost:9000/asr?task=translate
}

# ============================================================
# 🔊 TTS (Text-to-Speech)
# ============================================================

# Gera áudio a partir de texto
tts-speak() {
    local text="${1:-Hello from TTS}"
    local output="${2:-output.wav}"

    curl -X POST "http://localhost:5002/api/tts" \
         -H "Content-Type: application/json" \
         -d "{\"text\": \"$text\"}" \
         --output "$output"

    echo "Audio saved to: $output"
}

# ============================================================
# 🧪 API TESTING
# ============================================================

    curl http://localhost:11434/api/generate -d '{
      "model": "qwen3:8b",
      "prompt": "Why is the sky blue?",
      "stream": false
    }'
}

# Testa Stable Diffusion API
test-sd() {
    curl -X POST http://localhost:7860/sdapi/v1/txt2img \
         -H "Content-Type: application/json" \
         -d '{
           "prompt": "a cat in space",
           "steps": 20,
           "width": 512,
           "height": 512
         }' | jq -r '.images[0]' | base64 -d > test_sd.png

    echo "Image saved to: test_sd.png"
}

# ============================================================
# 📊 MONITORING
# ============================================================

# Mostra uso de recursos dos containers
alias ai-stats='docker stats $(docker ps --filter "network=multimodal-ai" -q)'

# GPU usage de todos os containers#!/bin/bash
# ============================================================
# Multimodal AI Stack Aliases
# ============================================================

# ============================================================
# 🚀 STACK MANAGEMENT
# ============================================================

# Sobe stack completa
alias ai-up='docker-compose -f ~/Base/docker-compose-multimodal.yml up -d'

# Para stack
alias ai-down='docker-compose -f ~/Base/docker-compose-multimodal.yml down'

# Restart stack
alias ai-restart='docker-compose -f ~/Base/docker-compose-multimodal.yml restart'

# Status dos serviços
alias ai-status='docker-compose -f ~/Base/docker-compose-multimodal.yml ps'

# Logs de todos os serviços
alias ai-logs='docker-compose -f ~/Base/docker-compose-multimodal.yml logs -f'

# ============================================================
# ============================================================


# Lista modelos instalados

# Chat interativo com modelo

# Remove modelo

# Puxa modelos populares

# ============================================================
# 🎨 STABLE DIFFUSION
# ============================================================

# Acessa WebUI (abre browser)
alias sd-open='xdg-open http://localhost:7860'

# Logs do SD
alias sd-logs='docker logs -f sd-webui'

# Restart SD
alias sd-restart='docker restart sd-webui'

# ============================================================
# 🗣️ WHISPER (Speech-to-Text)
# ============================================================

# Transcreve arquivo de áudio
whisper-transcribe() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-transcribe <audio_file>"
        return 1
    fi

    curl -F "audio_file=@$1" http://localhost:9000/asr?task=transcribe
}

# Traduz áudio para inglês
whisper-translate() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-translate <audio_file>"
        return 1
    fi

    curl -F "audio_file=@$1" http://localhost:9000/asr?task=translate
}

# ============================================================
# 🔊 TTS (Text-to-Speech)
# ============================================================

# Gera áudio a partir de texto
tts-speak() {
    local text="${1:-Hello from TTS}"
    local output="${2:-output.wav}"

    curl -X POST "http://localhost:5002/api/tts" \
         -H "Content-Type: application/json" \
         -d "{\"text\": \"$text\"}" \
         --output "$output"

    echo "Audio saved to: $output"
}

# ============================================================
# 🧪 API TESTING
# ============================================================

#    curl http://localhost:11434/api/generate -d '{
#      "model": "llama3.2",
#      "prompt": "Why is the sky blue?",
#      "stream": false
#    }'
#}

# Testa Stable Diffusion API
test-sd() {
    curl -X POST http://localhost:7860/sdapi/v1/txt2img \
         -H "Content-Type: application/json" \
         -d '{
           "prompt": "a cat in space",
           "steps": 20,
           "width": 512,
           "height": 512
         }' | jq -r '.images[0]' | base64 -d > test_sd.png

    echo "Image saved to: test_sd.png"
}

# ============================================================
# 📊 MONITORING
# ============================================================

# Mostra uso de recursos dos containers
alias ai-stats='docker stats $(docker ps --filter "network=multimodal-ai" -q)'

# GPU usage de todos os containers
alias ai-gpu='watch -n 1 "nvidia-smi && echo && docker ps --format \"table {{.Names}}\t{{.Status}}\""'

# ============================================================
# 🔧 UTILITIES
# ============================================================

# Limpa cache/modelos antigos
ai-cleanup() {
    echo "Cleaning up AI stack..."
    docker-compose -f ~/Base/docker-compose-multimodal.yml down -v
    docker system prune -f
    echo "Cleanup complete!"
}

# Download de modelos populares
ai-download-models() {
    echo "📥 Downloading popular models..."


    echo "✓ Models downloaded!"
}

# Backup de configurações
ai-backup() {
    local backup_dir="$HOME/ai-backup-$(date +%Y%m%d)"
    mkdir -p "$backup_dir"


    echo "Backup saved to: $backup_dir"
}

# ============================================================
# 🎯 WORKFLOWS
# ============================================================

# Pipeline: Text → Image → Description
workflow-text-to-image-analysis() {
    local prompt="$1"

    echo "1. Generating image from: $prompt"
    curl -X POST http://localhost:7860/sdapi/v1/txt2img \
         -H "Content-Type: application/json" \
         -d "{\"prompt\": \"$prompt\", \"steps\": 20}" \
         | jq -r '.images[0]' | base64 -d > workflow_image.png

    echo "2. Analyzing generated image..."
    # Aqui você usaria uma Vision API ou modelo local
    echo "Image saved to: workflow_image.png"
}

# Pipeline: Audio → Text → Summary
workflow-audio-to-summary() {
    local audio_file="$1"

    echo "1. Transcribing audio..."
    local text=$(curl -F "audio_file=@$audio_file" \
                      http://localhost:9000/asr?task=transcribe | jq -r '.text')

    echo "Transcription: $text"

    echo "2. Generating summary..."
    #curl http://localhost:11434/api/generate -d "{
    #  \"model\": \"llama3.2\",
    #  \"prompt\": \"Summarize this in one sentence: $text\",
    #  \"stream\": false
    #}" | jq -r '.response'
}

# ============================================================
# 📚 HELP
# ============================================================

ai-help() {
    echo "🤖 Multimodal AI Stack - Commands"
    echo ""
    echo "Stack Management:"
    echo "  ai-up              - Start all services"
    echo "  ai-down            - Stop all services"
    echo "  ai-restart         - Restart all services"
    echo "  ai-status          - Show service status"
    echo "  ai-logs            - Follow logs"
    echo ""
    echo ""
    echo "Stable Diffusion:"
    echo "  sd-open            - Open WebUI in browser"
    echo "  sd-logs            - View SD logs"
    echo "  test-sd            - Test SD API"
    echo ""
    echo "Whisper (STT):"
    echo "  whisper-transcribe <file>  - Transcribe audio"
    echo "  whisper-translate <file>   - Translate to English"
    echo ""
    echo "TTS:"
    echo "  tts-speak \"text\" [output.wav]  - Generate speech"
    echo ""
    echo "Monitoring:"
    echo "  ai-stats           - Container resource usage"
    echo "  ai-gpu             - GPU usage monitor"
    echo ""
    echo "Workflows:"
    echo "  workflow-text-to-image-analysis <prompt>"
    echo "  workflow-audio-to-summary <audio_file>"
    echo ""
    echo "Utilities:"
    echo "  ai-cleanup         - Clean cache and volumes"
    echo "  ai-download-models - Download popular models"
    echo "  ai-backup          - Backup configurations"
}

# Export functions
export -f whisper-transcribe
export -f whisper-translate
export -f tts-speak
export -f test-sd
export -f ai-cleanup
export -f ai-download-models
export -f ai-backup
export -f workflow-text-to-image-analysis
export -f workflow-audio-to-summary
export -f ai-help

#echo "✓ Multimodal AI aliases loaded! Type 'ai-help' for commands"
alias gpu-watch='watch -n 1 "nvidia-smi && echo && docker ps --format \"table {{.Names}}\t{{.Status}}\""'
