---
name: hono
description: >-
  Hono web framework best practices for TypeScript APIs, @hono/zod-validator,
  type-safe RPC (hc), middleware composition, and RFC 9457 error mapping.
  Use when building, routing, or typing HTTP APIs with Hono in Node.js, Bun, or Edge runtimes.
  Keywords: hono, @hono/zod-validator, hc, rpc, middleware, c.json, createFactory.
  Do not use for Fastify-specific lifecycle hooks or plugins — use fastify.
---

# Hono TypeScript API Best Practices

## Activation Contract
Activate when building or refactoring HTTP routes, middleware, validation, or type-safe RPC clients with `hono`.

## Hard Rules
1. **Method Chaining for RPC Type Inference**:
   - Always chain `.get()`, `.post()`, `.put()`, `.delete()` on the `Hono` instance (`const routes = app.get(...).post(...)`) and `export type AppType = typeof routes` when using `hc<AppType>()` RPC clients.
2. **Strict Input Validation (`@hono/zod-validator`)**:
   - Validate `json`, `query`, `param`, and `header` inputs with `zValidator('json', schema, (result, c) => ...)` returning RFC 9457 `ProblemDetails` on validation failure.
3. **Typed Context Variables (`createFactory`)**:
   - Define `type Env = { Variables: { user: AuthUser; correlationId: string } }` and instantiate `new Hono<Env>()` or `createFactory<Env>()` so `c.get('user')` and `c.set('user', ...)` are 100% type-safe without `as any`.
4. **Hexagonal Controller Boundary**:
   - Hono handlers belong strictly in `infrastructure/http/`. Extract validated DTOs via `c.req.valid('json')`, invoke the Application Use Case (`ResultAsync`), and map the result with `.match()` to `c.json(payload, status)`.

## Execution Pattern

```typescript
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { container } from '../../di/container.js';
import { IssueInvoiceUseCase } from '../../../application/use-cases/issue-invoice.use-case.js';
import { toProblemDetails } from '../problem-details.js';

export type AppEnv = {
  Variables: {
    correlationId: string;
  };
};

const createInvoiceSchema = z.object({
  customerId: z.string().min(1),
  amountCents: z.number().int().positive(),
});

export const invoiceRoutes = new Hono<AppEnv>().post(
  '/',
  zValidator('json', createInvoiceSchema),
  async (c) => {
    const dto = c.req.valid('json');
    const useCase = container.resolve(IssueInvoiceUseCase);
    const result = await useCase.execute(dto);

    return result.match(
      (output) => c.json(output, 201),
      (error) => {
        const problem = toProblemDetails(error, c.req.path, c.get('correlationId'));
        return c.json(problem, problem.status as 400 | 404 | 409 | 422 | 500, {
          'Content-Type': 'application/problem+json',
        });
      },
    );
  },
);

export type InvoiceRoutesType = typeof invoiceRoutes;
```

## Output Contract
- Zero untyped `c.req.json()` calls.
- Exported route types (`typeof routes`) for `hc` client compatibility.
- Standardized `application/problem+json` error responses.
