-- Initial schema for model management

CREATE TABLE IF NOT EXISTS models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_id TEXT NOT NULL,
    provider TEXT NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    context_window INTEGER NOT NULL DEFAULT 4096,
    max_tokens INTEGER,
    input_cost_per_1k REAL,
    output_cost_per_1k REAL,
    enabled BOOLEAN NOT NULL DEFAULT 1,
    capabilities TEXT, -- JSON array of capabilities (chat, completion, embedding, etc.)
    metadata TEXT, -- JSON object for additional metadata
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_seen_at INTEGER,
    UNIQUE(provider, model_id)
);

CREATE INDEX IF NOT EXISTS idx_models_provider ON models(provider);
CREATE INDEX IF NOT EXISTS idx_models_enabled ON models(enabled);
CREATE INDEX IF NOT EXISTS idx_models_provider_enabled ON models(provider, enabled);

-- Full-text search index for models
CREATE VIRTUAL TABLE IF NOT EXISTS models_fts USING fts5(
    model_id,
    display_name,
    description,
    content='models',
    content_rowid='id'
);

-- Triggers to keep FTS index in sync
CREATE TRIGGER IF NOT EXISTS models_fts_insert AFTER INSERT ON models BEGIN
    INSERT INTO models_fts(rowid, model_id, display_name, description)
    VALUES (new.id, new.model_id, new.display_name, new.description);
END;

CREATE TRIGGER IF NOT EXISTS models_fts_delete AFTER DELETE ON models BEGIN
    DELETE FROM models_fts WHERE rowid = old.id;
END;

CREATE TRIGGER IF NOT EXISTS models_fts_update AFTER UPDATE ON models BEGIN
    DELETE FROM models_fts WHERE rowid = old.id;
    INSERT INTO models_fts(rowid, model_id, display_name, description)
    VALUES (new.id, new.model_id, new.display_name, new.description);
END;

-- Trigger to update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS models_updated_at AFTER UPDATE ON models BEGIN
    UPDATE models SET updated_at = strftime('%s', 'now') WHERE id = new.id;
END;

-- Provider health tracking
CREATE TABLE IF NOT EXISTS provider_health (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'unknown', -- healthy, degraded, unhealthy, unknown
    circuit_breaker_state TEXT NOT NULL DEFAULT 'closed', -- closed, open, half_open
    failure_count INTEGER NOT NULL DEFAULT 0,
    success_count INTEGER NOT NULL DEFAULT 0,
    last_success_at INTEGER,
    last_failure_at INTEGER,
    last_error TEXT,
    average_latency_ms REAL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_provider_health_status ON provider_health(status);

-- Request logs for analytics
CREATE TABLE IF NOT EXISTS request_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id TEXT NOT NULL UNIQUE,
    provider TEXT NOT NULL,
    model_id TEXT NOT NULL,
    endpoint TEXT NOT NULL, -- /v1/chat/completions, /v1/completions, etc.
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    total_tokens INTEGER,
    cost_usd REAL,
    latency_ms INTEGER,
    status TEXT NOT NULL, -- success, error, timeout
    error_message TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_request_logs_provider ON request_logs(provider);
CREATE INDEX IF NOT EXISTS idx_request_logs_model ON request_logs(model_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_created_at ON request_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_request_logs_status ON request_logs(status);

-- Cache for responses (optional, Redis is primary cache)
CREATE TABLE IF NOT EXISTS response_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cache_key TEXT NOT NULL UNIQUE,
    provider TEXT NOT NULL,
    model_id TEXT NOT NULL,
    request_hash TEXT NOT NULL,
    response_data TEXT NOT NULL, -- JSON
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    expires_at INTEGER NOT NULL,
    hit_count INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_response_cache_expires_at ON response_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_response_cache_request_hash ON response_cache(request_hash);