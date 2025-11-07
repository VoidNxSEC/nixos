/**
 * Collects and aggregates metrics with statistical analysis
 */
export class MetricsCollector {
    latencies = [];
    errorCounts = {
        transient: 0,
        rate_limit: 0,
        permanent: 0,
        server_error: 0,
        unknown: 0,
    };
    queueLengths = [];
    queueTimes = [];
    totalRequests = 0;
    successfulRequests = 0;
    failedRequests = 0;
    retriedRequests = 0;
    totalRetries = 0;
    circuitBreakerActivations = 0;
    startTime;
    maxSamples = 1000; // Keep last 1000 samples for percentiles
    constructor() {
        this.startTime = Date.now();
    }
    /**
     * Record a successful request
     */
    recordSuccess(latencyMs) {
        this.totalRequests++;
        this.successfulRequests++;
        this.recordLatency(latencyMs);
    }
    /**
     * Record a failed request
     */
    recordFailure(latencyMs, errorCategory) {
        this.totalRequests++;
        this.failedRequests++;
        this.recordLatency(latencyMs);
        if (errorCategory) {
            this.errorCounts[errorCategory]++;
        }
    }
    /**
     * Record a retry attempt
     */
    recordRetry(isFirstRetry) {
        this.totalRetries++;
        if (isFirstRetry) {
            this.retriedRequests++;
        }
    }
    /**
     * Record circuit breaker activation
     */
    recordCircuitBreakerTrip() {
        this.circuitBreakerActivations++;
    }
    /**
     * Record queue metrics
     */
    recordQueueMetrics(queueLength, timeInQueueMs) {
        this.queueLengths.push(queueLength);
        this.queueTimes.push(timeInQueueMs);
        // Keep only recent samples
        if (this.queueLengths.length > this.maxSamples) {
            this.queueLengths.shift();
        }
        if (this.queueTimes.length > this.maxSamples) {
            this.queueTimes.shift();
        }
    }
    /**
     * Record latency sample
     */
    recordLatency(latencyMs) {
        this.latencies.push(latencyMs);
        // Keep only recent samples for percentile calculation
        if (this.latencies.length > this.maxSamples) {
            this.latencies.shift();
        }
    }
    /**
     * Calculate latency percentiles
     */
    calculatePercentiles() {
        if (this.latencies.length === 0) {
            return { p50: 0, p95: 0, p99: 0, max: 0 };
        }
        const sorted = [...this.latencies].sort((a, b) => a - b);
        const len = sorted.length;
        return {
            p50: sorted[Math.floor(len * 0.5)] || 0,
            p95: sorted[Math.floor(len * 0.95)] || 0,
            p99: sorted[Math.floor(len * 0.99)] || 0,
            max: sorted[len - 1] || 0,
        };
    }
    /**
     * Calculate average
     */
    average(values) {
        if (values.length === 0)
            return 0;
        return values.reduce((sum, val) => sum + val, 0) / values.length;
    }
    /**
     * Get current metrics snapshot
     */
    getMetrics() {
        const now = Date.now();
        const durationMs = now - this.startTime;
        const durationMin = durationMs / 60000;
        return {
            totalRequests: this.totalRequests,
            successfulRequests: this.successfulRequests,
            failedRequests: this.failedRequests,
            averageLatency: this.average(this.latencies),
            circuitBreakerActivations: this.circuitBreakerActivations,
            retriedRequests: this.retriedRequests,
            totalRetries: this.totalRetries,
            errorsByCategory: { ...this.errorCounts },
            latencyPercentiles: this.calculatePercentiles(),
            requestsPerMinute: durationMin > 0 ? this.totalRequests / durationMin : 0,
            queueMetrics: {
                averageQueueLength: this.average(this.queueLengths),
                maxQueueLength: Math.max(...this.queueLengths, 0),
                totalTimeInQueue: this.queueTimes.reduce((sum, time) => sum + time, 0),
            },
            timeWindow: {
                startTime: this.startTime,
                endTime: now,
                durationMs,
            },
        };
    }
    /**
     * Reset all metrics
     */
    reset() {
        this.latencies = [];
        this.errorCounts = {
            transient: 0,
            rate_limit: 0,
            permanent: 0,
            server_error: 0,
            unknown: 0,
        };
        this.queueLengths = [];
        this.queueTimes = [];
        this.totalRequests = 0;
        this.successfulRequests = 0;
        this.failedRequests = 0;
        this.retriedRequests = 0;
        this.totalRetries = 0;
        this.circuitBreakerActivations = 0;
        this.startTime = Date.now();
    }
}
//# sourceMappingURL=metrics-collector.js.map