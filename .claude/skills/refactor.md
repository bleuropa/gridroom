---
name: refactor
description: Code refactoring patterns and techniques. Improves code quality without changing behavior.
---

# Refactoring Skill

Apply systematic refactoring techniques to improve code quality, maintainability, and readability without changing external behavior.

## When To Use

- Code is working but hard to understand
- Duplicated code across files
- Functions too long or complex
- Poor naming
- Tight coupling
- Before adding new features to messy code

## Core Principles

1. **Preserve behavior** - Tests should still pass
2. **Small steps** - Refactor incrementally
3. **Test first** - Ensure tests exist before refactoring
4. **One thing at a time** - Don't mix refactoring with features
5. **Commit often** - Small, focused commits

## Common Refactorings

### Extract Function

**When**: Function too long, repeated code, or complex logic

```javascript
// Before
function processOrder(order) {
  // validate order (20 lines)
  // calculate total (15 lines)
  // apply discount (25 lines)
  // save to database (10 lines)
}

// After
function processOrder(order) {
  validateOrder(order)
  const total = calculateTotal(order)
  const finalTotal = applyDiscount(total, order.customerTier)
  saveOrder(order, finalTotal)
}
```

### Extract Variable

**When**: Complex expression hard to understand

```javascript
// Before
if (user.age >= 18 && user.hasLicense && user.violations < 3) {
  // allow rental
}

// After
const isEligibleToRent = user.age >= 18 &&
                         user.hasLicense &&
                         user.violations < 3
if (isEligibleToRent) {
  // allow rental
}
```

### Rename

**When**: Name doesn't reflect purpose

```javascript
// Before
const d = new Date()
const temp = calculateValue()
function process(x) { }

// After
const currentDate = new Date()
const userBalance = calculateBalance()
function processPayment(transaction) { }
```

### Remove Duplication

**When**: Same code in multiple places

```javascript
// Before
function formatUserName(user) {
  return user.firstName + ' ' + user.lastName
}
function displayUser(user) {
  const name = user.firstName + ' ' + user.lastName
  return `User: ${name}`
}

// After
function getFullName(user) {
  return `${user.firstName} ${user.lastName}`
}
function formatUserName(user) {
  return getFullName(user)
}
function displayUser(user) {
  return `User: ${getFullName(user)}`
}
```

### Simplify Conditional

**When**: Complex nested conditions

```javascript
// Before
if (user) {
  if (user.isActive) {
    if (user.hasPermission('admin')) {
      return true
    }
  }
}
return false

// After
return user?.isActive && user.hasPermission('admin')
```

### Replace Magic Numbers

**When**: Unexplained numeric literals

```javascript
// Before
if (user.loginAttempts > 5) {
  lockAccount()
}
setTimeout(retry, 300000)

// After
const MAX_LOGIN_ATTEMPTS = 5
const RETRY_DELAY_MS = 5 * 60 * 1000 // 5 minutes

if (user.loginAttempts > MAX_LOGIN_ATTEMPTS) {
  lockAccount()
}
setTimeout(retry, RETRY_DELAY_MS)
```

### Decompose Conditional

**When**: Conditional logic is complex

```javascript
// Before
if (date.getMonth() === 11 && date.getDate() > 20 ||
    date.getMonth() === 0 && date.getDate() < 7) {
  // holiday pricing
}

// After
function isHolidayPeriod(date) {
  return isChristmasWeek(date) || isNewYearsWeek(date)
}
function isChristmasWeek(date) {
  return date.getMonth() === 11 && date.getDate() > 20
}
function isNewYearsWeek(date) {
  return date.getMonth() === 0 && date.getDate() < 7
}

if (isHolidayPeriod(date)) {
  // holiday pricing
}
```

## Refactoring Process

### 1. Ensure Tests Exist

Before refactoring:
- Run tests to verify current behavior
- Add tests if missing
- Ensure tests are comprehensive

### 2. Make Small Changes

- One refactoring at a time
- Run tests after each change
- Commit if tests pass
- Revert if tests fail

### 3. Improve Incrementally

Don't try to perfect everything at once:
- Start with obvious improvements
- Focus on high-impact areas
- Stop when good enough

### 4. Document Intent

When refactoring reveals complexity:
- Add comments explaining why (not what)
- Update documentation
- Consider if further refactoring needed

## Red Flags (When NOT to Refactor)

❌ **Don't refactor if**:
- No tests exist (write tests first)
- Under time pressure (schedule it properly)
- Changing behavior (that's a feature, not refactoring)
- Just making it "your way" (style preferences aren't refactoring)

## Refactoring Checklist

Before:
- [ ] Tests exist and pass
- [ ] Understand current behavior
- [ ] Know what you're trying to improve

During:
- [ ] Make small, incremental changes
- [ ] Run tests after each change
- [ ] Commit successful changes

After:
- [ ] All tests still pass
- [ ] Code is more understandable
- [ ] No behavior changes
- [ ] Documentation updated if needed

## Common Patterns

### Long Function → Extract Methods
### Duplicated Code → Extract Common Function
### Complex Conditional → Extract Predicate Functions
### Magic Numbers → Named Constants
### Long Parameter List → Parameter Object
### Primitive Obsession → Value Objects
### Large Class → Extract Classes

## Remember

- Refactoring ≠ Rewriting
- Keep changes small and focused
- Tests are your safety net
- Commit often
- Don't mix refactoring with features
- Stop when improvement marginal

## Customize

Add YOUR project's refactoring patterns:
- Common code smells you see
- Refactorings that work well in your stack
- Team conventions
- Architecture patterns
