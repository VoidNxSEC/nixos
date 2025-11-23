use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{info, warn};

use crate::{error::ApiResult, state::AppState};

/// OpenAI-compatible text completion request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletionRequest {
    pub model: String,
    pub prompt: String,
    #[serde(default)]
    pub max_tokens: Option<u32>,
    #[serde(default)]
    pub temperature: Option<f32>,
    #[serde(default)]
    pub top_p: Option<f32>,
    #[serde(default)]
    pub n: Option<u32>,
    #[serde(default)]
    pub stream: Option<bool>,
    #[serde(default)]
    pub stop: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletionResponse {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub model: String,
    pub choices: Vec<CompletionChoice>,
    pub usage: CompletionUsage,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletionChoice {
    pub text: String,
    pub index: u32,
    pub logprobs: Option<serde_json::Value>,
    pub finish_reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletionUsage {
    pub prompt_tokens: u32,
    pub completion_tokens: u32,
    pub total_tokens: u32,
}

/// POST /v1/completions - Text completion endpoint
pub async fn text_completions(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CompletionRequest>,
) -> ApiResult<Json<CompletionResponse>> {
    info!("Text completion request: model={}, prompt_len={}", req.model, req.prompt.len());

    // TODO: Implement actual completion logic
    warn!("Using mock response - completion implementation pending");

    let completion_id = format!("cmpl-{}", uuid::Uuid::new_v4());
    let created = chrono::Utc::now().timestamp();

    Ok(Json(CompletionResponse {
        id: completion_id,
        object: "text_completion".to_string(),
        created,
        model: req.model.clone(),
        choices: vec![CompletionChoice {
            text: "This is a mock completion. Implementation pending.".to_string(),
            index: 0,
            logprobs: None,
            finish_reason: Some("stop".to_string()),
        }],
        usage: CompletionUsage {
            prompt_tokens: 10,
            completion_tokens: 15,
            total_tokens: 25,
        },
    }))
}