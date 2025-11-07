import type {
  RateLimitConfig,
  RequestQueue,
  QueuedRequest,
  RateLimitMetrics,
  CircuitBreaker as CircuitBreakerType,
  CircuitBreakerState,
} from '../types/middleware/rate-limiter.js';
import {
  RateLimitError,
  CircuitBreakerError,
} from '../types/middleware/rate-limiter.js';
import { CircuitBreaker } from './circuit-breaker.js';
import { RetryStrategy } from './retry-strategy.js';

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
export class SmartRateLimiter {
  private configs: Map<string, RateLimitConfig>;
  private queues: Map<string, RequestQueue>;
  private metrics: Map<string, RateLimitMetrics>;
  private circuitBreakers: Map<string, CircuitBreaker>;
  private retryStrategies: Map<string, RetryStrategy>;

  constructor(configs: Map<string, RateLimitConfig>) {
    this.configs = configs;
    this.queues = new Map();
    this.metrics = new Map();
    this.circuitBreakers = new Map();

    // Initialize queues, metrics, and circuit breakers for each provider
    for (const [provider, config] of configs.entries()) {
      this.queues.set(provider, {
        queue: [],
        processing: false,
        lastRequestTime: 0,
      });

      this.metrics.set(provider, {
        provider,
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        retriedRequests: 0,
        averageLatency: 0,
        circuitBreakerTrips: 0,
        lastRequestTime: 0,
      });

      // Initialize circuit breaker with config settings
      this.circuitBreakers.set(
        provider,
        new CircuitBreaker(
          config.circuitBreaker.failureThreshold,
          config.circuitBreaker.resetTimeout,
          3 // halfOpenMaxAttempts - hardcoded for now
        )
      );
    }

    // Initialize retry strategies for each provider
    this.retryStrategies = new Map();
    for (const [provider, config] of configs.entries()) {
      this.retryStrategies.set(
        provider,
        new RetryStrategy(
          config.retryStrategy,
          1000,  // baseDelay: 1 second
          32000, // maxDelay: 32 seconds
          0.1    // jitterFactor: 10% randomness
        )
      );
    }
  }

  /**
   * Execute a function with rate limiting, circuit breaker protection, and retry logic
   *
   * @param provider - The provider name (e.g., 'deepseek', 'openai')
   * @param fn - The async function to execute
   * @returns Promise resolving to the function result
   */
  async execute<T>(provider: string, fn: () => Promise<T>): Promise<T> {
    const config = this.configs.get(provider);
    if (!config) {
      throw new Error(`No rate limit configuration found for provider: ${provider}`);
    }

    const circuitBreaker = this.circuitBreakers.get(provider);
    const retryStrategy = this.retryStrategies.get(provider);
    
    if (!circuitBreaker || !retryStrategy) {
      throw new Error(`Missing components for provider: ${provider}`);
    }

    let lastError: Error | undefined;
    let retriedAttempts = 0;

    // Retry loop: attempt 0 to maxRetries (inclusive)
    for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
      try {
        // Attempt execution through circuit breaker and queue
        const result = await circuitBreaker.execute(async () => {
          return this.executeWithQueue(provider, fn);
        });
        
        // Success - update retry metrics if this wasn't the first attempt
        if (attempt > 0) {
          retriedAttempts = attempt;
          this.updateRetryMetrics(provider, retriedAttempts);
        }
        
        return result;
      } catch (error) {
        lastError = error as Error;

        // Don't retry if circuit breaker is open - fail fast
        if (error instanceof CircuitBreakerError) {
          throw error;
        }

        // Don't retry on last attempt
        if (attempt === config.maxRetries) {
          break;
        }

        // Calculate and apply backoff delay before next retry
        const delay = retryStrategy.calculateDelay(attempt);
        console.log(
          `[RateLimiter] Retry attempt ${attempt + 1}/${config.maxRetries} for ${provider} after ${Math.round(delay)}ms`
        );
        await this.sleep(delay);
      }
    }

    // All retries exhausted
    throw new RateLimitError(
      `All ${config.maxRetries + 1} attempts failed for provider ${provider}: ${lastError?.message}`,
      provider,
      undefined // No retry after - retries exhausted
    );
  }

  /**
   * Execute a function through the request queue
   * (Extracted from previous execute method for retry logic)
   */
  private async executeWithQueue<T>(provider: string, fn: () => Promise<T>): Promise<T> {
    const queue = this.queues.get(provider);
    if (!queue) {
      throw new Error(`No queue found for provider: ${provider}`);
    }

    // Create a promise that will be resolved when the request completes
    return new Promise<T>((resolve, reject) => {
      const request: QueuedRequest<T> = {
        id: this.generateRequestId(),
        fn,
        resolve,
        reject,
        timestamp: Date.now(),
        provider,
      };

      // Add to queue
      queue.queue.push(request);

      // Start processing if not already processing
      if (!queue.processing) {
        this.processQueue(provider).catch((error) => {
          console.error(`[RateLimiter] Error processing queue for ${provider}:`, error);
        });
      }
    });
  }

  /**
   * Process the request queue for a provider
   */
  private async processQueue(provider: string): Promise<void> {
    const queue = this.queues.get(provider);
    const config = this.configs.get(provider);
    
    if (!queue || !config) {
      return;
    }

    queue.processing = true;

    while (queue.queue.length > 0) {
      const request = queue.queue.shift();
      if (!request) {
        break;
      }

      try {
        // Calculate delay based on rate limit
        const delayMs = this.calculateDelay(provider, config);
        
        if (delayMs > 0) {
          await this.sleep(delayMs);
        }

        // Update last request time
        queue.lastRequestTime = Date.now();

        // Execute the request
        const startTime = Date.now();
        const result = await request.fn();
        const latency = Date.now() - startTime;

        // Update metrics
        this.updateMetrics(provider, true, latency);

        // Resolve the promise
        request.resolve(result);
      } catch (error) {
        // Update metrics
        this.updateMetrics(provider, false, 0);

        // Wrap error with context
        const wrappedError = this.wrapError(error, provider, request);
        request.reject(wrappedError);
      }
    }

    queue.processing = false;
  }

  /**
   * Calculate delay needed before next request
   */
  private calculateDelay(provider: string, config: RateLimitConfig): number {
    const queue = this.queues.get(provider);
    if (!queue) {
      return 0;
    }

    const now = Date.now();
    const timeSinceLastRequest = now - queue.lastRequestTime;
    
    // Calculate minimum delay between requests (in milliseconds)
    const minDelayMs = 60000 / config.requestsPerMinute;

    // If enough time has passed, no delay needed
    if (timeSinceLastRequest >= minDelayMs) {
      return 0;
    }

    // Otherwise, wait for the remaining time
    return minDelayMs - timeSinceLastRequest;
  }

  /**
   * Update metrics for a provider
   */
  private updateMetrics(provider: string, success: boolean, latency: number): void {
    const metrics = this.metrics.get(provider);
    if (!metrics) {
      return;
    }

    metrics.totalRequests++;
    metrics.lastRequestTime = Date.now();

    if (success) {
      metrics.successfulRequests++;
      
      // Update average latency (running average)
      const totalLatency = metrics.averageLatency * (metrics.successfulRequests - 1);
      metrics.averageLatency = (totalLatency + latency) / metrics.successfulRequests;
    } else {
      metrics.failedRequests++;
    }

    // Update circuit breaker trip count
    const circuitBreaker = this.circuitBreakers.get(provider);
    if (circuitBreaker && circuitBreaker.getState() === 'open') {
      metrics.circuitBreakerTrips++;
    }
  }
  /**
   * Update retry metrics when a request required retries
   */
  private updateRetryMetrics(provider: string, attemptCount: number): void {
    const metrics = this.metrics.get(provider);
    if (!metrics) {
      return;
    }

    metrics.retriedRequests++;
    console.log(`[RateLimiter] Request for ${provider} succeeded after ${attemptCount} retries`);
  }


  /**
   * Wrap error with additional context
   */
  private wrapError(error: unknown, provider: string, request: QueuedRequest<any>): Error {
    const errorMessage = error instanceof Error ? error.message : String(error);
    const contextMessage = `[RateLimiter] Request failed for provider '${provider}' (ID: ${request.id}): ${errorMessage}`;

    if (error instanceof Error) {
      const wrappedError = new Error(contextMessage);
      wrappedError.stack = error.stack;
      wrappedError.cause = error;
      return wrappedError;
    }

    return new Error(contextMessage);
  }

  /**
   * Get current metrics for a provider
   */
  getMetrics(provider: string): RateLimitMetrics | undefined {
    return this.metrics.get(provider);
  }

  /**
   * Get all metrics
   */
  getAllMetrics(): Map<string, RateLimitMetrics> {
    return new Map(this.metrics);
  }

  /**
   * Get queue status for a provider
   */
  getQueueStatus(provider: string): { queueLength: number; processing: boolean } | undefined {
    const queue = this.queues.get(provider);
    if (!queue) {
      return undefined;
    }

    return {
      queueLength: queue.queue.length,
      processing: queue.processing,
    };
  }

  /**
   * Generate a unique request ID
   */
  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * Sleep for specified milliseconds
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}