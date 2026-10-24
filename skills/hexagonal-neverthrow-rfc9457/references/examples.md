# Hexagonal + `neverthrow` + RFC 9457 Reference Examples

## 1. Typed `DomainError` Hierarchy (`src/domain/errors/domain-error.ts`)

```typescript
export type ErrorCategory =
  | 'VALIDATION'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'EXTERNAL_DEPENDENCY'
  | 'INTERNAL';

export abstract class DomainError {
  abstract readonly code: string;
  abstract readonly category: ErrorCategory;

  constructor(
    public readonly message: string,
    public readonly details?: Record<string, unknown>,
    public readonly cause?: unknown,
  ) {}
}

export class InvalidInvoiceAmountError extends DomainError {
  readonly code = 'INVOICE_INVALID_AMOUNT';
  readonly category = 'VALIDATION' as const;

  constructor(amount: number) {
    super(`Invoice amount must be greater than zero. Received: ${amount}`, { amount });
  }
}

export class InvoiceNotFoundError extends DomainError {
  readonly code = 'INVOICE_NOT_FOUND';
  readonly category = 'NOT_FOUND' as const;

  constructor(invoiceId: string) {
    super(`Invoice '${invoiceId}' was not found.`, { invoiceId });
  }
}

export class DatabasePersistenceError extends DomainError {
  readonly code = 'DATABASE_PERSISTENCE_ERROR';
  readonly category = 'INTERNAL' as const;
}
```

---

## 2. Immutable Entity with `create()` & `rehydrate()` (`src/domain/entities/invoice.entity.ts`)

```typescript
import { err, ok, type Result } from 'neverthrow';
import { InvalidInvoiceAmountError, type DomainError } from '../errors/domain-error.js';

export interface InvoiceProps {
  readonly id: string;
  readonly customerId: string;
  readonly amountCents: number;
  readonly status: 'PENDING' | 'ISSUED' | 'CANCELLED';
  readonly createdAt: Date;
}

export class Invoice {
  private constructor(private readonly props: InvoiceProps) {}

  public static create(input: {
    id: string;
    customerId: string;
    amountCents: number;
  }): Result<Invoice, DomainError> {
    if (!Number.isInteger(input.amountCents) || input.amountCents <= 0) {
      return err(new InvalidInvoiceAmountError(input.amountCents));
    }

    return ok(
      new Invoice({
        id: input.id,
        customerId: input.customerId,
        amountCents: input.amountCents,
        status: 'PENDING',
        createdAt: new Date(),
      }),
    );
  }

  public static rehydrate(props: InvoiceProps): Invoice {
    return new Invoice(props);
  }

  get id(): string {
    return this.props.id;
  }

  get customerId(): string {
    return this.props.customerId;
  }

  get amountCents(): number {
    return this.props.amountCents;
  }

  get status(): InvoiceProps['status'] {
    return this.props.status;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }
}
```

---

## 3. Domain Port (`src/domain/ports/invoice-repository.port.ts`)

```typescript
import type { ResultAsync } from 'neverthrow';
import type { Invoice } from '../entities/invoice.entity.js';
import type { DomainError } from '../errors/domain-error.js';

export interface InvoiceRepositoryPort {
  findById(id: string): ResultAsync<Invoice | null, DomainError>;
  save(invoice: Invoice): ResultAsync<void, DomainError>;
}
```

---

## 4. Application Use Case with `tsyringe` (`src/application/use-cases/issue-invoice.use-case.ts`)

```typescript
import { errAsync, okAsync, type ResultAsync } from 'neverthrow';
import { inject, injectable } from 'tsyringe';
import { Invoice } from '../../domain/entities/invoice.entity.js';
import { InvoiceNotFoundError, type DomainError } from '../../domain/errors/domain-error.js';
import type { InvoiceRepositoryPort } from '../../domain/ports/invoice-repository.port.js';
import { TOKENS } from '../../infrastructure/di/tokens.js';

export interface GetInvoiceOutputDto {
  id: string;
  customerId: string;
  amountCents: number;
  status: string;
}

@injectable()
export class GetInvoiceUseCase {
  constructor(
    @inject(TOKENS.InvoiceRepository)
    private readonly invoiceRepo: InvoiceRepositoryPort,
  ) {}

  public execute(invoiceId: string): ResultAsync<GetInvoiceOutputDto, DomainError> {
    return this.invoiceRepo.findById(invoiceId).andThen((invoice) => {
      if (!invoice) {
        return errAsync(new InvoiceNotFoundError(invoiceId));
      }
      return okAsync({
        id: invoice.id,
        customerId: invoice.customerId,
        amountCents: invoice.amountCents,
        status: invoice.status,
      });
    });
  }
}
```

---

## 5. RFC 9457 `ProblemDetails` Mapper (`src/infrastructure/http/problem-details.ts`)

```typescript
import type { DomainError, ErrorCategory } from '../../domain/errors/domain-error.js';

export interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  code: string;
  correlationId?: string;
  extensions?: Record<string, unknown>;
}

const STATUS_BY_CATEGORY: Record<ErrorCategory, { status: number; title: string }> = {
  VALIDATION: { status: 422, title: 'Unprocessable Entity' },
  NOT_FOUND: { status: 404, title: 'Resource Not Found' },
  CONFLICT: { status: 409, title: 'Resource Conflict' },
  UNAUTHORIZED: { status: 401, title: 'Unauthorized' },
  FORBIDDEN: { status: 403, title: 'Forbidden' },
  EXTERNAL_DEPENDENCY: { status: 502, title: 'Bad Gateway' },
  INTERNAL: { status: 500, title: 'Internal Server Error' },
};

export function toProblemDetails(
  error: DomainError,
  instancePath: string,
  correlationId?: string,
): ProblemDetails {
  const { status, title } = STATUS_BY_CATEGORY[error.category];
  const isInternal = error.category === 'INTERNAL';

  return {
    type: `https://problems.internal.dev/${error.code.toLowerCase().replace(/_/g, '-')}`,
    title,
    status,
    detail: isInternal ? 'An unexpected internal error occurred.' : error.message,
    instance: instancePath,
    code: error.code,
    correlationId,
    ...(isInternal || !error.details ? {} : { extensions: error.details }),
  };
}
```
