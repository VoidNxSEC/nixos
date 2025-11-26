use crate::models::{GpuInfo, GpuProcess, VramState};
use nvml_wrapper::{enum_wrappers::device::TemperatureSensor, Nvml};
use tracing::{error, warn};

/// VRAM monitor using NVIDIA Management Library
pub struct VramMonitor {
    nvml: Nvml,
}

impl VramMonitor {
    /// Initialize VRAM monitor
    pub fn new() -> anyhow::Result<Self> {
        let nvml = Nvml::init()?;
        Ok(Self { nvml })
    }

    /// Get current VRAM state
    pub fn get_state(&self) -> VramState {
        let gpus = self.query_gpus();
        let processes = self.query_processes();

        let (total_mb, used_mb): (u64, u64) = gpus.iter().fold((0, 0), |(t, u), gpu| {
            (t + gpu.total_mb, u + gpu.used_mb)
        });

        let total_gb = total_mb as f64 / 1024.0;
        let used_gb = used_mb as f64 / 1024.0;
        let free_gb = total_gb - used_gb;
        let utilization_percent = if total_gb > 0.0 {
            (used_gb / total_gb) * 100.0
        } else {
            0.0
        };

        VramState {
            timestamp: chrono::Utc::now().to_rfc3339(),
            total_gb: (total_gb * 100.0).round() / 100.0,
            used_gb: (used_gb * 100.0).round() / 100.0,
            free_gb: (free_gb * 100.0).round() / 100.0,
            utilization_percent: (utilization_percent * 10.0).round() / 10.0,
            gpus,
            processes,
        }
    }

    /// Query all GPUs
    fn query_gpus(&self) -> Vec<GpuInfo> {
        let device_count = match self.nvml.device_count() {
            Ok(count) => count,
            Err(e) => {
                error!("Failed to get device count: {}", e);
                return vec![];
            }
        };

        let mut gpus = Vec::new();

        for i in 0..device_count {
            let device = match self.nvml.device_by_index(i) {
                Ok(dev) => dev,
                Err(e) => {
                    warn!("Failed to get device {}: {}", i, e);
                    continue;
                }
            };

            // Get memory info
            let memory = match device.memory_info() {
                Ok(mem) => mem,
                Err(e) => {
                    warn!("Failed to get memory info for GPU {}: {}", i, e);
                    continue;
                }
            };

            // Get utilization
            let utilization = device
                .utilization_rates()
                .map(|u| u.gpu)
                .unwrap_or(0);

            // Get temperature
            let temperature = device
                .temperature(TemperatureSensor::Gpu)
                .unwrap_or(0);

            // Get GPU name
            let name = device
                .name()
                .unwrap_or_else(|_| format!("GPU {}", i));

            let total_mb = memory.total / (1024 * 1024);
            let used_mb = memory.used / (1024 * 1024);
            let free_mb = memory.free / (1024 * 1024);

            gpus.push(GpuInfo {
                id: i,
                name,
                total_mb,
                used_mb,
                free_mb,
                utilization_percent: utilization,
                temperature_c: temperature,
            });
        }

        gpus
    }

    /// Query GPU processes
    fn query_processes(&self) -> Vec<GpuProcess> {
        let device_count = match self.nvml.device_count() {
            Ok(count) => count,
            Err(_) => return vec![],
        };

        let mut all_processes = Vec::new();

        for i in 0..device_count {
            let device = match self.nvml.device_by_index(i) {
                Ok(dev) => dev,
                Err(_) => continue,
            };

            let processes = match device.running_compute_processes() {
                Ok(procs) => procs,
                Err(_) => continue,
            };

            for proc in processes {
                // Get process name from /proc/{pid}/comm
                let name = std::fs::read_to_string(format!("/proc/{}/comm", proc.pid))
                    .ok()
                    .map(|s| s.trim().to_string())
                    .unwrap_or_else(|| format!("pid:{}", proc.pid));

                // Extract memory usage from UsedGpuMemory enum
                use nvml_wrapper::enums::device::UsedGpuMemory;
                let memory_mb = match proc.used_gpu_memory {
                    UsedGpuMemory::Used(bytes) => bytes / (1024 * 1024),
                    UsedGpuMemory::Unavailable => 0,
                };

                all_processes.push(GpuProcess {
                    gpu_id: i,
                    pid: proc.pid,
                    name,
                    memory_mb,
                });
            }
        }

        all_processes
    }

    /// Check if enough VRAM is available
    pub fn can_fit(&self, required_gb: f64, safety_margin: f64) -> bool {
        let state = self.get_state();
        let margin_gb = required_gb * safety_margin;
        (required_gb + margin_gb) <= state.free_gb
    }

    /// Recommend optimal GPU layers for model
    pub fn recommend_layers(&self, model_size_gb: f64) -> u32 {
        let state = self.get_state();
        let available_gb = state.free_gb;

        // Assume 32 layers typical, each using model_size / 32
        let per_layer = model_size_gb / 32.0;
        let overhead = 0.5; // 500MB overhead

        // Calculate max layers that fit
        let max_layers = ((available_gb - overhead) / per_layer).floor() as u32;
        std::cmp::min(max_layers, 32) // Clamp to 0-32
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vram_monitor() {
        // This test requires NVIDIA GPU
        // Skip if not available
        if let Ok(monitor) = VramMonitor::new() {
            let state = monitor.get_state();
            assert!(state.total_gb > 0.0);
            println!("Total VRAM: {:.2}GB", state.total_gb);
            println!("Used VRAM: {:.2}GB", state.used_gb);
            println!("Free VRAM: {:.2}GB", state.free_gb);
        }
    }
}
