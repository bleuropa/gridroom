# Adding Your Conventions

Balustrade enforces **example conventions**. Replace them with **your conventions**.

---

## What Balustrade Checks (Examples)

These are demonstrations, not requirements:

### 1. Temporal Language in Evergreen Docs
**What**: Blocks words like "will", "soon", "recently" in `vault/product/`, `vault/architecture/`, `vault/features/`

**Why**: Keeps docs timeless and current

**Where**: `.claude/hooks/pre-commit.sh` lines 59-70

**Customize**: Edit word list, add exceptions, or remove entirely

### 2. Task Structure
**What**: Validates task files have required fields (status, priority, created, updated)

**Why**: Consistent task tracking

**Where**: `.claude/hooks/pre-commit.sh` lines 76-106

**Customize**: Add your required fields, change valid statuses

### 3. Task Size
**What**: Warns if task has >7 checklist items

**Why**: Encourages right-sized work

**Where**: `.claude/hooks/pre-commit.sh` lines 112-131

**Customize**: Change threshold (line 123)

### 4. Conventional Commits
**What**: Enforces `type(scope): description` format

**Why**: Searchable history, clear changelogs

**Where**: `.claude/hooks/commit-msg.sh`

**Customize**: Add your types, change pattern

---

## Common Conventions To Add

### API Naming Standards

**Example**: All API routes must match REST pattern

```bash
# Add to pre-commit.sh

check_api_routes() {
    local file=$1

    # Only check API route files
    if echo "$file" | grep -qE 'routes/.*\.(js|ts)'; then
        # Check for non-REST patterns
        if grep -E 'app\.(get|post|put|delete)\("/[^/]+/[^/]+/[^/]+"' "$file"; then
            echo "❌ API route doesn't follow REST pattern: $file"
            echo "   Expected: /resource/:id not /nested/routes/here"
            exit 1
        fi
    fi
}
```

### Error Handling Pattern

**Example**: All errors must have error codes

```bash
check_error_codes() {
    local file=$1

    if echo "$file" | grep -qE '\.(js|ts)$'; then
        # Check for throw new Error without code
        if grep -n 'throw new Error(' "$file" | grep -v 'code:'; then
            echo "⚠️  Error without code in: $file"
            echo "   All errors should have error codes"
            # Warning only
        fi
    fi
}
```

### Test Coverage Requirement

**Example**: New features must include tests

```bash
check_test_coverage() {
    # Get new/modified files
    local feature_files=$(git diff --cached --name-only --diff-filter=AM | grep -E 'src/.*\.(js|ts)$')

    for file in $feature_files; do
        # Check if corresponding test file exists
        local test_file=$(echo "$file" | sed 's/src/test/' | sed 's/\.(js|ts)$/.test.\1/')

        if [ ! -f "$test_file" ]; then
            echo "⚠️  No test file for: $file"
            echo "   Expected: $test_file"
        fi
    done
}
```

### Database Migration Safety

**Example**: No dropping columns in migrations

```bash
check_migrations() {
    local file=$1

    if echo "$file" | grep -qE 'migrations/.*\.(js|sql)'; then
        if grep -iE '(drop column|drop table)' "$file"; then
            echo "❌ Destructive migration detected: $file"
            echo "   Use deprecation strategy instead of dropping"
            exit 1
        fi
    fi
}
```

### Documentation Requirements

**Example**: Public functions must have JSDoc

```bash
check_jsdoc() {
    local file=$1

    if echo "$file" | grep -qE '\.(js|ts)$'; then
        # Find exported functions without JSDoc
        # (This is a simplified check)
        if grep -A1 'export function' "$file" | grep -v '/\*\*'; then
            echo "⚠️  Exported function without JSDoc in: $file"
        fi
    fi
}
```

---

## Adding Your Convention

### Step 1: Identify The Rule

What do you want to enforce?
- Code pattern?
- Documentation standard?
- Naming convention?
- Process requirement?

### Step 2: Choose Hook Type

**pre-commit**: Validate code/docs before commit
**commit-msg**: Validate commit message
**post-commit**: Auto-update after commit
**pre-compaction**: Save context before memory compression

Most conventions go in **pre-commit**.

### Step 3: Write The Check

Template:
```bash
check_my_convention() {
    local file=$1

    # 1. Filter files (only check relevant ones)
    if ! echo "$file" | grep -qE 'pattern'; then
        return 0
    fi

    # 2. Run your check
    if [ condition ]; then
        # 3. Report violation
        echo "❌ Convention violated: $file"
        echo "   Explanation of what's wrong"
        exit 1  # Block commit
        # OR don't exit for warning only
    fi
}
```

### Step 4: Add To Pre-Commit Hook

Edit `.claude/hooks/pre-commit.sh`:

```bash
# Add your function before "Run All Checks"

# Then add to the checks:
for FILE in $STAGED_MD_FILES; do
    if [ -f "$FILE" ]; then
        check_temporal_language "$FILE"
        check_my_convention "$FILE"  # <-- Add here
    fi
done
```

### Step 5: Test It

```bash
# Make a change that violates your convention
git add .
git commit -m "test: my convention"

# Should block or warn
```

### Step 6: Document It

Add to `CONVENTIONS.md` in your project:
- What you check
- Why you check it
- How to customize
- Examples

---

## Convention Design Guidelines

### Good Conventions

✅ **Clear and objective** - No ambiguity about what's allowed
✅ **Easy to check** - Can be validated automatically
✅ **Helpful errors** - Messages explain how to fix
✅ **Appropriately strict** - Block real problems, warn about preferences

### Bad Conventions

❌ **Subjective** - "Code should be clean" (too vague)
❌ **Slow to check** - Don't make hooks take >5 seconds
❌ **Brittle** - Don't break on edge cases
❌ **Over-strict** - Don't block every minor style issue

---

## Examples From Real Projects

### Stripe
- API changes require versioning
- Breaking changes need deprecation period
- All endpoints have OpenAPI specs

### GitHub
- Feature flags for all new features
- Accessibility requirements for UI
- Security review for auth changes

### Shopify
- GraphQL schema changes need approval
- No N+1 queries in controllers
- All public APIs have examples

---

## The Point

Balustrade shows you **how** to enforce conventions.

The **specific conventions** are up to you.

Start with Balustrade's examples, then:
1. Keep what makes sense for your project
2. Remove what doesn't
3. Add your own

Your `.claude/hooks/` become **your team's conventions**, enforced automatically.
