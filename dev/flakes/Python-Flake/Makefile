.PHONY: help init dev ml llm hack lowlevel clean test lint format setup-ollama docker-up docker-down

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║   Ultimate Dev Environment - Commands     ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

init: ## Initialize project and enable direnv
	@echo "$(BLUE)🚀 Initializing Ultimate Dev Environment...$(NC)"
	@direnv allow .
	@mkdir -p data models logs notebooks scripts
	@echo "$(GREEN)✅ Environment ready!$(NC)"

dev: ## Enter default development shell
	@echo "$(BLUE)🔧 Entering full development environment...$(NC)"
	@nix develop

ml: ## Enter ML-focused environment
	@echo "$(BLUE)🤖 Entering ML environment...$(NC)"
	@nix develop .#ml

llm: ## Enter LLM development environment with Ollama
	@echo "$(BLUE)🧠 Starting LLM environment...$(NC)"
	@nix develop .#llm

hack: ## Enter hacking/pentesting environment
	@echo "$(YELLOW)⚠️  Entering hacking environment...$(NC)"
	@echo "$(RED)Use responsibly and ethically!$(NC)"
	@nix develop .#hacking

lowlevel: ## Enter low-level development environment
	@echo "$(BLUE)⚙️  Entering low-level environment...$(NC)"
	@nix develop .#lowlevel

# Python operations
test: ## Run tests
	@nix develop -c pytest tests/ -v

lint: ## Run linters (ruff, mypy)
	@echo "$(BLUE)🔍 Running linters...$(NC)"
	@nix develop -c ruff check .
	@nix develop -c mypy src/

format: ## Format code with black and ruff
	@echo "$(BLUE)✨ Formatting code...$(NC)"
	@nix develop -c black .
	@nix develop -c ruff check --fix .

# Jupyter operations
jupyter: ## Start Jupyter Lab
	@echo "$(BLUE)📓 Starting Jupyter Lab...$(NC)"
	@nix develop -c jupyter lab --ip=0.0.0.0 --port=8888

notebook: ## Start Jupyter Notebook
	@nix develop -c jupyter notebook

# LLM operations
setup-ollama: ## Download and setup Ollama models
	@echo "$(BLUE)🧠 Setting up Ollama models...$(NC)"
	@nix develop .#llm -c bash -c "\
		ollama pull llama2 && \
		ollama pull codellama && \
		ollama pull mistral && \
		echo '$(GREEN)✅ Models downloaded!$(NC)' \
	"

ollama-serve: ## Start Ollama server
	@nix develop .#llm -c ollama serve

# Docker operations
docker-up: ## Start auxiliary services (PostgreSQL, Redis, etc)
	@echo "$(BLUE)🐳 Starting Docker services...$(NC)"
	@docker-compose up -d

docker-down: ## Stop Docker services
	@docker-compose down

docker-logs: ## Show Docker logs
	@docker-compose logs -f

# Data operations
download-datasets: ## Download common ML datasets
	@echo "$(BLUE)📦 Downloading datasets...$(NC)"
	@mkdir -p data/raw
	@nix develop .#ml -c python scripts/download_datasets.py

# Security/Hacking shortcuts
scan-ports: ## Quick port scan (requires target)
	@echo "$(YELLOW)🔍 Usage: make scan-ports TARGET=example.com$(NC)"
	@nix develop .#hacking -c nmap -sV -sC $(TARGET)

web-enum: ## Web directory enumeration (requires url)
	@echo "$(YELLOW)🌐 Usage: make web-enum URL=http://example.com$(NC)"
	@nix develop .#hacking -c gobuster dir -u $(URL) -w /usr/share/wordlists/dirb/common.txt

# Build operations
build: ## Build the project
	@nix build

check: ## Check flake
	@nix flake check

update: ## Update flake dependencies
	@nix flake update

# Reverse Engineering
disasm: ## Disassemble binary (requires BIN)
	@echo "$(BLUE)🔬 Disassembling $(BIN)...$(NC)"
	@nix develop .#lowlevel -c objdump -d -M intel $(BIN)

analyze-binary: ## Open binary in Ghidra
	@nix develop .#lowlevel -c ghidra $(BIN)

debug: ## Debug binary with GDB
	@nix develop .#lowlevel -c gdb $(BIN)

# Performance profiling
profile-cpu: ## Profile CPU usage of Python script
	@echo "$(BLUE)⚡ Profiling $(SCRIPT)...$(NC)"
	@nix develop -c python -m cProfile -o profile.stats $(SCRIPT)
	@nix develop -c python -c "import pstats; p = pstats.Stats('profile.stats'); p.sort_stats('cumulative'); p.print_stats(20)"

profile-mem: ## Profile memory usage
	@nix develop -c python -m memory_profiler $(SCRIPT)

# Cleanup
clean: ## Clean build artifacts and cache
	@echo "$(BLUE)🧹 Cleaning...$(NC)"
	@rm -rf __pycache__ .pytest_cache .mypy_cache .ruff_cache
	@rm -rf dist build *.egg-info
	@rm -rf .coverage htmlcov
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Cleaned!$(NC)"

deep-clean: clean ## Deep clean including Nix store
	@nix-collect-garbage -d

# Info
info: ## Show environment information
	@nix develop -c devenv-info

versions: ## Show versions of key tools
	@echo "$(BLUE)📊 Tool Versions:$(NC)"
	@echo "Nix:     $$(nix --version)"
	@nix develop -c python --version
	@nix develop -c gcc --version | head -n1
	@nix develop -c rustc --version 2>/dev/null || echo "Rust: not in default PATH"

# Advanced: Shell with all environments combined
super-shell: ## Enter shell with ALL tools (heavy!)
	@echo "$(RED)⚡ SUPER SHELL - All tools loaded!$(NC)"
	@nix develop --impure

# Git operations
git-hooks: ## Setup git hooks
	@echo "$(BLUE)🎣 Setting up git hooks...$(NC)"
	@echo '#!/bin/sh\nmake format && make lint' > .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "$(GREEN)✅ Pre-commit hook installed$(NC)"

# Documentation
docs: ## Generate documentation
	@echo "$(BLUE)📚 Generating documentation...$(NC)"
	@nix develop -c pdoc --html --output-dir docs src/

# Benchmarking
benchmark: ## Run benchmarks
	@nix develop -c python -m pytest benchmarks/ --benchmark-only

# MLOps
train-model: ## Train a model (example)
	@echo "$(BLUE)🏋️  Training model...$(NC)"
	@nix develop .#ml -c python scripts/train.py

evaluate-model: ## Evaluate trained model
	@nix develop .#ml -c python scripts/evaluate.py

# Quick hacks
quick-server: ## Start a quick HTTP server
	@nix develop -c python -m http.server 8000

quick-tunnel: ## Expose local server (requires ngrok in PATH)
	@echo "$(BLUE)🌐 Creating tunnel to localhost:8000$(NC)"
	@ngrok http 8000

# Monitoring
monitor-gpu: ## Monitor GPU usage (NVIDIA)
	@watch -n 0.5 nvidia-smi

monitor-system: ## Monitor system resources
	@nix develop -c btop

# AI Assistant integration
ask-claude: ## Ask Claude for coding help (requires API key)
	@echo "$(BLUE)🤖 Ask me anything!$(NC)"
	@nix develop -c python scripts/ask_claude.py

# Default target
.DEFAULT_GOAL := help
