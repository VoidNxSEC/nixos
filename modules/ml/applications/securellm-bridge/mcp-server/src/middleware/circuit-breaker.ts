import type { CircuitBreakerState, CircuitBreakerMetrics } from '../types/middleware/rate-limiter.js';
import { CircuitBreakerError } from '../types/middleware/rate-limiter.js';

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
export class CircuitBreaker {
  private state: CircuitBreakerState = 'closed';
  private failureCount: number = 0;
  private successCount: number = 0;
  private lastFailureTime: number = 0;
  private nextAttemptTime: number = 0;

  constructor(
    private failureThreshold: number = 5,
    private resetTimeout: number = 60000,
    private halfOpenMaxAttempts: number = 3
  ) {
    if (failureThreshold < 1) {
      throw new Error('failureThreshold must be at least 1');
    }
    if (resetTimeout < 1000) {
      throw new Error('resetTimeout must be at least 1000ms');
    }
    if (halfOpenMaxAttempts < 1) {
      throw new Error('halfOpenMaxAttempts must be at least 1');
    }
  }

  /**
   * Execute a function with circuit breaker protection
   * 
   * @param fn - The async function to execute
   * @returns Promise resolving to the function result
   * @throws CircuitBreakerError if circuit is open
   */
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    // Check if we should attempt to reset the circuit
    if (this.state === 'open' && this.shouldAttemptReset()) {
      this.transitionTo('half-open');
    }

    // If circuit is open, fail fast
    if (this.state === 'open') {
      throw new CircuitBreakerError(
        `Circuit breaker is open. Service unavailable until ${new Date(this.nextAttemptTime).toISOString()}`,
        'unknown', // Provider will be set by caller
        this.nextAttemptTime
      );
    }

    try {
      // Execute the function
      const result = await fn();

      // On success, handle state transitions
      this.onSuccess();

      return result;
    } catch (error) {
      // On failure, handle state transitions
      this.onFailure();

      // Re-throw the original error
      throw error;
    }
  }

  /**
   * Handle successful request
   */
  private onSuccess(): void {
    if (this.state === 'half-open') {
      this.successCount++;

      // If we've had enough successful requests in half-open, close the circuit
      if (this.successCount >= this.halfOpenMaxAttempts) {
        this.transitionTo('closed');
      }
    } else if (this.state === 'closed') {
      // Reset failure count on success in closed state
      this.failureCount = 0;
    }
  }

  /**
   * Handle failed request
   */
  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.state === 'half-open') {
      // Any failure in half-open state reopens the circuit
      this.transitionTo('open');
    } else if (this.state === 'closed') {
      // If we've reached the failure threshold, open the circuit
      if (this.failureCount >= this.failureThreshold) {
        this.transitionTo('open');
      }
    }
  }

  /**
   * Transition to a new state
   */
  private transitionTo(newState: CircuitBreakerState): void {
    const oldState = this.state;
    this.state = newState;

    // Reset counters based on new state
    if (newState === 'open') {
      this.nextAttemptTime = Date.now() + this.resetTimeout;
      this.successCount = 0;
    } else if (newState === 'half-open') {
      this.successCount = 0;
      this.failureCount = 0;
    } else if (newState === 'closed') {
      this.failureCount = 0;
      this.successCount = 0;
      this.nextAttemptTime = 0;
    }

    // Log state transition for debugging
    console.log(`[CircuitBreaker] State transition: ${oldState} → ${newState}`);
  }

  /**
   * Check if we should attempt to reset the circuit
   */
  private shouldAttemptReset(): boolean {
    return this.state === 'open' && Date.now() >= this.nextAttemptTime;
  }

  /**
   * Get current circuit breaker state
   */
  getState(): CircuitBreakerState {
    return this.state;
  }

  /**
   * Get current circuit breaker metrics
   */
  getMetrics(): CircuitBreakerMetrics {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      lastFailureTime: this.lastFailureTime,
      nextAttemptTime: this.nextAttemptTime,
    };
  }

  /**
   * Reset the circuit breaker to initial state (for testing/manual intervention)
   */
  reset(): void {
    this.state = 'closed';
    this.failureCount = 0;
    this.successCount = 0;
    this.lastFailureTime = 0;
    this.nextAttemptTime = 0;
    console.log('[CircuitBreaker] Manual reset to closed state');
  }
}