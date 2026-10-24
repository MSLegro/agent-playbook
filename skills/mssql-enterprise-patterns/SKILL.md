---
name: mssql-enterprise-patterns
description: >-
  Enterprise SQL Server (node-mssql) patterns, connection pooling, deadlock retry
  with exponential backoff, parameterized queries, BullMQ + Redis background queues,
  and streaming Excel/Word generation (exceljs, docxtemplater).
  Use when building or optimizing Node.js backends integrating with Microsoft SQL Server,
  BullMQ workers, or automated financial/clinical document reporting.
  Keywords: mssql, sql server, connection pool, deadlock, 1205, bullmq, ioredis, exceljs, docxtemplater, transactions.
  Do not use for SQLite/Turso/Drizzle lightweight apps — use turso-db or drizzle-orm-patterns.
---

# Enterprise SQL Server (`mssql`), BullMQ & Document Reporting Patterns

## Activation Contract
Activate this skill when writing or reviewing:
- Microsoft SQL Server (`mssql` / `tedious`) adapters, stored procedure calls, or complex reporting queries in Node.js/TypeScript.
- Background job queues using `bullmq` and `ioredis`.
- Server-side document generation (`exceljs`, `xlsx`, `docxtemplater`).

## Hard Rules

### 1. SQL Server Connection Pooling (`node-mssql`)
- **Single Shared Pool per Database**: Never call `sql.connect(config)` inside a request handler or repository method. Create a singleton `ConnectionPool` managed at the infrastructure lifecycle level with graceful shutdown (`pool.close()`).
- **Mandatory Timeouts & Pool Sizing**: Configure explicit `connectionTimeout`, `requestTimeout`, `pool.max`, `pool.min`, and `pool.idleTimeoutMillis`.

### 2. Zero SQL Injection (Strict Parameter Binding)
- **NEVER interpolate variables** (`${value}`) into SQL strings.
- Always bind parameters with explicit SQL types (`request.input('customerId', sql.VarChar(50), customerId)`, `sql.Int`, `sql.Decimal(18, 2)`, `sql.DateTime2`).
- Whitelist dynamic `ORDER BY` column names against a strict `ReadonlySet<string>` or `zod.enum([...])`.

### 3. Deadlock (`1205`) & Transient Fault Resilience
- SQL Server error `1205` (Deadlock victim) and transient network timeouts (`ETIMEOUT`, `ECONNRESET`) MUST be retried with exponential backoff + jitter (max 3 attempts) at the repository adapter level before returning `err(new DatabasePersistenceError(...))`.
- Queries that read reporting snapshots without modifying data should use `READ COMMITTED SNAPSHOT` or explicit locking hints only when architected by DBA policy.

### 4. Transactions & Idempotency
- Multi-statement mutations MUST run inside a `new sql.Transaction(pool)` with explicit `begin()`, `commit()`, and `rollback()` in a `try/catch` wrapped by `ResultAsync`.
- Always guard `rollback()` with a state check so a disconnected transaction does not throw an unhandled secondary error.

### 5. BullMQ + Redis (`ioredis`) Workers
- **Connection Reuse**: Set `maxRetriesPerRequest: null` on the `ioredis` connection passed to BullMQ `Worker`.
- **Idempotent Job IDs**: Use deterministic `jobId` (e.g., `sync:${entityType}:${entityId}:${dateKey}`) to prevent duplicate queue flooding.
- **Graceful Shutdown**: Listen to `SIGTERM` / `SIGINT` and call `await worker.close()` before closing the SQL pool.

### 6. Streaming Excel/Document Generation
- For datasets > 5,000 rows, use `ExcelJS.stream.xlsx.WorkbookWriter` instead of in-memory `new ExcelJS.Workbook()` to prevent Node.js heap OOM (`FATAL ERROR: Ineffective mark-compact near heap limit`).

## Decision Gates
- **Is the query returning > 10,000 rows for an export?**
  -> Enable `request.stream = true` on `mssql` and pipe row chunks directly into `WorkbookWriter` (`commit()` each row).
- **Does the operation call an external SOAP/REST API and update SQL Server?**
  -> Never hold an open SQL transaction across an external HTTP call. Fetch/validate first, perform the HTTP call (or offload to a BullMQ job), and then open a short transaction to persist the result.

## Output Contract
When implementing SQL Server or BullMQ adapters:
1. Wrap all `mssql` operations in `ResultAsync` returning typed `DomainError` instances.
2. Bind every SQL parameter with explicit `sql.<Type>`.
3. Include explicit row-to-Domain Mappers (`Mapper.toDomain(row)`).

## References
- Production-ready implementations of Singleton `MssqlPoolManager`, Deadlock Retry wrapper, Safe Transactions, BullMQ Worker setup, and Streaming `ExcelJS` exporter: see [examples.md](references/examples.md).
