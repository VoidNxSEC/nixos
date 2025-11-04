/// Backend driver module
///
/// Implements standard interface for all ML backends:
/// - Ollama (systemd service + HTTP API)
/// - llama.cpp (systemd service + HTTP API)
/// - vLLM (Docker container + HTTP API)
/// - TGI (Docker container + HTTP API)
///
/// TODO: Implement in Phase 2

use crate::models::BackendInfo;

pub struct BackendDriver;

impl BackendDriver {
    /// Detect and return all available backends
    pub async fn list_backends() -> Vec<BackendInfo> {
        // TODO: Implement backend detection
        vec![]
    }

    /// Load model on specified backend
    pub async fn load_model(
        backend: &str,
        _model_path: &str,
        _gpu_layers: Option<u32>,
    ) -> anyhow::Result<()> {
        anyhow::bail!("Backend loading not implemented for: {}", backend)
    }

    /// Unload model from backend
    pub async fn unload_model(_backend: &str) -> anyhow::Result<()> {
        anyhow::bail!("Backend unloading not implemented")
    }

    /// Switch model on backend (hot-reload)
    pub async fn switch_model(
        backend: &str,
        _model_path: &str,
        _gpu_layers: Option<u32>,
    ) -> anyhow::Result<()> {
        anyhow::bail!("Backend switching not implemented for: {}", backend)
    }

    /// Check backend health
    pub async fn health_check(_backend: &str) -> bool {
        // TODO: Implement health checks
        false
    }
}
