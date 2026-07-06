#!/bin/bash
# ============================================================
# GPU Docker Core Aliases - NixOS Edition
# Baseado no exemplo 1 (golden standard)
# ============================================================

# ============================================================
# 🐳 DOCKER GPU BASE COMMANDS
# ============================================================

alias gpu-shell='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3'

alias gpu-dev='docker run --rm -it \
  --name gpu-playground \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3'

alias gpu-net='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  --network host \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3'

# Versão com shm-size aumentado (pra datasets grandes)
alias gpu-bigmem='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  --shm-size=8g \
  --ipc=host \
  --ulimit stack=67108864 \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3'

# ============================================================
# ⚡ GPU TEST SUITE
# ============================================================

alias gpu-quick='docker run --rm \
  --device=nvidia.com/gpu=all \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python -c "import torch; print(f\"CUDA: {torch.cuda.is_available()}\"); print(f\"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}\")"'

alias gpu-stress='docker run --rm \
  --device=nvidia.com/gpu=all \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python -c "import torch; a=torch.randn(10000,10000).cuda(); b=torch.randn(10000,10000).cuda(); print(\"Stressing GPU...\"); [torch.matmul(a,b) for _ in range(100)]; print(\"✓ Stress test complete\")"'

# ============================================================
# 📊 GPU MONITORING
# ============================================================

alias gpu-watch='watch -n 0.5 nvidia-smi'

alias gpu-stat='nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total --format=csv,noheader'

alias gpu-monitor='while true; do clear; nvidia-smi; sleep 1; done'

alias gpu-ps='nvidia-smi pmon -c 1'

alias gpu-temp='nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits'

# ============================================================
# 🔧 GPU TROUBLESHOOTING
# ============================================================

alias gpu-check='lsmod | grep nvidia && echo "✓ NVIDIA drivers loaded" || echo "✗ NVIDIA drivers NOT loaded"'

alias gpu-info='nvidia-smi -L && nvidia-smi -q | grep -A 10 "Product Name\|Driver Version\|CUDA Version"'

alias gpu-clean='sudo fuser -v /dev/nvidia* 2>/dev/null | awk "{print \$2}" | xargs -r sudo kill -9'

alias gpu-reset='sudo rmmod nvidia_uvm && sudo modprobe nvidia_uvm'

# ============================================================
# 🐍 PYTHON/PYTORCH QUICK TESTS
# ============================================================

alias torch-version='docker run --rm \
  --device=nvidia.com/gpu=all \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python -c "import torch; print(f\"PyTorch: {torch.__version__}\"); print(f\"CUDA: {torch.version.cuda}\")"'

alias gpu-matmul='docker run --rm \
  --device=nvidia.com/gpu=all \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python -c "import torch; a=torch.randn(1000,1000).cuda(); b=torch.randn(1000,1000).cuda(); c=torch.matmul(a,b); print(\"✓ Matmul OK\")"'

# ============================================================
# 🚀 INTERACTIVE ENVIRONMENTS
# ============================================================

alias gpu-jupyter='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  --ipc=host \
  --ulimit stack=67108864 \
  --shm-size=8g \
  -v $(pwd):/workspace \
  -p 8888:8888 \
  --name jupyter-gpu \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token="" --NotebookApp.password=""'

alias gpu-jupyter-token='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  -p 8888:8888 \
  --name jupyter-gpu-secure \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser'

alias gpu-python='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python'

alias gpu-bash='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  /bin/bash'

alias gpu-ipython='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  ipython'

# ============================================================
# 🎯 FUNCTIONS
# ============================================================

gpu-run() {
    if [ -z "$1" ]; then
        echo "Usage: gpu-run <script.py>"
        return 1
    fi
    docker run --rm -it \
        --device=nvidia.com/gpu=all \
        -v $(pwd):/workspace \
        nvcr.io/nvidia/pytorch:25.09-py3 \
        python "/workspace/$1"
}

gpu-exec() {
    if [ -z "$1" ]; then
        echo "Usage: gpu-exec <python_command>"
        return 1
    fi
    docker run --rm \
        --device=nvidia.com/gpu=all \
        -v $(pwd):/workspace \
        nvcr.io/nvidia/pytorch:25.09-py3 \
        python -c "$1"
}

gpu-bench() {
    local size=${1:-4096}
    echo "🔥 Running matmul benchmark with size $size..."
    docker run --rm \
        --device=nvidia.com/gpu=all \
        nvcr.io/nvidia/pytorch:25.09-py3 \
        python -c "
	import torch
	import time
	size = $size
	a = torch.randn(size, size).cuda()
	b = torch.randn(size, size).cuda()
	torch.cuda.synchronize()
	start = time.time()
	c = torch.matmul(a, b)
	torch.cuda.synchronize()
	elapsed = time.time() - start
	gflops = (2 * size**3 / elapsed) / 1e9
	print(f'Matrix {size}x{size}: {elapsed*1000:.2f}ms - {gflops:.2f} GFLOPS')
	"
}

gpu-mem() {
    echo "📊 GPU Memory Usage:"
    nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv
}

# Função híbrida multi-modal
drun-cuda() {
    docker run --rm -it \
        --device=nvidia.com/gpu=all \
        --ipc=host \
        --ulimit stack=67108864 \
        --shm-size=8g \
        "$@"
}

gpu-help() {
    echo "🚀 GPU Docker Aliases - Core Commands"
    echo ""
    echo "Basic:"
    echo "  gpu-shell         - Interactive shell with GPU"
    echo "  gpu-dev           - Named container for debugging"
    echo "  gpu-net           - Container with host network"
    echo "  gpu-bigmem        - Container with 8GB shared memory"
    echo ""
    echo "Testing:"
    echo "  gpu-quick         - Quick CUDA availability check"
    echo "  gpu-stress        - GPU stress test"
    echo "  gpu-matmul        - Simple matmul test"
    echo ""
    echo "Monitoring:"
    echo "  gpu-watch         - Watch nvidia-smi (0.5s refresh)"
    echo "  gpu-stat          - Compact GPU stats"
    echo "  gpu-monitor       - Continuous monitoring"
    echo "  gpu-ps            - GPU processes"
    echo "  gpu-temp          - Just temperature"
    echo "  gpu-mem           - Memory usage summary"
    echo ""
    echo "Troubleshooting:"
    echo "  gpu-check         - Check NVIDIA drivers"
    echo "  gpu-info          - Detailed GPU info"
    echo "  gpu-clean         - Kill GPU processes (sudo)"
    echo "  gpu-reset         - Reset NVIDIA UVM module"
    echo ""
    echo "Interactive:"
    echo "  gpu-python        - Interactive Python with GPU"
    echo "  gpu-ipython       - IPython with GPU"
    echo "  gpu-bash          - Bash shell in container"
    echo "  gpu-jupyter       - Jupyter Lab (port 8888, no token)"
    echo "  gpu-jupyter-token - Jupyter Lab (port 8888, with token)"
    echo ""
    echo "Functions:"
    echo "  gpu-run <file>       - Run Python script with GPU"
    echo "  gpu-exec \"<code>\"    - Execute Python code string"
    echo "  gpu-bench [N]        - Benchmark matmul (default 4096)"
    echo "  gpu-mem              - Show GPU memory usage"
    echo "  drun-cuda <args>     - Custom docker run with GPU+optimizations"
    echo "  gpu-help             - Show this help"
    echo ""
    echo "Versions:"
    echo "  torch-version     - Show PyTorch and CUDA versions"
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

export -f gpu-run
export -f gpu-exec
export -f gpu-bench
export -f gpu-mem
export -f drun-cuda
export -f gpu-help

#echo "✓ GPU Core aliases loaded! Type 'gpu-help' for commands"
