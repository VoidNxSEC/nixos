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
export class RetryStrategy {
  // Cache for Fibonacci numbers to avoid recalculation
  private fibCache: Map<number, number> = new Map();

  constructor(
    private strategy: 'exponential' | 'linear' | 'fibonacci',
    private baseDelay: number = 1000,      // Base delay in ms
    private maxDelay: number = 32000,      // Max delay cap in ms
    private jitterFactor: number = 0.1     // Jitter: 0.0-1.0 (10% randomness)
  ) {
    if (baseDelay < 0) {
      throw new Error('baseDelay must be non-negative');
    }
    if (maxDelay < baseDelay) {
      throw new Error('maxDelay must be >= baseDelay');
    }
    if (jitterFactor < 0 || jitterFactor > 1) {
      throw new Error('jitterFactor must be between 0.0 and 1.0');
    }

    // Pre-populate Fibonacci cache for common values
    this.fibCache.set(0, 1);
    this.fibCache.set(1, 1);
  }

  /**
   * Calculate delay for a given attempt number
   * 
   * @param attempt - The retry attempt number (0-based)
   * @returns Delay in milliseconds with jitter applied
   */
  calculateDelay(attempt: number): number {
    if (attempt < 0) {
      throw new Error('attempt must be non-negative');
    }

    let delay: number;

    // Calculate base delay based on strategy
    switch (this.strategy) {
      case 'exponential':
        delay = this.exponentialDelay(attempt);
        break;
      case 'linear':
        delay = this.linearDelay(attempt);
        break;
      case 'fibonacci':
        delay = this.fibonacciDelay(attempt);
        break;
      default:
        throw new Error(`Unknown retry strategy: ${this.strategy}`);
    }

    // Cap at maxDelay
    delay = Math.min(delay, this.maxDelay);

    // Apply jitter
    delay = this.addJitter(delay);

    // Ensure non-negative
    return Math.max(0, delay);
  }

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
  private exponentialDelay(attempt: number): number {
    return this.baseDelay * Math.pow(2, attempt);
  }

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
  private linearDelay(attempt: number): number {
    // For attempt 0, use baseDelay instead of 0 to ensure some delay
    if (attempt === 0) {
      return this.baseDelay;
    }
    return this.baseDelay * attempt;
  }

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
  private fibonacciDelay(attempt: number): number {
    return this.baseDelay * this.fibonacci(attempt);
  }

  /**
   * Calculate Fibonacci number with caching
   * Uses iterative approach for efficiency
   * 
   * Note: We use a modified Fibonacci where fib(0) = 1, fib(1) = 1
   * to avoid zero delays on first retry
   */
  private fibonacci(n: number): number {
    // Check cache first
    if (this.fibCache.has(n)) {
      return this.fibCache.get(n)!;
    }

    // Calculate iteratively to avoid stack overflow and populate cache
    let prev = 1;
    let current = 1;

    for (let i = 2; i <= n; i++) {
      const next = prev + current;
      prev = current;
      current = next;
      this.fibCache.set(i, current);
    }

    return current;
  }

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
  private addJitter(delay: number): number {
    // Generate random value between -jitterFactor and +jitterFactor
    const randomFactor = (Math.random() * 2 - 1) * this.jitterFactor;
    
    // Apply jitter: delay * (1 + randomFactor)
    return delay * (1 + randomFactor);
  }

  /**
   * Get the current strategy type
   */
  getStrategy(): 'exponential' | 'linear' | 'fibonacci' {
    return this.strategy;
  }

  /**
   * Get strategy configuration
   */
  getConfig() {
    return {
      strategy: this.strategy,
      baseDelay: this.baseDelay,
      maxDelay: this.maxDelay,
      jitterFactor: this.jitterFactor,
    };
  }
}