#!/bin/bash
# ============================================================
# GPU Docker Aliases - NixOS Edition
# ============================================================
alias docker-check='docker exec jupyter-gpu python3 -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:',
      torch.cuda.is_available()); print('CUDA device count:', torch.cuda.device_count()); print('Current CUDA device:', torch.cuda.current_device() if
      torch.cuda.is_available() else 'N/A'); print('CUDA device name:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A');
      print('cuDNN version:', torch.backends.cudnn.version() if torch.cuda.is_available() else 'N/A')"'

alias docker-gpu='import torch
   from transformers import AutoTokenizer, AutoModelForCausalLM
   import warnings
   warnings.filterwarnings('ignore')

   print("=" * 60)
   print("Testing LLM Inference Workflow")
   print("=" * 60)

   # Check CUDA
   print(f"\n1. GPU Setup:")
   print(f"   CUDA Available: {torch.cuda.is_available()}")
   print(f"   Device: {torch.cuda.get_device_name(0)}")
   print(f"   Memory Available: {torch.cuda.get_device_properties(0).total_memory /
   1024**3:.2f} GB")

   # Test loading a small model (GPT-2 as example)
   print(f"\n2. Loading Model (GPT-2 small for testing)...")
   try:
       tokenizer = AutoTokenizer.from_pretrained("gpt2")
       model = AutoModelForCausalLM.from_pretrained("gpt2")
       model = model.to("cuda")
       print(f"   ✓ Model loaded successfully on GPU")

       # Test inference
       print(f"\n3. Running Inference Test...")
       input_text = "The future of AI is"
       inputs = tokenizer(input_text, return_tensors="pt").to("cuda")

       with torch.no_grad():
           outputs = model.generate(
               **inputs,
               max_new_tokens=20,
               temperature=0.7,
               do_sample=True
           )

       result = tokenizer.decode(outputs[0], skip_special_tokens=True)
       print(f"   Input: '{input_text}'")
       print(f"   Output: '{result}'")
       print(f"   ✓ Inference completed successfully!")

       # Clean up
       del model
       torch.cuda.empty_cache()

       print(f"\n4. Environment Check:")
       print(f"   ✓ PyTorch: {torch.__version__}")
       import transformers
       print(f"   ✓ Transformers: {transformers.__version__}")
       import accelerate
       print(f"   ✓ Accelerate: {accelerate.__version__}")
       import diffusers
       print(f"   ✓ Diffusers: {diffusers.__version__}")

       print(f"\n" + "=" * 60)
       print("✓ ALL TESTS PASSED - Environment is 100% functional!")
       print("=" * 60)

   except Exception as e:
       print(f"   ✗ Error: {str(e)}")
       import traceback
       traceback.print_exc()'
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

# ============================================================
# ⚡ GPU TEST SUITE
# ============================================================

alias gpu-test='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python /workspace/gpu_stress_test.py'

alias gpu-quick='docker run --rm \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  python -c "import torch; print(f\"CUDA: {torch.cuda.is_available()}\"); print(f\"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}\")"'

# ============================================================
# 📊 GPU MONITORING
# ============================================================

alias gpu-watch='watch -n 0.5 nvidia-smi'

alias gpu-stat='nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total --format=csv,noheader'

alias gpu-monitor='while true; do clear; nvidia-smi; sleep 1; done'

alias gpu-ps='nvidia-smi pmon -c 1'

# ============================================================
# 🔧 GPU TROUBLESHOOTING
# ============================================================

alias gpu-check='lsmod | grep nvidia && echo "✓ NVIDIA drivers loaded" || echo "✗ NVIDIA drivers NOT loaded"'

alias gpu-info='nvidia-smi -L && nvidia-smi -q | grep -A 10 "Product Name\|Driver Version\|CUDA Version"'

alias gpu-clean='sudo fuser -v /dev/nvidia* 2>/dev/null | awk "{print \$2}" | xargs -r sudo kill -9'

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
# 🚀 ADVANCED/INTERACTIVE
# ============================================================

alias gpu-jupyter='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  -p 8888:8888 \
  --name jupyter-gpu \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token="" --NotebookApp.password=""'

alias gpu-jupyter-debug='docker run --rm -it \
  --device=nvidia.com/gpu=all \
  -v $(pwd):/workspace \
  -p 8888:8888 \
  --name jupyter-gpu-debug \
  nvcr.io/nvidia/pytorch:25.09-py3 \
  bash -c "echo \"Starting Jupyter on 0.0.0.0:8888...\" && jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --debug"'

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

gpu-bench() {
    local size=${1:-4096}
    echo "Running matmul benchmark with size $size..."
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

# A function to run a Docker container with NVIDIA GPU and PyTorch settings.
drun-cuda() {
  docker run --rm -it \
    --device=nvidia.com/gpu=all \
    --ipc=host \
    --ulimit stack=1 \
    --ulimit stack=67108864 \
    --shm-size=8g \
    "$@"
}


gpu-help() {
    echo "🚀 GPU Docker Aliases:"
    echo ""
    echo "Basic:"
    echo "  gpu-shell      - Interactive shell with GPU"
    echo "  gpu-dev        - Named container for debugging"
    echo "  gpu-net        - Container with host network"
    echo ""
    echo "Testing:"
    echo "  gpu-test       - Run full test suite"
    echo "  gpu-quick      - Quick CUDA availability check"
    echo "  gpu-matmul     - Simple matmul test"
    echo ""
    echo "Monitoring:"
    echo "  gpu-watch      - Watch nvidia-smi (0.5s refresh)"
    echo "  gpu-stat       - Compact GPU stats"
    echo "  gpu-monitor    - Continuous monitoring"
    echo "  gpu-ps         - GPU processes"
    echo ""
    echo "Utils:"
    echo "  gpu-check      - Check NVIDIA drivers"
    echo "  gpu-info       - Detailed GPU info"
    echo "  gpu-clean      - Kill GPU processes (sudo)"
    echo "  gpu-python     - Interactive Python with GPU"
    echo "  gpu-bash       - Bash shell in container"
    echo "  gpu-jupyter    - Start Jupyter Lab (port 8888)"
    echo ""
    echo "Functions:"
    echo "  gpu-run <file> - Run Python script with GPU"
    echo "  gpu-bench [N]  - Benchmark matmul (default 4096)"
    echo "  gpu-help       - Show this help"
}

# Export functions
export -f gpu-run
export -f gpu-bench
export -f gpu-help

#echo "✓ GPU aliases loaded!"
