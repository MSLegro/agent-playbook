# MSlegro Agent Playbook (`agent-playbook`)

Repositorio central, agnóstico de plataforma y auto-instalable con la constitución de ingeniería, metodología **ODD (Organic Driven Development)**, las **10 Leyes Arquitectónicas (ATLAS)**, memoria persistente (**Engram**) y catálogo curado de **Skills** para agentes de IA (**Google Antigravity**, **OpenCode**, **Claude Code**, **Cursor**, **Codex**).

---

## Cómo usar este Playbook con cualquier Agente de IA

En cualquier agente nuevo o sesión en blanco, pega únicamente este prompt:

> *"Lee `https://github.com/MSlegro/agent-playbook/blob/main/BOOTSTRAP.md` (o `~/.config/agent-playbook/BOOTSTRAP.md` si ya está clonado) y ejecuta el protocolo de onboarding para configurarte."*

O ejecuta directamente en tu terminal:

```bash
git clone https://github.com/MSlegro/agent-playbook.git ~/.config/agent-playbook
~/.config/agent-playbook/scripts/bootstrap.sh
```

---

## Arquitectura del Playbook

```text
~/.config/agent-playbook/
├── AGENTS.md                        # Entrypoint universal (< 24 KB, Progressive Disclosure)
├── GEMINI.md -> AGENTS.md           # Symlink nativo para Google Antigravity
├── CLAUDE.md -> AGENTS.md           # Symlink nativo para Claude Code
├── BOOTSTRAP.md                     # Instrucciones AI-to-AI para auto-configuración
├── core/                            # Constitución de Ingeniería (6 módulos)
│   ├── 01-persona-and-communication.md
│   ├── 02-organic-driven-development.md
│   ├── 03-architecture-and-code.md
│   ├── 04-memory-engram-protocol.md
│   ├── 05-git-and-commits.md
│   └── 06-security-and-guardrails.md
├── skills/                          # Catálogo curado de Skills de alta señal (< 500 líneas/SKILL.md)
│   ├── _shared/                     # Contratos compartidos ODD / RDD / Triage
│   ├── hexagonal-neverthrow-rfc9457/# 10 leyes ATLAS + neverthrow + RFC 9457
│   ├── mssql-enterprise-patterns/   # SQL Server pooling, deadlocks, BullMQ, Excel/Word
│   ├── rpa-hexagonal-orchestration/ # RPA Playwright (TS & Python uv) resiliente
│   ├── playbook-learn/              # Auto-evolución continua del playbook
│   └── ...                          # +30 skills oficiales verificadas
├── subagents/                       # Contratos de rol para subagentes (Explorer, Architect, Implementer, Verifier)
├── adapters/                        # Configuraciones listas para Antigravity, OpenCode y Claude
└── scripts/
    ├── bootstrap.sh                 # Instalador idempotente en ~/.gemini/config y ~/.config/opencode
    ├── init-project.sh              # Vincula un repositorio de proyecto al playbook
    └── validate-playbook.py         # Linter de frontmatter, límites de tamaño y enlaces Markdown
```

---

## Pilares del Flujo de Trabajo

### 1. Metodología ODD (Organic Driven Development)
Reemplaza las cascadas rígidas por un flujo adaptativo que escala según la complejidad de la tarea:
- **Clarify (`0–3 preguntas`)**: Resuelve ambigüedades antes de tocar código.
- **Plan (`Wait for Go`)**: Alinea diseño y alcance antes de implementar cambios no triviales.
- **Delegate (`Subagent-First`)**: Mantiene el hilo principal limpio delegando exploración e implementación pesada a subagentes aislados.
- **Verify (`3-2-1 Rule`)**: Verifica contra criterios de aceptación y tests reales; si hay `3` intentos fallidos, `2` regresiones o `1` contradicción de diseño, detiene parches y re-analiza la causa raíz.

### 2. Las 10 Leyes Arquitectónicas (Estándar ATLAS)
1. **Dependencia Unidireccional Estricta**: `domain/` <- `application/` <- `infrastructure/`.
2. **Inyección de Dependencias Explícita (`tsyringe`)**: Prohibido instanciar adaptadores con `new` dentro de casos de uso.
3. **Prohibición de `any`**: Tipado estricto en todo el proyecto; validación en bordes con `zod`.
4. **Inmutabilidad del Dominio**: Entidades con constructor privado, `create()` y `rehydrate()`.
5. **Manejo Funcional de Errores (`neverthrow`)**: `Result<T, E>` / `ResultAsync<T, E>` en dominio y aplicación; respuestas HTTP bajo **RFC 9457 (`ProblemDetails`)**.
6. **Seguridad por Diseño**: Consultas parametrizadas (`mssql` / `Drizzle`), validación de entrada y cero secretos en código.
7. **Idempotencia y Transaccionalidad**: Operaciones críticas y colas (`BullMQ`) idempotentes.
8. **Separación de DTOs y Dominio**: Mappers explícitos; nunca exponer entidades o filas SQL crudas.
9. **Observabilidad Estructurada**: Logs estructurados (`pino` / `loguru`) con `correlationId`.
10. **Testing por Capas**: Unit tests puros en `domain`/`application` (`Vitest` / `go test`) e integración/E2E (`Playwright`) en `infrastructure`.

### 3. Evolución Continua (`playbook-learn`)
Cada vez que descubras un patrón valioso o corrijas al agente en cualquier proyecto, dile:
> *"Guarda este aprendizaje en mi playbook"*

El agente activará la skill `playbook-learn`, actualizará la regla o skill correspondiente en `~/.config/agent-playbook`, ejecutará `validate-playbook.py` y dejará el cambio listo para todos tus agentes.
