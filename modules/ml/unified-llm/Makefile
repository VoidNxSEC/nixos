.PHONY: help build test clean install run docker nix lint format check-security

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)SecureLLM Bridge - Build Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

build: ## Build the project in debug mode
	@echo "$(BLUE)Building project...$(NC)"
	cargo build --all

release: ## Build the project in release mode with optimizations
	@echo "$(BLUE)Building release version...$(NC)"
	cargo build --release --all
	@echo "$(GREEN)✓ Binary available at: target/release/securellm$(NC)"

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	cargo test --all

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests (verbose)...$(NC)"
	cargo test --all -- --nocapture

check: ## Quick check if code compiles
	@echo "$(BLUE)Checking compilation...$(NC)"
	cargo check --all

clippy: ## Run clippy linter
	@echo "$(BLUE)Running clippy...$(NC)"
	cargo clippy --all-targets --all-features -- -D warnings

format: ## Format code with rustfmt
	@echo "$(BLUE)Formatting code...$(NC)"
	cargo fmt --all

format-check: ## Check if code is formatted
	@echo "$(BLUE)Checking code format...$(NC)"
	cargo fmt --all -- --check

lint: clippy format-check ## Run all linters

audit: ## Check for security vulnerabilities in dependencies
	@echo "$(BLUE)Auditing dependencies...$(NC)"
	cargo audit

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	cargo clean
	rm -rf target/

install: release ## Install the CLI binary
	@echo "$(BLUE)Installing securellm CLI...$(NC)"
	cargo install --path crates/cli --force
	@echo "$(GREEN)✓ Installed! Run: securellm --help$(NC)"

run: ## Run the CLI (development mode)
	@echo "$(BLUE)Running securellm...$(NC)"
	cargo run --bin securellm -- --help

run-chat: ## Run a test chat command (requires API key)
	@echo "$(BLUE)Running test chat...$(NC)"
	@if [ -z "$$SECURELLM_API_KEY" ]; then \
		echo "$(YELLOW)⚠  SECURELLM_API_KEY not set$(NC)"; \
		exit 1; \
	fi
	cargo run --bin securellm -- chat \
		--provider deepseek \
		--model deepseek-chat \
		"Hello, how are you?"

# Docker targets
docker: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t securellm:latest .
	@echo "$(GREEN)✓ Image built: securellm:latest$(NC)"

docker-alpine: ## Build minimal Alpine-based Docker image
	@echo "$(BLUE)Building Alpine Docker image...$(NC)"
	docker build -f containers/Dockerfile.alpine -t securellm:alpine .
	@echo "$(GREEN)✓ Image built: securellm:alpine$(NC)"

docker-run: docker ## Build and run Docker container
	@echo "$(BLUE)Running Docker container...$(NC)"
	docker run --rm securellm:latest --help

docker-compose-up: ## Start services with docker-compose
	@echo "$(BLUE)Starting services with docker-compose...$(NC)"
	cd containers && docker-compose up -d

docker-compose-down: ## Stop docker-compose services
	@echo "$(BLUE)Stopping services...$(NC)"
	cd containers && docker-compose down

# Nix targets
nix-build: ## Build with Nix
	@echo "$(BLUE)Building with Nix...$(NC)"
	nix build

nix-run: ## Run with Nix
	@echo "$(BLUE)Running with Nix...$(NC)"
	nix run

nix-develop: ## Enter Nix development shell
	@echo "$(BLUE)Entering Nix development environment...$(NC)"
	nix develop

nix-flake-update: ## Update Nix flake inputs
	@echo "$(BLUE)Updating Nix flake...$(NC)"
	nix flake update

# Development helpers
watch: ## Watch for changes and rebuild
	@echo "$(BLUE)Watching for changes...$(NC)"
	cargo watch -x build

watch-test: ## Watch for changes and run tests
	@echo "$(BLUE)Watching for changes (tests)...$(NC)"
	cargo watch -x test

dev: ## Start development environment with watch
	@echo "$(BLUE)Starting development environment...$(NC)"
	cargo watch -x 'check --all' -x 'test --all' -x 'clippy --all-targets'

# Documentation
doc: ## Generate and open documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	cargo doc --all --no-deps --open

doc-private: ## Generate documentation including private items
	@echo "$(BLUE)Generating documentation (with private items)...$(NC)"
	cargo doc --all --no-deps --document-private-items --open

# Examples
example-deepseek: ## Run DeepSeek example (requires API key)
	@echo "$(BLUE)Running DeepSeek example...$(NC)"
	@if [ -z "$$SECURELLM_API_KEY" ]; then \
		echo "$(YELLOW)⚠  Set SECURELLM_API_KEY environment variable$(NC)"; \
		exit 1; \
	fi
	cargo run --example rust_api_example

example-config: ## Show example configuration
	@echo "$(BLUE)Example configuration:$(NC)"
	@cat examples/config.toml

# Benchmarking
bench: ## Run benchmarks
	@echo "$(BLUE)Running benchmarks...$(NC)"
	cargo bench --all

# Security
check-security: audit ## Run security checks
	@echo "$(BLUE)Running security checks...$(NC)"
	@echo "$(YELLOW)TODO: Add cargo-deny, cargo-geiger$(NC)"

# CI/CD
ci: format-check clippy test ## Run all CI checks
	@echo "$(GREEN)✓ All CI checks passed$(NC)"

# Information
info: ## Show project information
	@echo "$(BLUE)SecureLLM Bridge$(NC)"
	@echo "Version: 0.1.0"
	@echo "Rust version: $$(rustc --version)"
	@echo "Cargo version: $$(cargo --version)"
	@echo ""
	@echo "Crates:"
	@echo "  - securellm-core      (core abstractions)"
	@echo "  - securellm-security  (security primitives)"
	@echo "  - securellm-providers (LLM provider adapters)"
	@echo "  - securellm-cli       (command-line interface)"
	@echo "  - securellm-desktop   (desktop app - WIP)"
	@echo "  - securellm-proxy     (proxy server - WIP)"

deps: ## Show dependency tree
	@echo "$(BLUE)Dependency tree:$(NC)"
	cargo tree --all

outdated: ## Check for outdated dependencies
	@echo "$(BLUE)Checking for outdated dependencies...$(NC)"
	cargo outdated

# Setup helpers
setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@echo "Installing required tools..."
	@command -v cargo-watch >/dev/null 2>&1 || cargo install cargo-watch
	@command -v cargo-audit >/dev/null 2>&1 || cargo install cargo-audit
	@command -v cargo-outdated >/dev/null 2>&1 || cargo install cargo-outdated
	@echo "$(GREEN)✓ Setup complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Set your API key: export SECURELLM_API_KEY='your-key'"
	@echo "  2. Build the project: make build"
	@echo "  3. Run tests: make test"
	@echo "  4. Try the CLI: make run-chat"

all: format lint test build ## Run format, lint, test, and build
	@echo "$(GREEN)✓ All tasks completed successfully!$(NC)"
