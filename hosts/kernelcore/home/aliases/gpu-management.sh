#!/usr/bin/env bash
# GPU Management Aliases

# GPU mode switching
alias gpu-local='gpu-mode-local'
alias gpu-docker='gpu-mode-docker'
alias gpu='gpu-status'

# Quick GPU info
alias gpu-mem='nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk -F, "{printf \"Used: %d MiB / %d MiB (%.1f%%)\\n\", \$1, \$2, (\$1/\$2)*100}"'
alias gpu-procs='nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader'
alias gpu-temp='nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | awk "{print \$1 \"°C\"}"'

# Service management
alias llama-start='sudo systemctl start llamacpp.service'
alias llama-stop='sudo systemctl stop llamacpp.service'
alias llama-status='systemctl status llamacpp.service --no-pager'
alias llama-logs='journalctl -u llamacpp.service -f'


# Docker GPU containers
alias gpu-containers='docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "gpu-api|jupyter|koboldcpp|comfyui"'
alias gpu-api-logs='docker logs gpu-api -f'
alias jupyter-logs='docker logs jupyter-gpu -f'
alias kobold-logs='docker logs koboldcpp -f'

# Quick access to services
alias llama='curl http://127.0.0.1:8080/health 2>/dev/null && echo "LlamaCPP is running on http://127.0.0.1:8080" || echo "LlamaCPP is not running"'

# GPU resource report
alias gpu-report='echo "=== GPU Resource Report ===" && echo "" && nvidia-smi && echo "" && echo "=== Running Services ===" && gpu-status'
