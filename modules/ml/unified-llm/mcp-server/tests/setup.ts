/**
 * Test utilities for rate limiter tests
 */

/**
 * Create a mock async function that fails a specific number of times
 */
export function createMockFunction(
  failCount: number,
  errorMessage: string = 'Mock error'
): () => Promise<string> {
  let callCount = 0;
  return async () => {
    callCount++;
    if (callCount <= failCount) {
      throw new Error(errorMessage);
    }
    return 'success';
  };
}

/**
 * Create a mock function that simulates rate limit errors
 */
export function createRateLimitMock(failCount: number): () => Promise<string> {
  let callCount = 0;
  return async () => {
    callCount++;
    if (callCount <= failCount) {
      const error: any = new Error('Rate limit exceeded');
      error.status = 429;
      throw error;
    }
    return 'success';
  };
}

/**
 * Sleep helper for async tests
 */
export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Measure execution time
 */
export async function measureTime<T>(fn: () => Promise<T>): Promise<{ result: T; time: number }> {
  const start = Date.now();
  const result = await fn();
  const time = Date.now() - start;
  return { result, time };
}