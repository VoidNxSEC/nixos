import type { CircuitBreakerState, CircuitBreakerMetrics } from '../types/middleware/rate-limiter.js';
/**
 * Circuit Breaker - Phase 1.2 Implementation
 *
 * Implements the Circuit Breaker pattern to prevent cascading failures.
 *
 * States:
 * - closed: Normal operation, requests pass through
 * - open: Circuit tripped, requests fail fast
 * - half-open: Testing if service recovered
 *
 * State Transitions:
 * - closed → open: After failureThreshold consecutive failures
 * - open → half-open: After resetTimeout milliseconds
 * - half-open → closed: After halfOpenMaxAttempts successful requests
 * - half-open → open: On any failure during half-open
 */
export declare class CircuitBreaker {
    private failureThreshold;
    private resetTimeout;
    private halfOpenMaxAttempts;
    private state;
    private failureCount;
    private successCount;
    private lastFailureTime;
    private nextAttemptTime;
    constructor(failureThreshold?: number, resetTimeout?: number, halfOpenMaxAttempts?: number);
    /**
     * Execute a function with circuit breaker protection
     *
     * @param fn - The async function to execute
     * @returns Promise resolving to the function result
     * @throws CircuitBreakerError if circuit is open
     */
    execute<T>(fn: () => Promise<T>): Promise<T>;
    /**
     * Handle successful request
     */
    private onSuccess;
    /**
     * Handle failed request
     */
    private onFailure;
    /**
     * Transition to a new state
     */
    private transitionTo;
    /**
     * Check if we should attempt to reset the circuit
     */
    private shouldAttemptReset;
    /**
     * Get current circuit breaker state
     */
    getState(): CircuitBreakerState;
    /**
     * Get current circuit breaker metrics
     */
    getMetrics(): CircuitBreakerMetrics;
    /**
     * Reset the circuit breaker to initial state (for testing/manual intervention)
     */
    reset(): void;
}
//# sourceMappingURL=circuit-breaker.d.ts.map