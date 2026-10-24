# 04 — Protocolo de Memoria Persistente (`engram`) y Evolución (`playbook-learn`)

El ecosistema cuenta con **dos capas de memoria complementarias** que todo agente debe distinguir y utilizar de manera proactiva:

1. **Memoria Episódica de Proyecto (`engram` MCP):** Guarda el estado, decisiones arquitectónicas locales, progreso de tareas ODD (`odd/<feature>/tasks`) y descubrimientos específicos del repositorio actual.
2. **Sabiduría de Ingeniería Replicable (`agent-playbook` en `~/.config/agent-playbook`):** Guarda reglas transversales, *skills* perfeccionadas y patrones de ingeniería que aplican a todos los proyectos presentes y futuros (gestionada mediante la skill `playbook-learn`).

---

## Parte I: Protocolo Obligatorio de `engram`

Si tienes disponible las herramientas MCP de `engram` (`mem_search`, `mem_context`, `mem_save`, `mem_get_observation`, `mem_session_summary`), este protocolo es **SIEMPRE ACTIVO**.

### 1. Cuándo Consultar la Memoria (Lectura Proactiva)
- **Al inicio de una tarea sobre un proyecto existente:** Ejecuta `mem_search` con palabras clave de la solicitud del usuario para recuperar contexto previo antes de explorar a ciegas.
- **Al retomar una feature ODD interrumpida:** Ejecuta `mem_context` $\rightarrow$ `mem_search(query: "odd/<feature>/tasks")` $\rightarrow$ `mem_get_observation` y reconcilia con `odd/tasks/<feature>.md`.
- **Cuando el usuario mencione trabajo pasado** (*"recordar"*, *"qué hicimos"*, *"cómo resolvimos"*).

### 2. Disparadores de Guardado Inmediato (`mem_save` sin esperar a que lo pidan)
Llama a `mem_save` inmediatamente después de cualquiera de estos eventos:
- Decisión de arquitectura o diseño tomada (con sus *trade-offs*).
- Bug complejo resuelto (incluyendo causa raíz real y archivo afectado).
- Descubrimiento no obvio o *gotcha* sobre un repositorio, base de datos o portal externo.
- Creación o actualización de una tarea grande ODD (`topic_key: "odd/<feature-name>/tasks"`).
- Preferencia o restricción operativa aprendida del usuario.

#### Formato Estándar para `mem_save`
- **`title`**: Verbo + qué se hizo (corto y buscable, ej. `"Configured MSSQL deadlock retry in FlowRepository"`).
- **`type`**: `architecture` | `decision` | `bugfix` | `discovery` | `pattern` | `config` | `preference`.
- **`scope`**: `project` (por defecto) o `personal`.
- **`topic_key`**: Clave estable para temas que evolucionan (ej. `architecture/error-handling`, `odd/<feature>/tasks`) para hacer *upsert* sin duplicar entradas.
- **`content`**:
  - **What**: Una oración de qué se hizo.
  - **Why**: Qué lo motivó.
  - **Where**: Rutas de archivos afectados.
  - **Learned**: Casos borde o sorpresas técnicas encontradas.

### 3. Protocolo de Cierre de Sesión y Post-Compactación
- Antes de dar por cerrada una sesión larga de trabajo, invoca `mem_session_summary` con: `Goal`, `Discoveries`, `Accomplished`, `Next Steps` y `Relevant Files`.
- Si ocurre una compactación de contexto, persiste primero el resumen con `mem_session_summary` y recupera contexto con `mem_context` antes de continuar.

---

## Parte II: Cuándo Elevar un Aprendizaje al `agent-playbook` (`playbook-learn`)

Cuando un descubrimiento **no es exclusivo de un solo proyecto**, sino una mejora en la forma de programar, auditar o diseñar sistemas (por ejemplo: un nuevo antipatrón detectado en TypeScript/Fastify/Playwright, una regla que evita errores de la IA o una nueva skill técnica):
- Activa la skill **`playbook-learn`** para codificar la regla o actualizar la `SKILL.md` correspondiente dentro de `~/.config/agent-playbook`, validarla con `./scripts/validate-playbook.py` y versionarla en Git.
