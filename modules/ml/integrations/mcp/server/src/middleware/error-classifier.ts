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
export enum ErrorCategory {
  /** Temporary errors that should be retried (network glitches, timeouts) */
  TRANSIENT = 'transient',
  
  /** Rate limit errors (429, quota exceeded) */
  RATE_LIMIT = 'rate_limit',
  
  /** Permanent errors that should not be retried (400, 401, 403, 404) */
  PERMANENT = 'permanent',
  
  /** Server errors that might be temporary (500, 502, 503) */
  SERVER_ERROR = 'server_error',
  
  /** Unknown errors (default to transient for safety) */
  UNKNOWN = 'unknown',
}

export interface ErrorClassification {
  category: ErrorCategory;
  shouldRetry: boolean;
  message: string;
  httpStatus?: number;
  errorCode?: string;
}

export class ErrorClassifier {
  /**
   * Classify an error to determine if it should be retried
   */
  static classify(error: Error | unknown): ErrorClassification {
    // Handle null/undefined
    if (!error) {
      return {
        category: ErrorCategory.UNKNOWN,
        shouldRetry: false,
        message: 'Unknown error (null/undefined)',
      };
    }

    // Convert to Error if needed
    const err = error instanceof Error ? error : new Error(String(error));
    const message = err.message.toLowerCase();

    // Check for rate limit errors (ALWAYS retry with backoff)
    if (this.isRateLimitError(err, message)) {
      return {
        category: ErrorCategory.RATE_LIMIT,
        shouldRetry: true,
        message: 'Rate limit exceeded',
        httpStatus: this.extractHttpStatus(err),
        errorCode: this.extractErrorCode(err),
      };
    }

    // Check for network/timeout errors (TRANSIENT - retry)
    if (this.isTransientError(err, message)) {
      return {
        category: ErrorCategory.TRANSIENT,
        shouldRetry: true,
        message: 'Transient network error',
        httpStatus: this.extractHttpStatus(err),
      };
    }

    // Check for permanent errors (DO NOT retry)
    if (this.isPermanentError(err, message)) {
      return {
        category: ErrorCategory.PERMANENT,
        shouldRetry: false,
        message: 'Permanent error (invalid request)',
        httpStatus: this.extractHttpStatus(err),
        errorCode: this.extractErrorCode(err),
      };
    }

    // Check for server errors (MAYBE retry)
    if (this.isServerError(err, message)) {
      return {
        category: ErrorCategory.SERVER_ERROR,
        shouldRetry: true,
        message: 'Server error (may be temporary)',
        httpStatus: this.extractHttpStatus(err),
      };
    }

    // Default to UNKNOWN (be conservative - don't retry by default)
    return {
      category: ErrorCategory.UNKNOWN,
      shouldRetry: false,
      message: err.message || 'Unknown error',
    };
  }

  /**
   * Check if error is a rate limit error
   */
  private static isRateLimitError(err: Error, message: string): boolean {
    const httpStatus = this.extractHttpStatus(err);
    
    // HTTP 429 Too Many Requests
    if (httpStatus === 429) return true;
    
    // Common rate limit keywords
    const rateLimitKeywords = [
      'rate limit',
      'too many requests',
      'quota exceeded',
      'throttled',
      'rate_limit_exceeded',
    ];
    
    return rateLimitKeywords.some(keyword => message.includes(keyword));
  }

  /**
   * Check if error is transient (network/timeout)
   */
  private static isTransientError(err: Error, message: string): boolean {
    const httpStatus = this.extractHttpStatus(err);
    
    // Network/timeout errors
    const transientKeywords = [
      'timeout',
      'timed out',
      'network',
      'connection',
      'econnrefused',
      'enotfound',
      'econnreset',
      'etimedout',
      'socket hang up',
    ];
    
    // HTTP status codes that indicate transient issues
    const transientStatuses = [408, 504]; // Request Timeout, Gateway Timeout
    
    return (
      transientStatuses.includes(httpStatus || 0) ||
      transientKeywords.some(keyword => message.includes(keyword))
    );
  }

  /**
   * Check if error is permanent (client error)
   */
  private static isPermanentError(err: Error, message: string): boolean {
    const httpStatus = this.extractHttpStatus(err);
    
    // Client errors that should NOT be retried
    const permanentStatuses = [
      400, // Bad Request
      401, // Unauthorized
      403, // Forbidden
      404, // Not Found
      405, // Method Not Allowed
      422, // Unprocessable Entity
    ];
    
    // Keywords indicating permanent errors
    const permanentKeywords = [
      'invalid',
      'unauthorized',
      'forbidden',
      'not found',
      'bad request',
      'authentication failed',
      'permission denied',
    ];
    
    return (
      permanentStatuses.includes(httpStatus || 0) ||
      permanentKeywords.some(keyword => message.includes(keyword))
    );
  }

  /**
   * Check if error is a server error (5xx)
   */
  private static isServerError(err: Error, message: string): boolean {
    const httpStatus = this.extractHttpStatus(err);
    
    // Server errors (5xx) - may be temporary
    if (httpStatus && httpStatus >= 500 && httpStatus < 600) {
      return true;
    }
    
    // Common server error keywords
    const serverErrorKeywords = [
      'internal server error',
      'service unavailable',
      'bad gateway',
      'gateway timeout',
    ];
    
    return serverErrorKeywords.some(keyword => message.includes(keyword));
  }

  /**
   * Extract HTTP status code from error
   */
  private static extractHttpStatus(err: any): number | undefined {
    // Check common properties where status might be stored
    if (typeof err.status === 'number') return err.status;
    if (typeof err.statusCode === 'number') return err.statusCode;
    if (typeof err.response?.status === 'number') return err.response.status;
    
    // Try to parse from message
    const match = err.message?.match(/\b(4\d{2}|5\d{2})\b/);
    return match ? parseInt(match[1], 10) : undefined;
  }

  /**
   * Extract error code from error
   */
  private static extractErrorCode(err: any): string | undefined {
    if (typeof err.code === 'string') return err.code;
    if (typeof err.errorCode === 'string') return err.errorCode;
    if (typeof err.response?.code === 'string') return err.response.code;
    return undefined;
  }
}