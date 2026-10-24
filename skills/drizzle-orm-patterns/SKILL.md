---
name: drizzle-orm-patterns
description: >-
  Type-safe Drizzle ORM schema design, SQLite/LibSQL (Turso) and PostgreSQL queries,
  inferSelectModel/inferInsertModel types, transactions, and drizzle-kit migrations.
  Use when defining database schemas, writing relational or SQL-like queries, or
  implementing repository adapters with drizzle-orm.
  Keywords: drizzle-orm, drizzle-kit, sqliteTable, pgTable, LibSQL, relations, InferSelectModel, eq, and, sql.
  Do not use for raw Microsoft SQL Server (node-mssql) queries — use mssql-enterprise-patterns.
---

# Drizzle ORM Type-Safe Patterns

## Activation Contract
Activate when designing schemas, migrations, or repository adapters using `drizzle-orm` and `drizzle-kit` (with LibSQL/Turso, SQLite, or PostgreSQL).

## Hard Rules
1. **Explicit Column Types & Timestamps**:
   - Use snake_case database column names mapped to camelCase TypeScript keys (`createdAt: integer('created_at', { mode: 'timestamp_ms' }).notNull()`).
   - Always define explicit `.notNull()`, primary keys, foreign key `.references(() => ..., { onDelete: 'cascade' })`, and indexes on filter/join columns.
2. **Type Inference via `$inferSelect` / `$inferInsert`**:
   - Derive persistence row types directly from table definitions (`type OrderRow = typeof orders.$inferSelect`) inside `infrastructure/database/`.
   - Map `OrderRow` to Domain Entities via explicit Mappers (`OrderMapper.toDomain(row)`). Never leak Drizzle table types into `domain/`.
3. **Wrap Queries in `ResultAsync`**:
   - Inside repository adapters, wrap `db.select()`, `db.insert()`, `db.update()`, and `db.transaction()` in `ResultAsync.fromPromise(..., toDatabaseError)`.
4. **Prevent N+1 Queries**:
   - Prefer single-roundtrip relational queries (`db.query.orders.findMany({ with: { items: true } })`) or explicit `.leftJoin()` over looping `await db.select()` inside `.map()`.
5. **Migration Discipline (`drizzle-kit`)**:
   - Generate SQL migrations via `drizzle-kit generate` and commit migration files to version control; avoid `drizzle-kit push` against production databases.

## Execution Pattern

```typescript
import { eq } from 'drizzle-orm';
import { integer, sqliteTable, text, index } from 'drizzle-orm/sqlite-core';
import { ResultAsync } from 'neverthrow';
import { DatabasePersistenceError, type DomainError } from '../../domain/errors/domain-error.js';

export const invoicesTable = sqliteTable(
  'invoices',
  {
    id: text('id').primaryKey(),
    customerId: text('customer_id').notNull(),
    amountCents: integer('amount_cents').notNull(),
    status: text('status', { enum: ['PENDING', 'ISSUED', 'CANCELLED'] }).notNull(),
    createdAt: integer('created_at', { mode: 'timestamp_ms' }).notNull(),
  },
  (table) => [index('idx_invoices_customer_id').on(table.customerId)],
);

export type InvoiceRow = typeof invoicesTable.$inferSelect;
export type NewInvoiceRow = typeof invoicesTable.$inferInsert;

export function findInvoiceRowById(
  db: { select: Function },
  id: string,
): ResultAsync<InvoiceRow | null, DomainError> {
  return ResultAsync.fromPromise(
    db
      .select()
      .from(invoicesTable)
      .where(eq(invoicesTable.id, id))
      .limit(1)
      .then((rows: InvoiceRow[]) => rows[0] ?? null),
    (err) => new DatabasePersistenceError(`Failed to query invoice '${id}'`, { id }, err),
  );
}
```

## Output Contract
- Schema files export table definitions and `$inferSelect` / `$inferInsert` types.
- Indexes declared for all foreign keys and frequent `WHERE` predicates.
- All repository methods return `ResultAsync<DomainEntity, DomainError>`.
