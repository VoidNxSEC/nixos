import { describe, it } from 'node:test';
import assert from 'node:assert';
import { ErrorClassifier, ErrorCategory } from '../src/middleware/error-classifier.js';

describe('ErrorClassifier', () => {
  it('should classify rate limit errors (429)', () => {
    const error: any = new Error('Too many requests');
    error.status = 429;

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.RATE_LIMIT);
    assert.strictEqual(classification.shouldRetry, true);
    assert.strictEqual(classification.httpStatus, 429);
  });

  it('should classify rate limit by keyword', () => {
    const error = new Error('Rate limit exceeded');

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.RATE_LIMIT);
    assert.strictEqual(classification.shouldRetry, true);
  });

  it('should classify transient errors', () => {
    const error: any = new Error('Connection timeout');
    error.code = 'ETIMEDOUT';

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.TRANSIENT);
    assert.strictEqual(classification.shouldRetry, true);
  });

  it('should classify permanent errors (401)', () => {
    const error: any = new Error('Unauthorized');
    error.status = 401;

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.PERMANENT);
    assert.strictEqual(classification.shouldRetry, false);
    assert.strictEqual(classification.httpStatus, 401);
  });

  it('should classify permanent errors (404)', () => {
    const error: any = new Error('Not found');
    error.status = 404;

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.PERMANENT);
    assert.strictEqual(classification.shouldRetry, false);
  });

  it('should classify server errors (5xx)', () => {
    const error: any = new Error('Internal server error');
    error.status = 500;

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.SERVER_ERROR);
    assert.strictEqual(classification.shouldRetry, true);
    assert.strictEqual(classification.httpStatus, 500);
  });

  it('should classify unknown errors conservatively', () => {
    const error = new Error('Some weird error');

    const classification = ErrorClassifier.classify(error);

    assert.strictEqual(classification.category, ErrorCategory.UNKNOWN);
    assert.strictEqual(classification.shouldRetry, false); // Conservative: don't retry
  });

  it('should handle null/undefined errors', () => {
    const classification = ErrorClassifier.classify(null);

    assert.strictEqual(classification.category, ErrorCategory.UNKNOWN);
    assert.strictEqual(classification.shouldRetry, false);
  });
});