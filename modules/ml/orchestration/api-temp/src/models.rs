use serde::{Deserialize, Serialize};

/// Model metadata from registry database
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ModelInfo {
    pub id: i64,
    pub name: String,
    pub path: String,
    pub format: String,
    pub size_gb: f64,
    pub vram_estimate_gb: f64,
    pub architecture: Option<String>,
    pub quantization: Option<String>,
    pub parameter_count: Option<String>,
    pub context_length: i64,
    pub compatible_backends: String, // JSON array
    pub last_scanned: String,
    pub last_used: Option<String>,
    pub usage_count: i64,
    pub priority: String,
    pub tags: Option<String>, // JSON array
    pub notes: Option<String>,
}

impl ModelInfo {
    /// Parse compatible_backends JSON string to Vec
    pub fn get_backends(&self) -> Vec<String> {
        serde_json::from_str(&self.compatible_backends).unwrap_or_default()
    }

    /// Parse tags JSON string to Vec
    pub fn get_tags(&self) -> Vec<String> {
        self.tags
            .as_ref()
            .and_then(|t| serde_json::from_str(t).ok())
            .unwrap_or_default()
    }
}

/// Backend information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendInfo {
    pub name: String,
    pub status: String, // active, inactive, error
    #[serde(rename = "type")]
    pub backend_type: String, // systemd, docker, api
    pub host: String,
    pub port: u16,
    pub loaded_model: Option<String>,
    pub vram_usage_mb: Option<u64>,
}

/// VRAM state snapshot
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VramState {
    pub timestamp: String,
    pub total_gb: f64,
    pub used_gb: f64,
    pub free_gb: f64,
    pub utilization_percent: f64,
    pub gpus: Vec<GpuInfo>,
    pub processes: Vec<GpuProcess>,
}

/// GPU information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpuInfo {
    pub id: u32,
    pub name: String,
    pub total_mb: u64,
    pub used_mb: u64,
    pub free_mb: u64,
    pub utilization_percent: u32,
    pub temperature_c: u32,
}

/// GPU process information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpuProcess {
    pub gpu_id: u32,
    pub pid: u32,
    pub name: String,
    pub memory_mb: u64,
}

/// Request to load a model
#[derive(Debug, Deserialize)]
pub struct LoadRequest {
    pub model_id: Option<i64>,
    pub model_path: Option<String>,
    pub backend: String,
    pub priority: Option<String>,
    pub gpu_layers: Option<u32>,
}

/// Request to unload a model
#[derive(Debug, Deserialize)]
pub struct UnloadRequest {
    pub backend: String,
}

/// Request to switch models
#[derive(Debug, Deserialize)]
pub struct SwitchRequest {
    pub backend: String,
    pub model_id: Option<i64>,
    pub model_path: Option<String>,
    pub gpu_layers: Option<u32>,
}

/// Generic API response
#[derive(Debug, Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
        }
    }

    pub fn error(message: impl Into<String>) -> Self {
        Self {
            success: false,
            data: None,
            error: Some(message.into()),
        }
    }
}
