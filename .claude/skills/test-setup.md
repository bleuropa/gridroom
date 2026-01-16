---
name: test-setup
description: Setting up tests for new code. Covers unit tests, integration tests, and test organization.
---

# Test Setup Skill

Guidance for writing effective tests, organizing test files, and establishing good testing practices.

## When To Use

- Adding tests to new features
- Setting up test infrastructure
- Improving test coverage
- Learning testing patterns

## Test Types

### Unit Tests

**What**: Test individual functions/classes in isolation
**When**: Pure logic, utilities, business rules
**Speed**: Fast (milliseconds)
**Dependencies**: Mock external dependencies

```javascript
// Example: Testing a pure function
describe('calculateDiscount', () => {
  it('applies 10% discount for premium users', () => {
    const result = calculateDiscount(100, 'premium')
    expect(result).toBe(90)
  })

  it('returns original price for regular users', () => {
    const result = calculateDiscount(100, 'regular')
    expect(result).toBe(100)
  })

  it('handles zero price', () => {
    const result = calculateDiscount(0, 'premium')
    expect(result).toBe(0)
  })
})
```

### Integration Tests

**What**: Test multiple components working together
**When**: API endpoints, database operations, service interactions
**Speed**: Slower (seconds)
**Dependencies**: Use real dependencies or test doubles

```javascript
// Example: Testing an API endpoint
describe('POST /api/users', () => {
  it('creates user and returns 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'Test User', email: 'test@example.com' })

    expect(response.status).toBe(201)
    expect(response.body.user).toMatchObject({
      name: 'Test User',
      email: 'test@example.com'
    })
  })

  it('returns 400 for invalid email', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'Test', email: 'invalid' })

    expect(response.status).toBe(400)
  })
})
```

### End-to-End Tests

**What**: Test complete user workflows
**When**: Critical user paths, full stack verification
**Speed**: Slowest (seconds to minutes)
**Dependencies**: Full application stack

```javascript
// Example: E2E test
test('user can complete checkout', async ({ page }) => {
  await page.goto('/products')
  await page.click('[data-testid="add-to-cart"]')
  await page.click('[data-testid="checkout"]')
  await page.fill('[name="cardNumber"]', '4242424242424242')
  await page.click('[data-testid="place-order"]')

  await expect(page.locator('.order-confirmation')).toBeVisible()
})
```

## Test Organization

### File Structure

```
your-project/
├── src/
│   ├── utils.js
│   ├── user-service.js
│   └── api/
│       └── users.js
├── tests/
│   ├── unit/
│   │   ├── utils.test.js
│   │   └── user-service.test.js
│   ├── integration/
│   │   └── api/
│   │       └── users.test.js
│   └── e2e/
│       └── checkout.spec.js
```

**Naming conventions**:
- Unit tests: `[filename].test.js` or `[filename].spec.js`
- Integration tests: `[feature].integration.test.js`
- E2E tests: `[workflow].e2e.spec.js`

### Test Structure (AAA Pattern)

```javascript
test('descriptive test name', () => {
  // Arrange - Set up test data and conditions
  const user = { id: 1, name: 'Test' }
  const service = new UserService()

  // Act - Execute the code being tested
  const result = service.formatUser(user)

  // Assert - Verify the results
  expect(result).toBe('User: Test')
})
```

## Writing Good Tests

### Good Test Names

❌ **Bad**:
```javascript
test('it works', ...)
test('test user', ...)
test('should work correctly', ...)
```

✅ **Good**:
```javascript
test('returns 404 when user not found', ...)
test('calculates total including tax', ...)
test('validates email format', ...)
```

### Test One Thing

❌ **Bad** (tests multiple things):
```javascript
test('user service', () => {
  const user = service.create({ name: 'Test' })
  expect(user.id).toBeDefined()

  service.update(user.id, { name: 'Updated' })
  expect(service.find(user.id).name).toBe('Updated')

  service.delete(user.id)
  expect(service.find(user.id)).toBeNull()
})
```

✅ **Good** (separate tests):
```javascript
test('create returns user with ID', () => {
  const user = service.create({ name: 'Test' })
  expect(user.id).toBeDefined()
})

test('update modifies user name', () => {
  const user = service.create({ name: 'Test' })
  service.update(user.id, { name: 'Updated' })
  expect(service.find(user.id).name).toBe('Updated')
})

test('delete removes user', () => {
  const user = service.create({ name: 'Test' })
  service.delete(user.id)
  expect(service.find(user.id)).toBeNull()
})
```

### Test Edge Cases

```javascript
describe('divide', () => {
  it('divides two positive numbers', () => {
    expect(divide(10, 2)).toBe(5)
  })

  it('divides negative numbers', () => {
    expect(divide(-10, 2)).toBe(-5)
  })

  it('throws when dividing by zero', () => {
    expect(() => divide(10, 0)).toThrow('Division by zero')
  })

  it('handles decimal results', () => {
    expect(divide(10, 3)).toBeCloseTo(3.333, 2)
  })
})
```

## Mocking and Stubbing

### When to Mock

**Mock external dependencies**:
- API calls
- Database queries
- File system
- External services
- Time/dates

**Don't mock**:
- Code you're testing
- Simple utilities
- Your own business logic

### Example: Mocking API Call

```javascript
// Mock the HTTP client
jest.mock('./http-client')

test('fetches user data', async () => {
  // Setup mock response
  httpClient.get.mockResolvedValue({
    data: { id: 1, name: 'Test' }
  })

  // Test code that uses httpClient
  const user = await fetchUser(1)

  expect(user.name).toBe('Test')
  expect(httpClient.get).toHaveBeenCalledWith('/users/1')
})
```

## Test Fixtures and Factories

### Create Test Data Helpers

```javascript
// test/fixtures/user-factory.js
export function createUser(overrides = {}) {
  return {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    role: 'user',
    ...overrides
  }
}

// In tests
const admin = createUser({ role: 'admin' })
const john = createUser({ name: 'John', email: 'john@example.com' })
```

## Common Testing Patterns

### Setup and Teardown

```javascript
describe('User database', () => {
  beforeAll(async () => {
    // Runs once before all tests
    await database.connect()
  })

  afterAll(async () => {
    // Runs once after all tests
    await database.disconnect()
  })

  beforeEach(() => {
    // Runs before each test
    jest.clearAllMocks()
  })

  afterEach(async () => {
    // Runs after each test
    await database.clearAllTables()
  })
})
```

### Parameterized Tests

```javascript
describe.each([
  { input: 0, expected: 'zero' },
  { input: 1, expected: 'one' },
  { input: 5, expected: 'five' },
  { input: 10, expected: 'ten' }
])('numberToWord($input)', ({ input, expected }) => {
  test(`returns "${expected}"`, () => {
    expect(numberToWord(input)).toBe(expected)
  })
})
```

## Testing Async Code

### Promises

```javascript
test('fetches user data', async () => {
  const user = await fetchUser(1)
  expect(user.name).toBe('Test')
})

// Or with .resolves
test('fetches user data', () => {
  return expect(fetchUser(1)).resolves.toMatchObject({
    name: 'Test'
  })
})
```

### Error Handling

```javascript
test('throws error for invalid ID', async () => {
  await expect(fetchUser(-1)).rejects.toThrow('Invalid ID')
})
```

## Test Coverage

### What to Aim For

- **Critical paths**: 100% coverage
- **Business logic**: 90%+ coverage
- **Utilities**: 80%+ coverage
- **UI components**: Behavior over coverage %

### Measuring Coverage

```bash
# Most test runners have coverage options
npm test -- --coverage
pytest --cov=src
cargo test --coverage
```

### Coverage ≠ Quality

✅ **Good**: High coverage of critical logic with meaningful assertions
❌ **Bad**: High coverage with weak assertions that don't verify behavior

## Checklist

When writing tests:
- [ ] Test name describes what's being tested
- [ ] Test is focused (tests one thing)
- [ ] Edge cases covered
- [ ] Assertions are meaningful
- [ ] External dependencies mocked
- [ ] Test data is clear and minimal
- [ ] Tests are independent (no shared state)
- [ ] Tests run fast (especially unit tests)

## Remember

- Tests are documentation of how code should work
- Good tests catch bugs before production
- Fast tests encourage running them often
- Flaky tests erode confidence
- Tests should be as simple as possible

## Customize

Add YOUR project's testing patterns:
- Testing framework setup (Jest, Vitest, pytest, etc.)
- Mock/stub libraries
- Test database setup
- CI/CD integration
- Coverage requirements
- Common test utilities
