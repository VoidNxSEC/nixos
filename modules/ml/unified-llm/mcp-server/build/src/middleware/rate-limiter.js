import { RateLimitError, CircuitBreakerError, } from '../types/middleware/rate-limiter.js';
import { CircuitBreaker } from './circuit-breaker.js';
import { RetryStrategy } from './retry-strategy.js';
import { ErrorClassifier, ErrorCategory } from './error-classifier.js';
import { MetricsCollector } from './metrics-collector.js';
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
    configs;
    queues;
    metricsCollectors;
    circuitBreakers;
    retryStrategies;
    constructor(configs) {
        this.configs = configs;
        this.queues = new Map();
        this.metricsCollectors = new Map();
        this.circuitBreakers = new Map();
        // Initialize queues, metrics collectors, and circuit breakers for each provider
        for (const [provider, config] of configs.entries()) {
            this.queues.set(provider, {
                queue: [],
                processing: false,
                lastRequestTime: 0,
            });
            // Initialize MetricsCollector for enhanced metrics tracking
            this.metricsCollectors.set(provider, new MetricsCollector());
            // Initialize circuit breaker with config settings
            this.circuitBreakers.set(provider, new CircuitBreaker(config.circuitBreaker.failureThreshold, config.circuitBreaker.resetTimeout, 3 // halfOpenMaxAttempts - hardcoded for now
            ));
        }
        // Initialize retry strategies for each provider
        this.retryStrategies = new Map();
        for (const [provider, config] of configs.entries()) {
            this.retryStrategies.set(provider, new RetryStrategy(config.retryStrategy, 1000, // baseDelay: 1 second
            32000, // maxDelay: 32 seconds
            0.1 // jitterFactor: 10% randomness
            ));
        }
    }
    /**
     * Execute a function with rate limiting, circuit breaker protection, and retry logic
     *
     * @param provider - The provider name (e.g., 'deepseek', 'openai')
     * @param fn - The async function to execute
     * @returns Promise resolving to the function result
     */
    async execute(provider, fn) {
        const config = this.configs.get(provider);
        if (!config) {
            throw new Error(`No rate limit configuration found for provider: ${provider}`);
        }
        const circuitBreaker = this.circuitBreakers.get(provider);
        const retryStrategy = this.retryStrategies.get(provider);
        const collector = this.metricsCollectors.get(provider);
        if (!circuitBreaker || !retryStrategy) {
            throw new Error(`Missing components for provider: ${provider}`);
        }
        let lastError;
        let lastClassification = undefined;
        // Retry loop: attempt 0 to maxRetries (inclusive)
        for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
            const startTime = Date.now();
            try {
                // Attempt execution through circuit breaker and queue
                const result = await circuitBreaker.execute(async () => {
                    return this.executeWithQueue(provider, fn);
                });
                const latency = Date.now() - startTime;
                // Success - record metrics
                if (collector) {
                    collector.recordSuccess(latency);
                    if (attempt > 0) {
                        collector.recordRetry(attempt === 1);
                    }
                }
                return result;
            }
            catch (error) {
                const latency = Date.now() - startTime;
                lastError = error;
                // Don't retry if circuit breaker is open - fail fast
                if (error instanceof CircuitBreakerError) {
                    if (collector) {
                        collector.recordCircuitBreakerTrip();
                    }
                    throw error;
                }
                // Classify the error to determine if we should retry
                const classification = ErrorClassifier.classify(error);
                lastClassification = classification;
                // Record failure with error category
                if (collector) {
                    collector.recordFailure(latency, classification.category);
                }
                // Don't retry permanent errors
                if (!classification.shouldRetry) {
                    throw new RateLimitError(`Permanent error (${classification.category}): ${classification.message}`, provider, undefined);
                }
                // Don't retry on last attempt
                if (attempt === config.maxRetries) {
                    break;
                }
                // Record retry attempt
                if (collector && attempt > 0) {
                    collector.recordRetry(false);
                }
                // For rate limit errors, use longer delays
                const baseDelay = classification.category === ErrorCategory.RATE_LIMIT
                    ? retryStrategy.calculateDelay(attempt) * 2 // Double delay for rate limits
                    : retryStrategy.calculateDelay(attempt);
                console.log(`[RateLimiter] Retry attempt ${attempt + 1}/${config.maxRetries} for ${provider} after ${Math.round(baseDelay)}ms (${classification.category})`);
                await this.sleep(baseDelay);
            }
        }
        // All retries exhausted
        throw new RateLimitError(`All ${config.maxRetries + 1} attempts failed for provider ${provider}: ${lastError?.message}`, provider, undefined // No retry after - retries exhausted
        );
    }
    /**
     * Execute a function through the request queue
     * (Extracted from previous execute method for retry logic)
     */
    async executeWithQueue(provider, fn) {
        const queue = this.queues.get(provider);
        const collector = this.metricsCollectors.get(provider);
        if (!queue) {
            throw new Error(`No queue found for provider: ${provider}`);
        }
        const queueStartTime = Date.now();
        // Create a promise that will be resolved when the request completes
        return new Promise((resolve, reject) => {
            const request = {
                id: this.generateRequestId(),
                fn,
                resolve,
                reject,
                timestamp: Date.now(),
                provider,
            };
            // Add to queue
            queue.queue.push(request);
            // Record queue metrics
            if (collector) {
                const queueTime = Date.now() - queueStartTime;
                const queueLength = queue.queue.length;
                collector.recordQueueMetrics(queueLength, queueTime);
            }
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
    async processQueue(provider) {
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
            }
            catch (error) {
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
    calculateDelay(provider, config) {
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
     * @deprecated This method is no longer used - MetricsCollector handles all metrics
     */
    updateMetrics(provider, success, latency) {
        // Legacy method - metrics now handled by MetricsCollector
        // Kept for backward compatibility but does nothing
    }
    /**
     * Update retry metrics when a request required retries
     * @deprecated This method is no longer used - MetricsCollector handles all metrics
     */
    updateRetryMetrics(provider, attemptCount) {
        // Legacy method - metrics now handled by MetricsCollector
        console.log(`[RateLimiter] Request for ${provider} succeeded after ${attemptCount} retries`);
    }
    /**
     * Wrap error with additional context
     */
    wrapError(error, provider, request) {
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
    getMetrics(provider) {
        const collector = this.metricsCollectors.get(provider);
        return collector?.getMetrics();
    }
    /**
     * Get all metrics
     */
    getAllMetrics() {
        const allMetrics = new Map();
        for (const [provider, collector] of this.metricsCollectors.entries()) {
            allMetrics.set(provider, collector.getMetrics());
        }
        return allMetrics;
    }
    /**
     * Get queue status for a provider
     */
    getQueueStatus(provider) {
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
    generateRequestId() {
        return `req_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    }
    /**
     * Sleep for specified milliseconds
     */
    sleep(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }
}
//# sourceMappingURL=rate-limiter.js.map