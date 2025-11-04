# ML Offload System - Phase 2 Design
**Based on LM Studio & llama.cpp Memory Management Techniques**

> **Status**: Design Phase
> **Created**: 2025-11-04
> **Objective**: Implement intelligent model loading/unloading with dynamic parameter optimization

---

## Executive Summary

Phase 2 will implement the core model orchestration features, focusing on **efficient VRAM utilization** by adopting techniques used in LM Studio and llama.cpp.

**Key Insight**: You don't need to load the entire model into VRAM to get good performance. Strategic partial offloading can maximize hardware utilization.

---

## Core Techniques from LM Studio/llama.cpp

### 1. **GPU Layer Offloading** (Partial Loading)

**Concept**: Selectively offload only N layers to GPU, keep rest in CPU RAM.

```bash
# llama.cpp parameter
llama-server -ngl 32 --model model.gguf
```

**Benefits**:
- Fits larger models in limited VRAM
- Example: 13B model with only 6GB VRAM by offloading 20 layers instead of all 40

**Implementation for Phase 2**:
```json
{
  "model_id": 2,
  "backend": "llamacpp",
  "params": {
    "gpu_layers": 20,        // -ngl parameter
    "auto_adjust": true      // Automatically calculate optimal layers
  }
}
```

**Algorithm**:
```python
def calculate_optimal_gpu_layers(model, available_vram):
    """
    Calculate maximum GPU layers that fit in VRAM.

    Formula (from LM Studio):
    - Base model size (quantized)
    - + KV cache size (context_length × layers × hidden_size)
    - + Overhead (~500MB)
    """
    layer_size_mb = model.size_gb * 1024 / model.layer_count
    kv_cache_mb = (context_length * 4096 * 0.008)  # ~8MB per 1k context
    overhead_mb = 500

    available_mb = available_vram * 1024 - kv_cache_mb - overhead_mb
    max_layers = int(available_mb / layer_size_mb)

    return min(max_layers, model.layer_count)
```

### 2. **Dynamic Context Window Adjustment**

**Concept**: Reduce context size to fit model in VRAM.

**Context vs VRAM Relationship**:
| Context Length | KV Cache VRAM (7B model) |
|----------------|--------------------------|
| 2,048 tokens   | ~500 MB                  |
| 4,096 tokens   | ~1 GB                    |
| 8,192 tokens   | ~2 GB                    |
| 16,384 tokens  | ~4 GB                    |
| 32,768 tokens  | ~8 GB                    |

**Implementation**:
```rust
pub struct LoadRequest {
    model_id: i64,
    backend: String,
    params: ModelLoadParams,
}

pub struct ModelLoadParams {
    /// Context window size (in tokens)
    context_length: Option<u32>,  // Default: auto-calculated

    /// GPU layers to offload
    gpu_layers: Option<u32>,      // Default: auto-calculated

    /// KV cache quantization (4-bit, 8-bit, f16)
    kv_cache_type: Option<String>, // Default: "f16"

    /// RoPE frequency scaling
    rope_freq_scale: Option<f32>,  // For extended context

    /// Flash attention (more memory efficient)
    flash_attention: Option<bool>, // Default: true
}
```

**Auto-Calculation Strategy**:
```rust
pub fn auto_calculate_params(
    model: &Model,
    available_vram_gb: f32,
) -> ModelLoadParams {
    // Start with maximum context
    let mut context = 8192;
    let mut gpu_layers = model.layer_count;

    // Calculate VRAM requirements
    loop {
        let required_vram = calculate_vram_need(
            model,
            context,
            gpu_layers,
            KVCacheType::F16,
        );

        if required_vram <= available_vram_gb * 0.9 {
            // 90% threshold for safety
            break;
        }

        // Reduce context first (less impact on quality)
        if context > 2048 {
            context /= 2;
        } else if gpu_layers > 0 {
            // Then reduce GPU layers
            gpu_layers -= 5;
        } else {
            // Model too large
            return Err("Model cannot fit in available VRAM");
        }
    }

    ModelLoadParams {
        context_length: Some(context),
        gpu_layers: Some(gpu_layers),
        kv_cache_type: Some("f16".to_string()),
        rope_freq_scale: None,
        flash_attention: Some(true),
    }
}
```

### 3. **KV Cache Quantization**

**Concept**: Store key/value cache in lower precision (4-bit/8-bit instead of 16-bit).

**VRAM Savings**:
- **f16** (default): 8MB per 1k context
- **q8_0** (8-bit): 4MB per 1k context (50% savings)
- **q4_0** (4-bit): 2MB per 1k context (75% savings)

**Trade-offs**:
- Minimal quality loss with q8_0
- Slight quality degradation with q4_0
- Enables 2x-4x larger context windows

### 4. **Partial Tensor Offloading**

**Concept**: Keep attention layers in VRAM, FFN (feed-forward) experts in CPU RAM.

**llama.cpp Command**:
```bash
# Offload FFN experts to CPU for MoE models
llama-server --override-tensor "\.ffn_.*_exps\.weight=CPU"
```

**Use Case**:
- Massive MoE models (Mixtral, Qwen-3-235B)
- Only active experts needed in VRAM
- Inactive experts can stay in CPU RAM

**Implementation Priority**: Phase 3 (complex, requires tensor-level control)

### 5. **Multi-Step Loading Process**

**Concept**: Load model gradually to detect OOM early.

**LM Studio Approach**:
1. **Pre-flight check**: Estimate VRAM before loading
2. **Progressive loading**: Load layer-by-layer with monitoring
3. **Fallback**: Reduce parameters if OOM detected
4. **Validation**: Test inference before marking "ready"

**Implementation**:
```rust
pub async fn load_model_with_validation(
    model_id: i64,
    backend: &str,
    params: ModelLoadParams,
) -> Result<LoadedModel> {
    // 1. Pre-flight VRAM estimation
    let estimated_vram = estimate_vram_usage(&model, &params);
    if estimated_vram > get_available_vram() {
        return Err("Insufficient VRAM (pre-flight check failed)");
    }

    // 2. Start loading with monitoring
    let load_handle = backend.load_model_async(model_id, params);

    // 3. Monitor VRAM during load
    tokio::spawn(async move {
        while !load_handle.is_complete() {
            let current_vram = get_vram_usage();
            if current_vram > MAX_VRAM_THRESHOLD {
                load_handle.cancel();
                return Err("VRAM exceeded during load");
            }
            tokio::time::sleep(Duration::from_millis(100)).await;
        }
    });

    // 4. Validate with test inference
    let model = load_handle.await?;
    let test_response = model.generate("Hello", max_tokens=5);

    if test_response.is_ok() {
        Ok(model)
    } else {
        Err("Model loaded but inference failed")
    }
}
```

---

## Phase 2 Implementation Plan

### Core Features

#### 1. Model Loading API (`POST /load`)

**Request**:
```json
{
  "model_id": 1,
  "backend": "llamacpp",
  "params": {
    "context_length": 4096,     // Optional (auto if omitted)
    "gpu_layers": 32,           // Optional (auto if omitted)
    "kv_cache_type": "q8_0",    // Optional (default: f16)
    "rope_freq_scale": 1.0,     // Optional
    "flash_attention": true     // Optional (default: true)
  },
  "priority": "medium"          // high, medium, low
}
```

**Response**:
```json
{
  "status": "loading",
  "model_id": 1,
  "estimated_time_seconds": 15,
  "vram_usage_gb": 4.2,
  "params_used": {
    "context_length": 4096,
    "gpu_layers": 32,
    "kv_cache_type": "q8_0"
  }
}
```

#### 2. Model Unloading API (`POST /unload`)

**Request**:
```json
{
  "backend": "llamacpp",
  "model_id": 1
}
```

**Response**:
```json
{
  "status": "unloaded",
  "vram_freed_gb": 4.2
}
```

#### 3. Model Hot-Switching (`POST /switch`)

**Concept**: Unload current model and load new one atomically.

**Request**:
```json
{
  "from_model_id": 1,
  "to_model_id": 2,
  "backend": "llamacpp",
  "params": {
    "context_length": 2048
  }
}
```

**Response**:
```json
{
  "status": "switching",
  "estimated_time_seconds": 20,
  "old_model_unloaded": true,
  "new_model_loading": true
}
```

#### 4. Auto-Scaling Based on VRAM Threshold

**Configuration**:
```nix
kernelcore.ml.offload.vramIntelligence = {
  autoScaling = {
    enable = true;
    threshold = 85;           # Trigger at 85% VRAM usage
    evictionPolicy = "priority"; # Evict low-priority models first
  };
};
```

**Logic**:
```rust
pub async fn vram_monitor_loop(state: Arc<AppState>) {
    loop {
        let vram_state = get_vram_state();

        if vram_state.utilization_percent > 85.0 {
            // VRAM threshold exceeded - trigger auto-scaling
            let loaded_models = get_loaded_models();

            // Sort by priority (low → high)
            loaded_models.sort_by_key(|m| m.priority);

            // Unload low-priority models until under threshold
            for model in loaded_models {
                if model.priority == Priority::Low {
                    unload_model(model.id).await?;

                    let new_vram = get_vram_state().utilization_percent;
                    if new_vram < 80.0 {
                        break; // Under threshold now
                    }
                }
            }
        }

        tokio::time::sleep(Duration::from_secs(5)).await;
    }
}
```

---

## Database Schema Extensions

### Add `loaded_models` Table

```sql
CREATE TABLE loaded_models (
    id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    backend TEXT NOT NULL,
    loaded_at TEXT NOT NULL,
    last_used TEXT NOT NULL,

    -- Load parameters
    context_length INTEGER NOT NULL,
    gpu_layers INTEGER NOT NULL,
    kv_cache_type TEXT NOT NULL,

    -- VRAM tracking
    vram_usage_mb INTEGER NOT NULL,

    -- Inference stats
    request_count INTEGER DEFAULT 0,
    total_tokens_generated INTEGER DEFAULT 0,

    FOREIGN KEY (model_id) REFERENCES models(id)
);
```

### Add `model_queue` Table

```sql
CREATE TABLE model_queue (
    id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    backend TEXT NOT NULL,
    priority TEXT NOT NULL,
    requested_at TEXT NOT NULL,
    status TEXT NOT NULL,  -- pending, loading, failed
    params_json TEXT,

    FOREIGN KEY (model_id) REFERENCES models(id)
);
```

---

## Phase 2 Milestones

### Milestone 1: Basic Load/Unload (Week 1)
- ✅ Implement `POST /load` endpoint
- ✅ Implement `POST /unload` endpoint
- ✅ Basic llamacpp backend integration
- ✅ VRAM tracking for loaded models

### Milestone 2: Smart Parameter Calculation (Week 2)
- ✅ Auto-calculate optimal `gpu_layers`
- ✅ Auto-calculate safe `context_length`
- ✅ KV cache quantization support
- ✅ Pre-flight VRAM estimation

### Milestone 3: Hot-Switching (Week 3)
- ✅ Implement `POST /switch` endpoint
- ✅ Atomic unload→load operation
- ✅ Queue management
- ✅ Priority-based scheduling

### Milestone 4: Auto-Scaling (Week 4)
- ✅ VRAM threshold monitoring
- ✅ Priority-based eviction
- ✅ LRU fallback policy
- ✅ Alert system integration

---

## Testing Strategy

### Test Cases

1. **Load Small Model (Fits Easily)**
   - Model: Qwen2.5-1.5B (1.1GB)
   - Expected: Full GPU offload, max context (8192)

2. **Load Medium Model (Tight Fit)**
   - Model: L3-8B-Stheno (4.87GB VRAM)
   - Expected: Auto-reduce to ~20 GPU layers, context 4096

3. **Load Large Model (Doesn't Fit)**
   - Model: LLaMA2-13B (7.83GB VRAM)
   - Expected: Error or extreme parameter reduction

4. **Hot-Switch Under Load**
   - Switch from 8B → 1.5B while requests active
   - Expected: Graceful transition, no dropped requests

5. **Auto-Scaling Trigger**
   - Load model until 90% VRAM
   - Expected: Auto-evict low-priority model

---

## Success Metrics

- ✅ Load model in < 20 seconds
- ✅ Hot-switch in < 30 seconds
- ✅ Auto-scaling reaction time < 10 seconds
- ✅ VRAM utilization > 80% (efficient usage)
- ✅ Zero OOM crashes (robust handling)

---

## Next Steps

1. Review this design with user
2. Create detailed GitHub issues for each milestone
3. Set up development branch: `feature/phase2-model-loading`
4. Begin Milestone 1 implementation

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-04
**Maintained By**: kernelcore
**Review Schedule**: Weekly during Phase 2 development
