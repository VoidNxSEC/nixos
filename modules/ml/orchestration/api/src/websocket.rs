/// WebSocket handler for real-time updates
///
/// Provides live updates for:
/// - VRAM state changes
/// - Model loading progress
/// - Backend status changes
/// - Inference request completion

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    response::IntoResponse,
};
use futures::{sink::SinkExt, stream::StreamExt};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::broadcast;
use tracing::{error, info, warn};

use crate::AppState;

/// WebSocket event types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum WsEvent {
    /// VRAM state update
    VramUpdate {
        timestamp: String,
        total_gb: f64,
        used_gb: f64,
        free_gb: f64,
        utilization_percent: f64,
    },
    
    /// Model loading progress
    ModelLoadProgress {
        model_id: i64,
        model_name: String,
        progress_percent: u8,
        stage: String, // "downloading", "loading", "validating", "ready"
        estimated_seconds_remaining: Option<u32>,
    },
    
    /// Model loaded successfully
    ModelLoaded {
        model_id: i64,
        model_name: String,
        backend: String,
        vram_usage_gb: f64,
        load_time_seconds: f64,
    },
    
    /// Model unloaded
    ModelUnloaded {
        model_id: i64,
        model_name: String,
        backend: String,
        vram_freed_gb: f64,
    },
    
    /// Backend status change
    BackendStatus {
        backend: String,
        status: String, // "active", "inactive", "error"
        loaded_model: Option<String>,
    },
    
    /// Inference request completed
    InferenceComplete {
        request_id: String,
        model_id: i64,
        tokens_generated: u32,
        time_ms: u64,
    },
    
    /// Error occurred
    Error {
        message: String,
        details: Option<String>,
    },
    
    /// Heartbeat/keepalive
    Ping {
        timestamp: String,
    },
}

/// WebSocket client subscription options
#[derive(Debug, Clone, Deserialize)]
pub struct SubscriptionOptions {
    /// Subscribe to VRAM updates
    #[serde(default = "default_true")]
    pub vram_updates: bool,
    
    /// Subscribe to model loading events
    #[serde(default = "default_true")]
    pub model_events: bool,
    
    /// Subscribe to backend status
    #[serde(default = "default_true")]
    pub backend_status: bool,
    
    /// Subscribe to inference completion events
    #[serde(default)]
    pub inference_events: bool,
    
    /// Update interval in seconds (for VRAM updates)
    #[serde(default = "default_update_interval")]
    pub update_interval_seconds: u64,
}

fn default_true() -> bool {
    true
}

fn default_update_interval() -> u64 {
    2 // 2 second default interval
}

impl Default for SubscriptionOptions {
    fn default() -> Self {
        Self {
            vram_updates: true,
            model_events: true,
            backend_status: true,
            inference_events: false,
            update_interval_seconds: 2,
        }
    }
}

/// WebSocket upgrade handler
pub async fn websocket_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

/// Handle WebSocket connection
async fn handle_socket(socket: WebSocket, state: AppState) {
    info!("New WebSocket connection established");
    
    let (mut sender, mut receiver) = socket.split();
    let (event_tx, mut event_rx) = broadcast::channel::<WsEvent>(100);
    
    // Store event sender in app state for broadcasting
    // (This would require adding broadcast::Sender to AppState)
    
    // Default subscription options
    let mut subscription_opts = SubscriptionOptions::default();
    
    // Spawn task to send events to client
    let send_task = tokio::spawn(async move {
        while let Ok(event) = event_rx.recv().await {
            let json = match serde_json::to_string(&event) {
                Ok(j) => j,
                Err(e) => {
                    error!("Failed to serialize event: {}", e);
                    continue;
                }
            };
            
            if sender.send(Message::Text(json)).await.is_err() {
                // Client disconnected
                break;
            }
        }
    });
    
    // Spawn task to handle VRAM monitoring
    let state_clone = state.clone();
    let event_tx_clone = event_tx.clone();
    let mut vram_task = tokio::spawn(async move {
        let mut interval = tokio::time::interval(
            tokio::time::Duration::from_secs(subscription_opts.update_interval_seconds)
        );
        
        loop {
            interval.tick().await;
            
            if !subscription_opts.vram_updates {
                continue;
            }
            
            // Get VRAM state
            let vram_monitor = state_clone.vram_monitor.read().await;
            let vram_state = vram_monitor.get_state();
            drop(vram_monitor);
            
            let event = WsEvent::VramUpdate {
                timestamp: chrono::Utc::now().to_rfc3339(),
                total_gb: vram_state.total_gb,
                used_gb: vram_state.used_gb,
                free_gb: vram_state.free_gb,
                utilization_percent: vram_state.utilization_percent,
            };
            
            if event_tx_clone.send(event).is_err() {
                // No receivers
                break;
            }
        }
    });
    
    // Handle incoming messages from client
    while let Some(Ok(msg)) = receiver.next().await {
        match msg {
            Message::Text(text) => {
                // Try to parse as subscription update
                if let Ok(new_opts) = serde_json::from_str::<SubscriptionOptions>(&text) {
                    info!("Updated subscription options: {:?}", new_opts);
                    subscription_opts = new_opts;
                    
                    // Restart VRAM task with new interval
                    vram_task.abort();
                    let state_clone = state.clone();
                    let event_tx_clone = event_tx.clone();
                    let opts = subscription_opts.clone();
                    vram_task = tokio::spawn(async move {
                        let mut interval = tokio::time::interval(
                            tokio::time::Duration::from_secs(opts.update_interval_seconds)
                        );
                        
                        loop {
                            interval.tick().await;
                            
                            if !opts.vram_updates {
                                continue;
                            }
                            
                            let vram_monitor = state_clone.vram_monitor.read().await;
                            let vram_state = vram_monitor.get_state();
                            drop(vram_monitor);
                            
                            let event = WsEvent::VramUpdate {
                                timestamp: chrono::Utc::now().to_rfc3339(),
                                total_gb: vram_state.total_gb,
                                used_gb: vram_state.used_gb,
                                free_gb: vram_state.free_gb,
                                utilization_percent: vram_state.utilization_percent,
                            };
                            
                            if event_tx_clone.send(event).is_err() {
                                break;
                            }
                        }
                    });
                } else {
                    warn!("Received unrecognized message: {}", text);
                }
            }
            Message::Close(_) => {
                info!("WebSocket connection closed by client");
                break;
            }
            Message::Ping(_data) => {
                // Respond to ping with pong
                // (axum handles this automatically)
                let _ = event_tx.send(WsEvent::Ping {
                    timestamp: chrono::Utc::now().to_rfc3339(),
                });
            }
            _ => {}
        }
    }
    
    // Cleanup
    send_task.abort();
    vram_task.abort();
    info!("WebSocket connection terminated");
}

/// Broadcast an event to all connected WebSocket clients
pub async fn broadcast_event(
    _state: &AppState,
    _event: WsEvent,
) -> anyhow::Result<()> {
    // TODO: Implement actual broadcasting
    // This requires storing the broadcast sender in AppState
    Ok(())
}
