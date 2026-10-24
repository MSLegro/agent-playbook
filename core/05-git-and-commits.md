# 05 — Flujo de Git, Work-Unit Commits y Pull Requests

## 1. Regla de Oro en Commits (Cero Atribución de IA)
- **Prohibido terminantemente** añadir `Co-Authored-By: Claude`, `Co-Authored-By: Gemini`, `Co-Authored-By: Antigravity`, enlaces a herramientas de IA o firmas automáticas en mensajes de commit, descripciones de PRs o comentarios de código.
- Todo commit debe seguir estrictamente la especificación **Conventional Commits**:
  ```text
  <type>(<optional-scope>): <imperative-summary>
  ```
  - Tipos permitidos: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`.
  - Ejemplo correcto: `feat(billing): add deadlock retry to invoice repository`
  - Ejemplo prohibido: `Updated files ✨ Co-Authored-By: AI`

---

## 2. Commits por Unidad de Trabajo (`Work-Unit Commits`)
- **Cada commit debe ser una unidad funcional coherente y verificada:** incluye el cambio de comportamiento + sus pruebas correspondientes + la actualización de documentación/tipos en el mismo slice.
- **Heurística de tamaño (~400 líneas):** Apunta a slices revisables de alrededor de 400 líneas modificadas como guía de planificación (sin sacrificar tests ni legibilidad solo por recortar líneas).
- **Aislamiento de Alto Riesgo:** Cualquier unidad de trabajo cuya línea `Risk:` nombre uno de los **6 Ítems de Alto Riesgo** (migraciones de datos, seguridad/auth, cambios en contratos compartidos, concurrencia, CI/deploy) debe ir en su **propio commit aislado** para facilitar la auditoría y eventuales *rollbacks*.
- **Nunca mezclar:** No combines refactors cosméticos masivos o cambios de formateador global en el mismo commit que una corrección de negocio o feature crítica.

---

## 3. Gestión de Ramas y Entrega
- Antes de iniciar una implementación grande (ODD *Large*), asegúrate de estar en una rama de feature descriptiva (`feat/<nombre>`, `fix/<nombre>`, `refactor/<nombre>`), nunca comiteando trabajo incompleto directamente sobre `main` o `master` salvo instrucción explícita del usuario.
- Los commits locales por unidad de trabajo en la rama de la feature son parte del flujo normal autorizado; sin embargo, **`git push`, la creación de Pull Requests (`gh pr create`) y los merges requieren siempre autorización explícita del usuario**.
