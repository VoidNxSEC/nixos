// Type definitions for Rate Limiting Middleware

/**
 * Configuration for rate limiting a specific provider
 */
export interface RateLimitConfig {
  provider: string;
  requestsPerMinute: number;
  burstSize: number;
  retryStrategy: 'exponential' | 'linear' | 'fibonacci';
  maxRetries: number;
  circuitBreaker: {
    failureThreshold: number;
    resetTimeout: number;
  };
}

/**
 * State of circuit breaker for a provider
 */
export type CircuitBreakerState = 'closed' | 'open' | 'half-open';

/**
 * Queued request with metadata
 */
export interface QueuedRequest<T> {
  id: string;
  fn: () => Promise<T>;
  resolve: (value: T) => void;
  reject: (error: Error) => void;
  timestamp: number;
  provider: string;
}

/**
 * Request queue for managing provider requests
 */
export interface RequestQueue {
  queue: QueuedRequest<any>[];
  processing: boolean;
  lastRequestTime: number;
}

/**
 * Circuit breaker tracking for a provider
 */
export interface CircuitBreaker {
  state: CircuitBreakerState;
  failureCount: number;
  lastFailureTime: number;
  lastStateChange: number;
}

/**
 * Metrics for circuit breaker status
 */
export interface CircuitBreakerMetrics {
  state: CircuitBreakerState;
  failureCount: number;
  successCount: number;
  lastFailureTime: number;
  nextAttemptTime: number;
}

/**
 * Metrics tracked for rate limiting performance
 */
export interface RateLimitMetrics {
  provider?: string;
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  retriedRequests: number;
  totalRetries: number;
  averageLatency: number;
  circuitBreakerActivations: number;
  lastRequestTime?: number;
  
  // Enhanced metrics
  errorsByCategory: {
    transient: number;
    rate_limit: number;
    permanent: number;
    server_error: number;
    unknown: number;
  };
  latencyPercentiles: {
    p50: number;
    p95: number;
    p99: number;
    max: number;
  };
  requestsPerMinute: number;
  queueMetrics: {
    averageQueueLength: number;
    maxQueueLength: number;
    totalTimeInQueue: number;
  };
  timeWindow: {
    startTime: number;
    endTime: number;
    durationMs: number;
  };
}

/**
 * Error thrown when rate limit is exceeded
 */
export class RateLimitError extends Error {
  constructor(
    message: string,
    public provider: string,
    public retryAfter?: number
  ) {
    super(message);
    this.name = 'RateLimitError';
  }
}

/**
 * Error thrown when circuit breaker is open
 */
export class CircuitBreakerError extends Error {
  constructor(
    message: string,
    public provider: string,
    public resetTime: number
  ) {
    super(message);
    this.name = 'CircuitBreakerError';
  }
}

/**
 * Re-export error classification types from error-classifier
 */
export { ErrorCategory, ErrorClassification } from '../../middleware/error-classifier.js';