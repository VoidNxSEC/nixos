/**
 * Retry Strategy - Phase 1.3 Implementation
 *
 * Implements three backoff algorithms with jitter to handle transient failures
 * and prevent thundering herd problems.
 *
 * Algorithms:
 * - Exponential: 2^attempt * baseDelay (best for rate limits/API overload)
 * - Linear: attempt * baseDelay (best for temporary network issues)
 * - Fibonacci: fib(attempt) * baseDelay (gradual backoff without explosive growth)
 *
 * Jitter: Randomizes delays to prevent synchronized retries
 */
export declare class RetryStrategy {
    private strategy;
    private baseDelay;
    private maxDelay;
    private jitterFactor;
    private fibCache;
    constructor(strategy: 'exponential' | 'linear' | 'fibonacci', baseDelay?: number, // Base delay in ms
    maxDelay?: number, // Max delay cap in ms
    jitterFactor?: number);
    /**
     * Calculate delay for a given attempt number
     *
     * @param attempt - The retry attempt number (0-based)
     * @returns Delay in milliseconds with jitter applied
     */
    calculateDelay(attempt: number): number;
    /**
     * Exponential backoff: 2^attempt * baseDelay
     *
     * Example with baseDelay=1000ms:
     * attempt 0: 1s
     * attempt 1: 2s
     * attempt 2: 4s
     * attempt 3: 8s
     * attempt 4: 16s
     * attempt 5: 32s (capped at maxDelay)
     */
    private exponentialDelay;
    /**
     * Linear backoff: attempt * baseDelay
     *
     * Example with baseDelay=1000ms:
     * attempt 0: 0s (will be 1s after jitter minimum)
     * attempt 1: 1s
     * attempt 2: 2s
     * attempt 3: 3s
     * attempt 4: 4s
     * attempt 5: 5s
     */
    private linearDelay;
    /**
     * Fibonacci backoff: fib(attempt) * baseDelay
     *
     * Example with baseDelay=1000ms:
     * attempt 0: 1s (fib(0) = 1)
     * attempt 1: 1s (fib(1) = 1)
     * attempt 2: 2s (fib(2) = 2)
     * attempt 3: 3s (fib(3) = 3)
     * attempt 4: 5s (fib(4) = 5)
     * attempt 5: 8s (fib(5) = 8)
     * attempt 6: 13s (fib(6) = 13)
     */
    private fibonacciDelay;
    /**
     * Calculate Fibonacci number with caching
     * Uses iterative approach for efficiency
     *
     * Note: We use a modified Fibonacci where fib(0) = 1, fib(1) = 1
     * to avoid zero delays on first retry
     */
    private fibonacci;
    /**
     * Add jitter to prevent thundering herd
     *
     * Jitter formula: delay * (1 + random(-jitterFactor, +jitterFactor))
     *
     * Example with jitterFactor=0.1 and delay=1000ms:
     * - Jitter range: -10% to +10%
     * - Result range: 900ms to 1100ms
     *
     * This randomization ensures that multiple failed requests don't
     * all retry at exactly the same time, which could overwhelm the service.
     */
    private addJitter;
    /**
     * Get the current strategy type
     */
    getStrategy(): 'exponential' | 'linear' | 'fibonacci';
    /**
     * Get strategy configuration
     */
    getConfig(): {
        strategy: "exponential" | "linear" | "fibonacci";
        baseDelay: number;
        maxDelay: number;
        jitterFactor: number;
    };
}
//# sourceMappingURL=retry-strategy.d.ts.map