# TypeScript Development Guidelines

This document contains TypeScript-specific implementation guidelines that complement the language-agnostic principles in CLAUDE.md.

## TypeScript Configuration

### Strict Mode Requirements

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

- **No `any`** - ever. Use `unknown` if type is truly unknown
- **No type assertions** (`as SomeType`) unless absolutely necessary with clear justification
- **No `@ts-ignore`** or `@ts-expect-error` without explicit explanation
- These rules apply to test code as well as production code

## Type Definitions

- **Prefer `type` over `interface`** in all cases
- Use explicit typing where it aids clarity, but leverage inference where appropriate
- Utilize utility types effectively (`Pick`, `Omit`, `Partial`, `Required`, etc.)
- Create domain-specific types (e.g., `UserId`, `PaymentId`) for type safety

```typescript
// Good - branded types for domain safety
type UserId = string & { readonly brand: unique symbol };
type PaymentAmount = number & { readonly brand: unique symbol };

// Avoid - primitive types without domain meaning
type UserId = string;
type PaymentAmount = number;
```

## Schema-First Development with Zod

Always define your schemas first, then derive types from them:

```typescript
import { z } from "zod";

// Define schemas first - these provide runtime validation
const AddressDetailsSchema = z.object({
  houseNumber: z.string(),
  houseName: z.string().optional(),
  addressLine1: z.string().min(1),
  addressLine2: z.string().optional(),
  city: z.string().min(1),
  postcode: z.string().regex(/^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$/i),
});

const PayingCardDetailsSchema = z.object({
  cvv: z.string().regex(/^\d{3,4}$/),
  token: z.string().min(1),
});

const PostPaymentsRequestV3Schema = z.object({
  cardAccountId: z.string().length(16),
  amount: z.number().positive(),
  source: z.enum(["Web", "Mobile", "API"]),
  accountStatus: z.enum(["Normal", "Restricted", "Closed"]),
  lastName: z.string().min(1),
  dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  payingCardDetails: PayingCardDetailsSchema,
  addressDetails: AddressDetailsSchema,
  brand: z.enum(["Visa", "Mastercard", "Amex"]),
});

// Derive types from schemas
type AddressDetails = z.infer<typeof AddressDetailsSchema>;
type PayingCardDetails = z.infer<typeof PayingCardDetailsSchema>;
type PostPaymentsRequestV3 = z.infer<typeof PostPaymentsRequestV3Schema>;

// Use schemas at runtime boundaries
export const parsePaymentRequest = (data: unknown): PostPaymentsRequestV3 => {
  return PostPaymentsRequestV3Schema.parse(data);
};

// Example of schema composition for complex domains
const BaseEntitySchema = z.object({
  id: z.string().uuid(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

const CustomerSchema = BaseEntitySchema.extend({
  email: z.string().email(),
  tier: z.enum(["standard", "premium", "enterprise"]),
  creditLimit: z.number().positive(),
});

type Customer = z.infer<typeof CustomerSchema>;
```

### Schema Usage in Tests

**CRITICAL**: Tests must use real schemas and types from the main project, not redefine their own.

```typescript
// ❌ WRONG - Defining schemas in test files
const ProjectSchema = z.object({
  id: z.string(),
  workspaceId: z.string(),
  ownerId: z.string().nullable(),
  name: z.string(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

// ✅ CORRECT - Import schemas from the shared schema package
import { ProjectSchema, type Project } from "@your-org/schemas";
```

**Why this matters:**

- **Type Safety**: Ensures tests use the same types as production code
- **Consistency**: Changes to schemas automatically propagate to tests
- **Maintainability**: Single source of truth for data structures
- **Prevents Drift**: Tests can't accidentally diverge from real schemas

**Implementation:**

- All domain schemas should be exported from a shared schema package or module
- Test files should import schemas from the shared location
- If a schema isn't exported yet, add it to the exports rather than duplicating it
- Mock data factories should use the real types derived from real schemas

```typescript
// ✅ CORRECT - Test factories using real schemas
import { ProjectSchema, type Project } from "@your-org/schemas";

const getMockProject = (overrides?: Partial<Project>): Project => {
  const baseProject = {
    id: "proj_123",
    workspaceId: "ws_456",
    ownerId: "user_789",
    name: "Test Project",
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const projectData = { ...baseProject, ...overrides };

  // Validate against real schema to catch type mismatches
  return ProjectSchema.parse(projectData);
};
```

## Testing Tools and Framework

### Preferred Testing Stack

- **Jest** or **Vitest** for testing frameworks
- **React Testing Library** for React components
- **MSW (Mock Service Worker)** for API mocking when needed
- All test code must follow the same TypeScript strict mode rules as production code

### Test Data Pattern

Use factory functions with optional overrides for test data:

```typescript
const getMockPaymentPostPaymentRequest = (
  overrides?: Partial<PostPaymentsRequestV3>
): PostPaymentsRequestV3 => {
  return {
    CardAccountId: "1234567890123456",
    Amount: 100,
    Source: "Web",
    AccountStatus: "Normal",
    LastName: "Doe",
    DateOfBirth: "1980-01-01",
    PayingCardDetails: {
      Cvv: "123",
      Token: "token",
    },
    AddressDetails: getMockAddressDetails(),
    Brand: "Visa",
    ...overrides,
  };
};

const getMockAddressDetails = (
  overrides?: Partial<AddressDetails>
): AddressDetails => {
  return {
    HouseNumber: "123",
    HouseName: "Test House",
    AddressLine1: "Test Address Line 1",
    AddressLine2: "Test Address Line 2",
    City: "Test City",
    ...overrides,
  };
};
```

Key principles:

- Always return complete objects with sensible defaults
- Accept optional `Partial<T>` overrides
- Build incrementally - extract nested object factories as needed
- Compose factories for complex objects
- Consider using a test data builder pattern for very complex objects

## TDD Examples in TypeScript

### Red-Green-Refactor Workflow

```typescript
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
const processOrder = (order: Order): ProcessedOrder => {
  const itemsTotal = order.items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  return {
    ...order,
    shippingCost: order.shippingCost,
    total: itemsTotal + order.shippingCost,
  };
};

// Step 3: Red - Add test for free shipping behavior
describe("Order processing", () => {
  it("should calculate total with shipping cost", () => {
    // ... existing test
  });

  it("should apply free shipping for orders over £50", () => {
    const order = createOrder({
      items: [{ price: 60, quantity: 1 }],
      shippingCost: 5.99,
    });

    const processed = processOrder(order);

    expect(processed.shippingCost).toBe(0);
    expect(processed.total).toBe(60);
  });
});

// Step 4: Green - Add conditional logic
const processOrder = (order: Order): ProcessedOrder => {
  const itemsTotal = order.items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  const shippingCost = itemsTotal > 50 ? 0 : order.shippingCost;

  return {
    ...order,
    shippingCost,
    total: itemsTotal + shippingCost,
  };
};

// Step 5: Refactor - Extract constants and improve readability
const FREE_SHIPPING_THRESHOLD = 50;

const calculateItemsTotal = (items: OrderItem[]): number => {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
};

const qualifiesForFreeShipping = (itemsTotal: number): boolean => {
  return itemsTotal > FREE_SHIPPING_THRESHOLD;
};

const processOrder = (order: Order): ProcessedOrder => {
  const itemsTotal = calculateItemsTotal(order.items);
  const shippingCost = qualifiesForFreeShipping(itemsTotal)
    ? 0
    : order.shippingCost;

  return {
    ...order,
    shippingCost,
    total: itemsTotal + shippingCost,
  };
};
```

## Error Handling Patterns

### Result Type Pattern

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

const processPayment = (
  payment: Payment
): Result<ProcessedPayment, PaymentError> => {
  if (!isValidPayment(payment)) {
    return { success: false, error: new PaymentError("Invalid payment") };
  }

  if (!hasSufficientFunds(payment)) {
    return { success: false, error: new PaymentError("Insufficient funds") };
  }

  return { success: true, data: executePayment(payment) };
};
```

### Early Returns with Exceptions

```typescript
const processPayment = (payment: Payment): ProcessedPayment => {
  if (!isValidPayment(payment)) {
    throw new PaymentError("Invalid payment");
  }

  if (!hasSufficientFunds(payment)) {
    throw new PaymentError("Insufficient funds");
  }

  return executePayment(payment);
};
```

## React Component Testing

```typescript
// Good - testing user-visible behavior
describe("PaymentForm", () => {
  it("should show error when submitting invalid amount", async () => {
    render(<PaymentForm />);

    const amountInput = screen.getByLabelText("Amount");
    const submitButton = screen.getByRole("button", { name: "Submit Payment" });

    await userEvent.type(amountInput, "-100");
    await userEvent.click(submitButton);

    expect(screen.getByText("Amount must be positive")).toBeInTheDocument();
  });
});
```

## Testing Behavior Examples

```typescript
// Good - tests behavior through public API
describe("PaymentProcessor", () => {
  it("should decline payment when insufficient funds", () => {
    const payment = getMockPaymentPostPaymentRequest({ Amount: 1000 });
    const account = getMockAccount({ Balance: 500 });

    const result = processPayment(payment, account);

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Insufficient funds");
  });

  it("should process valid payment successfully", () => {
    const payment = getMockPaymentPostPaymentRequest({ Amount: 100 });
    const account = getMockAccount({ Balance: 500 });

    const result = processPayment(payment, account);

    expect(result.success).toBe(true);
    expect(result.data.remainingBalance).toBe(400);
  });
});
```

### Achieving 100% Coverage Through Business Behavior

Example showing how validation code gets 100% coverage without testing it directly:

```typescript
// payment-validator.ts (implementation detail)
export const validatePaymentAmount = (amount: number): boolean => {
  return amount > 0 && amount <= 10000;
};

export const validateCardDetails = (card: PayingCardDetails): boolean => {
  return /^\d{3,4}$/.test(card.cvv) && card.token.length > 0;
};

// payment-processor.ts (public API)
export const processPayment = (
  request: PaymentRequest
): Result<Payment, PaymentError> => {
  // Validation is used internally but not exposed
  if (!validatePaymentAmount(request.amount)) {
    return { success: false, error: new PaymentError("Invalid amount") };
  }

  if (!validateCardDetails(request.payingCardDetails)) {
    return { success: false, error: new PaymentError("Invalid card details") };
  }

  // Process payment...
  return { success: true, data: executedPayment };
};

// payment-processor.test.ts
describe("Payment processing", () => {
  // These tests achieve 100% coverage of validation code
  // without directly testing the validator functions

  it("should reject payments with negative amounts", () => {
    const payment = getMockPaymentPostPaymentRequest({ amount: -100 });
    const result = processPayment(payment);

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Invalid amount");
  });

  it("should reject payments exceeding maximum amount", () => {
    const payment = getMockPaymentPostPaymentRequest({ amount: 10001 });
    const result = processPayment(payment);

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Invalid amount");
  });

  it("should reject payments with invalid CVV format", () => {
    const payment = getMockPaymentPostPaymentRequest({
      payingCardDetails: { cvv: "12", token: "valid-token" },
    });
    const result = processPayment(payment);

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Invalid card details");
  });

  it("should process valid payments successfully", () => {
    const payment = getMockPaymentPostPaymentRequest({
      amount: 100,
      payingCardDetails: { cvv: "123", token: "valid-token" },
    });
    const result = processPayment(payment);

    expect(result.success).toBe(true);
    expect(result.data.status).toBe("completed");
  });
});
```

## Functional Programming Examples

```typescript
// Good - Pure function with immutable updates
const applyDiscount = (order: Order, discountPercent: number): Order => {
  return {
    ...order,
    items: order.items.map((item) => ({
      ...item,
      price: item.price * (1 - discountPercent / 100),
    })),
    totalPrice: order.items.reduce(
      (sum, item) => sum + item.price * (1 - discountPercent / 100),
      0
    ),
  };
};

// Good - Composition over complex logic
const processOrder = (order: Order): ProcessedOrder => {
  return pipe(
    order,
    validateOrder,
    applyPromotions,
    calculateTax,
    assignWarehouse
  );
};

// When heavy FP abstractions ARE appropriate:
// - Complex async flows that benefit from Task/IO types
// - Error handling chains that benefit from Result/Either types
// Example with Result type for complex error handling:
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

const chainPaymentOperations = (
  payment: Payment
): Result<Receipt, PaymentError> => {
  return pipe(
    validatePayment(payment),
    chain(authorizePayment),
    chain(capturePayment),
    map(generateReceipt)
  );
};
```

## TypeScript Anti-patterns to Avoid

```typescript
// Avoid: Mutation
const addItem = (items: Item[], newItem: Item) => {
  items.push(newItem); // Mutates array
  return items;
};

// Prefer: Immutable update
const addItem = (items: Item[], newItem: Item): Item[] => {
  return [...items, newItem];
};

// Avoid: Using `any`
const processData = (data: any) => {
  return data.someProperty;
};

// Prefer: Proper typing
const processData = (data: { someProperty: string }): string => {
  return data.someProperty;
};

// Avoid: Type assertions without justification
const result = apiResponse as PaymentResult;

// Prefer: Runtime validation
const result = PaymentResultSchema.parse(apiResponse);
```

## Naming Conventions

- **Functions**: `camelCase`, verb-based (e.g., `calculateTotal`, `validatePayment`)
- **Types**: `PascalCase` (e.g., `PaymentRequest`, `UserProfile`)
- **Constants**: `UPPER_SNAKE_CASE` for true constants, `camelCase` for configuration
- **Files**: `kebab-case.ts` for all TypeScript files
- **Test files**: `*.test.ts` or `*.spec.ts`

## Build and Quality Tools

Run these commands to ensure code quality:

```bash
npm test          # All tests must pass
npm run lint      # All linting must pass
npm run typecheck # TypeScript must be happy
```