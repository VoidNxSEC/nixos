/// Inference endpoints module
///
/// Provides OpenAI-compatible API endpoints for:
/// - Chat completions (POST /v1/chat/completions)
/// - Embeddings (POST /v1/embeddings)
///
/// These endpoints proxy to the active backend (llama.cpp, vLLM, TGI)

use axum::{
    extract::State,
    http::StatusCode,
    response::{
        sse::{Event, KeepAlive},
        IntoResponse, Response, Sse,
    },
    Json,
};
use futures::stream::{self, Stream};
use serde::{Deserialize, Serialize};
use std::convert::Infallible;
use tracing::{info, warn};

use crate::backends::llamacpp::LlamaCppBackend;
use crate::AppState;

// =============================================================================
// Chat Completions API
// =============================================================================

#[derive(Debug, Deserialize, Serialize)]
pub struct ChatCompletionRequest {
    /// ID of the model to use
    pub model: String,
    
    /// Messages in the conversation
    pub messages: Vec<ChatMessage>,
    
    /// Temperature (0.0 to 2.0)
    #[serde(default = "default_temperature")]
    pub temperature: f32,
    
    /// Maximum tokens to generate
    #[serde(default)]
    pub max_tokens: Option<u32>,
    
    /// Whether to stream the response
    #[serde(default)]
    pub stream: bool,
    
    /// Stop sequences
    #[serde(default)]
    pub stop: Option<Vec<String>>,
    
    /// Top-p sampling
    #[serde(default)]
    pub top_p: Option<f32>,
    
    /// Frequency penalty
    #[serde(default)]
    pub frequency_penalty: Option<f32>,
    
    /// Presence penalty
    #[serde(default)]
    pub presence_penalty: Option<f32>,
    
    /// Number of completions to generate
    #[serde(default = "default_n")]
    pub n: u32,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ChatMessage {
    /// Role: "system", "user", "assistant"
    pub role: String,
    
    /// Message content
    pub content: String,
    
    /// Optional name of the message author
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ChatCompletionResponse {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub model: String,
    pub choices: Vec<ChatChoice>,
    pub usage: Usage,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ChatChoice {
    pub index: u32,
    pub message: ChatMessage,
    pub finish_reason: String,
}

#[derive(Debug, Serialize)]
pub struct ChatCompletionChunk {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub model: String,
    pub choices: Vec<ChatChoiceDelta>,
}

#[derive(Debug, Serialize)]
pub struct ChatChoiceDelta {
    pub index: u32,
    pub delta: ChatMessageDelta,
    pub finish_reason: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ChatMessageDelta {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub role: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub content: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Usage {
    pub prompt_tokens: u32,
    pub completion_tokens: u32,
    pub total_tokens: u32,
}

fn default_temperature() -> f32 {
    0.7
}

fn default_n() -> u32 {
    1
}

// =============================================================================
// Embeddings API
// =============================================================================

#[derive(Debug, Deserialize, Serialize)]
pub struct EmbeddingsRequest {
    /// ID of the model to use
    pub model: String,
    
    /// Input text(s) to embed
    pub input: EmbeddingInput,
    
    /// Encoding format (default: "float")
    #[serde(default = "default_encoding_format")]
    pub encoding_format: String,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum EmbeddingInput {
    Single(String),
    Multiple(Vec<String>),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EmbeddingsResponse {
    pub object: String,
    pub data: Vec<EmbeddingData>,
    pub model: String,
    pub usage: EmbeddingUsage,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EmbeddingData {
    pub object: String,
    pub embedding: Vec<f32>,
    pub index: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EmbeddingUsage {
    pub prompt_tokens: u32,
    pub total_tokens: u32,
}

fn default_encoding_format() -> String {
    "float".to_string()
}

// =============================================================================
// Handlers
// =============================================================================

pub async fn chat_completions_handler(
    State(state): State<AppState>,
    Json(request): Json<ChatCompletionRequest>,
) -> Response {
    info!("Chat completion request for model: {}", request.model);
    
    // Validate request
    if request.messages.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({
                "error": {
                    "message": "messages array cannot be empty",
                    "type": "invalid_request_error"
                }
            })),
        ).into_response();
    }
    
    if request.stream {
        // Return SSE stream
        streaming_response(state, request).await.into_response()
    } else {
        // Return single response
        match non_streaming_response(state, request).await {
            Ok(response) => response.into_response(),
            Err(err) => err.into_response(),
        }
    }
}

async fn non_streaming_response(
    _state: AppState,
    request: ChatCompletionRequest,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    // Create llamacpp backend client
    let backend = match LlamaCppBackend::with_defaults() {
        Ok(b) => b,
        Err(e) => {
            warn!("Failed to create llamacpp backend: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": {
                        "message": "Failed to initialize backend",
                        "type": "internal_error"
                    }
                })),
            ));
        }
    };
    
    // Convert request to JSON for proxying
    let request_json = serde_json::to_value(&request).unwrap();
    
    // Proxy to llama-server
    match backend.proxy_chat_completion(request_json).await {
        Ok(response) => {
            let status = response.status();
            let body = response.bytes().await.unwrap_or_default();
            
            if status.is_success() {
                // Parse and return the response
                match serde_json::from_slice::<ChatCompletionResponse>(&body) {
                    Ok(chat_response) => Ok(Json(chat_response)),
                    Err(e) => {
                        warn!("Failed to parse llama-server response: {}", e);
                        Err((
                            StatusCode::INTERNAL_SERVER_ERROR,
                            Json(serde_json::json!({
                                "error": {
                                    "message": "Failed to parse backend response",
                                    "type": "internal_error"
                                }
                            })),
                        ))
                    }
                }
            } else {
                warn!("llama-server returned error: {}", status);
                Err((
                    StatusCode::BAD_GATEWAY,
                    Json(serde_json::json!({
                        "error": {
                            "message": "Backend returned error",
                            "type": "backend_error"
                        }
                    })),
                ))
            }
        }
        Err(e) => {
            warn!("Failed to proxy to llama-server: {}", e);
            Err((
                StatusCode::BAD_GATEWAY,
                Json(serde_json::json!({
                    "error": {
                        "message": "Failed to connect to backend",
                        "type": "connection_error"
                    }
                })),
            ))
        }
    }
}

async fn streaming_response(
    _state: AppState,
    request: ChatCompletionRequest,
) -> impl IntoResponse {
    let model = request.model.clone();
    let id = format!("chatcmpl-{}", uuid::Uuid::new_v4());
    let created = chrono::Utc::now().timestamp();
    
    // Create a stream of SSE events
    let stream = stream::iter(vec![
        // Initial chunk with role
        Ok::<_, Infallible>(Event::default().json_data(ChatCompletionChunk {
            id: id.clone(),
            object: "chat.completion.chunk".to_string(),
            created,
            model: model.clone(),
            choices: vec![ChatChoiceDelta {
                index: 0,
                delta: ChatMessageDelta {
                    role: Some("assistant".to_string()),
                    content: None,
                },
                finish_reason: None,
            }],
        }).unwrap()),
        // Content chunks
        Ok(Event::default().json_data(ChatCompletionChunk {
            id: id.clone(),
            object: "chat.completion.chunk".to_string(),
            created,
            model: model.clone(),
            choices: vec![ChatChoiceDelta {
                index: 0,
                delta: ChatMessageDelta {
                    role: None,
                    content: Some("[Mock Stream] ".to_string()),
                },
                finish_reason: None,
            }],
        }).unwrap()),
        Ok(Event::default().json_data(ChatCompletionChunk {
            id: id.clone(),
            object: "chat.completion.chunk".to_string(),
            created,
            model: model.clone(),
            choices: vec![ChatChoiceDelta {
                index: 0,
                delta: ChatMessageDelta {
                    role: None,
                    content: Some("Streaming response is under development.".to_string()),
                },
                finish_reason: None,
            }],
        }).unwrap()),
        // Final chunk
        Ok(Event::default().json_data(ChatCompletionChunk {
            id: id.clone(),
            object: "chat.completion.chunk".to_string(),
            created,
            model: model.clone(),
            choices: vec![ChatChoiceDelta {
                index: 0,
                delta: ChatMessageDelta {
                    role: None,
                    content: None,
                },
                finish_reason: Some("stop".to_string()),
            }],
        }).unwrap()),
        Ok(Event::default().data("[DONE]")),
    ]);
    
    Sse::new(stream).keep_alive(KeepAlive::default())
}

pub async fn embeddings_handler(
    State(_state): State<AppState>,
    Json(request): Json<EmbeddingsRequest>,
) -> Result<Json<EmbeddingsResponse>, (StatusCode, Json<serde_json::Value>)> {
    info!("Embeddings request for model: {}", request.model);
    
    // Create llamacpp backend client
    let backend = match LlamaCppBackend::with_defaults() {
        Ok(b) => b,
        Err(e) => {
            warn!("Failed to create llamacpp backend: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": {
                        "message": "Failed to initialize backend",
                        "type": "internal_error"
                    }
                })),
            ));
        }
    };
    
    // Convert request to JSON for proxying
    let request_json = serde_json::to_value(&request).unwrap();
    
    // Proxy to llama-server
    match backend.proxy_embeddings(request_json).await {
        Ok(response) => {
            let status = response.status();
            let body = response.bytes().await.unwrap_or_default();
            
            if status.is_success() {
                // Parse and return the response
                match serde_json::from_slice::<EmbeddingsResponse>(&body) {
                    Ok(embeddings_response) => Ok(Json(embeddings_response)),
                    Err(e) => {
                        warn!("Failed to parse llama-server embeddings response: {}", e);
                        Err((
                            StatusCode::INTERNAL_SERVER_ERROR,
                            Json(serde_json::json!({
                                "error": {
                                    "message": "Failed to parse backend response",
                                    "type": "internal_error"
                                }
                            })),
                        ))
                    }
                }
            } else {
                warn!("llama-server returned error for embeddings: {}", status);
                Err((
                    StatusCode::BAD_GATEWAY,
                    Json(serde_json::json!({
                        "error": {
                            "message": "Backend returned error",
                            "type": "backend_error"
                        }
                    })),
                ))
            }
        }
        Err(e) => {
            warn!("Failed to proxy embeddings to llama-server: {}", e);
            Err((
                StatusCode::BAD_GATEWAY,
                Json(serde_json::json!({
                    "error": {
                        "message": "Failed to connect to backend",
                        "type": "connection_error"
                    }
                })),
            ))
        }
    }
}

// =============================================================================
// Models List (OpenAI compatible)
// =============================================================================

#[derive(Debug, Serialize)]
pub struct ModelsListResponse {
    pub object: String,
    pub data: Vec<ModelInfo>,
}

#[derive(Debug, Serialize)]
pub struct ModelInfo {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub owned_by: String,
}

pub async fn list_models_openai_handler(
    State(state): State<AppState>,
) -> Result<Json<ModelsListResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Get models from database
    match state.db.list_models(None, None, 100).await {
        Ok(models) => {
            let data = models
                .into_iter()
                .map(|m| ModelInfo {
                    id: m.name,
                    object: "model".to_string(),
                    created: chrono::Utc::now().timestamp(),
                    owned_by: "ml-offload".to_string(),
                })
                .collect();
            
            Ok(Json(ModelsListResponse {
                object: "list".to_string(),
                data,
            }))
        }
        Err(e) => {
            warn!("Error listing models: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": {
                        "message": "Failed to list models",
                        "type": "internal_error"
                    }
                })),
            ))
        }
    }
}
