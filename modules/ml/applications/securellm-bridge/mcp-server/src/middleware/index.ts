// Middleware exports

export { SmartRateLimiter } from './rate-limiter.js';
export { CircuitBreaker } from './circuit-breaker.js';
export { RetryStrategy } from './retry-strategy.js';
export { ErrorClassifier, ErrorCategory } from './error-classifier.js';
export { MetricsCollector } from './metrics-collector.js';

export type {
  RateLimitConfig,
  RequestQueue,
  QueuedRequest,
  RateLimitMetrics,
  CircuitBreaker as CircuitBreakerType,
  CircuitBreakerState,
  CircuitBreakerMetrics,
  ErrorClassification,
} from '../types/middleware/rate-limiter.js';

export {
  RateLimitError,
  CircuitBreakerError,
} from '../types/middleware/rate-limiter.js';