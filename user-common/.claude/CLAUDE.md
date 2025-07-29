# Development Guidelines for Claude

## Core Philosophy

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE.** Every single line of production code must be written in response to a failing test. No exceptions. This is not a suggestion or a preference - it is the fundamental practice that enables all other principles in this document.

I follow Test-Driven Development (TDD) with a strong emphasis on behavior-driven testing and functional programming principles. All work should be done in small, incremental changes that maintain a working state throughout development.

## Universal Principles

**Core Practices:**

- Write tests first (TDD) - Red-Green-Refactor cycle
- Test behavior, not implementation details
- Immutable data structures only
- Small, pure functions with single responsibilities
- 100% test coverage through business behavior

**Code Quality:**

- Self-documenting code without comments
- Early returns over nested conditionals
- Composition over complex abstractions

## Testing Principles

### Behavior-Driven Testing

- **No "unit tests"** - this term is not helpful. Tests should verify expected behavior, treating implementation as a black box
- Test through the public API exclusively - internals should be invisible to tests
- No 1:1 mapping between test files and implementation files
- Tests that examine internal implementation details are wasteful and should be avoided
- **Coverage targets**: 100% coverage should be expected at all times, but these tests must ALWAYS be based on business behaviour, not implementation details
- Tests must document expected business behaviour

### Test Organization Pattern

```
src/
  features/
    payment/
      payment-processor.[ext]
      payment-validator.[ext]
      payment-processor.test.[ext] // Validator is implementation detail, covered through behavior
```

### Test Data Pattern

Use factory functions with optional overrides for test data:

```
const getMockEntity = (overrides?) => {
  return {
    // Complete object with sensible defaults
    ...baseDefaults,
    ...overrides,
  };
};
```

Key principles:

- Always return complete objects with sensible defaults
- Accept optional overrides parameter
- Build incrementally - extract nested object factories as needed
- Compose factories for complex objects
- Use real schemas/types from the project, never redefine in tests

## Code Style

### Functional Programming

I follow a "functional light" approach:

- **No data mutation** - work with immutable data structures
- **Pure functions** wherever possible
- **Composition** as the primary mechanism for code reuse
- Avoid heavy FP abstractions (no need for complex monads or pipe/compose patterns) unless there is a clear advantage to using them

#### Universal Functional Patterns

```
// Good - Pure function with immutable updates
const applyDiscount = (order, discountPercent) => {
  return {
    ...order,
    items: order.items.map(item => ({
      ...item,
      price: item.price * (1 - discountPercent / 100),
    })),
    totalPrice: calculateNewTotal(order.items, discountPercent),
  };
};

// Good - Composition over complex logic
const processOrder = (order) => {
  return pipe(
    order,
    validateOrder,
    applyPromotions,
    calculateTax,
    assignWarehouse
  );
};
```

### Code Structure

- **No nested if/else statements** - use early returns, guard clauses, or composition
- **Avoid deep nesting** in general (max 2 levels)
- Keep functions small and focused on a single responsibility
- Prefer flat, readable code over clever abstractions

### Naming Conventions

**Universal patterns:**
- **Functions**: verb-based, descriptive names (e.g., `calculateTotal`, `validatePayment`)
- **Constants**: `UPPER_SNAKE_CASE` for true constants

### No Comments in Code

Code should be self-documenting through clear naming and structure. Comments indicate that the code itself is not clear enough.

```
// Avoid: Comments explaining what the code does
const calculateDiscount = (price, customer) => {
  // Check if customer is premium
  if (customer.tier === "premium") {
    // Apply 20% discount for premium customers
    return price * 0.8;
  }
  // Regular customers get 10% discount
  return price * 0.9;
};

// Good: Self-documenting code with clear names
const PREMIUM_DISCOUNT_MULTIPLIER = 0.8;
const STANDARD_DISCOUNT_MULTIPLIER = 0.9;

const isPremiumCustomer = (customer) => {
  return customer.tier === "premium";
};

const calculateDiscount = (price, customer) => {
  const discountMultiplier = isPremiumCustomer(customer)
    ? PREMIUM_DISCOUNT_MULTIPLIER
    : STANDARD_DISCOUNT_MULTIPLIER;

  return price * discountMultiplier;
};
```

## Development Workflow

### TDD Process - THE FUNDAMENTAL PRACTICE

**CRITICAL**: TDD is not optional. Every feature, every bug fix, every change MUST follow this process:

Follow Red-Green-Refactor strictly:

1. **Red**: Write a failing test for the desired behavior. NO PRODUCTION CODE until you have a failing test.
2. **Green**: Write the MINIMUM code to make the test pass. Resist the urge to write more than needed.
3. **Refactor**: Assess the code for improvement opportunities. If refactoring would add value, clean up the code while keeping tests green. If the code is already clean and expressive, move on.

**Common TDD Violations to Avoid:**

- Writing production code without a failing test first
- Writing multiple tests before making the first one pass
- Writing more production code than needed to pass the current test
- Skipping the refactor assessment step when code could be improved
- Adding functionality "while you're there" without a test driving it

**Remember**: If you're typing production code and there isn't a failing test demanding that code, you're not doing TDD.

#### TDD Example Workflow

```
// Step 1: Red - Start with the simplest behavior
describe("Order processing", () => {
  it("should calculate total with shipping cost", () => {
    const order = createOrder({
      items: [{ price: 30, quantity: 1 }],
      shippingCost: 5.99,
    });

    const processed = processOrder(order);

    expect(processed.total).toBe(35.99);
    expect(processed.shippingCost).toBe(5.99);
  });
});

// Step 2: Green - Minimal implementation
const processOrder = (order) => {
  const itemsTotal = sumItemPrices(order.items);
  return {
    ...order,
    shippingCost: order.shippingCost,
    total: itemsTotal + order.shippingCost,
  };
};

// Step 3: Red - Add test for business rule
// Step 4: Green - Add minimal code to pass
// Step 5: Refactor - Extract meaningful functions

const FREE_SHIPPING_THRESHOLD = 50;

const processOrder = (order) => {
  const itemsTotal = calculateItemsTotal(order.items);
  const shippingCost = qualifiesForFreeShipping(itemsTotal)
    ? 0
    : order.shippingCost;

  return { ...order, shippingCost, total: itemsTotal + shippingCost };
};
```

### Refactoring - The Critical Third Step

Evaluating refactoring opportunities is not optional - it's the third step in the TDD cycle. After achieving a green state and committing your work, you MUST assess whether the code can be improved. However, only refactor if there's clear value - if the code is already clean and expresses intent well, move on to the next test.

#### What is Refactoring?

Refactoring means changing the internal structure of code without changing its external behavior. The public API remains unchanged, all tests continue to pass, but the code becomes cleaner, more maintainable, or more efficient. Remember: only refactor when it genuinely improves the code - not all code needs refactoring.

#### When to Refactor

- **Always assess after green**: Once tests pass, before moving to the next test, evaluate if refactoring would add value
- **When you see duplication**: But understand what duplication really means (see DRY below)
- **When names could be clearer**: Variable names, function names, or type names that don't clearly express intent
- **When structure could be simpler**: Complex conditional logic, deeply nested code, or long functions
- **When patterns emerge**: After implementing several similar features, useful abstractions may become apparent

**Remember**: Not all code needs refactoring. If the code is already clean, expressive, and well-structured, commit and move on. Refactoring should improve the code - don't change things just for the sake of change.

#### Refactoring Guidelines

##### 1. Commit Before Refactoring

Always commit your working code before starting any refactoring. This gives you a safe point to return to:

```bash
git add .
git commit -m "feat: add payment validation"
# Now safe to refactor
```

##### 2. Look for Useful Abstractions Based on Semantic Meaning

Create abstractions only when code shares the same semantic meaning and purpose. Don't abstract based on structural similarity alone - **duplicate code is far cheaper than the wrong abstraction**.

**Questions to ask before abstracting:**

- Do these code blocks represent the same concept or different concepts that happen to look similar?
- If the business rules for one change, should the others change too?
- Would a developer reading this abstraction understand why these things are grouped together?
- Am I abstracting based on what the code IS (structure) or what it MEANS (semantics)?

**Remember**: It's much easier to create an abstraction later when the semantic relationship becomes clear than to undo a bad abstraction that couples unrelated concepts.

##### 3. Understanding DRY - It's About Knowledge, Not Code

DRY (Don't Repeat Yourself) is about not duplicating **knowledge** in the system, not about eliminating all code that looks similar.

```
// This is NOT a DRY violation - different knowledge despite similar code
const validateUserAge = (age) => age >= 18 && age <= 100;
const validateProductRating = (rating) => rating >= 1 && rating <= 5;
const validateYearsOfExperience = (years) => years >= 0 && years <= 50;

// These represent completely different business rules:
// - User age has legal requirements (18+) and practical limits (100)
// - Product ratings follow a 1-5 star system
// - Years of experience starts at 0 with reasonable upper bound
// Abstracting them would couple unrelated business concepts

// This IS a DRY violation - same knowledge in multiple places
const FREE_SHIPPING_THRESHOLD = 50; // Knowledge duplicated across functions!
const STANDARD_SHIPPING_COST = 5.99;

const calculateShippingCost = (itemsTotal) => {
  return itemsTotal > FREE_SHIPPING_THRESHOLD ? 0 : STANDARD_SHIPPING_COST;
};
// Now all classes use the single source of truth
```

##### 4. Maintain External APIs During Refactoring

Refactoring must never break existing consumers of your code.

##### 5. Verify and Commit After Refactoring

**CRITICAL**: After every refactoring:

1. Run all tests - they must pass without modification
2. Run static analysis and quality checks - must pass
3. Commit the refactoring separately from feature changes

#### Refactoring Checklist

Before considering refactoring complete, verify:

- [ ] The refactoring actually improves the code (if not, don't refactor)
- [ ] All tests still pass without modification
- [ ] All static analysis and quality checks pass
- [ ] No new public APIs were added (only internal ones)
- [ ] Code is more readable than before
- [ ] Any duplication removed was duplication of knowledge, not just code
- [ ] No speculative abstractions were created
- [ ] The refactoring is committed separately from feature changes

#### Example Refactoring Session

```
// After getting tests green with minimal implementation:
describe("Order processing", () => {
  it("calculates total with items and shipping", () => {
    const order = { items: [{ price: 30 }, { price: 20 }], shipping: 5 };
    expect(calculateOrderTotal(order)).toBe(55);
  });

  it("applies free shipping over threshold", () => {
    const order = { items: [{ price: 30 }, { price: 25 }], shipping: 5 };
    expect(calculateOrderTotal(order)).toBe(55);
  });
});

// Green implementation (minimal):
const calculateOrderTotal = (order) => {
  const itemsTotal = order.items.reduce((sum, item) => sum + item.price, 0);
  const shipping = itemsTotal > 50 ? 0 : order.shipping;
  return itemsTotal + shipping;
};

// Commit working version
// git commit -m "feat: implement order total calculation"

// Assess refactoring opportunities and extract meaningful functions:
const FREE_SHIPPING_THRESHOLD = 50;

const calculateOrderTotal = (order) => {
  const itemsTotal = calculateItemsTotal(order.items);
  const shipping = calculateShipping(order.shipping, itemsTotal);
  return itemsTotal + shipping;
};

// Run tests and quality checks - all pass!
// git commit -m "refactor: extract calculation helpers"
```

##### Example: When NOT to Refactor

```
// After getting this test green:
describe("Discount calculation", () => {
  it("should apply 10% discount", () => {
    const originalPrice = 100;
    const discountedPrice = applyDiscount(originalPrice, 0.1);
    expect(discountedPrice).toBe(90);
  });
});

// Green implementation:
const applyDiscount = (price, discountRate) => {
  return price * (1 - discountRate);
};

// Assess refactoring opportunities:
// - Code is already simple and clear
// - Function name clearly expresses intent
// - Implementation is straightforward
// - No unclear logic or magic numbers
// Conclusion: No refactoring needed.

// Commit and move to the next test
```

### Commit Guidelines

- Each commit should represent a complete, working change
- Use conventional commits format:
  ```
  feat: add payment validation
  fix: correct date formatting in payment processor
  refactor: extract payment validation logic
  test: add edge cases for payment validation
  ```
- Include test changes with feature changes in the same commit

### Pull Request Standards

- Every PR must have all tests passing
- All linting and quality checks must pass
- Work in small increments that maintain a working state
- PRs should be focused on a single feature or fix
- Include description of the behavior change, not implementation details

## Working with Claude

### Critical Instructions

1. **ALWAYS FOLLOW TDD** - No production code without a failing test. This is not negotiable.
2. **Think deeply** before making any edits
3. **Understand the full context** of the code and requirements
4. **Ask clarifying questions** when requirements are ambiguous
5. **Think from first principles** - don't make assumptions
6. **Assess refactoring after every green** - Look for opportunities to improve code structure, but only refactor if it adds value
7. **Keep project docs current** - update them whenever you introduce meaningful changes

### Code Changes Process

1. **Start with a failing test** - always. No exceptions.
2. **Write minimal code** to make test pass
3. **Assess refactoring opportunities** (but only refactor if it adds value)
4. **Verify all tests and quality checks pass**
5. **Commit changes**

Key principles:
- Respect existing patterns and conventions
- Maintain test coverage for all behavior changes
- Keep changes small and incremental
- Follow established code quality standards
- Provide rationale for significant design decisions

**If you find yourself writing production code without a failing test, STOP immediately and write the test first.**

### Communication

- Be explicit about trade-offs in different approaches
- Explain the reasoning behind significant design decisions
- Flag any deviations from these guidelines with justification
- Suggest improvements that align with these principles
- When unsure, ask for clarification rather than assuming

## Universal Error Handling Patterns

```
// Good - Result type pattern (adapt to language)
const processPayment = (payment) => {
  if (!isValidPayment(payment)) {
    return { success: false, error: "Invalid payment" };
  }

  if (!hasSufficientFunds(payment)) {
    return { success: false, error: "Insufficient funds" };
  }

  return { success: true, data: executePayment(payment) };
};

// Also good - early returns with exceptions
const processPayment = (payment) => {
  if (!isValidPayment(payment)) {
    throw new PaymentError("Invalid payment");
  }

  if (!hasSufficientFunds(payment)) {
    throw new PaymentError("Insufficient funds");
  }

  return executePayment(payment);
};
```

## Testing Behavior Examples

```
// Good - tests behavior through public API
describe("PaymentProcessor", () => {
  it("should decline payment when insufficient funds", () => {
    const payment = createMockPayment({ amount: 1000 });
    const account = createMockAccount({ balance: 500 });

    const result = processPayment(payment, account);

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Insufficient funds");
  });

  it("should process valid payment successfully", () => {
    const payment = createMockPayment({ amount: 100 });
    const account = createMockAccount({ balance: 500 });

    const result = processPayment(payment, account);

    expect(result.success).toBe(true);
    expect(result.data.remainingBalance).toBe(400);
  });
});

// Avoid - testing implementation details
describe("PaymentProcessor", () => {
  it("should call checkBalance method", () => {
    // This tests implementation, not behavior
  });
});
```

### Achieving 100% Coverage Through Business Behavior

```
// validation.ext (implementation detail)
export const validateAmount = (amount) => amount > 0 && amount <= 10000;

// processor.ext (public API)
export const processPayment = (request) => {
  if (!validateAmount(request.amount)) {
    return { success: false, error: "Invalid amount" };
  }
  // Process payment...
  return { success: true, data: executedPayment };
};

// processor.test.ext - 100% validation coverage without direct testing
describe("Payment processing", () => {
  it("should reject negative amounts", () => {
    const result = processPayment({ amount: -100 });
    expect(result.success).toBe(false);
  });

  it("should reject amounts exceeding maximum", () => {
    const result = processPayment({ amount: 10001 });
    expect(result.success).toBe(false);
  });

  it("should process valid amounts", () => {
    const result = processPayment({ amount: 100 });
    expect(result.success).toBe(true);
  });
});
```

## Universal Anti-patterns to Avoid

```
// Avoid: Mutation
const addItem = (items, newItem) => {
  items.push(newItem); // Mutates array
  return items;
};

// Prefer: Immutable update
const addItem = (items, newItem) => {
  return [...items, newItem]; // or language equivalent
};

// Avoid: Nested conditionals
if (user) {
  if (user.isActive) {
    if (user.hasPermission) {
      // do something
    }
  }
}

// Prefer: Early returns
if (!user || !user.isActive || !user.hasPermission) {
  return;
}
// do something

// Avoid: Large functions
const processOrder = (order) => {
  // 100+ lines of code
};

// Prefer: Composed small functions
const processOrder = (order) => {
  const validatedOrder = validateOrder(order);
  const pricedOrder = calculatePricing(validatedOrder);
  const finalOrder = applyDiscounts(pricedOrder);
  return submitOrder(finalOrder);
};
```

## Mermaid Diagrams

When explaining architecture, topology, workflows, or any structural/process concepts, leverage Mermaid diagrams for visual clarity.

### Rules:
- **ONE diagram per request** - Display system limitation
- **Use**: `mermaid-show --display kitty-overlay "syntax"`
- **Types**: `graph TD` (flows), `sequenceDiagram` (interactions), `classDiagram` (structure), `erDiagram` (data)

### Examples:
```
graph TD; A[Start]-->B{Decision}; B-->C[End]
sequenceDiagram; User->>API: Request; API-->>User: Response
```

### Command:
```bash
mermaid-show --display kitty-overlay "graph TD; A-->B; B-->C;"
```

## Program Execution Guidelines

**Use Bash tool for:**
- Quick commands that complete immediately: `npm test`, `git status`, `python script.py`
- Build/install commands: `npm install`, `make build`
- File operations and utilities

**Use HT MCP tools for:**
- Long-running processes: `npm run dev`, `python manage.py runserver`
- Interactive TUI applications: `vim`, `htop`
- Programs requiring session management or continuous monitoring

Choose based on program behavior: immediate completion → Bash, persistent/interactive → HT MCP.

## Summary

The key is to write clean, testable, functional code that evolves through small, safe increments. Every change should be driven by a test that describes the desired behavior, and the implementation should be the simplest thing that makes that test pass.

When in doubt, favor simplicity and readability over cleverness.