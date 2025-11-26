/**
 * Error Classification System - Phase 1.5
 *
 * Intelligent error classification to distinguish between:
 * - Transient errors (should retry)
 * - Permanent errors (fail fast)
 * - Rate limit errors (retry with longer delays)
 * - Server errors (maybe retry)
 * - Unknown errors (default to not retrying for safety)
 */
/**
 * Error classification for determining retry strategy
 */
export declare enum ErrorCategory {
    /** Temporary errors that should be retried (network glitches, timeouts) */
    TRANSIENT = "transient",
    /** Rate limit errors (429, quota exceeded) */
    RATE_LIMIT = "rate_limit",
    /** Permanent errors that should not be retried (400, 401, 403, 404) */
    PERMANENT = "permanent",
    /** Server errors that might be temporary (500, 502, 503) */
    SERVER_ERROR = "server_error",
    /** Unknown errors (default to transient for safety) */
    UNKNOWN = "unknown"
}
export interface ErrorClassification {
    category: ErrorCategory;
    shouldRetry: boolean;
    message: string;
    httpStatus?: number;
    errorCode?: string;
}
export declare class ErrorClassifier {
    /**
     * Classify an error to determine if it should be retried
     */
    static classify(error: Error | unknown): ErrorClassification;
    /**
     * Check if error is a rate limit error
     */
    private static isRateLimitError;
    /**
     * Check if error is transient (network/timeout)
     */
    private static isTransientError;
    /**
     * Check if error is permanent (client error)
     */
    private static isPermanentError;
    /**
     * Check if error is a server error (5xx)
     */
    private static isServerError;
    /**
     * Extract HTTP status code from error
     */
    private static extractHttpStatus;
    /**
     * Extract error code from error
     */
    private static extractErrorCode;
}
//# sourceMappingURL=error-classifier.d.ts.map