#!/bin/bash
# ============================================================
# AI Compose Stack Manager - Docker Compose Edition
# Conecta com docker-compose-multimodal.yml
# ============================================================

# ============================================================
# 📍 CONFIGURATION
# ============================================================

# Path do docker-compose (ajusta conforme teu setup)
AI_COMPOSE_FILE="${AI_COMPOSE_FILE:-$HOME/Base/docker-compose-multimodal.yml}"

# Alias helper pra não digitar sempre
alias dc-ai="docker-compose -f $AI_COMPOSE_FILE"

# ============================================================
# 🚀 STACK LIFECYCLE
# ============================================================

# Start completo (all services)
alias ai-up='docker-compose -f $AI_COMPOSE_FILE up -d'

# Start seletivo (só o que você quer)
ai-up-minimal() {
}

ai-up-full() {
    echo "🚀 Starting FULL stack (all services)..."
    docker-compose -f "$AI_COMPOSE_FILE" up -d
    sleep 5
    ai-status
}

ai-up-llm() {
}

ai-up-vision() {
    echo "🚀 Starting Vision stack (ComfyUI)..."
    docker-compose -f "$AI_COMPOSE_FILE" up -d comfyui
}

ai-up-audio() {
    echo "🚀 Starting Audio stack (Whisper + Piper)..."
    docker-compose -f "$AI_COMPOSE_FILE" up -d whisper-api piper-tts
}

# Stop
alias ai-down='docker-compose -f $AI_COMPOSE_FILE down'

# Stop com limpeza de volumes (CUIDADO: deleta modelos baixados)
ai-down-clean() {
    echo "⚠️  This will DELETE all volumes (models, outputs, etc)"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        docker-compose -f "$AI_COMPOSE_FILE" down -v
        echo "✓ Clean shutdown complete"
    else
        echo "Cancelled"
    fi
}

# Restart
alias ai-restart='docker-compose -f $AI_COMPOSE_FILE restart'

# Restart específico
ai-restart-service() {
    if [ -z "$1" ]; then
        echo "Usage: ai-restart-service <service_name>"
        return 1
    fi
    docker-compose -f "$AI_COMPOSE_FILE" restart "$1"
}

# ============================================================
# 📊 MONITORING & STATUS
# ============================================================

# Status detalhado
alias ai-status='docker-compose -f $AI_COMPOSE_FILE ps'

# Logs de todos os serviços
alias ai-logs='docker-compose -f $AI_COMPOSE_FILE logs -f'

# Logs de serviço específico
ai-logs-service() {
    if [ -z "$1" ]; then
        echo "Usage: ai-logs-service <service_name>"
        return 1
    fi
    docker-compose -f "$AI_COMPOSE_FILE" logs -f "$1"
}

# Quick health check
ai-health() {
    echo "🏥 Health Check - Multimodal AI Stack"
    echo "======================================"
    
    curl -s http://localhost:11434/api/tags > /dev/null && echo "✓ OK" || echo "✗ DOWN"
    
    # ComfyUI
    echo -n "ComfyUI (8188): "
    curl -s http://localhost:8188/ > /dev/null && echo "✓ OK" || echo "✗ DOWN"
    
    # vLLM
    echo -n "vLLM (8000): "
    curl -s http://localhost:8000/health > /dev/null && echo "✓ OK" || echo "✗ DOWN"
    
    # Whisper
    echo -n "Whisper (9000): "
    curl -s http://localhost:9000/health > /dev/null && echo "✓ OK" || echo "✗ DOWN"
    
    # Jupyter
    echo -n "Jupyter (8888): "
    curl -s http://localhost:8888/ > /dev/null && echo "✓ OK" || echo "✗ DOWN"
    
    # NGINX
    echo -n "NGINX (80): "
    curl -s http://localhost/health > /dev/null && echo "✓ OK" || echo "✗ DOWN"
}

# Dashboard (abre no browser)
ai-dashboard() {
    echo "🌐 Opening dashboard..."
    xdg-open http://localhost/ 2>/dev/null || open http://localhost/ 2>/dev/null
}

# GPU Usage (compose version)
alias ai-gpu-compose='watch -n 1 "nvidia-smi && echo && docker-compose -f $AI_COMPOSE_FILE ps"'

# ============================================================
# ============================================================




#    echo "📥 Downloading popular models via compose..."
#    echo "✓ Models ready!"
#}

# ============================================================
# 🎨 COMFYUI (Compose Integration)
# ============================================================

alias comfy-compose-open='xdg-open http://localhost:8188'

alias comfy-compose-logs='docker-compose -f $AI_COMPOSE_FILE logs -f comfyui'

# Download popular checkpoints
comfy-download-models() {
    echo "📥 Downloading SD models for ComfyUI..."
    docker-compose -f "$AI_COMPOSE_FILE" exec comfyui-gpu bash -c "
        cd /comfyui/models/checkpoints &&
        wget -nc https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
    "
    echo "✓ Models downloaded!"
}

# ============================================================
# 🗣️ WHISPER (Compose Integration)
# ============================================================

whisper-compose-transcribe() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-compose-transcribe <audio_file>"
        return 1
    fi
    
    echo "🎤 Transcribing: $1"
    curl -F "audio_file=@$1" http://localhost:9000/asr?task=transcribe | jq -r '.text'
}

# ============================================================
# 🎯 WORKFLOWS (Compose-Aware)
# ============================================================

# Full pipeline test
ai-test-pipeline() {
    echo "🧪 Testing full AI pipeline..."
    echo ""
    
    #curl -s http://localhost:11434/api/generate -d '{
    #  "model": "llama3.2",
    #  "prompt": "Say hello in one word",
    #  "stream": false
    #}' | jq -r '.response'
    #echo ""
    
    # 2. Test vLLM
    echo "2️⃣ Testing vLLM..."
    curl -s http://localhost:8000/health && echo "vLLM is healthy"
    echo ""
    
    # 3. Test ComfyUI
    echo "3️⃣ Testing ComfyUI..."
    curl -s http://localhost:8188/ > /dev/null && echo "ComfyUI is responding"
    echo ""
    
    # 4. Test Whisper
    echo "4️⃣ Testing Whisper..."
    curl -s http://localhost:9000/health && echo "Whisper is healthy"
    echo ""
    
    echo "✓ Pipeline test complete!"
}

# Unified workflow: Text → Image → Description
workflow-compose-full() {
    local prompt="${1:-a futuristic city at sunset}"
    
    echo "🎬 Full workflow: Text → Image → Description"
    echo "Prompt: $prompt"
    echo ""
    
    # 1. Generate image via ComfyUI API (simplified)
    echo "🎨 Step 1: Generating image..."
    echo "(Manual: Open http://localhost:8188 and generate)"
    
    # 2. Analyze with vision model
    #echo "👁️ Step 2: Would analyze with LLaVA..."
}

# ============================================================
# 🔧 MAINTENANCE & UTILITIES
# ============================================================

# Update all images
ai-update() {
    echo "🔄 Updating all container images..."
    docker-compose -f "$AI_COMPOSE_FILE" pull
    echo "✓ Images updated. Run 'ai-restart' to apply changes"
}

# Show disk usage
ai-disk() {
    echo "💾 Docker Disk Usage - AI Stack"
    echo "================================"
    echo ""
    docker system df -v | grep -A 10 "VOLUME NAME"
}

# Backup volumes
ai-backup() {
    local backup_dir="$HOME/ai-backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    echo "💾 Backing up AI volumes to: $backup_dir"
    
    docker run --rm \
        -v "$backup_dir":/backup \
    
    echo "✓ Backup complete: $backup_dir"
}

# ============================================================
# 📚 HELP & DOCUMENTATION
# ============================================================

ai-compose-help() {
    echo "🤖 AI Compose Stack - Docker Compose Edition"
    echo ""
    echo "Lifecycle:"
    echo "  ai-up              - Start all services"
    echo "  ai-up-full         - Start all + show status"
    echo "  ai-up-llm          - Start LLM services only"
    echo "  ai-up-vision       - Start ComfyUI only"
    echo "  ai-up-audio        - Start audio services"
    echo "  ai-down            - Stop all services"
    echo "  ai-down-clean      - Stop + delete volumes (⚠️  DESTRUCTIVE)"
    echo "  ai-restart         - Restart all services"
    echo "  ai-restart-service <name> - Restart specific service"
    echo ""
    echo "Monitoring:"
    echo "  ai-status          - Show container status"
    echo "  ai-health          - Quick health check"
    echo "  ai-logs            - Follow all logs"
    echo "  ai-logs-service <name> - Follow specific service logs"
    echo "  ai-dashboard       - Open web dashboard"
    echo "  ai-gpu-compose     - GPU + container monitoring"
    echo ""
    echo ""
    echo "ComfyUI (Compose):"
    echo "  comfy-compose-open           - Open in browser"
    echo "  comfy-compose-logs           - View logs"
    echo "  comfy-download-models        - Download SD checkpoints"
    echo ""
    echo "Whisper (Compose):"
    echo "  whisper-compose-transcribe <file> - Transcribe audio"
    echo ""
    echo "Workflows:"
    echo "  ai-test-pipeline             - Test all services"
    echo "  workflow-compose-full <prompt> - Full multimodal workflow"
    echo ""
    echo "Maintenance:"
    echo "  ai-update          - Update all images"
    echo "  ai-disk            - Show disk usage"
    echo "  ai-backup          - Backup volumes"
    echo ""
    echo "🎯 Quick Start:"
    echo "  1. ai-up-full          # Start everything"
    echo "  3. ai-health           # Verify all working"
    echo "  4. ai-dashboard        # Open UI"
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

export -f ai-up-minimal
export -f ai-up-full
export -f ai-up-llm
export -f ai-up-vision
export -f ai-up-audio
export -f ai-down-clean
export -f ai-restart-service
export -f ai-logs-service
export -f ai-health
export -f ai-dashboard
export -f comfy-download-models
export -f whisper-compose-transcribe
export -f ai-test-pipeline
export -f workflow-compose-full
export -f ai-update
export -f ai-disk
export -f ai-backup
export -f ai-compose-help

#echo "✓ AI Compose Stack aliases loaded! Type 'ai-compose-help' for commands"
