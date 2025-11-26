import { RateLimitConfig } from '../types/middleware/rate-limiter.js';

/**
 * Rate limit configurations for different API providers and operations
 * 
 * Adjust these values based on actual API limits and usage patterns.
 * These are conservative defaults to prevent hitting rate limits.
 */
export const RATE_LIMIT_CONFIGS: Record<string, RateLimitConfig> = {
  // OpenAI API limits (60 req/min for GPT-4)
  openai: {
    provider: 'openai',
    requestsPerMinute: 60,
    burstSize: 10,
    retryStrategy: 'exponential',
    maxRetries: 3,
    circuitBreaker: {
      failureThreshold: 5,
      resetTimeout: 60000, // 1 minute
    },
  },

  // Anthropic API limits (50 req/min)
  anthropic: {
    provider: 'anthropic',
    requestsPerMinute: 50,
    burstSize: 8,
    retryStrategy: 'exponential',
    maxRetries: 3,
    circuitBreaker: {
      failureThreshold: 5,
      resetTimeout: 60000,
    },
  },

  // DeepSeek API limits (60 req/min)
  deepseek: {
    provider: 'deepseek',
    requestsPerMinute: 60,
    burstSize: 10,
    retryStrategy: 'exponential',
    maxRetries: 3,
    circuitBreaker: {
      failureThreshold: 5,
      resetTimeout: 60000,
    },
  },

  // Ollama (local) - high limits since it's local
  ollama: {
    provider: 'ollama',
    requestsPerMinute: 300,
    burstSize: 50,
    retryStrategy: 'exponential',
    maxRetries: 2,
    circuitBreaker: {
      failureThreshold: 10,
      resetTimeout: 30000,
    },
  },

  // Build operations (prevent build spam)
  build: {
    provider: 'build',
    requestsPerMinute: 10,
    burstSize: 2,
    retryStrategy: 'exponential',
    maxRetries: 1,
    circuitBreaker: {
      failureThreshold: 3,
      resetTimeout: 120000, // 2 minutes
    },
  },

  // Crypto operations (key generation is expensive)
  crypto: {
    provider: 'crypto',
    requestsPerMinute: 5,
    burstSize: 2,
    retryStrategy: 'exponential',
    maxRetries: 2,
    circuitBreaker: {
      failureThreshold: 3,
      resetTimeout: 60000,
    },
  },

  // Database operations (high limits for local SQLite)
  database: {
    provider: 'database',
    requestsPerMinute: 1000,
    burstSize: 100,
    retryStrategy: 'exponential',
    maxRetries: 2,
    circuitBreaker: {
      failureThreshold: 20,
      resetTimeout: 30000,
    },
  },

  // Generic/default limits for unknown providers
  default: {
    provider: 'default',
    requestsPerMinute: 30,
    burstSize: 5,
    retryStrategy: 'exponential',
    maxRetries: 3,
    circuitBreaker: {
      failureThreshold: 5,
      resetTimeout: 60000,
    },
  },
};