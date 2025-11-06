# ML Offload System - Development Instructions

## Project Overview

The ML Offload System is a multi-stack architecture designed to provide intelligent model inference capabilities for React Native IDE development. The system proxies requests to llama.cpp servers, manages VRAM resources, and provides OpenAI-compatible APIs.

**Primary Goal**: Build a robust backend API that intelligently manages ML model inference with a focus on resource efficiency and developer experience.

**Key Philosophy**: Back-end logic and implementation first, UI after. Neovim integration serves as the first MVP for rapid testing and validation.

---

## Technology Stack Architecture

### 🦀 Rust Backend (Core API)
**Location**: `modules/ml/offload/api/`

**Responsibilities**:
- ML Offload Manager API using Axum framework
- HTTP proxy to llama.cpp server at 127.0.0.1:8080
- OpenAI-compatible endpoints:
  - `/v1/chat/completions` - Chat completions (streaming & non-streaming)
  - `/v1/embeddings` - Text embeddings
  - `/v1/models` - Model listing
- Health monitoring and backend status (`/api/health`, `/api/backend/info`)
- VRAM intelligence and resource monitoring (nvml-wrapper)
- Smart parameter calculation and context management

**Current Status**: ✅ Foundation complete
- llama.cpp backend proxy implemented
- OpenAI-compatible API working
- Health check system in place

**Key Files**:
- `src/main.rs` - API entry point and routing
- `src/inference.rs` - Inference handlers and request proxying
- `src/backends/llamacpp.rs` - llama.cpp HTTP client
- `src/health.rs` - Health check system
- `src/vram.rs` - VRAM monitoring

### ⚛️ React Frontend (Desktop IDE)
**Location**: TBD (future: `ide/` or `frontend/`)

**Responsibilities**:
- Desktop client interface for React Native development
- IDE features: code editing, debugging, model interactions
- Integration with MCP server for intelligent coding sessions
- Visual representation of model status and VRAM usage
- Configuration management UI

**Current Status**: 🔜 Planned (Phase 4)

**Architecture Considerations**:
- Electron or Tauri wrapper for desktop deployment
- Communication with Rust backend via HTTP/WebSocket
- MCP client integration for AI-assisted coding
- Real-time status updates

### 🐹 Go Network Layer
**Location**: TBD (future: `network/` or `proxy/`)

**Responsibilities**:
- Network proxying and routing
- Network configuration management
- Connection pooling and load balancing
- Multi-backend routing (future multi-server support)
- Request/response transformation if needed

**Current Status**: 🔜 Planned (Phase 3)

**Architecture Considerations**:
- Lightweight proxy service
- Health-aware routing
- Minimal overhead design
- Integration with Rust backend

### 📝 Neovim Integration (First MVP)
**Location**: `~/.config/nvim/lua/ml-offload/`

**Responsibilities**:
- Lightweight client for quick tests and validations
- Direct connection to Rust API (HTTP client)
- Command-line interface for model interactions:
  - `:MLChat <prompt>` - Send chat completion
  - `:MLEmbed <text>` - Get embeddings
  - `:MLStatus` - Check backend health
  - `:MLModels` - List available models
- Fast iteration and debugging tool
- Visual selection support for code context
- Floating window UI for responses

**Current Status**: ✅ Completed (Phase 1 - MVP)

**Implementation Details**:
- **Type**: Lua plugin using `plenary.nvim` for HTTP
- **Files**:
  - `~/.config/nvim/lua/ml-offload/init.lua` - Main plugin implementation
  - `~/.config/nvim/lua/ml-offload/README.md` - Comprehensive documentation
  - `~/.config/nvim/lua/plugins/ml-offload.lua` - Plugin specification (lazy.nvim)
- **Features**:
  - Lazy loading on commands and keybindings
  - OpenAI-compatible API integration
  - Production-grade error handling
  - Configurable UI (floating windows)
  - Markdown syntax highlighting for responses

**Keybindings**:
- `<leader>mc` - Chat with model (normal/visual mode)
- `<leader>ms` - Check API status
- `<leader>me` - Get embeddings for selection (visual mode)
- `<leader>mm` - List available models

**Configuration Pattern**:
Follows production Neovim configuration architecture with:
- Lazy loading for performance
- Comprehensive logging
- Health checks integration
- Environment awareness
- Graceful error recovery

**Testing Focus**:
- Manual validation of API responses ✅
- Quick parameter tuning ✅
- Debugging inference issues ✅
- Context window testing ✅
- Visual selection workflow ✅

---

## Development Phases

### Phase 1: Backend Foundation & MVP (CURRENT)
**Status**: 🔄 In Progress

**Completed**:
- ✅ llama.cpp proxy implementation
- ✅ OpenAI-compatible API endpoints
- ✅ Health monitoring system
- ✅ NixOS flake integration

**Current Focus**:
- ⏳ Verify build completion
- ⏳ Test API endpoints with llama-server
- 🎯 Neovim MVP integration
- 🎯 MCP server implementation

**Deliverables**:
- Working Rust API with llama.cpp proxy
- Neovim plugin/client for testing
- Basic MCP server for intelligent sessions
- Documentation and testing procedures

### Phase 2: Intelligence Layer
**Status**: 📋 Planned

**Goals**:
- Smart parameter calculation based on VRAM availability
- Automatic context window management
- Model capability detection
- Resource-aware request routing
- Caching strategies for embeddings

**Technical Details**:
- VRAM monitoring integration with inference decisions
- Dynamic batch size calculation
- Context pruning algorithms
- Model metadata management

### Phase 3: Network Layer (Go)
**Status**: 📋 Planned

**Goals**:
- Implement Go proxy service
- Network configuration management
- Multi-backend support (multiple llama-servers)
- Load balancing and failover

**Integration Points**:
- Sits between clients and Rust API
- May handle SSL/TLS termination
- Request routing logic
- Monitoring and logging

### Phase 4: Desktop Client (React)
**Status**: 📋 Planned

**Goals**:
- Full IDE interface implementation
- MCP integration for AI-assisted coding
- Visual model management
- Advanced configuration UI

**Features**:
- Code editor with ML assistance
- Real-time VRAM visualization
- Model switching UI
- Prompt templates and history

---

## Development Guidelines

### General Principles

1. **Back-End First**: Always implement and test backend logic before UI
2. **Test Early**: Use Neovim MVP for immediate validation
3. **Resource Aware**: Every feature should consider VRAM and compute constraints
4. **Incremental**: Build in small, testable increments
5. **Documentation**: Document as you go, especially API contracts

### Rust Backend Guidelines

**Code Organization**:
```
src/
├── main.rs           # Entry point, routing
├── inference.rs      # Inference handlers
├── backends/         # Backend implementations
│   ├── mod.rs
│   └── llamacpp.rs
├── health.rs         # Health checks
├── vram.rs          # VRAM monitoring
└── models.rs        # Model management
```

**Conventions**:
- Use `anyhow::Result` for error handling
- Follow Rust API Guidelines (naming, organization)
- Add tracing/logging to all handlers
- Write tests for business logic
- Use async/await properly (don't block)

**Testing**:
```bash
# Run tests
cargo test

# Check formatting
cargo fmt --check

# Run clippy
cargo clippy -- -D warnings

# Build with NixOS
sudo nixos-rebuild build --flake .#kernelcore
```

### Go Network Layer Guidelines

**Code Organization** (when implemented):
```
network/
├── main.go           # Entry point
├── proxy/            # Proxy logic
├── config/           # Configuration
└── health/           # Health checks
```

**Conventions**:
- Follow Go standard project layout
- Use context for cancellation
- Proper error wrapping
- Structured logging

### React Frontend Guidelines

**Code Organization** (when implemented):
```
frontend/
├── src/
│   ├── components/   # React components
│   ├── hooks/        # Custom hooks
│   ├── services/     # API clients
│   └── mcp/          # MCP integration
├── public/
└── package.json
```

**Conventions**:
- TypeScript for type safety
- Functional components with hooks
- MCP SDK integration
- Proper error boundaries

### Neovim Integration Guidelines

**Implementation Approach**:
- Start with Lua plugin (faster iteration)
- HTTP client using `plenary.nvim` or `curl`
- Configuration in `lua/ml-offload/config.lua`
- Commands in `lua/ml-offload/commands.lua`

**Example Command Structure**:
```lua
-- lua/ml-offload/init.lua
local M = {}

M.setup = function(opts)
  opts = opts or {}
  M.config = {
    api_url = opts.api_url or "http://127.0.0.1:8000",
    timeout = opts.timeout or 30000,
  }
end

M.chat = function(prompt)
  -- Call /v1/chat/completions
end

M.status = function()
  -- Call /api/health
end

return M
```

---

## MCP Server Implementation

### Overview
Model Context Protocol (MCP) server for intelligent coding sessions, providing global availability in the desktop client with quality control.

### Goals
1. **Context Management**: Preserve conversation history across sessions
2. **Quality Control**: Ensure high-quality prompts and responses
3. **Global Availability**: Accessible from desktop client
4. **Integration**: Seamless connection with ML Offload API

### Architecture
```
MCP Server (Rust or standalone)
    ↓
ML Offload API (Rust)
    ↓
llama.cpp Server (127.0.0.1:8080)
```

### Implementation Options

**Option 1: Rust MCP Server**
- Implement using `mcp-server` crate (if available)
- Direct integration with ML Offload API
- Shared VRAM monitoring

**Option 2: Standalone MCP Server**
- Separate process (Node.js/Python)
- HTTP client to ML Offload API
- More flexibility in tooling

### Features to Implement
1. **Context Preservation**: Store conversation history
2. **Prompt Engineering**: Template system for better prompts
3. **Resource Awareness**: Check VRAM before large requests
4. **Caching**: Cache embeddings and common responses
5. **Tools**: Expose coding tools (file operations, search, etc.)

### Integration Points
- Desktop client connects via MCP SDK
- Neovim can use MCP client (optional)
- Shared configuration with ML Offload API

---

## Testing Strategy

### Unit Testing
- **Rust**: `cargo test` for all modules
- **Go**: `go test ./...` for network layer
- **React**: Jest/Vitest for components
- **Neovim**: Manual testing with real API

### Integration Testing
- **API → llama.cpp**: Test all endpoints with real server
- **Neovim → API**: End-to-end command testing
- **MCP → API**: Protocol compliance testing

### Manual Testing with Neovim MVP
1. Start llama.cpp server: `llama-server --port 8080`
2. Start ML Offload API: `cargo run` or via NixOS service
3. Open Neovim with plugin loaded
4. Test commands:
   - `:MLStatus` - Check health
   - `:MLChat "Explain Rust lifetimes"` - Test chat
   - `:MLEmbed "test text"` - Test embeddings
5. Verify responses and debug issues

### Performance Testing
- Measure latency for different request sizes
- Test concurrent request handling
- Monitor VRAM usage under load
- Profile Rust code for bottlenecks

---

## Iteration Logic

### Daily Development Cycle
1. **Morning**: Check build status, review overnight thoughts
2. **Implementation**: Focus on one feature/module at a time
3. **Testing**: Use Neovim MVP to validate immediately
4. **Documentation**: Update docs and comments
5. **Commit**: Small, focused commits with clear messages

### Feature Development Flow
```
1. Plan → Write specification in comments
2. Implement → Write code following guidelines
3. Test → Neovim MVP or unit tests
4. Refine → Address issues, improve code
5. Document → Update README, add examples
6. Commit → Push to repository
```

### Debugging Process
1. Use Neovim MVP to reproduce issue
2. Add logging/tracing to identify problem
3. Write test case that fails
4. Fix issue
5. Verify test passes
6. Remove/refine logging

### Code Review Checklist
- [ ] Follows project conventions
- [ ] Has appropriate error handling
- [ ] Includes logging/tracing
- [ ] Has tests (if applicable)
- [ ] Documentation updated
- [ ] No compiler warnings
- [ ] Passes clippy/formatting checks

---

## Configuration Management

### Environment Variables
```bash
# ML Offload API
ML_OFFLOAD_PORT=8000
ML_OFFLOAD_HOST=127.0.0.1
LLAMACPP_URL=http://127.0.0.1:8080

# Optional
RUST_LOG=info,ml_offload=debug
NVIDIA_VISIBLE_DEVICES=0
```

### NixOS Configuration
- Service defined in `modules/ml/offload/default.nix`
- Configuration in `hosts/kernelcore/configuration.nix`
- Build with: `sudo nixos-rebuild build --flake .#kernelcore`

### Neovim Configuration
```lua
-- ~/.config/nvim/lua/plugins/ml-offload.lua
return {
  'your-username/ml-offload-nvim',
  config = function()
    require('ml-offload').setup({
      api_url = "http://127.0.0.1:8000",
      timeout = 30000,
    })
  end
}
```

---

## Troubleshooting

### Common Issues

**Build Failures**:
- Check `flake.lock` is up to date: `nix flake update`
- Verify Rust version: `rustc --version`
- Check dependencies: `cargo tree`

**API Connection Issues**:
- Verify llama-server is running: `curl http://127.0.0.1:8080/health`
- Check ML Offload API: `curl http://127.0.0.1:8000/api/health`
- Review logs: `journalctl -u ml-offload-api -f`

**Neovim Plugin Issues**:
- Check Neovim logs: `:messages`
- Verify API URL in config
- Test API manually with curl
- Enable debug logging in plugin

**VRAM Issues**:
- Monitor with: `nvidia-smi`
- Check VRAM usage: `curl http://127.0.0.1:8000/api/backend/info`
- Reduce batch size or context length

---

## Future Considerations

### Scalability
- Multi-server support (load balancing)
- Distributed inference across multiple GPUs
- Request queuing and prioritization
- Rate limiting per user/client

### Features
- Model hot-swapping without restart
- A/B testing different models
- Prompt template library
- Response caching
- Fine-tuning integration

### Observability
- Prometheus metrics export
- Grafana dashboards
- Request tracing (OpenTelemetry)
- Performance profiling

### Security
- API authentication (tokens/keys)
- Rate limiting
- Input validation and sanitization
- Secure model loading

---

## Resources

### Documentation
- CLAUDE.md - AI assistant usage guidelines
- README.md - Project overview
- Rust API docs: `cargo doc --open`

### External References
- llama.cpp docs: https://github.com/ggerganov/llama.cpp
- Axum framework: https://docs.rs/axum
- MCP Protocol: https://modelcontextprotocol.io
- Neovim API: `:help api`

---

## Contact & Support

For questions or issues:
1. Check this INSTRUCTIONS.md first
2. Review CLAUDE.md for AI assistant usage
3. Check existing issues/documentation
4. Create detailed issue report with logs

---

*Last Updated: 2025-11-05*
*Version: 0.1.0 - Initial MVP Phase*
