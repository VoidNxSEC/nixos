import { describe, it } from 'node:test';
import assert from 'node:assert';
import { MetricsCollector } from '../src/middleware/metrics-collector.js';
import { ErrorCategory } from '../src/middleware/error-classifier.js';
describe('MetricsCollector', () => {
    it('should track successful requests', () => {
        const collector = new MetricsCollector();
        collector.recordSuccess(100);
        collector.recordSuccess(200);
        collector.recordSuccess(150);
        const metrics = collector.getMetrics();
        assert.strictEqual(metrics.totalRequests, 3);
        assert.strictEqual(metrics.successfulRequests, 3);
        assert.strictEqual(metrics.failedRequests, 0);
        assert.ok(metrics.averageLatency > 0);
    });
    it('should track failed requests by category', () => {
        const collector = new MetricsCollector();
        collector.recordFailure(100, ErrorCategory.RATE_LIMIT);
        collector.recordFailure(200, ErrorCategory.TRANSIENT);
        collector.recordFailure(150, ErrorCategory.PERMANENT);
        const metrics = collector.getMetrics();
        assert.strictEqual(metrics.totalRequests, 3);
        assert.strictEqual(metrics.failedRequests, 3);
        assert.strictEqual(metrics.errorsByCategory.rate_limit, 1);
        assert.strictEqual(metrics.errorsByCategory.transient, 1);
        assert.strictEqual(metrics.errorsByCategory.permanent, 1);
    });
    it('should calculate latency percentiles', () => {
        const collector = new MetricsCollector();
        // Add 100 samples with known distribution
        for (let i = 1; i <= 100; i++) {
            collector.recordSuccess(i * 10); // 10ms, 20ms, ..., 1000ms
        }
        const metrics = collector.getMetrics();
        // Percentiles use Math.floor, so p50 at index 50 is the 51st item (510ms)
        assert.strictEqual(metrics.latencyPercentiles.p50, 510); // Median (index 50)
        assert.strictEqual(metrics.latencyPercentiles.p95, 960); // 95th (index 95)
        assert.strictEqual(metrics.latencyPercentiles.p99, 1000); // 99th (index 99)
        assert.strictEqual(metrics.latencyPercentiles.max, 1000); // Max
    });
    it('should track retry attempts', () => {
        const collector = new MetricsCollector();
        collector.recordRetry(true); // First retry of request 1
        collector.recordRetry(false); // Second retry of request 1
        collector.recordRetry(true); // First retry of request 2
        const metrics = collector.getMetrics();
        assert.strictEqual(metrics.retriedRequests, 2); // 2 requests needed retries
        assert.strictEqual(metrics.totalRetries, 3); // 3 total retry attempts
    });
    it('should track circuit breaker trips', () => {
        const collector = new MetricsCollector();
        collector.recordCircuitBreakerTrip();
        collector.recordCircuitBreakerTrip();
        const metrics = collector.getMetrics();
        assert.strictEqual(metrics.circuitBreakerActivations, 2);
    });
    it('should track queue metrics', () => {
        const collector = new MetricsCollector();
        collector.recordQueueMetrics(5, 100);
        collector.recordQueueMetrics(3, 50);
        collector.recordQueueMetrics(7, 150);
        const metrics = collector.getMetrics();
        assert.strictEqual(metrics.queueMetrics.averageQueueLength, 5); // (5+3+7)/3
        assert.strictEqual(metrics.queueMetrics.maxQueueLength, 7);
        assert.strictEqual(metrics.queueMetrics.totalTimeInQueue, 300); // 100+50+150
    });
    it('should calculate requests per minute', () => {
        const collector = new MetricsCollector();
        // Record some requests
        for (let i = 0; i < 10; i++) {
            collector.recordSuccess(100);
        }
        const metrics = collector.getMetrics();
        // Should calculate a rate (may be very high due to short duration)
        assert.ok(metrics.requestsPerMinute >= 0, 'Requests per minute should be non-negative');
        assert.strictEqual(metrics.totalRequests, 10, 'Should have tracked 10 requests');
    });
    it('should reset metrics', () => {
        const collector = new MetricsCollector();
        collector.recordSuccess(100);
        collector.recordFailure(200, ErrorCategory.RATE_LIMIT);
        collector.reset();
        const metrics = collector.getMetrics();
        assert.strictEqual(metrics.totalRequests, 0);
        assert.strictEqual(metrics.successfulRequests, 0);
        assert.strictEqual(metrics.failedRequests, 0);
    });
});
//# sourceMappingURL=metrics-collector.test.js.map