import { describe, it } from 'node:test';
import assert from 'node:assert';
import { CircuitBreaker } from '../src/middleware/circuit-breaker.js';
import { createMockFunction, sleep } from './setup.js';

describe('CircuitBreaker', () => {
  it('should start in closed state', () => {
    const cb = new CircuitBreaker(3, 1000);
    assert.strictEqual(cb.getState(), 'closed');
  });

  it('should open after threshold failures', async () => {
    const cb = new CircuitBreaker(3, 1000);
    const failingFn = createMockFunction(5, 'Test error');

    // First 3 failures
    for (let i = 0; i < 3; i++) {
      try {
        await cb.execute(failingFn);
      } catch (e) {
        // Expected
      }
    }

    assert.strictEqual(cb.getState(), 'open', 'Circuit should be open after threshold');
  });

  it('should fail fast when open', async () => {
    const cb = new CircuitBreaker(2, 1000);
    const failingFn = createMockFunction(5, 'Test error');

    // Trigger circuit to open
    for (let i = 0; i < 2; i++) {
      try {
        await cb.execute(failingFn);
      } catch (e) {
        // Expected
      }
    }

    // Next call should fail immediately
    try {
      await cb.execute(failingFn);
      assert.fail('Should have thrown CircuitBreakerError');
    } catch (e: any) {
      assert.ok(e.message.includes('Circuit breaker is open'));
    }
  });

  it('should transition to half-open after timeout', async () => {
    const cb = new CircuitBreaker(2, 1000); // 1000ms timeout
    const failingFn = createMockFunction(5, 'Test error');

    // Open the circuit
    for (let i = 0; i < 2; i++) {
      try {
        await cb.execute(failingFn);
      } catch (e) {
        // Expected
      }
    }

    assert.strictEqual(cb.getState(), 'open');

    // Wait for timeout
    await sleep(1100);

    // Next call should transition to half-open
    try {
      await cb.execute(failingFn);
    } catch (e) {
      // Expected to fail but should be in half-open
    }

    assert.strictEqual(cb.getState(), 'open', 'Should reopen after half-open failure');
  });

  it('should close after successful half-open attempts', async () => {
    const cb = new CircuitBreaker(2, 1000, 2); // 2 half-open attempts
    const failThenSucceed = createMockFunction(2, 'Test error');

    // Open the circuit
    for (let i = 0; i < 2; i++) {
      try {
        await cb.execute(failThenSucceed);
      } catch (e) {
        // Expected
      }
    }

    // Wait for timeout
    await sleep(1100);

    // Succeed in half-open state (2 attempts needed)
    await cb.execute(failThenSucceed);
    await cb.execute(failThenSucceed);

    assert.strictEqual(cb.getState(), 'closed', 'Should close after successful half-open');
  });
});