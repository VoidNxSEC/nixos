# Next Session Prompt - Phase 2 Unified LLM Platform

**Status**: Week 1 - Day 1 Complete ✅
**Next**: Week 1 - Day 2-4 (Security-Architect Migration)
**Date**: 2025-11-06
**Last Updated**: 2025-11-06 07:57 UTC

---

## 🚀 Quick Start - Copy This Prompt

```
Continue Phase 2 implementation of the Unified LLM Platform.

CURRENT STATUS (Week 1 Day 1 ✅):
├── Foundation: Cargo workspace with 7 crates initialized
├── Core crate: 700+ lines (provider traits, types, errors)
├── Planning: 3,000+ lines of documentation complete
└── Commit: 61170ca "feat: initialize unified-llm workspace foundation"

NEXT TASKS (Week 1 Day 2-4 - Security-Architect Migration):

Step 1: Pre-flight Verification
- Verify Security-Architect source exists
- Check current workspace state
- Confirm Git status clean

Step 2: Migrate Security Crate
- Copy crates/security from Security-Architect
- Update Cargo.toml dependencies
- Fix imports (securellm_core → unified_llm_core)
- Verify compilation

Step 3: Migrate Providers Crate
- Copy crates/providers (DeepSeek ✅, OpenAI, Anthropic)
- Update dependencies and imports
- Verify compilation

Step 4: Integration Testing
- Run cargo check --all
- Run cargo test --all (if tests exist)
- Fix any compilation errors
- Document migration notes

Step 5: Commit Progress
- Stage changes
- Commit with descriptive message
- Update this prompt for Day 5-7

PROJECT STRUCTURE:
├── Source: /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/
├── Destination: /etc/nixos/modules/ml/unified-llm/
└── Docs: /etc/nixos/docs/PHASE2-*.md

REFERENCE DOCUMENTS:
├── docs/PHASE2-UNIFIED-ARCHITECTURE.md (1,179 lines)
├── docs/PHASE2-IMPLEMENTATION-ROADMAP.md (626 lines)
└── docs/NEXT-SESSION-PROMPT.md (this file)

Execute in CODE mode. Begin with Step 1.
```

---

## 📅 Complete 8-Week Roadmap

### Week 1: Foundation & Security-Architect Migration (Days 1-10)
```
Day 1 ✅ COMPLETE
├── Created Cargo workspace
├── Implemented core crate (700+ lines)
└── Wrote planning docs (3,000+ lines)

Day 2-4 ⏳ NEXT - Security-Architect Migration
├── Migrate crates/security (TLS, audit, rate limiting)
├── Migrate crates/providers (cloud APIs)
└── Verify compilation

Day 5-7 - ML Offload Migration
├── Copy ML Offload API backends
├── Create crates/local with VRAM intelligence
└── Integrate SQLite registry

Day 8-10 - Router Crate Implementation
├── Create crates/router with routing strategies
├── Implement fallback chain logic
├── Add cost optimization
└── Verify end-to-end compilation
```

### Week 2: API & Integration (Days 11-20)
```
Day 11-13 - API Crate Implementation
├── Create crates/api with Axum
├── Implement REST endpoints (/v1/chat/completions)
├── Add WebSocket support
└── Wire router + security + providers

Day 14-16 - CLI Crate Migration
├── Migrate CLI from Security-Architect
├── Add local model commands
├── Update to use unified API
└── Test all commands

Day 17-20 - Basic Integration Tests
├── Cloud provider tests (DeepSeek)
├── Local backend tests (mock)
├── Fallback scenario tests
└── Fix integration issues
```

### Week 3: MCP Server Unification (Days 21-30)
```
Day 21-23 - MCP Server Setup
├── Merge Security-Architect + mlx-mcp TypeScript
├── Unified package.json
├── Create base server structure
└── Test MCP protocol

Day 24-26 - Tool Implementation
├── Inference tools (chat, complete, embed)
├── Model management tools
├── Security tools (audit, logs)
└── Monitoring tools (VRAM, health)

Day 27-30 - Caching & Optimization
├── Implement smart caching from mlx-mcp
├── Add summarization for token economy
├── Rate limiting integration
└── Performance optimization
```

### Week 4: Testing Foundation (Days 31-40)
```
Day 31-33 - Unit Tests
├── Core crate tests (90% coverage)
├── Security crate tests (95% coverage)
├── Providers tests (85% coverage)
└── Local crate tests (90% coverage)

Day 34-36 - Router & API Tests
├── Router crate tests (95% coverage)
├── API endpoint tests
├── WebSocket tests
└── CLI command tests

Day 37-40 - Integration Tests
├── End-to-end scenarios
├── Cloud → Local fallback
├── Model loading/unloading
└── VRAM auto-scaling
```

### Week 5: Advanced Testing (Days 41-50)
```
Day 41-43 - Security Testing
├── TLS configuration tests
├── Rate limiting tests
├── Audit logging verification
├── Input sanitization tests
└── Security audit tool

Day 44-46 - Performance Testing
├── Latency benchmarks (p50, p95, p99)
├── VRAM utilization tests
├── Concurrent user tests (100+)
└── Throughput tests (1000+ req/min)

Day 47-50 - Load Testing & Bug Fixes
├── Sustained load (1 hour)
├── Spike tests (traffic burst)
├── Fix all critical bugs
└── Address performance issues
```

### Week 6: Documentation (Days 51-60)
```
Day 51-53 - API Documentation
├── REST API reference (OpenAPI/Swagger)
├── MCP tools reference
├── Configuration guide
└── Security best practices

Day 54-56 - User Guides
├── Getting started guide
├── Deployment guide (Docker, NixOS, K8s)
├── Migration guide
└── Troubleshooting guide

Day 57-60 - Developer Documentation
├── Architecture overview
├── Code structure documentation
├── Contributing guide
└── Testing guide
```

### Week 7: NixOS Integration (Days 61-70)
```
Day 61-63 - NixOS Module Creation
├── Create modules/ml/unified-llm/default.nix
├── Configure systemd services
├── Set up SOPS secrets management
└── Configure firewall rules

Day 64-66 - Docker Deployment
├── Create optimized Dockerfile
├── docker-compose.yml with all services
├── Test container deployment
└── Push to registry

Day 67-70 - Testing & Validation
├── Test on clean NixOS system
├── Verify all services running
├── Test failover scenarios
└── Load testing in production config
```

### Week 8: Launch & Handoff (Days 71-80)
```
Day 71-73 - Pre-Launch Preparation
├── Final security audit
├── Performance optimization
├── Documentation review
└── Create runbooks

Day 74-76 - Training & Knowledge Transfer
├── User training session
├── Admin training session
├── Document operational procedures
└── Create incident response plan

Day 77-78 - Production Deployment
├── Deploy to production environment
├── Configure monitoring & alerting
├── Smoke tests
└── Gradual rollout

Day 79-80 - Launch & Stabilization
├── Monitor for issues
├── Collect user feedback
├── Hot-fix critical issues
└── Plan Phase 3 features
```

---

## 📖 Context Reference

### What Was Completed (Week 1 Day 1)

#### Planning Documentation (2,032+ lines)
1. **[PHASE2-UNIFIED-ARCHITECTURE.md](PHASE2-UNIFIED-ARCHITECTURE.md)** (1,424 lines)
   - Complete technical design
   - Component hierarchy and data flows
   - Unified traits, API endpoints, database schema
   - Security integration strategy

2. **[PHASE2-IMPLEMENTATION-ROADMAP.md](PHASE2-IMPLEMENTATION-ROADMAP.md)** (608 lines)
   - 8-week implementation plan
   - Week-by-week task breakdown (56 days)
   - Success metrics and KPIs
   - Risk management

#### Infrastructure Created
```
/etc/nixos/modules/ml/unified-llm/
├── Cargo.toml              # Workspace configuration
├── Cargo.lock              # Dependency lock
├── crates/
│   ├── core/              # ✅ COMPLETE (700+ lines)
│   │   ├── src/error.rs       (138 lines - Error handling)
│   │   ├── src/provider.rs    (148 lines - Provider trait)
│   │   ├── src/models.rs      (176 lines - Model info)
│   │   ├── src/request.rs     (236 lines - Request types)
│   │   └── src/response.rs    (202 lines - Response types)
│   │
│   ├── security/          # ⏳ Ready for migration
│   ├── providers/         # ⏳ Ready for migration
│   ├── local/             # ⏳ Ready for migration
│   ├── router/            # ⏳ Ready for migration
│   ├── api/               # ⏳ Ready for migration
│   └── cli/               # ⏳ Ready for migration
```

#### Git Commits
- `3e4b655` - Phase 2 planning documentation
- `021dc83` - Test report updates
- `61170ca` - Unified-LLM workspace foundation (Week 1 Day 1) ✅ **CURRENT**

All pushed to `origin/main`

---

## 🎯 Week 1 Schedule

### Day 1 ✅ COMPLETE
- [x] Create unified directory structure
- [x] Initialize Cargo workspace
- [x] Implement core crate with provider traits
- [x] Write comprehensive planning docs
- [x] Commit and push to GitHub

### Day 2-4 ⏳ NEXT
**Goal**: Migrate Security-Architect code

**Tasks**:
1. Copy `crates/security/` from Security-Architect
   ```bash
   cp -r /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/security/src/* \
         modules/ml/unified-llm/crates/security/src/
   ```

2. Copy `crates/providers/` from Security-Architect
   ```bash
   cp -r /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/providers/src/* \
         modules/ml/unified-llm/crates/providers/src/
   ```

3. Update Cargo.toml for each crate:
   - Add necessary dependencies
   - Update paths to `unified-llm-core`

4. Fix imports:
   ```bash
   # Change securellm_core to unified_llm_core
   find modules/ml/unified-llm/crates -name "*.rs" -type f \
        -exec sed -i 's/securellm_core/unified_llm_core/g' {} \;
   ```

5. Verify compilation:
   ```bash
   cd modules/ml/unified-llm
   cargo check --package unified-llm-security
   cargo check --package unified-llm-providers
   ```

6. Commit progress:
   ```bash
   git add modules/ml/unified-llm/crates/{security,providers}
   git commit -m "feat: migrate Security-Architect crates (Week 1 Day 2-4)"
   git push origin main
   ```

### Day 5-7 ⏳ UPCOMING
**Goal**: Migrate ML Offload code

### Day 8-10 ⏳ UPCOMING
**Goal**: Create unified flake.nix

---

## 📚 Key Files to Reference

### Planning & Architecture
- [`docs/PHASE2-UNIFIED-ARCHITECTURE.md`](PHASE2-UNIFIED-ARCHITECTURE.md) - Technical design
- [`docs/PHASE2-IMPLEMENTATION-ROADMAP.md`](PHASE2-IMPLEMENTATION-ROADMAP.md) - 8-week plan
- [`docs/ml-offload-phase2-design.md`](ml-offload-phase2-design.md) - VRAM intelligence

### Source Projects
- Security-Architect: `/home/kernelcore/Downloads/ClaudeSkills/Security-Architect/`
  - CLAUDE.md (806 lines) - Comprehensive documentation
  - crates/security/ - TLS, audit, rate limiting
  - crates/providers/ - DeepSeek ✅, OpenAI, Anthropic
  
- mlx-mcp: `/home/kernelcore/dev/mlx-mcp/`
  - README.md (347 lines) - MCP server guide
  - src/ - TypeScript MCP server with caching
  
- ML Offload: `/etc/nixos/modules/ml/offload/`
  - api/src/ - Rust REST API
  - api/src/backends/ - llama.cpp, Ollama drivers

### Current Workspace
- Root: `/etc/nixos/modules/ml/unified-llm/`
- Core crate: `modules/ml/unified-llm/crates/core/`
- Workspace config: `modules/ml/unified-llm/Cargo.toml`

---

## 🔧 Useful Commands

### Development
```bash
# Navigate to workspace
cd /etc/nixos/modules/ml/unified-llm

# Check all crates
cargo check --all

# Check specific crate
cargo check --package unified-llm-core

# Run tests
cargo test --package unified-llm-core

# Format code
cargo fmt --all

# Lint
cargo clippy --all
```

### Git Workflow
```bash
# Check status
git status

# Stage changes
git add modules/ml/unified-llm

# Commit with conventional commits
git commit -m "feat: <description>"
git commit -m "fix: <description>"
git commit -m "docs: <description>"

# Push to remote
git push origin main
```

### File Operations
```bash
# Copy with progress
rsync -av --progress source/ destination/

# Search in files
rg "pattern" path/

# List files
ls -la modules/ml/unified-llm/crates/
```

---

## ⚠️ Important Notes

### Build Environment
- **Requires Nix environment** for proper linking
- Run `nix develop` before `cargo` commands if needed
- Linker errors outside Nix are expected

### Code Style
- Use `cargo fmt` before committing
- Address `cargo clippy` warnings
- Write tests for new functionality
- Document public APIs

### Commit Strategy
- Commit frequently (each logical unit of work)
- Use conventional commit messages
- Push to remote after each Day's work
- Update NEXT-SESSION-PROMPT.md for continuity

---

## 🎯 Success Criteria for Day 2-4

By end of Day 2-4, you should have:

- [x] Security crate migrated and compiling
- [x] Providers crate migrated (DeepSeek, OpenAI, Anthropic)
- [x] All imports updated to `unified-llm-core`
- [x] `cargo check --all` passes
- [x] Changes committed and pushed to GitHub
- [x] Documentation updated if needed

---

## 💡 Tips for Next Session

1. **Start with Security Crate**: It's smaller and has fewer dependencies
2. **Update Cargo.toml First**: Get dependencies right before fixing code
3. **Fix Imports Systematically**: Use sed or search/replace
4. **Compile Incrementally**: Fix errors one file at a time
5. **Commit Often**: Don't wait until everything works
6. **Reference Core Crate**: Use it as a template for structure

## 🔍 Detailed Step-by-Step Instructions

### Phase 2 Week 1 Day 2-4: Security-Architect Migration

#### Pre-Flight Checklist (5 minutes)

```bash
# 1. Verify Security-Architect source exists
ls -la /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/
# Expected: security/ providers/ core/ cli/ desktop/

# 2. Check workspace state
cd /etc/nixos/modules/ml/unified-llm
cargo check --package unified-llm-core
# Expected: "Finished" with no errors

# 3. Git status (should be clean)
cd /etc/nixos
git status
git log --oneline -3
# Expected: 61170ca as latest commit
```

#### Task 1: Migrate Security Crate (2-3 hours)

**Files to migrate:**
- `src/lib.rs` - Module exports
- `src/tls.rs` - TLS mutual authentication (~300 lines)
- `src/rate_limit.rs` - Token bucket rate limiting (~200 lines)
- `src/audit.rs` - Structured audit logging (~250 lines)
- `src/crypto.rs` - AES-256-GCM encryption (~150 lines)
- `src/sanitizer.rs` - Input sanitization (~100 lines)

**Step 1.1: Copy security source files**
```bash
cd /etc/nixos

# Create src directory if not exists
mkdir -p modules/ml/unified-llm/crates/security/src

# Copy all security source files
cp -r /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/security/src/* \
      modules/ml/unified-llm/crates/security/src/

# Verify files copied
ls -la modules/ml/unified-llm/crates/security/src/
# Expected: lib.rs, tls.rs, rate_limit.rs, audit.rs, crypto.rs, sanitizer.rs
```

**Step 1.2: Update security Cargo.toml**
```bash
# First, check what dependencies Security-Architect uses
cat /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/security/Cargo.toml

# Then update our Cargo.toml with those dependencies
# Edit: modules/ml/unified-llm/crates/security/Cargo.toml
```

Key dependencies to add (check exact versions from source):
```toml
[dependencies]
unified-llm-core = { path = "../core" }
tokio = { version = "1", features = ["full"] }
tracing = "0.1"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
ring = "0.17"  # For crypto
rustls = "0.21"  # For TLS
tokio-rustls = "0.24"
async-trait = "0.1"
thiserror = "1.0"
```

**Step 1.3: Fix imports**
```bash
cd modules/ml/unified-llm/crates/security

# Replace all securellm_core with unified_llm_core
find src -name "*.rs" -type f -exec sed -i 's/securellm_core/unified_llm_core/g' {} \;
find src -name "*.rs" -type f -exec sed -i 's/use securellm/use unified_llm/g' {} \;
find src -name "*.rs" -type f -exec sed -i 's/crate::securellm/crate::unified_llm/g' {} \;

# Verify changes
rg "securellm" src/
# Expected: No matches found
```

**Step 1.4: Verify compilation**
```bash
cd /etc/nixos/modules/ml/unified-llm
cargo check --package unified-llm-security 2>&1 | tee /tmp/security-check.log

# If errors, fix them iteratively:
# - Missing types: Check if they exist in unified-llm-core
# - Missing functions: Implement or import from core
# - Dependency issues: Add to Cargo.toml
```

**Common issues and fixes:**
1. **Missing Error type**: Use `unified_llm_core::Error`
2. **Missing Request/Response types**: Import from `unified_llm_core::request/response`
3. **Linker errors**: Run inside `nix develop` shell

#### Task 2: Migrate Providers Crate (2-3 hours)

**Files to migrate:**
- `src/lib.rs` - Module exports
- `src/deepseek.rs` - DeepSeek API client (~400 lines) ✅
- `src/openai.rs` - OpenAI API client (~350 lines)
- `src/anthropic.rs` - Anthropic API client (~350 lines)
- `src/ollama.rs` - Ollama integration (~200 lines)

**Step 2.1: Copy providers source files**
```bash
cd /etc/nixos

# Create src directory
mkdir -p modules/ml/unified-llm/crates/providers/src

# Copy all providers source files
cp -r /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/providers/src/* \
      modules/ml/unified-llm/crates/providers/src/

# Verify
ls -la modules/ml/unified-llm/crates/providers/src/
# Expected: lib.rs, deepseek.rs, openai.rs, anthropic.rs, ollama.rs
```

**Step 2.2: Update providers Cargo.toml**
```bash
# Check source dependencies
cat /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/providers/Cargo.toml

# Update: modules/ml/unified-llm/crates/providers/Cargo.toml
```

Key dependencies:
```toml
[dependencies]
unified-llm-core = { path = "../core" }
unified-llm-security = { path = "../security" }
reqwest = { version = "0.11", features = ["json", "rustls-tls"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tracing = "0.1"
async-trait = "0.1"
thiserror = "1.0"
url = "2.4"
```

**Step 2.3: Fix imports**
```bash
cd modules/ml/unified-llm/crates/providers

# Replace all securellm references
find src -name "*.rs" -type f -exec sed -i 's/securellm_core/unified_llm_core/g' {} \;
find src -name "*.rs" -type f -exec sed -i 's/securellm_security/unified_llm_security/g' {} \;
find src -name "*.rs" -type f -exec sed -i 's/use securellm/use unified_llm/g' {} \;

# Verify
rg "securellm" src/
# Expected: No matches
```

**Step 2.4: Verify compilation**
```bash
cd /etc/nixos/modules/ml/unified-llm
cargo check --package unified-llm-providers 2>&1 | tee /tmp/providers-check.log

# Fix any errors iteratively
```

#### Task 3: Integration Verification (1 hour)

**Step 3.1: Check all crates compile**
```bash
cd /etc/nixos/modules/ml/unified-llm

# Check each crate individually first
echo "Checking core..."
cargo check --package unified-llm-core

echo "Checking security..."
cargo check --package unified-llm-security

echo "Checking providers..."
cargo check --package unified-llm-providers

# Check entire workspace
echo "Checking all..."
cargo check --all
```

**Step 3.2: Run tests (if any exist)**
```bash
# Check if tests exist in source
ls -la /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/security/tests/ 2>/dev/null
ls -la /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/crates/providers/tests/ 2>/dev/null

# If tests exist, copy and run them
cargo test --package unified-llm-security
cargo test --package unified-llm-providers
```

**Step 3.3: Format and lint**
```bash
# Format all code
cargo fmt --all

# Run clippy (optional, may have warnings)
cargo clippy --all -- -W clippy::all
```

**Step 3.4: Document migration notes**
Create a migration log:
```bash
cat > modules/ml/unified-llm/MIGRATION-LOG.md << 'EOF'
# Migration Log - Week 1 Day 2-4

## Date: $(date -I)

### Migrated Components

#### Security Crate
- [x] Copied from Security-Architect/crates/security
- [x] Updated imports (securellm_* → unified_llm_*)
- [x] Updated Cargo.toml dependencies
- [x] Compilation successful
- Files: tls.rs, rate_limit.rs, audit.rs, crypto.rs, sanitizer.rs, lib.rs

#### Providers Crate
- [x] Copied from Security-Architect/crates/providers  
- [x] Updated imports
- [x] Updated Cargo.toml dependencies
- [x] Compilation successful
- Files: deepseek.rs, openai.rs, anthropic.rs, ollama.rs, lib.rs

### Issues Encountered
(Document any issues and solutions here)

### Next Steps
- Week 1 Day 5-7: Migrate ML Offload code to crates/local
- Week 1 Day 8-10: Implement crates/router

EOF
```

#### Task 4: Commit Progress (15 minutes)

```bash
cd /etc/nixos

# Stage changes
git add modules/ml/unified-llm/crates/security/
git add modules/ml/unified-llm/crates/providers/
git add modules/ml/unified-llm/MIGRATION-LOG.md

# Check what's staged
git diff --cached --stat
git diff --cached modules/ml/unified-llm/crates/security/Cargo.toml
git diff --cached modules/ml/unified-llm/crates/providers/Cargo.toml

# Commit with descriptive message
git commit -m "feat: migrate Security-Architect crates to unified-llm (Week 1 Day 2-4)

Migrate security and providers crates from Security-Architect project:

Security crate:
- TLS mutual authentication (tls.rs)
- Token bucket rate limiting (rate_limit.rs)
- Structured audit logging (audit.rs)
- AES-256-GCM encryption (crypto.rs)
- Input sanitization (sanitizer.rs)

---

## 🔍 Week 3 Day 21-30: MCP Server Unification (DETAILED GUIDE)

### Phase Overview

Merge two TypeScript MCP servers into one unified server:
1. **Security-Architect MCP** (`/home/kernelcore/Downloads/ClaudeSkills/Security-Architect/mcp-server/`)
   - Security tools (audit, logs, config validation)
   - Basic inference tools
   
2. **mlx-mcp** (`/home/kernelcore/dev/mlx-mcp/`)
   - Model management tools (list, load, unload, switch)
   - Smart caching with TTL
   - Token economy via summarization
   - VRAM monitoring

### Task 1: Analyze Existing MCP Servers (Day 21 - 2 hours)

**Step 1.1: Inventory Security-Architect MCP Server**
```bash
cd /home/kernelcore/Downloads/ClaudeSkills/Security-Architect/mcp-server

# List structure
ls -la
# Expected: package.json, tsconfig.json, src/

# Check tools
cat src/index.ts | grep "server.tool" -A 3

# Check dependencies
cat package.json | jq '.dependencies'
```

**Step 1.2: Inventory mlx-mcp Server**
```bash
cd /home/kernelcore/dev/mlx-mcp

# List structure
ls -la src/
# Expected: index.ts, cache.ts, summarizer.ts, tools/

# Check tools
cat src/index.ts | grep "server.tool" -A 3

# Check caching implementation
cat src/cache.ts | head -50

# Check summarization
cat src/summarizer.ts | head -50

# Check dependencies
cat package.json | jq '.dependencies'
```

**Step 1.3: Create comparison matrix**
```bash
cat > /tmp/mcp-comparison.md << 'EOF'
# MCP Server Comparison

## Security-Architect MCP
Tools:
- [ ] List (exact tool names from code)

Dependencies:
- [ ] List from package.json

## mlx-mcp
Tools:
- list_models
- get_model_info
- load_model
- unload_model
- switch_model
- get_vram_status
- trigger_model_scan

Dependencies:
- @modelcontextprotocol/sdk: ^1.0.4
- axios: ^1.6.0
- (others from package.json)

Features:
- Smart caching (5min models, 10s VRAM)
- Token economy via summarization
- Rate limiting
EOF

# Fill in Security-Architect details
```

### Task 2: Create Unified MCP Server Structure (Day 21-22 - 3 hours)

**Step 2.1: Create unified directory**
```bash
cd /etc/nixos/modules/ml/unified-llm

# Create MCP server structure
mkdir -p mcp-server/{src/tools,build}

# Copy base structure from mlx-mcp (it's more complete)
cp /home/kernelcore/dev/mlx-mcp/package.json mcp-server/
cp /home/kernelcore/dev/mlx-mcp/tsconfig.json mcp-server/
cp /home/kernelcore/dev/mlx-mcp/.gitignore mcp-server/ 2>/dev/null || true
```

**Step 2.2: Merge package.json**
```bash
cd /etc/nixos/modules/ml/unified-llm/mcp-server

# Edit package.json - update name and combine dependencies
cat > package.json << 'EOF'
{
  "name": "unified-llm-mcp",
  "version": "1.0.0",
  "description": "Unified MCP server for LLM orchestration with security",
  "main": "build/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "watch": "tsc --watch",
    "start": "node build/index.js",
    "dev": "tsc --watch & node --watch build/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "axios": "^1.6.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
```

**Step 2.3: Create tsconfig.json**
```bash
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022"],
    "moduleResolution": "node",
    "rootDir": "./src",
    "outDir": "./build",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "build"]
}
EOF
```

### Task 3: Merge MCP Server Code (Day 22-23 - 4 hours)

**Step 3.1: Copy utility modules from mlx-mcp**
```bash
cd /etc/nixos/modules/ml/unified-llm/mcp-server/src

# Copy cache.ts (smart caching)
cp /home/kernelcore/dev/mlx-mcp/src/cache.ts .

# Copy summarizer.ts (token economy)
cp /home/kernelcore/dev/mlx-mcp/src/summarizer.ts .

# Verify
ls -la
# Expected: cache.ts, summarizer.ts
```

**Step 3.2: Create tool modules**
```bash
mkdir -p tools

# Create inference tools (new - combines both servers)
cat > tools/inference.ts << 'EOF'
import { z } from 'zod';

export const chatTool = {
  name: 'chat',
  description: 'Send chat message to LLM with auto-routing',
  inputSchema: z.object({
    message: z.string().describe('The message to send'),
    provider: z.string().optional().describe('Force specific provider'),
    model: z.string().optional().describe('Model to use'),
    strategy: z.enum(['local-first', 'cloud-first', 'cost-optimized']).optional()
  })
};

export const completeTool = {
  name: 'complete',
  description: 'Text completion',
  inputSchema: z.object({
    prompt: z.string().describe('The prompt to complete'),
    provider: z.string().optional(),
    max_tokens: z.number().optional()
  })
};

export const embedTool = {
  name: 'embed',
  description: 'Generate embeddings',
  inputSchema: z.object({
    input: z.string().describe('Text to embed'),
    model: z.string().optional()
  })
};
EOF

# Create model tools (from mlx-mcp)
cp /home/kernelcore/dev/mlx-mcp/src/tools/models.ts tools/ 2>/dev/null || \
cat > tools/models.ts << 'EOF'
// Model management tools from mlx-mcp
import { z } from 'zod';

export const listModelsTool = {
  name: 'list_models',
  description: 'List available models (cloud + local)',
  inputSchema: z.object({
    provider_type: z.enum(['cloud', 'local', 'all']).optional(),
    backend: z.string().optional(),
    format: z.string().optional()
  })
};

// Add other model tools: get_model_info, load_model, unload_model, switch_model
EOF

# Create monitoring tools
cat > tools/monitoring.ts << 'EOF'
import { z } from 'zod';

export const getVramStatusTool = {
  name: 'get_vram_status',
  description: 'Real-time GPU VRAM status',
  inputSchema: z.object({})
};

export const getProviderHealthTool = {
  name: 'get_provider_health',
  description: 'Check all provider health',
  inputSchema: z.object({})
};

export const getSystemStatusTool = {
  name: 'get_system_status',
  description: 'Complete system status',
  inputSchema: z.object({})
};
EOF

# Create security tools (from Security-Architect)
cat > tools/security.ts << 'EOF'
import { z } from 'zod';

export const runSecurityAuditTool = {
  name: 'run_security_audit',
  description: 'Execute security audit',
  inputSchema: z.object({
    scope: z.enum(['config', 'providers', 'full']).optional()
  })
};

export const getAuditLogsTool = {
  name: 'get_audit_logs',
  description: 'Retrieve audit logs',
  inputSchema: z.object({
    since: z.string().optional(),
    provider: z.string().optional(),
    limit: z.number().optional()
  })
};

export const validateConfigTool = {
  name: 'validate_config',
  description: 'Validate configuration',
  inputSchema: z.object({})
};
EOF
```

**Step 3.3: Create main server (index.ts)**
```bash
cat > src/index.ts << 'EOF'
#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import axios from 'axios';
import { Cache } from './cache.js';
import { Summarizer } from './summarizer.js';

// Import tools
import * as inference from './tools/inference.js';
import * as models from './tools/models.js';
import * as monitoring from './tools/monitoring.js';
import * as security from './tools/security.js';

const API_BASE_URL = process.env.UNIFIED_LLM_API || 'http://localhost:9000';

// Initialize caching
const cache = new Cache({
  models: { ttl: 300, maxSize: 100 },
  vram: { ttl: 10, maxSize: 1 },
  health: { ttl: 60, maxSize: 10 },
  audit: { ttl: 0, maxSize: 0 }  // No caching for security-sensitive
});

// Initialize summarizer
const summarizer = new Summarizer();

// Create server
const server = new Server(
  {
    name: 'unified-llm-mcp',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Register all tools
server.tool(inference.chatTool.name, inference.chatTool.description, inference.chatTool.inputSchema, async (args) => {
  // Implementation
});

// ... register other tools

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
EOF
```

### Task 4: Install Dependencies and Build (Day 23 - 1 hour)

```bash
cd /etc/nixos/modules/ml/unified-llm/mcp-server

# Install dependencies
npm install

# Build
npm run build

# Verify build
ls -la build/
# Expected: index.js and other compiled files
```

### Task 5: Test MCP Server (Day 24 - 2 hours)

**Step 5.1: Test locally**
```bash
# Start server
npm start

# In another terminal, test with MCP inspector
# Or test individual tools
```

**Step 5.2: Test with Claude Desktop**
```bash
# Update Claude Desktop config
cat ~/.config/Claude/claude_desktop_config.json

# Add unified-llm-mcp server
# Test tools from Claude Desktop
```

### Task 6: Integration with Rust API (Day 25-26 - 3 hours)

Ensure MCP server can communicate with the Rust API:

```bash
# Test API endpoints the MCP server will call
curl http://localhost:9000/health
curl http://localhost:9000/v1/models
curl http://localhost:9000/health/vram
```

### Task 7: Documentation (Day 27 - 2 hours)

```bash
cat > mcp-server/README.md << 'EOF'
# Unified LLM MCP Server

Combined MCP server providing:
- Inference tools (chat, complete, embed)
- Model management (list, load, unload, switch)  
- Monitoring (VRAM, health)
- Security (audit, logs, validation)

## Features

- Smart caching (5min models, 10s VRAM)
- Token economy via summarization
- Rate limiting integration
- Unified API backend

## Installation

\`\`\`bash
npm install
npm run build
\`\`\`

## Usage

\`\`\`bash
npm start
\`\`\`

## Configuration

Set environment variables:
- `UNIFIED_LLM_API` - API base URL (default: http://localhost:9000)

## Available Tools

### Inference
- `chat` - Send chat message with auto-routing
- `complete` - Text completion
- `embed` - Generate embeddings

### Model Management
- `list_models` - List all models
- `get_model_info` - Model details
- `load_model` - Load local model
- `unload_model` - Unload model
- `switch_model` - Hot-swap models

### Monitoring
- `get_vram_status` - VRAM status
- `get_provider_health` - Provider health
- `get_system_status` - System status

### Security
- `run_security_audit` - Security audit
- `get_audit_logs` - Audit logs
- `validate_config` - Config validation
EOF
```

### Task 8: Commit MCP Server (Day 27 - 15 min)

```bash
cd /etc/nixos

git add modules/ml/unified-llm/mcp-server/
git commit -m "feat: create unified MCP server (Week 3 Day 21-27)

Merge Security-Architect MCP and mlx-mcp into unified server:

Features:
- Inference tools (chat, complete, embed)
- Model management (list, load, unload, switch)
- Monitoring (VRAM, health, system)
- Security (audit, logs, validation)
- Smart caching from mlx-mcp (5min models, 10s VRAM)
- Token economy via summarization
- Rate limiting integration

Structure:
- src/index.ts - Main server
- src/cache.ts - Smart caching
- src/summarizer.ts - Token economy
- src/tools/ - Tool implementations
- package.json - Dependencies
- tsconfig.json - TypeScript config

Integration:
- Connects to Rust API at localhost:9000
- Compatible with Claude Desktop
- Supports all MCP protocol features

Related: #phase2-unification
Status: Week 3 Day 21-27 complete ✅"

git push origin main
```

### Success Criteria for Week 3

- [ ] MCP server structure created in `mcp-server/`
- [ ] All tool categories implemented (inference, models, monitoring, security)
- [ ] Smart caching from mlx-mcp integrated
- [ ] Summarization for token economy working
- [ ] npm install && npm run build succeeds
- [ ] Server starts without errors
- [ ] Can communicate with Rust API
- [ ] Documentation complete
- [ ] Changes committed and pushed

### Time Estimates for Week 3

- Day 21: Analysis (2 hours)
- Day 22-23: Code migration (7 hours)
- Day 24: Testing (2 hours)
- Day 25-26: API integration (3 hours)
- Day 27: Documentation & commit (2.25 hours)

**Total: 16.25 hours**


Providers crate:
- DeepSeek API client (deepseek.rs) ✅ functional
- OpenAI API client (openai.rs)
- Anthropic API client (anthropic.rs)  
- Ollama integration (ollama.rs)

Changes:
- Updated all imports from securellm_* to unified_llm_*
- Updated Cargo.toml dependencies for both crates
- Verified compilation: cargo check --all passes
- Added MIGRATION-LOG.md for tracking

Next: Week 1 Day 5-7 - Migrate ML Offload code to crates/local

Related: #phase2-unification
Status: Week 1 Day 2-4 complete ✅"

# Push to remote
git push origin main

# Verify push
git log --oneline -1
```

#### Task 5: Update This Prompt for Day 5-7 (10 minutes)

Update [`docs/NEXT-SESSION-PROMPT.md`](NEXT-SESSION-PROMPT.md):

```markdown
**Status**: Week 1 - Day 2-4 Complete ✅  
**Next**: Week 1 - Day 5-7 (ML Offload Migration)
**Date**: [Update with current date]

## 🚀 Quick Start - Copy This Prompt

Continue Phase 2 implementation of the Unified LLM Platform.

CURRENT STATUS (Week 1 Day 2-4 ✅):
├── Security crate migrated and compiling
├── Providers crate migrated (DeepSeek ✅, OpenAI, Anthropic, Ollama)
├── All imports updated to unified_llm_*
└── Commit: [hash] "feat: migrate Security-Architect crates"

NEXT TASKS (Week 1 Day 5-7 - ML Offload Migration):
[Add detailed steps for Day 5-7]
```

### Success Checklist for Day 2-4

Before considering Day 2-4 complete, verify:

- [ ] Security crate files copied to `crates/security/src/`
- [ ] Providers crate files copied to `crates/providers/src/`
- [ ] Security Cargo.toml updated with all dependencies
- [ ] Providers Cargo.toml updated with all dependencies
- [ ] All `securellm_*` imports replaced with `unified_llm_*`
- [ ] `cargo check --package unified-llm-security` passes
- [ ] `cargo check --package unified-llm-providers` passes
- [ ] `cargo check --all` passes
- [ ] Code formatted with `cargo fmt --all`
- [ ] MIGRATION-LOG.md created
- [ ] Changes committed with descriptive message
- [ ] Changes pushed to `origin/main`
- [ ] NEXT-SESSION-PROMPT.md updated for Day 5-7

### Time Estimates

- Pre-flight checks: 5 minutes
- Security crate migration: 2-3 hours
- Providers crate migration: 2-3 hours  
- Integration verification: 1 hour
- Commit and documentation: 25 minutes

**Total: 5.5 - 7.5 hours**

---

---

## 📞 Support Resources

- Architecture docs are comprehensive - refer to them often
- Core crate has examples of proper structure and testing
- Security-Architect CLAUDE.md has detailed implementation notes
- ML Offload Phase 2 design has VRAM algorithms

---

**Ready to Continue!** Use the prompt above to jump right back in. 🚀

**Last Updated**: 2025-11-06  
**Next Session**: Week 1 Day 2-4 (Security-Architect Migration)  
**Mode**: Code (for implementation work)