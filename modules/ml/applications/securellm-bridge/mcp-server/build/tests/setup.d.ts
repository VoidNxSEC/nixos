/**
 * Test utilities for rate limiter tests
 */
/**
 * Create a mock async function that fails a specific number of times
 */
export declare function createMockFunction(failCount: number, errorMessage?: string): () => Promise<string>;
/**
 * Create a mock function that simulates rate limit errors
 */
export declare function createRateLimitMock(failCount: number): () => Promise<string>;
/**
 * Sleep helper for async tests
 */
export declare function sleep(ms: number): Promise<void>;
/**
 * Measure execution time
 */
export declare function measureTime<T>(fn: () => Promise<T>): Promise<{
    result: T;
    time: number;
}>;
//# sourceMappingURL=setup.d.ts.map