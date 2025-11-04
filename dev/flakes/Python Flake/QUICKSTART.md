# 🚀 QUICKSTART - Ultimate Dev Environment

**5 minutos do zero ao desenvolvimento completo.**

## 🎯 Instalação Zero-to-Hero

### 1. Setup Inicial (< 2min)

```bash
# Se ainda não tem Nix, instale:
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone/crie o projeto
mkdir ultimate-dev && cd ultimate-dev

# Copie os arquivos do flake
# ... (flake.nix, README.md, etc)

# OPCIONAL: Valide o ambiente
python scripts/setup_env.py --auto-fix

# Enable direnv (opcional mas recomendado)
direnv allow .
```

### 2. Entre no Ambiente (< 1min)

```bash
# Ambiente completo (TUDO)
nix develop

# OU escolha um especializado:
nix develop .#ml       # Machine Learning
nix develop .#llm      # LLMs (Ollama auto-start)
nix develop .#hacking  # Pentesting
nix develop .#lowlevel # C/Assembly/RE
```

### 3. Primeiro Teste (< 1min)

```bash
# Dentro do ambiente
devenv-info              # Ver o que está disponível
python --version         # Python 3.11
gcc --version           # GCC latest
ollama --help           # LLM tools

# Quick ML test
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

### 4. Workflows Integrados (< 1min)

```bash
# Com Makefile (recomendado)
make help               # Ver todos os comandos
make ml                 # Entrar ambiente ML
make jupyter            # Start Jupyter Lab
make docker-up          # Start todos os serviços

# Ou direto:
jupyter lab             # Notebooks
ollama run llama2       # Chat com LLM local
nmap -sV target.com     # Security scan
```

## 💎 Workflows Principais

### 🤖 Machine Learning

```bash
# Setup
make ml
make download-datasets  # Baixar datasets comuns

# Desenvolvimento
jupyter lab            # Start Jupyter
python scripts/download_datasets.py --list

# Com PyTorch
python <<EOF
import torch
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(784, 128),
    nn.ReLU(),
    nn.Linear(128, 10)
)
print(f"Model: {model}")
print(f"CUDA available: {torch.cuda.is_available()}")
EOF

# MLOps (com Docker)
make docker-up         # Start MLflow + PostgreSQL + MinIO
# Acesse: http://localhost:5000 (MLflow)
```

### 🧠 LLM Development

```bash
# Setup
make llm               # Ollama auto-start

# Download modelos
ollama pull llama2
ollama pull codellama
ollama pull mistral

# Usar modelos
ollama run llama2 "Explain quantum computing"
ollama run codellama "Write a FastAPI endpoint"

# Com Python + Claude API
export ANTHROPIC_API_KEY="your-key"
python scripts/ask_claude.py --mode chat --prompt "Help me debug this"

# RAG (Retrieval Augmented Generation)
python scripts/ask_claude.py --mode add-knowledge --file docs/manual.txt
python scripts/ask_claude.py --mode chat --rag --prompt "What does the manual say about X?"

# Análise de código
python scripts/ask_claude.py --mode analyze --file mycode.py
```

### 🎯 Hacking / Pentesting

```bash
# Setup
make hack              # Enter hacking environment

# Reconnaissance
nmap -sV -sC target.com
rustscan -a target.com

# Web enumeration
gobuster dir -u http://target.com -w /usr/share/wordlists/dirb/common.txt
ffuf -u http://target.com/FUZZ -w wordlist.txt

# Exploitation
msfconsole              # Metasploit
python scripts/ask_claude.py --mode exploit --prompt "buffer overflow in strcpy"

# Network analysis
wireshark               # Packet capture
tcpdump -i eth0 -w capture.pcap

# Password cracking
john --wordlist=rockyou.txt hashes.txt
hashcat -m 0 -a 0 hashes.txt wordlist.txt
```

### ⚙️ Low-Level / Reverse Engineering

```bash
# Setup
make lowlevel

# Análise automática
python scripts/analyze_binary.py /path/to/binary

# Análise manual
r2 -A binary          # Radare2
# Comandos r2:
# aaa               # Analyze all
# pdf @ main        # Disassemble main
# VV                # Visual mode (graph)
# /R                # ROP gadgets

# Ghidra
ghidra binary

# GDB com pwndbg
gdb binary
# break main
# run
# disass

# Criar CFG (Control Flow Graph)
python scripts/analyze_binary.py --cfg main binary

# Extrair ROP gadgets
python scripts/analyze_binary.py --gadgets binary

# Valgrind (memory leaks)
valgrind --leak-check=full ./programa
```

## 🔥 Workflows Avançados

### 1. ML Pipeline Completo

```bash
# 1. Setup infra
make docker-up         # PostgreSQL, MinIO, MLflow, Grafana

# 2. Download datasets
python scripts/download_datasets.py --download cifar10 mnist

# 3. Treinar modelo
python <<EOF
import torch
import torch.nn as nn
import mlflow

mlflow.set_tracking_uri("http://localhost:5000")

with mlflow.start_run():
    model = nn.Sequential(nn.Linear(784, 128), nn.ReLU(), nn.Linear(128, 10))
    mlflow.log_param("layers", 2)
    mlflow.log_param("hidden_size", 128)
    # Seu código de treinamento aqui
EOF

# 4. Visualizar métricas
# MLflow: http://localhost:5000
# Grafana: http://localhost:3000 (admin/admin)
```

### 2. LLM + RAG Application

```bash
# 1. Preparar knowledge base
mkdir -p data/docs
# Adicione seus documentos em data/docs/

# 2. Indexar documentos
python <<EOF
from scripts.ask_claude import LLMOrchestrator
import os

orchestrator = LLMOrchestrator()

for doc in os.listdir('data/docs'):
    with open(f'data/docs/{doc}') as f:
        content = f.read()
        orchestrator.add_to_knowledge_base(content, {"source": doc})

print("Knowledge base pronta!")
EOF

# 3. Query com RAG
python scripts/ask_claude.py --mode chat --rag --prompt "Explique X baseado nos documentos"
```

### 3. Security Assessment Automatizado

```bash
# 1. Recon automatizado
TARGET="example.com"

# Port scan
nmap -sV -sC -oN scan_$TARGET.txt $TARGET

# Web scan
nikto -h http://$TARGET -o nikto_$TARGET.txt
gobuster dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -o gobuster_$TARGET.txt

# 2. Análise com AI
python scripts/ask_claude.py --mode chat --prompt "Analyze these scan results and suggest attack vectors" --file scan_$TARGET.txt

# 3. Generate exploit
python scripts/ask_claude.py --mode exploit --prompt "SQL injection in login form"
```

### 4. Binary Analysis + AI

```bash
# 1. Análise automática
python scripts/analyze_binary.py malware.exe

# 2. Disassembly específica
python scripts/analyze_binary.py --function main malware.exe > main_disasm.txt

# 3. Análise com AI
python scripts/ask_claude.py --mode asm --file main_disasm.txt --arch x86_64

# 4. Gerar CFG
python scripts/analyze_binary.py --cfg main malware.exe
# Abre main_cfg.png
```

## 🐳 Docker Services

```bash
# Start todos os serviços
make docker-up

# Serviços disponíveis:
# - PostgreSQL:     localhost:5432 (devuser/devpass)
# - Redis:          localhost:6379
# - MinIO (S3):     localhost:9000 (minioadmin/minioadmin)
# - MLflow:         http://localhost:5000
# - Jupyter:        http://localhost:8888
# - Grafana:        http://localhost:3000 (admin/admin)
# - Elasticsearch:  localhost:9200
# - Kibana:         http://localhost:5601
# - RabbitMQ:       http://localhost:15672 (admin/admin)
# - VS Code Server: http://localhost:8080 (password: devpassword)
# - Portainer:      https://localhost:9443

# Ver logs
make docker-logs

# Parar tudo
make docker-down
```

## 📊 Profiling & Debugging

```bash
# Python profiling
make profile-cpu SCRIPT=train.py
make profile-mem SCRIPT=train.py

# C/C++ profiling
valgrind --tool=callgrind ./programa
kcachegrind callgrind.out.*

# GPU monitoring
make monitor-gpu       # watch nvidia-smi

# System monitoring
make monitor-system    # btop
```

## 🎨 Tips & Tricks

### Aliases Úteis (já incluídos)
```bash
py          # Python
ipy         # IPython
jup         # Jupyter
r2          # Radare2
ghidra      # Ghidra
scan        # nmap -sV -sC
dirscan     # gobuster dir
```

### Hotkeys do Makefile
```bash
make ml              # ML environment
make llm             # LLM environment
make hack            # Hacking environment
make lowlevel        # Low-level environment
make jupyter         # Start Jupyter Lab
make test            # Run tests
make format          # Format code
make clean           # Clean artifacts
```

### Git Integration
```bash
# Setup hooks
make git-hooks       # Auto-format & lint on commit
```

## 🔧 Troubleshooting

### Problema: "command not found"
```bash
# Certifique-se que está no ambiente Nix
nix develop

# Ou use direnv
direnv allow .
```

### Problema: Ollama não inicia
```bash
# Manual start
ollama serve &

# Check process
ps aux | grep ollama

# Kill e restart
pkill ollama
make llm
```

### Problema: CUDA not available
```bash
# Check NVIDIA drivers
nvidia-smi

# No NixOS, adicione em configuration.nix:
services.xserver.videoDrivers = [ "nvidia" ];

# Rebuild
sudo nixos-rebuild switch
```

### Problema: Docker permisson denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout e login novamente
```

### Validação completa
```bash
python scripts/setup_env.py --auto-fix --report
```

## 🚀 Next Steps

1. **Customize o flake.nix** para suas necessidades
2. **Adicione seus próprios scripts** em `scripts/`
3. **Configure CI/CD** com Nix
4. **Share seu setup** com o time

## 📚 Recursos

- **Documentação completa**: README.md
- **Makefile commands**: `make help`
- **Nix manual**: https://nixos.org/manual/nix/stable/
- **Tool docs**: Cada tool tem `--help`

---

**🎉 Pronto para desenvolver!**

*"The best way to predict the future is to invent it." - Alan Kay*
