# Rate Limiter Test Suite

Comprehensive unit tests for the Smart Rate Limiter system.

## Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run specific test file
node --test tests/circuit-breaker.test.js
```

## Test Coverage

- **Circuit Breaker**: State transitions, failure thresholds, half-open recovery
- **Retry Strategy**: Exponential, linear, fibonacci algorithms with jitter
- **Error Classifier**: Error categorization, HTTP status detection, keyword matching
- **Metrics Collector**: Success/failure tracking, percentiles, queue metrics

## Test Structure

Each test file follows this pattern:
1. Setup test utilities from `tests/setup.ts`
2. Group related tests with `describe()`
3. Individual test cases with `it()`
4. Assertions using Node.js built-in `assert` module

## Adding New Tests

1. Create new file: `tests/your-feature.test.ts`
2. Import necessary modules
3. Write test cases
4. Run `npm test` to verify