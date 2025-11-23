# SecureLLM API Server

OpenAI-compatible API server for unified LLM management across multiple providers.

## Features

- **OpenAI-Compatible API**: Drop-in replacement for OpenAI API
- **Multi-Provider Support**: DeepSeek, OpenAI, Anthropic, Groq, Cohere, llama.cpp/KoboldCPP
- **Advanced Reliability**: Circuit breakers, retry logic, failover
- **Production-Ready**: Connection pooling, rate limiting, caching
- **Observable**: Prometheus metrics, OpenTelemetry tracing, structured logging
- **Scalable**: SQLite registry, Redis caching, async architecture

## API Endpoints

### OpenAI-Compatible

- `GET /v1/models` - List all available models
- `POST /v1/chat/completions` - Chat completions (supports streaming)
- `POST /v1/completions` - Text completions

### Management

- `GET /api/health` - Detailed health check
- `GET /api/ready` - Readiness probe (K8s)
- `GET /api/metrics` - Prometheus metrics
- `POST /api/models/sync` - Trigger model discovery

## Configuration

### Environment Variables

See [`.env.example`](.env.example) for all available configuration options.

Key variables:
- `SERVER_PORT` - Server port (default: 8080)
- `DATABASE_URL` - SQLite database path
- `REDIS_URL` - Redis connection string
- `{PROVIDER}_ENABLED` - Enable/disable providers
- `{PROVIDER}_API_KEY` - API keys for cloud providers
- `LLAMACPP_BASE_URL` - URL for local llama.cpp server

### Configuration File (Optional)

Alternatively, use a TOML configuration file:

```bash
export CONFIG_PATH=/etc/securellm/config.toml
```

## Development

### Build

```bash
cargo build --release
```

### Run

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your settings

# Run server
cargo run --release
```

### Database Migrations

Migrations run automatically on startup using sqlx.

To create new migrations:

```bash
sqlx migrate add <migration_name>
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      API Server (Axum)                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ OpenAI-Compatible Endpoints (/v1/*)                    │ │
│  │  - models, chat/completions, completions               │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Management Endpoints (/api/*)                          │ │
│  │  - health, ready, metrics, models/sync                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                 │
│  ┌─────────────────────────▼──────────────────────────────┐ │
│  │          Provider Manager + Circuit Breakers           │ │
│  │  ┌──────────┬──────────┬──────────┬──────────────────┐ │ │
│  │  │ DeepSeek │ OpenAI   │ Anthropic│ llama.cpp/Kobold │ │ │
│  │  └──────────┴──────────┴──────────┴──────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                 │
│  ┌────────────┬────────────▼────────────┬─────────────────┐ │
│  │  SQLite    │   Redis Cache/Rate      │  Prometheus     │ │
│  │  Registry  │   Limiting              │  Metrics        │ │
│  └────────────┴─────────────────────────┴─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Deployment

See the `model-api` kit in the parent repository for Docker deployment.

## License

See root LICENSE file.