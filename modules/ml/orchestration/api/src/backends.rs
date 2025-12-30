/// Backend driver module
///
/// Implements standard interface for all ML backends:
/// - llama.cpp (systemd service + HTTP API) - PRIMARY
/// - vLLM (Docker container + HTTP API) - Future
/// - TGI (Docker container + HTTP API) - Future

pub mod llamacpp;

use crate::errors::{ApiError, ApiResult};
use crate::models::BackendInfo;
use crate::vram::VramMonitor;
use llamacpp::LlamaCppBackend;
use tracing::{info, warn};

pub struct BackendDriver;

impl BackendDriver {
    /// Detect and return all available backends
    pub async fn list_backends() -> Vec<BackendInfo> {
        let mut backends = vec![];

        // Check llamacpp backend
        match LlamaCppBackend::with_defaults() {
            Ok(backend) => {
                let is_ready = backend.is_ready().await;
                let (status, loaded_model) = if is_ready {
                    // Try to get current model info
                    let model = backend
                        .get_model_info()
                        .await
                        .ok()
                        .map(|info| info.model);
                    ("active", model)
                } else {
                    ("inactive", None)
                };

                backends.push(BackendInfo {
                    name: "llamacpp".to_string(),
                    status: status.to_string(),
                    backend_type: "systemd".to_string(),
                    host: "127.0.0.1".to_string(),
                    port: 8080,
                    loaded_model,
                    vram_usage_mb: None, // TODO: Get from VRAM monitor
                });
            }
            Err(e) => {
                warn!("Failed to check llamacpp backend: {}", e);
                backends.push(BackendInfo {
                    name: "llamacpp".to_string(),
                    status: "error".to_string(),
                    backend_type: "systemd".to_string(),
                    host: "127.0.0.1".to_string(),
                    port: 8080,
                    loaded_model: None,
                    vram_usage_mb: None,
                });
            }
        }

        backends
    }

    /// Check if model can be loaded (VRAM budget check)
    pub async fn can_load_model(model_size_gb: f64) -> ApiResult<bool> {
        let vram_monitor = VramMonitor::new()
            .map_err(|e| ApiError::VramMonitoringError(e.to_string()))?;

        let state = vram_monitor.get_state();

        // Need 10% buffer for safety
        let required_gb = model_size_gb * 1.1;

        if state.free_gb >= required_gb {
            Ok(true)
        } else {
            Err(ApiError::InsufficientVram {
                need_gb: required_gb,
                available_gb: state.free_gb,
            })
        }
    }

    /// Load model on specified backend
    pub async fn load_model(
        backend: &str,
        model_path: &str,
        model_size_gb: Option<f64>,
        gpu_layers: Option<u32>,
    ) -> ApiResult<()> {
        info!(
            "Loading model on backend '{}': {}",
            backend, model_path
        );

        // Pre-flight VRAM check if size provided
        if let Some(size_gb) = model_size_gb {
            Self::can_load_model(size_gb).await?;
        }

        match backend {
            "llamacpp" => {
                // Note: llama-server doesn't support hot-reloading models
                // The model is loaded on systemd service start
                // This would require restarting the service with new config
                warn!("llamacpp backend doesn't support dynamic model loading");
                warn!("Model must be configured in NixOS configuration and service restarted");

                // For now, just verify backend is running with a model
                let backend = LlamaCppBackend::with_defaults()
                    .map_err(|e| ApiError::BackendError(e.to_string()))?;

                if !backend.is_ready().await {
                    return Err(ApiError::BackendUnavailable {
                        backend: "llamacpp".to_string(),
                    });
                }

                info!("llamacpp backend is running");
                Ok(())
            }
            _ => Err(ApiError::InvalidRequest(format!(
                "Unsupported backend: {}",
                backend
            ))),
        }
    }

    /// Unload model from backend
    pub async fn unload_model(backend: &str) -> ApiResult<()> {
        info!("Unloading model from backend '{}'", backend);

        match backend {
            "llamacpp" => {
                // llama-server doesn't support unloading without stopping service
                warn!("llamacpp backend doesn't support dynamic model unloading");
                warn!("To unload, stop the systemd service: systemctl stop llamacpp-turbo");

                Ok(())
            }
            _ => Err(ApiError::InvalidRequest(format!(
                "Unsupported backend: {}",
                backend
            ))),
        }
    }

    /// Switch model on backend (hot-reload)
    pub async fn switch_model(
        backend: &str,
        model_path: &str,
        model_size_gb: Option<f64>,
        gpu_layers: Option<u32>,
    ) -> ApiResult<()> {
        info!(
            "Switching model on backend '{}' to: {}",
            backend, model_path
        );

        // Pre-flight VRAM check
        if let Some(size_gb) = model_size_gb {
            Self::can_load_model(size_gb).await?;
        }

        match backend {
            "llamacpp" => {
                warn!("llamacpp backend doesn't support hot model switching");
                warn!("Requires service restart with new configuration");

                Err(ApiError::BackendError(
                    "Hot model switching not supported by llamacpp backend".to_string(),
                ))
            }
            _ => Err(ApiError::InvalidRequest(format!(
                "Unsupported backend: {}",
                backend
            ))),
        }
    }

    /// Check backend health
    pub async fn health_check(backend: &str) -> bool {
        match backend {
            "llamacpp" => {
                if let Ok(backend) = LlamaCppBackend::with_defaults() {
                    backend.is_ready().await
                } else {
                    false
                }
            }
            _ => false,
        }
    }
}
