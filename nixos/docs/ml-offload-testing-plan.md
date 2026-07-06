# ML Offload System - Testing Plan

> **Status**: Ready for Phase 1 Testing
> **Created**: 2025-11-06
> **Component**: ML Offload API + Neovim Integration

---

## Testing Overview

This document outlines the comprehensive testing strategy for the ML Offload System Phase 1 MVP, which includes:
- **Rust Backend API** (OpenAI-compatible endpoints)
- **llama.cpp Backend** (llama-server on port 8080)
- **Neovim Plugin** (Lua client integration)

---

## Architecture Summary

```
Neovim Plugin (Lua)
    ↓ HTTP (port 9000)
ML Offload API (Rust/Axum)
    ↓ HTTP Proxy (port 8080)
llama-server (llama.cpp)
    ↓ CUDA
NVIDIA GPU (VRAM Management)
```

### Key Components

1. **ML Offload API** (`modules/ml/offload/api/`)
   - Port: 9000 (configured via `ML_OFFLOAD_PORT`)
   - Service: `ml-offload-api.service`
   - User: `ml-offload`
   - Log: `journalctl -u ml-offload-api.service`

2. **llama-server** (llamacpp service)
   - Port: 8080
   - Model: `/var/lib/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf`
   - Service: `llamacpp.service`
   - Threads: 40, GPU Layers: 32, Context: 4096

3. **Neovim Plugin** (`~/.config/nvim/lua/ml-offload/`)
   - API URL: **NEEDS UPDATE** - currently `http://127.0.0.1:8000` (should be 9000)
   - Commands: `:MLChat`, `:MLStatus`, `:MLEmbed`, `:MLModels`
   - Keybindings: `<leader>mc`, `<leader>ms`, `<leader>me`, `<leader>mm`

---

## Critical Issue Identified

⚠️ **PORT MISMATCH**: Neovim plugin is configured for port 8000, but API runs on port 9000!

**Fix Required**: Update [`/home/kernelcore/.config/nvim/lua/ml-offload/init.lua:9`](../../../home/kernelcore/.config/nvim/lua/ml-offload/init.lua:9)
```lua
-- FROM:
api_url = "http://127.0.0.1:8000",

-- TO:
api_url = "http://127.0.0.1:9000",
```

---

## Testing Phases

### Phase 1: Pre-Flight Checks

**Goal**: Verify all services are built and running

#### 1.1 Check Build Status
```bash
# Check if API binary exists
ls -lh /nix/store/*/bin/ml-offload-api 2>/dev/null || echo "API not built"

# Verify configuration is active
grep "ml.offload.api.enable = true" /etc/nixos/hosts/kernelcore/configuration.nix

# Check systemd service definition
systemctl cat ml-offload-api.service
```

**Expected Output**:
- Binary exists in nix store
- Configuration shows `enable = true`
- Service unit file exists

#### 1.2 Verify llama-server Status
```bash
# Check llamacpp service
systemctl status llamacpp.service

# Verify it's listening on port 8080
ss -tlnp | grep :8080

# Test health endpoint directly
curl -s http://127.0.0.1:8080/health | jq
```

**Expected Output**:
- Service active (running)
- Port 8080 listening
- Health check returns 200 OK with status info

#### 1.3 Check ML Offload API Status
```bash
# Check service status
systemctl status ml-offload-api.service

# View recent logs
journalctl -u ml-offload-api.service -n 50 --no-pager

# Check if listening on port 9000
ss -tlnp | grep :9000
```

**Expected Output**:
- Service active (running) OR failed (needs rebuild)
- Logs show initialization or errors
- Port 9000 listening (if running)

---

### Phase 2: API Endpoint Testing

**Goal**: Validate all API endpoints respond correctly

#### 2.1 Basic Health Checks

```bash
# Root endpoint
curl -s http://127.0.0.1:9000/ | jq

# Simple health check
curl -s http://127.0.0.1:9000/health | jq

# Detailed backend health
curl -s http://127.0.0.1:9000/api/health | jq

# Backend info (model details)
curl -s http://127.0.0.1:9000/api/backend/info | jq
```

**Expected Output**:
```json
// /api/health
{
  "status": "healthy",
  "backends": {
    "llamacpp": {
      "available": true,
      "ready": true,
      "details": "llama-server is running and ready"
    }
  }
}
```

#### 2.2 OpenAI-Compatible Endpoints

##### List Models
```bash
curl -s http://127.0.0.1:9000/v1/models | jq
```

**Expected**: List of available models from registry

##### Chat Completion (Non-Streaming)
```bash
curl -s http://127.0.0.1:9000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "messages": [
      {"role": "user", "content": "Say hello in one sentence"}
    ],
    "temperature": 0.7,
    "max_tokens": 50
  }' | jq
```

**Expected**: 
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1699...,
  "model": "default",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! ..."
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 5,
    "total_tokens": 15
  }
}
```

##### Embeddings
```bash
curl -s http://127.0.0.1:9000/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "input": "Hello world"
  }' | jq '.data[0] | {index, dimensions: (.embedding | length)}'
```

**Expected**: Embedding vector with dimensions (typically 4096 for L3-8B)

#### 2.3 VRAM and Status
```bash
# Current VRAM state
curl -s http://127.0.0.1:9000/vram | jq

# Full status
curl -s http://127.0.0.1:9000/status | jq
```

**Expected**: VRAM metrics (total, used, free GB)

---

### Phase 3: Neovim Integration Testing

**Goal**: Verify Neovim plugin can interact with API

#### 3.1 Fix Configuration (if needed)

Update `~/.config/nvim/lua/ml-offload/init.lua`:
```lua
M.config = {
  api_url = "http://127.0.0.1:9000",  -- CORRECTED PORT
  timeout = 30000,
  model = "default",
  -- ... rest of config
}
```

#### 3.2 Restart Neovim
```bash
# Close all Neovim instances
pkill -9 nvim

# Start fresh
nvim
```

#### 3.3 Test Commands

**In Neovim**:

1. **Check Status**
   ```vim
   :MLStatus
   ```
   **Expected**: Floating window with API health status

2. **List Models**
   ```vim
   :MLModels
   ```
   **Expected**: Floating window with available models

3. **Simple Chat**
   ```vim
   :MLChat Explain what a GGUF file is in one sentence
   ```
   **Expected**: Floating window with model's response

4. **Visual Selection Chat**
   ```vim
   " Select some code in visual mode (V)
   " Then run:
   <leader>mc
   ```
   **Expected**: Model analyzes selected code

5. **Embeddings** (Visual mode)
   ```vim
   " Select text in visual mode
   <leader>me
   ```
   **Expected**: Notification with embedding dimensions

---

### Phase 4: End-to-End Integration

**Goal**: Test complete flow from Neovim → API → llama-server → GPU

#### 4.1 Monitor Full Stack

Open 4 terminal windows:

**Terminal 1: API Logs**
```bash
journalctl -u ml-offload-api.service -f
```

**Terminal 2: llama-server Logs**
```bash
journalctl -u llamacpp.service -f
```

**Terminal 3: GPU Monitor**
```bash
watch -n 1 nvidia-smi
```

**Terminal 4: Neovim**
```bash
nvim
```

#### 4.2 Execute Test Sequence

In Neovim, run commands while watching logs:

1. `:MLStatus` - Watch API logs
2. `:MLChat Hello` - Watch all logs + GPU
3. Monitor GPU memory usage during inference
4. Verify response in Neovim

#### 4.3 Performance Validation

```bash
# Time a chat completion
time curl -s http://127.0.0.1:9000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "messages": [{"role": "user", "content": "Count from 1 to 10"}],
    "max_tokens": 100
  }' | jq '.choices[0].message.content'
```

**Expected**: Response within 5-10 seconds for ~50 tokens

---

## Success Criteria

### ✅ Phase 1 Complete When:
- [ ] API service is active and running
- [ ] llama-server is responding on port 8080
- [ ] Both services show in `systemctl status`
- [ ] No errors in recent logs

### ✅ Phase 2 Complete When:
- [ ] `/api/health` returns `"status": "healthy"`
- [ ] `/v1/models` lists available models
- [ ] `/v1/chat/completions` returns valid response
- [ ] `/v1/embeddings` returns embedding vector
- [ ] `/vram` shows GPU memory stats

### ✅ Phase 3 Complete When:
- [ ] Neovim loads plugin without errors
- [ ] `:MLStatus` shows healthy status
- [ ] `:MLModels` lists models
- [ ] `:MLChat` generates response in <10s
- [ ] Visual selection commands work
- [ ] No Lua errors in `:messages`

### ✅ Phase 4 Complete When:
- [ ] Complete request flow traced in logs
- [ ] GPU memory increases during inference
- [ ] Response time is acceptable (<10s for short prompts)
- [ ] VRAM returns to baseline after completion
- [ ] No errors or warnings in any component

---

## Troubleshooting Guide

### Issue: API Service Won't Start

**Check**:
```bash
# View full error
journalctl -u ml-offload-api.service -n 100 --no-pager

# Check if binary exists
ls -l /nix/store/*/bin/ml-offload-api

# Verify data directory exists
ls -ld /var/lib/ml-offload

# Check permissions
sudo -u ml-offload ls /var/lib/ml-offload
```

**Common Causes**:
- Build failed (missing Cargo.lock)
- Database path not writable
- CUDA/NVIDIA driver not accessible
- Port 9000 already in use

**Fix**: Rebuild and check dependencies
```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Issue: llama-server Not Responding

**Check**:
```bash
systemctl status llamacpp.service
journalctl -u llamacpp.service -n 50
curl http://127.0.0.1:8080/health
```

**Common Causes**:
- Model file not found
- VRAM exhausted
- CUDA initialization failed

**Fix**: Restart service
```bash
sudo systemctl restart llamacpp.service
```

### Issue: Neovim Plugin Errors

**Check**:
```vim
:messages    " View error messages
:checkhealth " Run health checks
```

**Common Causes**:
- Wrong API URL (port mismatch)
- plenary.nvim not installed
- API not running

**Fix**: Update config and restart Neovim

### Issue: "Connection Refused" Errors

**Check ports**:
```bash
ss -tlnp | grep -E ':(8080|9000)'
curl -v http://127.0.0.1:9000/health
curl -v http://127.0.0.1:8080/health
```

**Fix**: Ensure both services are running

---

## Next Steps After Testing

### If Tests Pass ✅:
1. Document successful configuration
2. Create usage examples
3. Begin Phase 2: Intelligence Layer
4. Plan MCP Server implementation

### If Tests Fail ❌:
1. Document specific failures
2. Identify root causes
3. Create fix implementation plan
4. Re-test after fixes

---

## Quick Test Commands

```bash
# One-liner health check
curl -s http://127.0.0.1:9000/api/health | jq -r '.status'

# Quick chat test
curl -s http://127.0.0.1:9000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"default","messages":[{"role":"user","content":"Hi"}]}' \
  | jq -r '.choices[0].message.content'

# Check VRAM
curl -s http://127.0.0.1:9000/vram | jq
```

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-06
**Next Review**: After Phase 1 Testing Complete