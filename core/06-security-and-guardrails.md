# 06 — Seguridad, Permisos y Guardrails Operativos

## 1. Matriz de Autonomía vs. Confirmación Humana

| Categoría de Acción | Política | Ejemplos |
| :--- | :---: | :--- |
| **Lectura y Exploración** | `ALLOW` (Autónomo) | `rg`, `find`, `git status`, `git diff`, `git log`, lectura de código y tests |
| **Edición dentro del Alcance Autorizado** | `ALLOW` (Autónomo) | Crear/editar archivos de código y tests dentro de `## Allowed edit surfaces` |
| **Verificación y Compilación** | `ALLOW` (Autónomo) | `pnpm test`, `vitest`, `pytest`, `go test`, `tsc --noEmit`, `eslint`, `oxlint` |
| **Operaciones Remotas o de Historial Git** | `ASK` (Confirmación obligatoria) | `git push`, `git push --force`, `git rebase`, `git reset --hard`, `gh pr merge` |
| **Operaciones Destructivas de Datos o Sistema** | `ASK` (Confirmación obligatoria) | `DROP TABLE`, `TRUNCATE`, `DELETE` sin `WHERE`, `rm -rf` fuera de `/tmp`, matar procesos ajenos |

---

## 2. Protección Estricta de Secretos y Datos Sensibles (Deny-List)
- **Prohibido leer, volcar en consola, incluir en prompts de subagentes o subir a Git:**
  - Archivos `.env`, `.env.local`, `.env.production`, `.env.*` (solo se permite leer `.env.example` o `.env.template`).
  - Archivos `credentials.json`, `service-account*.json`, `*.pem`, `*.key`, `*.pfx`, `id_rsa`, `id_ed25519`.
  - Tokens de acceso personal, cadenas de conexión con contraseñas (`MSSQL_PASSWORD`, `DATABASE_URL` reales) o datos reales de pacientes/clientes (PII / PHI).
- Antes de ejecutar cualquier `git add` o `git commit`, verifica mediante `git status` y `git diff --cached` que ningún archivo sensible ni binario temporal esté incluido.

---

## 3. Reglas de Seguridad en el Código Generado (Secure-by-Default)
1. **Cero Inyección SQL:** En `mssql`, `pg`, `libsql` o `drizzle-orm`, todas las consultas deben usar parámetros tipados (`request.input('id', sql.Int, id)` o builders parametrizados). Prohibida la interpolación de strings (`'SELECT ... WHERE id = ' + id`).
2. **Validación en Fronteras:** Todo endpoint HTTP, webhook o worker de cola valida su payload con esquemas estrictos (`Zod` o `TypeBox`) antes de invocar la capa de aplicación.
3. **Sanitización XSS y DOM:** En aplicaciones React/Next.js, evita `dangerouslySetInnerHTML`; si es estrictamente requerido, sanitiza previamente con `DOMPurify`.
4. **Aislamiento en Subagentes Escritores:** Ningún subagente escritor puede modificar archivos fuera de su lista explícita en `## Allowed edit surfaces`.
