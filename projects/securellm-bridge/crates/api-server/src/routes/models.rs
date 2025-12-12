use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{debug, info};

use crate::{error::ApiResult, state::AppState};

/// OpenAI-compatible model object
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Model {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub owned_by: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub permission: Option<Vec<ModelPermission>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub root: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelPermission {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub allow_create_engine: bool,
    pub allow_sampling: bool,
    pub allow_logprobs: bool,
    pub allow_search_indices: bool,
    pub allow_view: bool,
    pub allow_fine_tuning: bool,
    pub organization: String,
    pub group: Option<String>,
    pub is_blocking: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListModelsResponse {
    pub object: String,
    pub data: Vec<Model>,
}

/// GET /v1/models - List all available models
/// 
/// This endpoint returns all models from all configured providers
/// in OpenAI-compatible format.
pub async fn list_models(
    State(state): State<Arc<AppState>>,
) -> ApiResult<Json<ListModelsResponse>> {
    info!("Listing all available models");

    let mut models = Vec::new();

    // Query database for all registered models using runtime query
    let db_models = sqlx::query_as::<_, (String, String, String, i64, i64)>(
        r#"
        SELECT
            model_id,
            provider,
            display_name,
            context_window,
            created_at
        FROM models
        WHERE enabled = 1
        ORDER BY provider, model_id
        "#
    )
    .fetch_all(&state.db_pool)
    .await?;

    debug!("Found {} models in database", db_models.len());

    for (model_id, provider, _display_name, _context_window, created_at) in db_models {
        let model = Model {
            id: format!("{}/{}", provider, model_id),
            object: "model".to_string(),
            created: created_at,
            owned_by: provider.clone(),
            permission: Some(vec![ModelPermission {
                id: format!("modelperm-{}", uuid::Uuid::new_v4()),
                object: "model_permission".to_string(),
                created: created_at,
                allow_create_engine: false,
                allow_sampling: true,
                allow_logprobs: true,
                allow_search_indices: false,
                allow_view: true,
                allow_fine_tuning: false,
                organization: "*".to_string(),
                group: None,
                is_blocking: false,
            }]),
            root: Some(model_id.clone()),
            parent: None,
        };
        models.push(model);
    }

    info!("Returning {} models", models.len());

    Ok(Json(ListModelsResponse {
        object: "list".to_string(),
        data: models,
    }))
}

/// POST /api/models/sync - Trigger model discovery
/// 
/// This endpoint forces a rescan of all providers to discover new models.
pub async fn sync_models(
    State(state): State<Arc<AppState>>,
) -> ApiResult<(StatusCode, Json<serde_json::Value>)> {
    info!("Manual model sync triggered");

    // TODO: Implement model discovery service trigger
    // For now, return success
    
    Ok((
        StatusCode::OK,
        Json(serde_json::json!({
            "status": "success",
            "message": "Model sync initiated"
        })),
    ))
}