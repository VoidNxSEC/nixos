// Type definitions for Rate Limiting Middleware
/**
 * Error thrown when rate limit is exceeded
 */
export class RateLimitError extends Error {
    provider;
    retryAfter;
    constructor(message, provider, retryAfter) {
        super(message);
        this.provider = provider;
        this.retryAfter = retryAfter;
        this.name = 'RateLimitError';
    }
}
/**
 * Error thrown when circuit breaker is open
 */
export class CircuitBreakerError extends Error {
    provider;
    resetTime;
    constructor(message, provider, resetTime) {
        super(message);
        this.provider = provider;
        this.resetTime = resetTime;
        this.name = 'CircuitBreakerError';
    }
}
/**
 * Re-export error classification types from error-classifier
 */
export { ErrorCategory } from '../../middleware/error-classifier.js';
//# sourceMappingURL=rate-limiter.js.map