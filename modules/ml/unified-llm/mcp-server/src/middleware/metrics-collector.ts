import { ErrorCategory } from './error-classifier.js';
import type { RateLimitMetrics } from '../types/middleware/rate-limiter.js';

/**
 * Collects and aggregates metrics with statistical analysis
 */
export class MetricsCollector {
  private latencies: number[] = [];
  private errorCounts: Record<ErrorCategory, number> = {
    transient: 0,
    rate_limit: 0,
    permanent: 0,
    server_error: 0,
    unknown: 0,
  };
  private queueLengths: number[] = [];
  private queueTimes: number[] = [];
  
  private totalRequests = 0;
  private successfulRequests = 0;
  private failedRequests = 0;
  private retriedRequests = 0;
  private totalRetries = 0;
  private circuitBreakerActivations = 0;
  
  private startTime: number;
  private readonly maxSamples = 1000; // Keep last 1000 samples for percentiles
  
  constructor() {
    this.startTime = Date.now();
  }
  
  /**
   * Record a successful request
   */
  recordSuccess(latencyMs: number): void {
    this.totalRequests++;
    this.successfulRequests++;
    this.recordLatency(latencyMs);
  }
  
  /**
   * Record a failed request
   */
  recordFailure(latencyMs: number, errorCategory?: ErrorCategory): void {
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
  recordRetry(isFirstRetry: boolean): void {
    this.totalRetries++;
    if (isFirstRetry) {
      this.retriedRequests++;
    }
  }
  
  /**
   * Record circuit breaker activation
   */
  recordCircuitBreakerTrip(): void {
    this.circuitBreakerActivations++;
  }
  
  /**
   * Record queue metrics
   */
  recordQueueMetrics(queueLength: number, timeInQueueMs: number): void {
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
  private recordLatency(latencyMs: number): void {
    this.latencies.push(latencyMs);
    
    // Keep only recent samples for percentile calculation
    if (this.latencies.length > this.maxSamples) {
      this.latencies.shift();
    }
  }
  
  /**
   * Calculate latency percentiles
   */
  private calculatePercentiles(): { p50: number; p95: number; p99: number; max: number } {
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
  private average(values: number[]): number {
    if (values.length === 0) return 0;
    return values.reduce((sum, val) => sum + val, 0) / values.length;
  }
  
  /**
   * Get current metrics snapshot
   */
  getMetrics(): RateLimitMetrics {
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
  reset(): void {
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