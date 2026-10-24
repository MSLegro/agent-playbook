# 03 — Reglas de Arquitectura y Estándares de Código

Estas reglas arquitectónicas son obligatorias y tienen precedencia sobre cualquier detalle de implementación. Si implementar una funcionalidad parece requerir romper estas reglas, la solución debe ser rediseñada.

---

## Parte I: Las 10 Leyes Arquitectónicas (Estándar Hexagonal / Clean / ATLAS)

### 1. Las Dependencias Apuntan a Abstracciones
Los componentes de alto nivel dependen siempre de contratos (interfaces / puertos), nunca de implementaciones concretas:
`Presentation / Controller -> IUseCase / IService -> UseCase -> IRepository (Port) <- SqlRepository (Adapter)`.

### 2. Dirección Estricta de Dependencias
Las dependencias apuntan siempre hacia el centro del dominio:
```text
domain/ (Puro) <-- application/ (Casos de Uso y Puertos) <-- infrastructure/ + presentation/ (Adaptadores)
```
El dominio jamás depende de infraestructura, bases de datos, frameworks HTTP ni librerías de terceros.

### 3. Independencia Total del Dominio
La capa `domain/` contiene únicamente entidades, *value objects*, errores de dominio, invariantes y contratos de puertos.
- **Prohibido importar en runtime dentro de `domain/`:** Express, Fastify, Hono, Next.js, React, Axios, Drizzle, MSSQL, Prisma, Zod o `jsonwebtoken`.
- En `domain/` solo se permite `import type` (ej. `import type { ResultAsync } from 'neverthrow'`). Tras compilar, el código emitido de `domain/` debe tener cero dependencias de runtime externas.

### 4. Los Frameworks son Detalles Reemplazables
Todo framework (Fastify, Hono, Express, Next.js, Playwright) es un adaptador de borde. La lógica de negocio debe poder ejecutarse en un test unitario o cambiar de transporte HTTP sin tocar `domain/` ni `application/`.

### 5. Aislamiento entre Módulos (Sin Acceso Interno)
Cada módulo representa un subdominio funcional autónomo.
- Ningún módulo puede importar implementaciones internas (`infrastructure/` o repositorios privados) de otro módulo.
- Toda comunicación entre módulos ocurre exclusivamente a través de contratos públicos o servicios de aplicación expuestos.

### 6. Encapsulamiento del Dominio
Cada módulo es único dueño de sus datos y estado. Ningún módulo externo puede mutar tablas o estructuras internas de otro módulo directamente.

### 7. Sin Estado Mutable Compartido
Los módulos pueden compartir tipos, DTOs y contratos inmutables, pero nunca variables globales mutables ni singletons con estado de negocio compartido.

### 8. Una Responsabilidad por Directorio (Prohibición de Carpetas "Cajón de Sastre")
Cada directorio debe expresar claramente su intención funcional o arquitectónica (*Screaming Architecture*).
- **Nombres de directorio prohibidos:** `helpers/`, `misc/`, `common/`, `temp/`, `utils2/`. Si una pieza no tiene un lugar claro en la arquitectura, rediseña su responsabilidad.

### 9. El Dominio Impulsa las Decisiones
Las decisiones de diseño nacen de las invariantes del negocio, nunca de las limitaciones o atajos de un ORM o framework.

### 10. La Arquitectura es la Autoridad
Nunca degrades la arquitectura por urgencia táctica.

---

## Parte II: Manejo Funcional de Errores (`neverthrow` + RFC 9457 `ProblemDetails`)

En servicios backend y lógica de aplicación, los errores esperados y de infraestructura se manejan como **valores tipados (`Result` / `ResultAsync`)**, no lanzando excepciones (`throw`) de forma descontrolada entre capas.

### Flujo por Capas
| Capa | Responsabilidad | Firma Estándar |
| :--- | :--- | :--- |
| **Domain** | Declara puertos y tipos de fallo con `import type` | `findById(id: Id): ResultAsync<Entity, DbError \| NotFoundError>` |
| **Infrastructure** | Envuelve I/O con `ResultAsync.fromPromise(...)` adjuntando contexto técnico | `ResultAsync.fromPromise(pool.query(...), (cause) => new DbError(cause, { op }))` |
| **Application** | Compone reglas de negocio con `.map` / `.andThen` y expone la unión de errores del módulo | `execute(cmd): ResultAsync<OutputDTO, ModuleAppError>` |
| **Presentation** | Resuelve con `.match(ok => reply(ok), err => next(toHttpError(err)))` | Nunca construye respuestas de error manuales en el controlador |
| **Edge (`errorHandler`)** | Único emisor del formato estándar **RFC 9457 (`ProblemDetails`)** | Registra `stack`/`cause`/`context` en logs estructurados (`pino`) y responde JSON seguro |

### Formato de Salida (RFC 9457)
```json
{
  "type": "https://errors.domain.com/ValidationError",
  "title": "ValidationError",
  "status": 422,
  "detail": "El rango de fechas solicitado excede el límite permitido.",
  "instance": "/api/v1/reports"
}
```
- **Regla de Seguridad en Errores:** Jamás exponer `stack`, `cause`, nombres de tablas SQL ni trazas del driver en el cuerpo de respuesta HTTP al cliente.

---

## Parte III: Prácticas de Código Prohibidas y Estándares de Calidad

- **Cero `any` en TypeScript:** Usa tipos estrictos, `unknown` con *type guards* o inferencia de esquemas (`z.infer<typeof Schema>`).
- **Cero `catch {}` silenciosos:** Todo bloque de captura debe transformar el error en un `Err(...)` tipado o registrarlo con contexto completo.
- **Cero anidamiento profundo:** Usa *early returns* (*guard clauses*); evita `if/else` anidados de más de 2 niveles y ternarios anidados.
- **Validación en Fronteras:** Todo input externo (HTTP body/query/params, variables de entorno al inicio del proceso, filas de Excel/CSV, respuestas de APIs externas o selectores DOM en RPA) se valida y transforma en la frontera antes de entrar a `application/`.
