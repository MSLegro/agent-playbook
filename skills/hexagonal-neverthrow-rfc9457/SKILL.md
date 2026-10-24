---
name: hexagonal-neverthrow-rfc9457
description: >-
  Hexagonal Architecture (Ports & Adapters), Domain-Driven Design (DDD), functional
  error handling with neverthrow (Result/ResultAsync), tsyringe dependency injection,
  and RFC 9457 ProblemDetails HTTP responses (ATLAS 10 Architectural Laws).
  Use when designing or implementing backend services, domain entities, use cases,
  repositories, or HTTP controllers in TypeScript/Node.js.
  Keywords: hexagonal, clean architecture, ddd, neverthrow, Result, ResultAsync, RFC 9457, ProblemDetails, tsyringe, ATLAS.
  Do not use for frontend UI components — use vercel-react-best-practices or shadcn.
---

# Hexagonal Architecture + `neverthrow` + RFC 9457 (ATLAS Standard)

## Activation Contract
Activate this skill whenever creating, refactoring, or reviewing backend TypeScript/Node.js services, APIs (Fastify, Hono, Express), domain models, application use cases, or infrastructure adapters.

## Hard Rules (The 10 ATLAS Architectural Laws)
1. **Strict Unidirectional Dependency (`domain` <- `application` <- `infrastructure`)**:
   - `domain/` has **ZERO** imports from `application/`, `infrastructure/`, HTTP frameworks (`fastify`, `hono`, `express`), ORMs (`drizzle-orm`, `mssql`), or environment (`process.env`).
   - `application/` depends ONLY on `domain/` (entities, value objects, domain errors, port interfaces).
   - `infrastructure/` implements `domain/ports/` and wires dependencies at the Composition Root.
2. **Explicit Dependency Injection (`tsyringe`)**:
   - Inject ports via constructor using `@injectable()` and `@inject(TOKENS.PortName)`.
   - Never instantiate infrastructure adapters directly (`new SqlRepository()`) inside `application/` or `domain/`.
3. **Zero `any` Policy**:
   - `any` is strictly forbidden. Use `unknown` at untrusted boundaries and parse with `zod`.
4. **Immutable Domain Entities (`create` vs `rehydrate`)**:
   - Entity constructors MUST be `private`.
   - Expose `static create(props): Result<Entity, DomainError>` for new instances (validates invariants and emits domain events if needed).
   - Expose `static rehydrate(raw): Entity` for reconstituting already-validated records from persistence without re-triggering creation side effects.
5. **Functional Error Handling (`neverthrow`)**:
   - Business and expected infrastructure failures MUST return `Result<T, DomainError>` or `ResultAsync<T, DomainError>` (`ok`, `err`, `okAsync`, `errAsync`, `ResultAsync.fromPromise`).
   - NEVER use `throw new Error()` for control flow inside `domain/` or `application/`.
6. **RFC 9457 (`ProblemDetails`) HTTP Mapping**:
   - HTTP controllers unwrap `Result` via `.match(onSuccess, onError)` and map `DomainError` codes to standardized `application/problem+json` responses (`type`, `title`, `status`, `detail`, `instance`, `correlationId`).
7. **Input Validation at the Edge (`zod`)**:
   - Validate HTTP params, query, and body in `infrastructure/http/` before invoking the Use Case, or pass typed DTOs into the Use Case.
8. **Strict DTO / Persistence Mapping**:
   - Never leak database row types (`mssql` recordsets or ORM tables) into `application/` or HTTP responses. Always use explicit `Mapper.toDomain(row)` and `Mapper.toDto(entity)`.
9. **Structured Observability**:
   - Never use `console.log`. Inject a `LoggerPort` backed by `pino` with `correlationId` propagation.
10. **Layered Testing**:
    - Unit test `domain/` and `application/` in complete isolation using in-memory fakes or mocks of ports (`vitest`).

## Directory Blueprint

```text
src/
├── domain/
│   ├── entities/          # Private constructor + static create() / rehydrate()
│   ├── value-objects/     # Immutable VOs validated on creation
│   ├── errors/            # Typed DomainError hierarchy (code, message, metadata)
│   └── ports/             # Interfaces only (e.g., OrderRepositoryPort, CachePort)
├── application/
│   ├── use-cases/         # @injectable() classes returning ResultAsync<OutputDto, DomainError>
│   └── dtos/              # Input/Output contracts for use cases
└── infrastructure/
    ├── di/                # container.ts + tokens.ts (Composition Root)
    ├── database/          # Repositories implementing domain/ports + Mappers
    ├── http/
    │   ├── controllers/   # Parse with Zod -> call UseCase -> match() -> RFC 9457
    │   └── problem-details.ts
    └── logging/           # Pino implementation of LoggerPort
```

## Decision Gates
- **Does a method perform I/O (DB, HTTP, Redis, FileSystem)?**
  -> Wrap the promise with `ResultAsync.fromPromise(promise, (err) => new InfrastructureError(...))` inside the adapter. Never let raw rejected promises escape a port implementation.
- **Need to combine multiple `Result` or `ResultAsync` calls?**
  -> Use `.andThen(...)` for sequential dependent steps or `Result.combine([...])` / `ResultAsync.combine([...])` for parallel validation.

## Output Contract
When generating backend features under this skill:
1. Create/update Domain Error types and Port interfaces in `src/domain/` first.
2. Implement Domain Entities/Value Objects returning `Result<T, DomainError>`.
3. Implement Use Case in `src/application/use-cases/` using `@injectable()` and `ResultAsync`.
4. Implement Adapter + Mapper in `src/infrastructure/` and register in `src/infrastructure/di/`.
5. Map controller responses to RFC 9457 `ProblemDetails`.

## References
- Complete implementation patterns (Domain Entity, `DomainError`, Use Case with `tsyringe` + `ResultAsync`, Adapter with `fromPromise`, and RFC 9457 Fastify/Hono mapper): see [examples.md](references/examples.md).
