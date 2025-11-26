import { describe, it } from 'node:test';
import assert from 'node:assert';
import { RetryStrategy } from '../src/middleware/retry-strategy.js';

describe('RetryStrategy', () => {
  describe('Exponential backoff', () => {
    it('should calculate exponential delays', () => {
      const strategy = new RetryStrategy('exponential', 1000, 32000, 0);

      assert.strictEqual(strategy.calculateDelay(0), 1000);
      assert.strictEqual(strategy.calculateDelay(1), 2000);
      assert.strictEqual(strategy.calculateDelay(2), 4000);
      assert.strictEqual(strategy.calculateDelay(3), 8000);
      assert.strictEqual(strategy.calculateDelay(4), 16000);
      assert.strictEqual(strategy.calculateDelay(5), 32000); // Capped
      assert.strictEqual(strategy.calculateDelay(6), 32000); // Still capped
    });

    it('should add jitter to exponential delays', () => {
      const strategy = new RetryStrategy('exponential', 1000, 32000, 0.1);

      const delay1 = strategy.calculateDelay(1);
      const delay2 = strategy.calculateDelay(1);

      // Should be around 2000ms with ±10% jitter
      assert.ok(delay1 >= 1800 && delay1 <= 2200, `Expected delay ${delay1} to be 1800-2200`);
      assert.ok(delay2 >= 1800 && delay2 <= 2200, `Expected delay ${delay2} to be 1800-2200`);
      // Should be different due to jitter
      assert.notStrictEqual(delay1, delay2, 'Jitter should make delays different');
    });
  });

  describe('Linear backoff', () => {
    it('should calculate linear delays', () => {
      const strategy = new RetryStrategy('linear', 1000, 10000, 0);

      assert.strictEqual(strategy.calculateDelay(0), 1000);
      assert.strictEqual(strategy.calculateDelay(1), 1000);
      assert.strictEqual(strategy.calculateDelay(2), 2000);
      assert.strictEqual(strategy.calculateDelay(3), 3000);
      assert.strictEqual(strategy.calculateDelay(4), 4000);
      assert.strictEqual(strategy.calculateDelay(10), 10000); // Capped
    });
  });

  describe('Fibonacci backoff', () => {
    it('should calculate fibonacci delays', () => {
      const strategy = new RetryStrategy('fibonacci', 1000, 20000, 0);

      assert.strictEqual(strategy.calculateDelay(0), 1000);  // fib(0) = 1
      assert.strictEqual(strategy.calculateDelay(1), 1000);  // fib(1) = 1
      assert.strictEqual(strategy.calculateDelay(2), 2000);  // fib(2) = 2
      assert.strictEqual(strategy.calculateDelay(3), 3000);  // fib(3) = 3
      assert.strictEqual(strategy.calculateDelay(4), 5000);  // fib(4) = 5
      assert.strictEqual(strategy.calculateDelay(5), 8000);  // fib(5) = 8
      assert.strictEqual(strategy.calculateDelay(6), 13000); // fib(6) = 13
      assert.strictEqual(strategy.calculateDelay(7), 20000); // Capped
    });
  });
});