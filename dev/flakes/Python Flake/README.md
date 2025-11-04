# 🚀 Ultimate Dev Environment - Nix Flake

Ambiente de desenvolvimento definitivo para Python, ML, LLM, Low-Level, Hacking e mais.

## ⚡ Quick Start

```bash
# Clone ou crie o diretório
mkdir ultimate-dev && cd ultimate-dev

# Copie o flake.nix para este diretório

# Entre no ambiente completo
nix develop

# Ou escolha um ambiente especializado:
nix develop .#ml        # Machine Learning
nix develop .#llm       # LLM Development  
nix develop .#hacking   # Pentesting/Security
nix develop .#lowlevel  # C/C++/Assembly/Reverse Engineering
```

## 🎯 Ambientes Disponíveis

### 1. **Default** - Tudo Incluído
```bash
nix develop
```

**Inclui:**
- Python 3.11 com 60+ pacotes
- Ferramentas de ML (PyTorch, TensorFlow, JAX)
- Ferramentas de LLM (Ollama, llama.cpp, Transformers)
- Tools de hacking (nmap, metasploit, burpsuite, etc)
- Compiladores e debuggers (GCC, Clang, GDB, Radare2, Ghidra)
- Dev tools (git, neovim, tmux, docker, etc)

### 2. **ML/AI** - Machine Learning Focado
```bash
nix develop .#ml
```

**Otimizado para:**
- Deep Learning (PyTorch, TensorFlow, JAX)
- NLP & Transformers
- Data Science (Pandas, NumPy, Scikit-learn)
- Jupyter Notebooks
- TensorBoard

### 3. **LLM** - Large Language Models
```bash
nix develop .#llm
```

**Features:**
- Ollama (auto-start)
- llama.cpp para inferência rápida
- Transformers & LangChain
- Tokenizers & Datasets
- APIs (OpenAI, Anthropic)
- Vector DBs (ChromaDB, FAISS)

**Exemplo de uso:**
```bash
# Dentro do ambiente
ollama pull llama2
ollama run llama2 "Explain quantum computing"
```

### 4. **Hacking** - Pentesting & Security
```bash
nix develop .#hacking
```

**Tools incluídas:**
- 🔍 Recon: nmap, masscan, rustscan
- 🌐 Web: burpsuite, sqlmap, nikto, gobuster
- 🔐 Cracking: john, hashcat, hydra
- 📡 Network: wireshark, tcpdump, scapy
- 🎯 Exploitation: metasploit, exploitdb

**⚠️ AVISO:** Use apenas para fins éticos e autorizados!

### 5. **Low-Level** - System Programming
```bash
nix develop .#lowlevel
```

**Includes:**
- 🛠️ Compilers: GCC, Clang, LLVM
- 🐛 Debuggers: GDB, LLDB, Valgrind
- 🔬 Analysis: strace, ltrace, perf
- 🔓 Reverse: Radare2, Ghidra, Binary Ninja
- ⚙️ Build: CMake, Meson, Ninja

## 🎨 Aliases & Shortcuts

Cada ambiente inclui aliases úteis:

**Default:**
```bash
py            # Python
ipy           # IPython
jup           # Jupyter
r2            # Radare2
ghidra        # Ghidra
```

**Hacking:**
```bash
scan <target>           # nmap -sV -sC
dirscan <url>          # gobuster dir
vulnscan <target>      # nikto
```

**Low-Level:**
```bash
compile-debug <file>    # gcc -g -O0 -Wall
compile-release <file>  # gcc -O3 -march=native
check-mem <program>    # valgrind --leak-check=full
disasm <binary>        # objdump -d -M intel
```

## 🔥 Scripts Customizados

### `devenv-info`
Mostra informações sobre o ambiente atual.

### `python-ml`
Inicia Python com todas as libs de ML carregadas.

### `llm-chat`
Inicia Ollama e ambiente para testar LLMs locais.

## 📦 Python Packages Incluídos

### Core & Utils
- pip, virtualenv, setuptools, wheel
- rich, click, typer, pydantic

### Data Science
- numpy, pandas, scipy, matplotlib, seaborn, plotly
- jupyter, ipython, notebook

### Machine Learning
- scikit-learn, xgboost, lightgbm

### Deep Learning
- torch, torchvision, torchaudio
- tensorflow, keras
- jax, jaxlib

### NLP & LLM
- transformers, tokenizers, datasets
- langchain, openai, anthropic
- sentencepiece, tiktoken

### Vector Databases
- chromadb, faiss, pinecone-client, weaviate-client

### Hacking & Security
- pwntools, pycryptodome, scapy
- requests, beautifulsoup4, scrapy, selenium

### Performance
- cython, numba, cffi, pybind11

### Web & Async
- aiohttp, httpx, fastapi, flask
- asyncio, websockets

### Testing & Quality
- pytest, black, ruff, mypy, pylint

## 🚀 Exemplos de Uso

### ML - Treinar um modelo
```python
import torch
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(784, 128),
    nn.ReLU(),
    nn.Linear(128, 10)
)

# CUDA disponível se você tiver GPU NVIDIA
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)
```

### LLM - Usar Transformers
```python
from transformers import pipeline

generator = pipeline('text-generation', model='gpt2')
result = generator("The future of AI is", max_length=50)
print(result)
```

### Hacking - Port Scan
```bash
# Scan rápido
nmap -T4 -F target.com

# Scan completo com scripts
nmap -sV -sC -O -p- target.com -oN full_scan.txt

# Web enumeration
gobuster dir -u http://target.com -w /usr/share/wordlists/dirb/common.txt
```

### Low-Level - Análise de Binary
```bash
# Disassembly
r2 -A binary
# Dentro do radare2:
# pdf @ main  # disassembly da função main
# VV          # visual mode (graph)

# Ou com Ghidra
ghidra
```

## 🔧 Personalização

### Adicionar mais pacotes Python

Edite o `pythonEnv` no flake.nix:

```nix
pythonEnv = pkgs.python311.withPackages (ps: with ps; [
  # ... pacotes existentes ...
  seu-novo-pacote
]);
```

### Adicionar novas ferramentas

```nix
devShells.default = pkgs.mkShell {
  buildInputs = [
    pythonEnv
    pkgs.sua-nova-ferramenta
  ] ++ llmTools ++ ...;
};
```

### Criar novo shell especializado

```nix
devShells.blockchain = pkgs.mkShell {
  buildInputs = with pkgs; [
    go-ethereum
    solc
    hardhat
  ];
  
  shellHook = ''
    echo "⛓️ Blockchain Dev Environment"
  '';
};
```

## 🎯 Performance Tips

### CUDA para ML/DL
Se você tem GPU NVIDIA, o flake já configura:
- `CUDA_PATH`
- `EXTRA_LDFLAGS`  
- `EXTRA_CCFLAGS`

### Memory Profiling
```bash
# Python
python -m memory_profiler script.py

# C/C++
valgrind --tool=massif ./programa
ms_print massif.out.*
```

### GPU Monitoring
```bash
# Durante treinamento de modelos
watch -n 0.5 nvidia-smi
```

## 🐛 Troubleshooting

### Ollama não inicia?
```bash
# Manual start
ollama serve

# Check logs
tail -f /tmp/ollama.log
```

### CUDA not found?
```bash
# Verifique se está instalado
echo $CUDA_PATH

# Install NVIDIA drivers no NixOS
# configuration.nix:
services.xserver.videoDrivers = [ "nvidia" ];
```

### Build falhou?
```bash
# Limpar cache
nix flake update
nix develop --refresh

# Rebuild
nix develop --impure
```

## 📚 Recursos Adicionais

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Flakes Wiki](https://nixos.wiki/wiki/Flakes)
- [Poetry2nix](https://github.com/nix-community/poetry2nix)
- [Anthropic Claude Docs](https://docs.claude.com)
- [PyTorch Docs](https://pytorch.org/docs/)
- [HackTheBox](https://www.hackthebox.com) - Para prática ética

## 🤝 Contribuindo

Fork, customize e compartilhe suas melhorias!

## ⚖️ Licença

MIT - Use com responsabilidade

## 🙏 Créditos

Construído com:
- Nix Flakes
- Python 3.11
- As melhores ferramentas open-source

---

**Made with ❤️ for hackers, researchers, and developers**

*"The best way to predict the future is to invent it." - Alan Kay*
