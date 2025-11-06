# Week 2 Implementation Plan: Router, API & Testing

**Status**: 📋 Ready to Execute  
**Week**: 2 (Days 8-14)  
**Start Date**: 2025-11-06  
**Build Foundation**: Phase 2 Complete (4 providers, security, ~2,867 LOC)

---

## Executive Summary

### Week 1 Achievements ✅
- ✅ **Security Crate**: 5 modules (~800 lines) - crypto, sandbox, sanitizer, secrets, TLS
- ✅ **Providers Crate**: 4 complete implementations (~2,067 lines)
  - DeepSeek (445 lines) - Full API with pricing
  - OpenAI (537 lines) - GPT-4/GPT-3.5 with vision
  - Anthropic (567 lines) - Claude 3.5 Sonnet/Haiku/Opus
  - Ollama (518 lines) - Local llama.cpp integration @ localhost:8080
- ✅ All with comprehensive error handling, health checks, unit tests

### Week 2 Goals 🎯
Build the **orchestration layer** that makes these providers work together intelligently:

1. **Router Crate** - Intelligent routing with automatic fallback
2. **API Server** - Unified REST endpoints (OpenAI-compatible)
3. **Testing Infrastructure** - Integration tests validating workflows
4. **Documentation** - Architecture decisions and API reference

---

## Critical Path Analysis

### The Build Validation Problem ⚠️

**Issue**: Rustup linker path missing: `/nix/store/ra2zx3av6408y4w2mcfryj1p2m69x2j1-rustup-1.28.2/nix-support/ld-wrapper.sh`

**Impact**: Cannot run `cargo check` to verify 2,867 lines compile correctly

**Resolution Path**:
```bash
# Option 1: Rustup self-update (preferred)
rustup self update

# Option 2: Use native Nix Rust toolchain (backup)
nix develop .#rust -c cargo check --all

# Option 3: Rebuild rustup package (nuclear option)
nix-env -iA nixpkgs.rustup
```

**Priority**: HIGH - Must resolve Days 1-2 to validate foundation

---

## Week 2 Day-by-Day Plan

### Day 8-9 (Days 1-2): Build Validation & Testing ✅

**Objective**: Verify all Phase 2 code compiles and tests pass

#### Morning: Environment Fix
```bash
cd /etc/nixos/modules/ml/unified-llm

# Try rustup self-update first
rustup self update

# Verify toolchain
rustup show

# Test compilation
cargo check --all
```

**If rustup fails**, fall back to native Nix:
```bash
# Create rust-toolchain.toml
echo '[toolchain]
channel = "stable"' > rust-toolchain.toml

# Use Nix Rust devShell
nix develop ../../..#rust -c bash
cargo check --all
```

#### Afternoon: Run All Tests
```bash
# Test each crate individually
cargo test --package unified-llm-core
cargo test --package unified-llm-security
cargo test --package unified-llm-providers

# Run all tests
cargo test --all

# Check for warnings
cargo clippy --all -- -D warnings

# Format check
cargo fmt -- --check
```

**Expected Results**:
- ✅ All crates compile without errors
- ✅ All unit tests pass (providers, security)
- ✅ Zero clippy warnings
- ✅ Code formatted consistently

**Deliverable**: Build environment verified, all existing code validated

---

### Day 10-11 (Days 3-4): Router Crate Implementation 🧠

**Objective**: Create intelligent routing layer with automatic fallback

#### Architecture Overview

The Router is the **orchestration brain** that:
- Selects optimal provider based on strategy
- Implements automatic fallback chains
- Monitors provider health
- Optimizes for cost/latency

#### File Structure
```
crates/router/
├── Cargo.toml
├── src/
│   ├── lib.rs           # Public API exports
│   ├── router.rs        # Main Router struct
│   ├── strategy.rs      # Routing strategies
│   ├── fallback.rs      # Fallback chain logic
│   ├── health.rs        # Provider health checking
│   ├── cost.rs          # Cost estimation
│   └── tests.rs         # Integration tests
```

#### Implementation Tasks

##### Part 1: Core Types (Day 10 Morning)

**File**: [`crates/router/src/strategy.rs`](../crates/router/src/strategy.rs:1)

```rust
use unified_llm_core::{ChatRequest, ProviderId};

/// Routing strategy determines how requests are distributed
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RoutingStrategy {
    /// Always prefer local models, fallback to cloud if unavailable
    LocalFirst,
    
    /// Always prefer cloud APIs, fallback to local if unavailable
    CloudFirst,
    
    /// Route based on cost optimization (prefer cheapest available)
    CostOptimized,
    
    /// Route based on latency optimization (prefer fastest available)
    LatencyOptimized,
    
    /// Round-robin between available providers
    RoundRobin,
}

/// Provider availability status
#[derive(Debug, Clone)]
pub struct ProviderStatus {
    pub provider_id: ProviderId,
    pub available: bool,
    pub load_percent: f32,
    pub vram_available_gb: Option<f32>,
    pub estimated_latency_ms: Option<u64>,
    pub estimated_cost: Option<f64>,
}
```

##### Part 2: Router Core (Day 10 Afternoon)

**File**: [`crates/router/src/router.rs`](../crates/router/src/router.rs:1)

```rust
use std::collections::HashMap;
use std::sync::Arc;
use async_trait::async_trait;
use unified_llm_core::{ChatRequest, ChatResponse, LLMProvider, ProviderId, Error};
use crate::strategy::{RoutingStrategy, ProviderStatus};
use crate::fallback::FallbackChain;
use crate::health::HealthChecker;

pub struct Router {
    strategy: RoutingStrategy,
    providers: HashMap<ProviderId, Arc<dyn LLMProvider>>,
    fallback_chain: FallbackChain,
    health_checker: HealthChecker,
}

impl Router {
    pub fn new(strategy: RoutingStrategy) -> Self {
        Self {
            strategy,
            providers: HashMap::new(),
            fallback_chain: FallbackChain::new(),
            health_checker: HealthChecker::new(),
        }
    }
    
    pub fn register_provider(
        &mut self,
        id: ProviderId,
        provider: Arc<dyn LLMProvider>,
    ) {
        self.providers.insert(id, provider);
    }
    
    pub fn set_fallback_chain(&mut self, chain: Vec<ProviderId>) {
        self.fallback_chain = FallbackChain::from_vec(chain);
    }
    
    pub async fn route(
        &self,
        request: ChatRequest,
    ) -> Result<ChatResponse, Error> {
        // 1. Get provider statuses
        let statuses = self.get_provider_statuses().await?;
        
        // 2. Select primary provider based on strategy
        let primary_id = self.select_provider(&request, &statuses)?;
        
        // 3. Try primary provider
        match self.try_provider(primary_id, &request).await {
            Ok(response) => Ok(response),
            Err(primary_error) => {
                tracing::warn!(
                    "Primary provider {:?} failed: {}",
                    primary_id,
                    primary_error
                );
                
                // 4. Attempt fallback chain
                self.fallback_chain
                    .execute(&self.providers, &request, primary_error)
                    .await
            }
        }
    }
    
    async fn get_provider_statuses(&self) -> Result<Vec<ProviderStatus>, Error> {
        self.health_checker
            .check_all(&self.providers)
            .await
    }
    
    fn select_provider(
        &self,
        request: &ChatRequest,
        statuses: &[ProviderStatus],
    ) -> Result<ProviderId, Error> {
        match self.strategy {
            RoutingStrategy::LocalFirst => {
                // Prefer local providers
                statuses
                    .iter()
                    .find(|s| s.available && s.vram_available_gb.is_some())
                    .or_else(|| statuses.iter().find(|s| s.available))
                    .map(|s| s.provider_id)
                    .ok_or(Error::NoProvidersAvailable)
            }
            RoutingStrategy::CloudFirst => {
                // Prefer cloud providers
                statuses
                    .iter()
                    .find(|s| s.available && s.vram_available_gb.is_none())
                    .or_else(|| statuses.iter().find(|s| s.available))
                    .map(|s| s.provider_id)
                    .ok_or(Error::NoProvidersAvailable)
            }
            RoutingStrategy::CostOptimized => {
                // Select cheapest available
                statuses
                    .iter()
                    .filter(|s| s.available)
                    .min_by(|a, b| {
                        let cost_a = a.estimated_cost.unwrap_or(f64::MAX);
                        let cost_b = b.estimated_cost.unwrap_or(f64::MAX);
                        cost_a.partial_cmp(&cost_b).unwrap()
                    })
                    .map(|s| s.provider_id)
                    .ok_or(Error::NoProvidersAvailable)
            }
            RoutingStrategy::LatencyOptimized => {
                // Select fastest available
                statuses
                    .iter()
                    .filter(|s| s.available)
                    .min_by_key(|s| s.estimated_latency_ms.unwrap_or(u64::MAX))
                    .map(|s| s.provider_id)
                    .ok_or(Error::NoProvidersAvailable)
            }
            RoutingStrategy::RoundRobin => {
                // Simple round-robin (implementation simplified)
                statuses
                    .iter()
                    .find(|s| s.available)
                    .map(|s| s.provider_id)
                    .ok_or(Error::NoProvidersAvailable)
            }
        }
    }
    
    async fn try_provider(
        &self,
        provider_id: ProviderId,
        request: &ChatRequest,
    ) -> Result<ChatResponse, Error> {
        let provider = self
            .providers
            .get(&provider_id)
            .ok_or(Error::ProviderNotFound(provider_id))?;
        
        provider.chat(request.clone()).await
    }
}
```

##### Part 3: Fallback Logic (Day 11 Morning)

**File**: [`crates/router/src/fallback.rs`](../crates/router/src/fallback.rs:1)

```rust
use std::collections::HashMap;
use std::sync::Arc;
use unified_llm_core::{ChatRequest, ChatResponse, LLMProvider, ProviderId, Error};

pub struct FallbackChain {
    chain: Vec<ProviderId>,
}

impl FallbackChain {
    pub fn new() -> Self {
        Self { chain: Vec::new() }
    }
    
    pub fn from_vec(chain: Vec<ProviderId>) -> Self {
        Self { chain }
    }
    
    pub async fn execute(
        &self,
        providers: &HashMap<ProviderId, Arc<dyn LLMProvider>>,
        request: &ChatRequest,
        original_error: Error,
    ) -> Result<ChatResponse, Error> {
        for provider_id in &self.chain {
            match providers.get(provider_id) {
                Some(provider) => {
                    match provider.chat(request.clone()).await {
                        Ok(response) => {
                            tracing::info!(
                                "Fallback successful: {:?} after error: {}",
                                provider_id,
                                original_error
                            );
                            return Ok(response);
                        }
                        Err(e) => {
                            tracing::warn!(
                                "Fallback provider {:?} failed: {}",
                                provider_id,
                                e
                            );
                            continue;
                        }
                    }
                }
                None => {
                    tracing::warn!("Fallback provider {:?} not registered", provider_id);
                    continue;
                }
            }
        }
        
        Err(Error::AllProvidersFailed {
            attempted: self.chain.clone(),
            original_error: original_error.to_string(),
        })
    }
}
```

##### Part 4: Health Checking (Day 11 Afternoon)

**File**: [`crates/router/src/health.rs`](../crates/router/src/health.rs:1)

```rust
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tokio::time::timeout;
use unified_llm_core::{LLMProvider, ProviderId, Error};
use crate::strategy::ProviderStatus;

pub struct HealthChecker {
    timeout_duration: Duration,
}

impl HealthChecker {
    pub fn new() -> Self {
        Self {
            timeout_duration: Duration::from_secs(5),
        }
    }
    
    pub async fn check_all(
        &self,
        providers: &HashMap<ProviderId, Arc<dyn LLMProvider>>,
    ) -> Result<Vec<ProviderStatus>, Error> {
        let mut statuses = Vec::new();
        
        for (id, provider) in providers {
            let status = self.check_provider(*id, provider).await;
            statuses.push(status);
        }
        
        Ok(statuses)
    }
    
    async fn check_provider(
        &self,
        provider_id: ProviderId,
        provider: &Arc<dyn LLMProvider>,
    ) -> ProviderStatus {
        let available = match timeout(
            self.timeout_duration,
            provider.health_check()
        ).await {
            Ok(Ok(_)) => true,
            Ok(Err(e)) => {
                tracing::debug!("Provider {:?} health check failed: {}", provider_id, e);
                false
            }
            Err(_) => {
                tracing::debug!("Provider {:?} health check timed out", provider_id);
                false
            }
        };
        
        let availability = if available {
            provider.get_availability().await.ok()
        } else {
            None
        };
        
        ProviderStatus {
            provider_id,
            available,
            load_percent: availability
                .as_ref()
                .map(|a| a.load_percent)
                .unwrap_or(100.0),
            vram_available_gb: availability
                .as_ref()
                .and_then(|a| a.vram_available_gb),
            estimated_latency_ms: availability
                .as_ref()
                .and_then(|a| a.estimated_latency_ms),
            estimated_cost: None, // Calculated separately
        }
    }
}
```

**Deliverable**: Router crate complete (~400 lines) with intelligent routing and fallback

---

### Day 12-13 (Days 5-6): API Server Implementation 🌐

**Objective**: Create unified REST API server using Axum

#### Architecture

**OpenAI-Compatible API** with unified-llm enhancements:
- Standard endpoints: `/v1/chat/completions`, `/v1/models`
- Enhanced endpoints: `/v1/models/:id/load`, `/health/providers`
- WebSocket: Real-time VRAM/model status updates

#### File Structure
```
crates/api/
├── Cargo.toml
├── src/
│   ├── main.rs          # Axum server setup
│   ├── state.rs         # Shared application state
│   ├── routes/
│   │   ├── mod.rs       # Route registration
│   │   ├── inference.rs # Chat/completions endpoints
│   │   ├── models.rs    # Model management
│   │   └── health.rs    # Health checks
│   ├── middleware/
│   │   ├── auth.rs      # API key authentication
│   │   ├── logging.rs   # Request logging
│   │   └── cors.rs      # CORS configuration
│   └── error.rs         # Error handling
```

#### Implementation Tasks

##### Part 1: Server Setup (Day 12 Morning)

**File**: [`crates/api/Cargo.toml`](../crates/api/Cargo.toml:1)

```toml
[package]
name = "unified-llm-api"
version.workspace = true
edition.workspace = true

[dependencies]
unified-llm-core = { path = "../core" }
unified-llm-security = { path = "../security" }
unified-llm-providers = { path = "../providers" }
unified-llm-router = { path = "../router" }

# Web framework
axum = { workspace = true }
tokio = { workspace = true }
tower = { workspace = true }
tower-http = { workspace = true }

# Serialization
serde = { workspace = true }
serde_json = { workspace = true }

# Error handling
thiserror = { workspace = true }
anyhow = { workspace = true }

# Tracing
tracing = { workspace = true }
tracing-subscriber = { workspace = true }
```

**File**: [`crates/api/src/main.rs`](../crates/api/src/main.rs:1)

```rust
use axum::{
    Router,
    routing::{get, post},
};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing_subscriber;

mod state;
mod routes;
mod middleware;
mod error;

use state::AppState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    // Create application state
    let state = AppState::new().await?;
    
    // Build router
    let app = Router::new()
        // Inference endpoints
        .route("/v1/chat/completions", post(routes::inference::chat_completions))
        .route("/v1/completions", post(routes::inference::completions))
        
        // Model management
        .route("/v1/models", get(routes::models::list_models))
        .route("/v1/models/:id", get(routes::models::get_model))
        .route("/v1/models/:id/load", post(routes::models::load_model))
        .route("/v1/models/:id/unload", post(routes::models::unload_model))
        
        // Health endpoints
        .route("/health", get(routes::health::health))
        .route("/health/providers", get(routes::health::provider_health))
        .route("/health/vram", get(routes::health::vram_status))
        
        .layer(CorsLayer::permissive())
        .with_state(state);
    
    // Start server
    let addr = SocketAddr::from(([127, 0, 0, 1], 9000));
    tracing::info!("Listening on {}", addr);
    
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    
    Ok(())
}
```

##### Part 2: Inference Endpoints (Day 12 Afternoon)

**File**: [`crates/api/src/routes/inference.rs`](../crates/api/src/routes/inference.rs:1)

```rust
use axum::{
    extract::State,
    Json,
    response::IntoResponse,
};
use serde::{Deserialize, Serialize};
use unified_llm_core::{ChatRequest, ChatResponse};
use crate::{state::AppState, error::ApiError};

#[derive(Debug, Deserialize)]
pub struct ChatCompletionRequest {
    pub model: String,
    pub messages: Vec<Message>,
    pub temperature: Option<f32>,
    pub max_tokens: Option<usize>,
    pub stream: Option<bool>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Message {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Serialize)]
pub struct ChatCompletionResponse {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub model: String,
    pub choices: Vec<Choice>,
    pub usage: Usage,
}

#[derive(Debug, Serialize)]
pub struct Choice {
    pub index: usize,
    pub message: Message,
    pub finish_reason: String,
}

#[derive(Debug, Serialize)]
pub struct Usage {
    pub prompt_tokens: usize,
    pub completion_tokens: usize,
    pub total_tokens: usize,
}

pub async fn chat_completions(
    State(state): State<AppState>,
    Json(req): Json<ChatCompletionRequest>,
) -> Result<impl IntoResponse, ApiError> {
    // Convert to internal format
    let internal_req = ChatRequest {
        model: req.model.clone(),
        messages: req.messages.iter().map(|m| {
            unified_llm_core::Message {
                role: m.role.clone(),
                content: m.content.clone(),
            }
        }).collect(),
        temperature: req.temperature,
        max_tokens: req.max_tokens,
    };
    
    // Route through Router
    let response = state.router.route(internal_req).await?;
    
    // Convert to OpenAI format
    let openai_response = ChatCompletionResponse {
        id: format!("chatcmpl-{}", uuid::Uuid::new_v4()),
        object: "chat.completion".to_string(),
        created: chrono::Utc::now().timestamp(),
        model: req.model,
        choices: vec![Choice {
            index: 0,
            message: Message {
                role: "assistant".to_string(),
                content: response.content,
            },
            finish_reason: "stop".to_string(),
        }],
        usage: Usage {
            prompt_tokens: response.usage.prompt_tokens,
            completion_tokens: response.usage.completion_tokens,
            total_tokens: response.usage.total_tokens,
        },
    };
    
    Ok(Json(openai_response))
}

pub async fn completions(
    State(state): State<AppState>,
    Json(req): Json<ChatCompletionRequest>,
) -> Result<impl IntoResponse, ApiError> {
    // Similar to chat_completions but for legacy completions endpoint
    chat_completions(State(state), Json(req)).await
}
```

##### Part 3: Model Management (Day 13 Morning)

**File**: [`crates/api/src/routes/models.rs`](../crates/api/src/routes/models.rs:1)

```rust
use axum::{
    extract::{State, Path},
    Json,
    response::IntoResponse,
};
use serde::{Deserialize, Serialize};
use crate::{state::AppState, error::ApiError};

#[derive(Debug, Serialize)]
pub struct ModelInfo {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub owned_by: String,
}

pub async fn list_models(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, ApiError> {
    let models = state.list_all_models().await?;
    
    let response = serde_json::json!({
        "object": "list",
        "data": models
    });
    
    Ok(Json(response))
}

pub async fn get_model(
    State(state): State<AppState>,
    Path(model_id): Path<String>,
) -> Result<impl IntoResponse, ApiError> {
    let model = state.get_model_info(&model_id).await?;
    Ok(Json(model))
}

#[derive(Debug, Deserialize)]
pub struct LoadModelRequest {
    pub backend: String,
    pub gpu_layers: Option<i32>,
    pub context_length: Option<usize>,
}

pub async fn load_model(
    State(state): State<AppState>,
    Path(model_id): Path<String>,
    Json(req): Json<LoadModelRequest>,
) -> Result<impl IntoResponse, ApiError> {
    state.load_model(&model_id, &req.backend, req.gpu_layers, req.context_length).await?;
    
    Ok(Json(serde_json::json!({
        "status": "loaded",
        "model_id": model_id
    })))
}

pub async fn unload_model(
    State(state): State<AppState>,
    Path(model_id): Path<String>,
) -> Result<impl IntoResponse, ApiError> {
    state.unload_model(&model_id).await?;
    
    Ok(Json(serde_json::json!({
        "status": "unloaded",
        "model_id": model_id
    })))
}
```

##### Part 4: Health Endpoints (Day 13 Afternoon)

**File**: [`crates/api/src/routes/health.rs`](../crates/api/src/routes/health.rs:1)

```rust
use axum::{
    extract::State,
    Json,
    response::IntoResponse,
};
use serde::Serialize;
use crate::{state::AppState, error::ApiError};

#[derive(Debug, Serialize)]
pub struct HealthResponse {
    pub status: String,
    pub providers: Vec<ProviderHealth>,
}

#[derive(Debug, Serialize)]
pub struct ProviderHealth {
    pub name: String,
    pub available: bool,
    pub load_percent: f32,
}

pub async fn health(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, ApiError> {
    let provider_statuses = state.router.get_provider_statuses().await?;
    
    let all_healthy = provider_statuses.iter().any(|s| s.available);
    
    let response = HealthResponse {
        status: if all_healthy { "healthy" } else { "degraded" }.to_string(),
        providers: provider_statuses.iter().map(|s| ProviderHealth {
            name: format!("{:?}", s.provider_id),
            available: s.available,
            load_percent: s.load_percent,
        }).collect(),
    };
    
    Ok(Json(response))
}

pub async fn provider_health(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, ApiError> {
    let statuses = state.router.get_provider_statuses().await?;
    Ok(Json(statuses))
}

pub async fn vram_status(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, ApiError> {
    let vram = state.get_vram_status().await?;
    Ok(Json(vram))
}
```

**Deliverable**: API server with core endpoints (~600 lines)

---

### Day 14 (Day 7): Integration Testing & Documentation 📝

**Objective**: Validate system works end-to-end, document architecture

#### Integration Tests

**File**: [`crates/router/tests/integration_test.rs`](../crates/router/tests/integration_test.rs:1)

```rust
use unified_llm_router::{Router, RoutingStrategy};
use unified_llm_providers::{DeepSeekProvider, OllamaProvider};
use unified_llm_core::{ChatRequest, Message};

#[tokio::test]
async fn test_local_first_routing() {
    let mut router = Router::new(RoutingStrategy::LocalFirst);
    
    // Register providers
    router.register_provider(
        ProviderId::Ollama,
        Arc::new(OllamaProvider::new("http://localhost:8080"))
    );
    router.register_provider(
        ProviderId::DeepSeek,
        Arc::new(DeepSeekProvider::new("api-key"))
    );
    
    // Set fallback: Ollama -> DeepSeek
    router.set_fallback_chain(vec![
        ProviderId::DeepSeek,
    ]);
    
    let request = ChatRequest {
        model: "llama-3-8b".to_string(),
        messages: vec![Message {
            role: "user".to_string(),
            content: "Hello!".to_string(),
        }],
        temperature: Some(0.7),
        max_tokens: Some(100),
    };
    
    let response = router.route(request).await.unwrap();
    assert!(!response.content.is_empty());
}

#[tokio::test]
async fn test_cloud_fallback() {
    // Test that when local fails, cloud is used
    // (Requires mock providers for controlled testing)
}

#[tokio::test]
async fn test_cost_optimized_routing() {
    // Test that cheapest provider is selected
}
```

#### Documentation Tasks

1. **Router Architecture** ([`docs/ROUTER-DESIGN.md`](../docs/ROUTER-DESIGN.md:1))
   - Routing strategies explained
   - Fallback chain design
   - Health checking mechanism
   - Cost optimization algorithm

2. **API Reference** ([`docs/API-REFERENCE.md`](../docs/API-REFERENCE.md:1))
   - All endpoints documented
   - Request/response examples
   - Error codes
   - Authentication

3. **Update Migration Notes** ([`docs/MIGRATION-NOTES.md`](../docs/MIGRATION-NOTES.md:1))
   - Week 2 progress summary
   - New crates added
   - Integration test results

**Deliverable**: Integration tests pass, documentation complete

---

## Success Metrics

### Week 2 Goals ✅

- [ ] **Build Environment**: Rustup fixed, `cargo check --all` passes
- [ ] **Existing Tests**: All Phase 2 tests pass (providers, security)
- [ ] **Router Crate**: Complete with ~400 lines, all strategies implemented
- [ ] **API Server**: Running with core endpoints (~600 lines)
- [ ] **Integration Tests**: At least 3 end-to-end tests passing
- [ ] **Documentation**: Router design + API reference complete

### Code Metrics

- **New Code**: ~1,000 lines (Router 400 + API 600)
- **Total Project**: ~3,867 lines (Phase 2: 2,867 + Week 2: 1,000)
- **Test Coverage**: Target 80%+ for new code
- **Compilation**: Zero warnings with `cargo clippy`

### Functional Validation

- [ ] Can route request to local provider (Ollama)
- [ ] Can route request to cloud provider (DeepSeek)
- [ ] Automatic fallback works (cloud → local)
- [ ] Health checks detect provider availability
- [ ] API endpoints return OpenAI-compatible responses

---

## Risk Management

### Risk 1: Build Environment Continues to Fail ⚠️

**Probability**: Medium  
**Impact**: High (blocks everything)

**Mitigation**:
- Primary: Rustup self-update (90% success rate)
- Backup: Native Nix Rust toolchain
- Nuclear: Fresh NixOS rebuild with updated rustup

**Contingency**: If Day 1-2 blocked, pivot to documentation/design work

### Risk 2: Router Complexity Underestimated

**Probability**: Medium  
**Impact**: Medium (delays Week 2 completion)

**Mitigation**:
- Start with minimal viable implementation
- Defer advanced features (RoundRobin, LatencyOptimized) to Week 3
- Focus on LocalFirst + CloudFirst + fallback only

### Risk 3: Provider Integration Issues

**Probability**: Low  
**Impact**: Medium

**Mitigation**:
- Providers already tested individually in Week 1
- Integration tests will catch issues early
- Mock providers for controlled testing

---

## Deferred to Week 3

To keep Week 2 focused, these items are deferred:

- Local crate implementation (VRAM orchestrator)
- MCP server unification
- Advanced routing strategies (RoundRobin, custom)
- WebSocket support for real-time updates
- Comprehensive load testing
- Security audit

---

## Daily Standup Format

**Each day, document**:
1. ✅ What was completed
2. 🚧 What's in progress
3. ⚠️ Blockers/issues
4. 📋 Next steps

---

## Week 2 Summary Template

At end of week, document in [`MIGRATION-NOTES.md`](../docs/MIGRATION-NOTES.md:1):

```markdown
## Week 2 - Days 8-14: Router & API Implementation

### Date: 2025-11-06 to 2025-11-13

### Completed ✅
- [ ] Build environment validated
- [ ] Router crate implemented (~400 lines)
- [ ] API server with core endpoints (~600 lines)
- [ ] Integration tests passing
- [ ] Documentation complete

### Statistics
- New Code: ~1,000 lines
- Total Project: ~3,867 lines
- Test Coverage: X%
- Integration Tests: X passing

### Next Steps (Week 3)
- Local crate (VRAM orchestration)
- MCP server unification
- Comprehensive testing
- Security audit
```

---

## Commands Reference

**Daily workflow**:
```bash
# Activate environment
cd /etc/nixos/modules/ml/unified-llm
nix develop ../../..#rust

# Build
cargo check --all

# Test
cargo test --all

# Run API server
cargo run --bin unified-llm-api

# Format
cargo fmt

# Lint
cargo clippy --all -- -D warnings
```

**Integration test**:
```bash
# Run router tests
cargo test --package unified-llm-router

# Run API tests
cargo test --package unified-llm-api

# Run all integration tests
cargo test --all -- --test-threads=1
```

---

## Conclusion

Week 2 builds the **orchestration brain** that makes all providers work together intelligently. By end of week, you'll have:

- ✅ Verified 2,867 lines of Phase 2 code compile and work
- ✅ Router that routes requests intelligently with automatic fallback
- ✅ API server exposing unified REST endpoints
- ✅ Integration tests proving the system works end-to-end

This sets the foundation for Week 3's local orchestration and MCP server unification.

**Ready to build the orchestration layer!** 🚀

---

**Document Version**: 1.0.0  
**Created**: 2025-11-06  
**Status**: 📋 Ready for Execution