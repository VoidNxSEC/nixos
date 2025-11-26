import type { RateLimitConfig, RateLimitMetrics } from '../types/middleware/rate-limiter.js';
/**
 * Smart Rate Limiter - Phase 1.3 Implementation
 *
 * Features:
 * - Per-provider request queuing (FIFO)
 * - Simple delay-based rate limiting
 * - Basic error handling and wrapping
 * - Circuit breaker pattern (Phase 1.2)
 * - Exponential backoff with jitter (Phase 1.3)
 * - Intelligent retry logic (Phase 1.3)
 */
export declare class SmartRateLimiter {
    private configs;
    private queues;
    private metricsCollectors;
    private circuitBreakers;
    private retryStrategies;
    constructor(configs: Map<string, RateLimitConfig>);
    /**
     * Execute a function with rate limiting, circuit breaker protection, and retry logic
     *
     * @param provider - The provider name (e.g., 'deepseek', 'openai')
     * @param fn - The async function to execute
     * @returns Promise resolving to the function result
     */
    execute<T>(provider: string, fn: () => Promise<T>): Promise<T>;
    /**
     * Execute a function through the request queue
     * (Extracted from previous execute method for retry logic)
     */
    private executeWithQueue;
    /**
     * Process the request queue for a provider
     */
    private processQueue;
    /**
     * Calculate delay needed before next request
     */
    private calculateDelay;
    /**
     * Update metrics for a provider
     * @deprecated This method is no longer used - MetricsCollector handles all metrics
     */
    private updateMetrics;
    /**
     * Update retry metrics when a request required retries
     * @deprecated This method is no longer used - MetricsCollector handles all metrics
     */
    private updateRetryMetrics;
    /**
     * Wrap error with additional context
     */
    private wrapError;
    /**
     * Get current metrics for a provider
     */
    getMetrics(provider: string): RateLimitMetrics | undefined;
    /**
     * Get all metrics
     */
    getAllMetrics(): Map<string, RateLimitMetrics>;
    /**
     * Get queue status for a provider
     */
    getQueueStatus(provider: string): {
        queueLength: number;
        processing: boolean;
    } | undefined;
    /**
     * Generate a unique request ID
     */
    private generateRequestId;
    /**
     * Sleep for specified milliseconds
     */
    private sleep;
}
//# sourceMappingURL=rate-limiter.d.ts.map