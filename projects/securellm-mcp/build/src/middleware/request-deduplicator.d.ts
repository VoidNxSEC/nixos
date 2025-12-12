export declare class RequestDeduplicator {
    private inFlight;
    private stats;
    /**
     * Generate hash key from request parameters
     */
    private generateKey;
    /**
     * Execute request with deduplication
     * Returns existing promise if identical request is in-flight
     */
    deduplicate<T>(provider: string, requestData: any, fn: () => Promise<T>): Promise<T>;
    /**
     * Get deduplication statistics
     */
    getStats(): {
        savingsPercent: string;
        inFlightCount: number;
        total: number;
        deduplicated: number;
        unique: number;
    };
    /**
     * Clear all in-flight requests (for cleanup/reset)
     */
    clear(): void;
    /**
     * Clean up stale in-flight requests (older than timeout)
     */
    cleanupStale(timeoutMs?: number): void;
}
//# sourceMappingURL=request-deduplicator.d.ts.map