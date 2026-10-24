# Enterprise SQL Server, BullMQ & ExcelJS Reference Examples

## 1. Resilient `MssqlPoolManager` with Deadlock Retry (`src/infrastructure/database/mssql-pool.ts`)

```typescript
import sql, { type config as SqlConfig, type ConnectionPool } from 'mssql';
import { ResultAsync } from 'neverthrow';
import { DatabasePersistenceError, type DomainError } from '../../domain/errors/domain-error.js';

const TRANSIENT_SQL_NUMBERS = new Set([1205, 4060, 40197, 40501, 40613]);

export class MssqlPoolManager {
  private poolPromise: Promise<ConnectionPool> | null = null;

  constructor(private readonly config: SqlConfig) {}

  public async getPool(): Promise<ConnectionPool> {
    if (!this.poolPromise) {
      const pool = new sql.ConnectionPool({
        ...this.config,
        pool: {
          max: this.config.pool?.max ?? 20,
          min: this.config.pool?.min ?? 2,
          idleTimeoutMillis: 30_000,
        },
        options: {
          encrypt: true,
          trustServerCertificate: this.config.options?.trustServerCertificate ?? false,
          enableArithAbort: true,
          ...this.config.options,
        },
      });

      this.poolPromise = pool.connect().catch((err) => {
        this.poolPromise = null;
        throw err;
      });
    }
    return this.poolPromise;
  }

  public executeWithRetry<T>(
    operationName: string,
    fn: (pool: ConnectionPool) => Promise<T>,
    maxAttempts = 3,
  ): ResultAsync<T, DomainError> {
    return ResultAsync.fromPromise(
      (async () => {
        let lastError: unknown;
        for (let attempt = 1; attempt <= maxAttempts; attempt++) {
          try {
            const pool = await this.getPool();
            return await fn(pool);
          } catch (error) {
            lastError = error;
            const sqlNumber = (error as { number?: number })?.number;
            const code = (error as { code?: string })?.code;
            const isTransient =
              (sqlNumber !== undefined && TRANSIENT_SQL_NUMBERS.has(sqlNumber)) ||
              code === 'ETIMEOUT' ||
              code === 'ECONNRESET';

            if (!isTransient || attempt === maxAttempts) {
              throw error;
            }
            const delayMs = Math.min(1000, 100 * 2 ** attempt) + Math.floor(Math.random() * 75);
            await new Promise((resolve) => setTimeout(resolve, delayMs));
          }
        }
        throw lastError;
      })(),
      (err) =>
        new DatabasePersistenceError(
          `Database operation '${operationName}' failed.`,
          { operationName },
          err,
        ),
    );
  }

  public async close(): Promise<void> {
    if (this.poolPromise) {
      const pool = await this.poolPromise;
      await pool.close();
      this.poolPromise = null;
    }
  }
}
```

---

## 2. Parameterized Repository + Safe Transaction (`src/infrastructure/database/sql-invoice.repository.ts`)

```typescript
import sql from 'mssql';
import type { ResultAsync } from 'neverthrow';
import type { Invoice } from '../../domain/entities/invoice.entity.js';
import type { DomainError } from '../../domain/errors/domain-error.js';
import type { InvoiceRepositoryPort } from '../../domain/ports/invoice-repository.port.js';
import type { MssqlPoolManager } from './mssql-pool.js';

export class SqlInvoiceRepository implements InvoiceRepositoryPort {
  constructor(private readonly db: MssqlPoolManager) {}

  public save(invoice: Invoice): ResultAsync<void, DomainError> {
    return this.db.executeWithRetry('SqlInvoiceRepository.save', async (pool) => {
      const tx = new sql.Transaction(pool);
      let began = false;
      try {
        await tx.begin(sql.ISOLATION_LEVEL.READ_COMMITTED);
        began = true;

        const request = new sql.Request(tx);
        request.input('Id', sql.VarChar(64), invoice.id);
        request.input('CustomerId', sql.VarChar(64), invoice.customerId);
        request.input('AmountCents', sql.BigInt, invoice.amountCents);
        request.input('Status', sql.VarChar(20), invoice.status);
        request.input('CreatedAt', sql.DateTime2, invoice.createdAt);

        await request.query(`
          MERGE INTO dbo.Invoices AS target
          USING (SELECT @Id AS Id) AS source
          ON target.Id = source.Id
          WHEN MATCHED THEN
            UPDATE SET Status = @Status, AmountCents = @AmountCents
          WHEN NOT MATCHED THEN
            INSERT (Id, CustomerId, AmountCents, Status, CreatedAt)
            VALUES (@Id, @CustomerId, @AmountCents, @Status, @CreatedAt);
        `);

        await tx.commit();
      } catch (err) {
        if (began) {
          await tx.rollback().catch(() => undefined);
        }
        throw err;
      }
    });
  }
}
```

---

## 3. Memory-Safe Streaming Excel Export (`ExcelJS` + `mssql` Stream)

```typescript
import ExcelJS from 'exceljs';
import sql, { type ConnectionPool } from 'mssql';
import type { Writable } from 'node:stream';

export async function streamInvoicesToExcel(
  pool: ConnectionPool,
  customerId: string,
  outputStream: Writable,
): Promise<void> {
  const workbook = new ExcelJS.stream.xlsx.WorkbookWriter({
    stream: outputStream,
    useStyles: true,
  });
  const sheet = workbook.addWorksheet('Invoices');
  sheet.columns = [
    { header: 'Invoice ID', key: 'id', width: 28 },
    { header: 'Customer ID', key: 'customerId', width: 24 },
    { header: 'Amount (Cents)', key: 'amountCents', width: 18 },
    { header: 'Status', key: 'status', width: 16 },
  ];

  const request = pool.request();
  request.stream = true;
  request.input('CustomerId', sql.VarChar(64), customerId);
  request.query(`
    SELECT Id AS id, CustomerId AS customerId, AmountCents AS amountCents, Status AS status
    FROM dbo.Invoices
    WHERE CustomerId = @CustomerId
    ORDER BY CreatedAt DESC;
  `);

  await new Promise<void>((resolve, reject) => {
    request.on('row', (row: Record<string, unknown>) => {
      sheet.addRow(row).commit();
    });
    request.on('error', reject);
    request.on('done', () => resolve());
  });

  sheet.commit();
  await workbook.commit();
}
```
