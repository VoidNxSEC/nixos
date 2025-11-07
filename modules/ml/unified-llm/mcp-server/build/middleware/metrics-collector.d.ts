import { ErrorCategory } from './error-classifier.js';
import type { RateLimitMetrics } from '../types/middleware/rate-limiter.js';
/**
 * Collects and aggregates metrics with statistical analysis
 */
export declare class MetricsCollector {
    private latencies;
    private errorCounts;
    private queueLengths;
    private queueTimes;
    private totalRequests;
    private successfulRequests;
    private failedRequests;
    private retriedRequests;
    private totalRetries;
    private circuitBreakerActivations;
    private startTime;
    private readonly maxSamples;
    constructor();
    /**
     * Record a successful request
     */
    recordSuccess(latencyMs: number): void;
    /**
     * Record a failed request
     */
    recordFailure(latencyMs: number, errorCategory?: ErrorCategory): void;
    /**
     * Record a retry attempt
     */
    recordRetry(isFirstRetry: boolean): void;
    /**
     * Record circuit breaker activation
     */
    recordCircuitBreakerTrip(): void;
    /**
     * Record queue metrics
     */
    recordQueueMetrics(queueLength: number, timeInQueueMs: number): void;
    /**
     * Record latency sample
     */
    private recordLatency;
    /**
     * Calculate latency percentiles
     */
    private calculatePercentiles;
    /**
     * Calculate average
     */
    private average;
    /**
     * Get current metrics snapshot
     */
    getMetrics(): RateLimitMetrics;
    /**
     * Reset all metrics
     */
    reset(): void;
}
//# sourceMappingURL=metrics-collector.d.ts.map