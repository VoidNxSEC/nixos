import crypto from 'crypto';
export class RequestDeduplicator {
    inFlight = new Map();
    stats = {
        total: 0,
        deduplicated: 0,
        unique: 0,
    };
    /**
     * Generate hash key from request parameters
     */
    generateKey(provider, requestData) {
        const content = JSON.stringify({
            provider,
            data: requestData,
        });
        return crypto.createHash('sha256').update(content).digest('hex');
    }
    /**
     * Execute request with deduplication
     * Returns existing promise if identical request is in-flight
     */
    async deduplicate(provider, requestData, fn) {
        this.stats.total++;
        // Generate unique key for this request
        const key = this.generateKey(provider, requestData);
        // Check if identical request is already in-flight
        const existing = this.inFlight.get(key);
        if (existing) {
            this.stats.deduplicated++;
            console.log(`[Dedup] Cache HIT for ${provider} (saved API call #${this.stats.deduplicated})`);
            return existing.promise;
        }
        // Execute new request
        this.stats.unique++;
        const promise = fn().finally(() => {
            // Clear cache when request completes
            this.inFlight.delete(key);
        });
        // Cache the promise
        this.inFlight.set(key, {
            promise,
            timestamp: Date.now(),
            provider,
        });
        return promise;
    }
    /**
     * Get deduplication statistics
     */
    getStats() {
        const savingsPercent = this.stats.total > 0
            ? ((this.stats.deduplicated / this.stats.total) * 100).toFixed(1)
            : '0.0';
        return {
            ...this.stats,
            savingsPercent: `${savingsPercent}%`,
            inFlightCount: this.inFlight.size,
        };
    }
    /**
     * Clear all in-flight requests (for cleanup/reset)
     */
    clear() {
        this.inFlight.clear();
    }
    /**
     * Clean up stale in-flight requests (older than timeout)
     */
    cleanupStale(timeoutMs = 60000) {
        const now = Date.now();
        const stale = [];
        for (const [key, request] of this.inFlight.entries()) {
            if (now - request.timestamp > timeoutMs) {
                stale.push(key);
            }
        }
        stale.forEach(key => this.inFlight.delete(key));
        if (stale.length > 0) {
            console.log(`[Dedup] Cleaned up ${stale.length} stale requests`);
        }
    }
}
//# sourceMappingURL=request-deduplicator.js.map