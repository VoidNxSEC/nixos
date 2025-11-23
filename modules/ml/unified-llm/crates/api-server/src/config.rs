use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub redis: RedisConfig,
    pub providers: ProvidersConfig,
    pub security: SecurityConfig,
    pub telemetry: TelemetryConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub workers: usize,
    pub request_timeout_secs: u64,
    pub max_request_size_bytes: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub connect_timeout_secs: u64,
    pub idle_timeout_secs: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedisConfig {
    pub url: String,
    pub max_connections: u32,
    pub connect_timeout_secs: u64,
    pub ttl_secs: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProvidersConfig {
    pub deepseek: Option<ProviderConfig>,
    pub openai: Option<ProviderConfig>,
    pub anthropic: Option<ProviderConfig>,
    pub groq: Option<ProviderConfig>,
    pub cohere: Option<ProviderConfig>,
    pub llamacpp: Option<LlamaCppConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderConfig {
    pub enabled: bool,
    pub api_key: String,
    pub base_url: Option<String>,
    pub timeout_secs: u64,
    pub max_retries: u32,
    pub rate_limit_per_minute: u32,
    pub circuit_breaker: CircuitBreakerConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlamaCppConfig {
    pub enabled: bool,
    pub base_url: String,
    pub timeout_secs: u64,
    pub max_retries: u32,
    pub circuit_breaker: CircuitBreakerConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CircuitBreakerConfig {
    pub failure_threshold: u32,
    pub success_threshold: u32,
    pub timeout_secs: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    pub api_keys: Vec<String>,
    pub require_auth: bool,
    pub allowed_origins: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryConfig {
    pub metrics_enabled: bool,
    pub tracing_enabled: bool,
    pub log_level: String,
    pub otlp_endpoint: Option<String>,
}

impl Config {
    /// Load configuration from environment variables and config file
    pub fn load() -> Result<Self> {
        // Try to load from TOML file first
        let config_path = std::env::var("CONFIG_PATH")
            .unwrap_or_else(|_| "/etc/securellm/config.toml".to_string());

        let config = if PathBuf::from(&config_path).exists() {
            Self::from_file(&config_path)?
        } else {
            Self::from_env()?
        };

        // Validate configuration
        config.validate()?;

        Ok(config)
    }

    /// Load configuration from TOML file
    fn from_file(path: &str) -> Result<Self> {
        let content = std::fs::read_to_string(path)
            .context(format!("Failed to read config file: {}", path))?;
        
        toml::from_str(&content)
            .context("Failed to parse config file")
    }

    /// Load configuration from environment variables
    fn from_env() -> Result<Self> {
        Ok(Config {
            server: ServerConfig {
                host: std::env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
                port: std::env::var("SERVER_PORT")
                    .unwrap_or_else(|_| "8080".to_string())
                    .parse()
                    .context("Invalid SERVER_PORT")?,
                workers: std::env::var("SERVER_WORKERS")
                    .unwrap_or_else(|_| "4".to_string())
                    .parse()
                    .unwrap_or(4),
                request_timeout_secs: 30,
                max_request_size_bytes: 10 * 1024 * 1024, // 10MB
            },
            database: DatabaseConfig {
                url: std::env::var("DATABASE_URL")
                    .unwrap_or_else(|_| "sqlite:/var/lib/securellm/models.db".to_string()),
                max_connections: 10,
                min_connections: 2,
                connect_timeout_secs: 10,
                idle_timeout_secs: 600,
            },
            redis: RedisConfig {
                url: std::env::var("REDIS_URL")
                    .unwrap_or_else(|_| "redis://localhost:6379".to_string()),
                max_connections: 10,
                connect_timeout_secs: 5,
                ttl_secs: 3600,
            },
            providers: ProvidersConfig {
                deepseek: Self::load_provider_config("DEEPSEEK"),
                openai: Self::load_provider_config("OPENAI"),
                anthropic: Self::load_provider_config("ANTHROPIC"),
                groq: Self::load_provider_config("GROQ"),
                cohere: Self::load_provider_config("COHERE"),
                llamacpp: Self::load_llamacpp_config(),
            },
            security: SecurityConfig {
                api_keys: std::env::var("API_KEYS")
                    .unwrap_or_default()
                    .split(',')
                    .filter(|k| !k.is_empty())
                    .map(|k| k.to_string())
                    .collect(),
                require_auth: std::env::var("REQUIRE_AUTH")
                    .unwrap_or_else(|_| "false".to_string())
                    .parse()
                    .unwrap_or(false),
                allowed_origins: vec!["*".to_string()],
            },
            telemetry: TelemetryConfig {
                metrics_enabled: true,
                tracing_enabled: true,
                log_level: std::env::var("LOG_LEVEL").unwrap_or_else(|_| "info".to_string()),
                otlp_endpoint: std::env::var("OTLP_ENDPOINT").ok(),
            },
        })
    }

    fn load_provider_config(prefix: &str) -> Option<ProviderConfig> {
        let enabled = std::env::var(format!("{}_ENABLED", prefix))
            .unwrap_or_else(|_| "false".to_string())
            .parse()
            .unwrap_or(false);

        if !enabled {
            return None;
        }

        std::env::var(format!("{}_API_KEY", prefix)).ok().map(|api_key| {
            ProviderConfig {
                enabled,
                api_key,
                base_url: std::env::var(format!("{}_BASE_URL", prefix)).ok(),
                timeout_secs: 30,
                max_retries: 3,
                rate_limit_per_minute: 60,
                circuit_breaker: CircuitBreakerConfig {
                    failure_threshold: 5,
                    success_threshold: 2,
                    timeout_secs: 60,
                },
            }
        })
    }

    fn load_llamacpp_config() -> Option<LlamaCppConfig> {
        let enabled = std::env::var("LLAMACPP_ENABLED")
            .unwrap_or_else(|_| "true".to_string())
            .parse()
            .unwrap_or(true);

        if !enabled {
            return None;
        }

        Some(LlamaCppConfig {
            enabled,
            base_url: std::env::var("LLAMACPP_BASE_URL")
                .unwrap_or_else(|_| "http://localhost:5001".to_string()),
            timeout_secs: 60,
            max_retries: 3,
            circuit_breaker: CircuitBreakerConfig {
                failure_threshold: 5,
                success_threshold: 2,
                timeout_secs: 60,
            },
        })
    }

    /// Validate configuration
    fn validate(&self) -> Result<()> {
        if self.server.port == 0 {
            anyhow::bail!("Server port must be greater than 0");
        }

        if self.server.workers == 0 {
            anyhow::bail!("Server workers must be greater than 0");
        }

        // Check if at least one provider is enabled
        let has_provider = self.providers.deepseek.as_ref().map(|p| p.enabled).unwrap_or(false)
            || self.providers.openai.as_ref().map(|p| p.enabled).unwrap_or(false)
            || self.providers.anthropic.as_ref().map(|p| p.enabled).unwrap_or(false)
            || self.providers.groq.as_ref().map(|p| p.enabled).unwrap_or(false)
            || self.providers.cohere.as_ref().map(|p| p.enabled).unwrap_or(false)
            || self.providers.llamacpp.as_ref().map(|p| p.enabled).unwrap_or(false);

        if !has_provider {
            anyhow::bail!("At least one provider must be enabled");
        }

        Ok(())
    }
}

impl Default for Config {
    fn default() -> Self {
        Self::from_env().expect("Failed to load default config")
    }
}