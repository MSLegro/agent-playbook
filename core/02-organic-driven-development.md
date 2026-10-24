# 02 — Metodología: Organic Driven Development (ODD)

**Organic Driven Development (ODD)** es el flujo de trabajo obligatorio por defecto en cada solicitud, en cualquier agente o runtime, sin necesidad de que el usuario lo invoque explícitamente.

---

## Los 7 Pasos del Protocolo ODD (En Orden Estricto)

1. **Authorize (Read-Only por defecto):**
   - Consultas, explicaciones, revisiones de código, auditorías, comparativas y propuestas son **100% de solo lectura**.
   - En modo lectura está prohibido editar archivos, crear artefactos de implementación o delegar escritores.
   - Si la intención de modificar código es ambigua o condicional, haz una única pregunta de aclaración y mantente en solo lectura hasta recibir confirmación.
2. **Explore (Exploración Proporcional):**
   - Explora primero el código existente y los requisitos de manera proporcional a la solicitud antes de proponer o escribir.
   - Nunca delegues la lectura de archivos que de todas formas vas a leer *inline* para editar. Explora con un subagente únicamente cuando necesites un mapa arquitectónico para decidir o enrutar.
3. **Resolve Uncertainty:**
   - Recomienda investigación adicional solo ante una incertidumbre nombrada.
   - Haz **una sola pregunta enfocada** únicamente si hay una decisión real de producto o alcance abierta; detente y espera.
   - Usa como máximo un desafío de suposición (*assumption challenge*) de solo lectura ante una premisa de alto impacto no probada.
4. **Classify (Tamaño de Tarea por *Resume Test*):**
   - Nunca clasifiques el tamaño de una tarea contando archivos, líneas o tests.
   - Una tarea es **Small** cuando cumple las tres condiciones:
     1. **Entendida:** El resultado y los puntos de cambio se prueban en un solo lote de lectura ($\le 3$ llamadas, ~10k tokens).
     2. **Riesgo contenido:** No toca ninguno de los **6 Ítems de Alto Riesgo**.
     3. **Pasa el *Resume Test*:** Si la sesión se interrumpiera ahora mismo, otro ingeniero o agente podría terminar el trabajo mirando únicamente la solicitud original y `git diff`.
   - Una tarea es **Large** únicamente cuando falla el *Resume Test* (abarca múltiples sesiones, depende de bloqueos externos, tiene entregables independientes o requisitos extensos que se perderían tras compactación).
   - **Ruta Small:** Trabaja *inline*, observa RED antes del fix cuando aplique, corre el test enfocado y la suite una vez. Cero documentos de tareas en disco.
5. **Track Before the First Write (Solo Tareas Large Autorizadas):**
   - Antes de la primera escritura de código en una tarea *Large*, crea automáticamente `odd/tasks/<feature-name>.md` y su espejo en Engram bajo el tópico `odd/<feature-name>/tasks` sin pedir permiso por el almacenamiento.
   - Informa en una línea qué documento se creó y cuántas tareas contiene.
   - **Orden fijo obligatorio del documento `odd/tasks/<feature-name>.md`:**
     - **Header (2-3 líneas):** Objetivo, rama, estrategia de entrega y comando del test runner.
     - **`## Specs`:** Requisitos numerados `S1..Sn` citando **verbatim** los strings, mensajes de error, comandos y ejemplos exactos del usuario (sin resumir ni inventar requisitos no pedidos; marca los supuestos explícitamente).
     - **`## Tasks`:** Una línea por tarea (`T1..Tn`) con su `S#` vinculado, ruta (`inline` o `delegated`), estado y hash de commit o evidencia RED/GREEN.
     - **`## Log` (Siempre al final):** `L1` guarda la solicitud original verbatim; entradas posteriores registran correcciones del usuario, análisis de problemas y evidencia de verificación.
6. **Implement Task by Task:**
   - **Por defecto el agente principal escribe *inline*** siguiendo su bitácora, salvo que se active un **Delegation Trigger** con razón nombrada.
   - Al delegar, pasa referencias exactas (`Spec: odd/tasks/<feature>.md, T2, S3-S4`), nunca paráfrasis.
   - Cuando el usuario reporte un fallo, **reprodúcelo primero** antes de asumir su causa.
   - Cada test debe verificar los efectos observables en la interfaz pública (código de salida, respuesta HTTP/RFC 9457, estado persistido e invariante de que entradas rechazadas no mutan datos).
   - Haz commits por unidad funcional (*Work-Unit Commits*, heurística de ~400 líneas cambiadas) en la rama de la feature junto con sus tests y documentación.
7. **Close + Línea `Risk:` Obligatoria:**
   - Reporta el resultado verificado, cualquier chequeo fallido/pendiente y el siguiente paso.
   - **Cierra siempre todo cambio de código con la línea:**
     `Risk: item N (reason)` o `Risk: none`.

---

## Los 6 Ítems de Alto Riesgo (`High-Risk Items`)

Un cambio es de **Alto Riesgo** si un error sería difícil de detectar, difícil de revertir o impacta más allá del archivo editado:

1. **Item 1 — Datos irreversibles:** Migraciones de esquema, alteración o borrado de datos existentes en producción, cambios en formatos persistidos.
2. **Item 2 — Seguridad:** Autenticación, autorización, permisos, credenciales, secretos, guards, validación de entrada crítica o sandboxing.
3. **Item 3 — Contratos consumidos por otros:** Cambios o eliminaciones en APIs públicas, flags de CLI, esquemas de configuración o helpers compartidos que otros módulos consumen (antes de declarar `Risk: none`, verifica si el diff toca funciones compartidas).
4. **Item 4 — Concurrencia:** Locks, condiciones de carrera (*race conditions*), colas de trabajo (BullMQ/Redis), transacciones concurrentes o coordinación asíncrona.
5. **Item 5 — Delivery o Entorno:** Instaladores, scripts de despliegue, CI/CD, configuración NGINX/PM2/Docker o actualización de dependencias críticas.
6. **Item 6 — Sin red de pruebas:** Cambios en rutas críticas donde ningún test existente ni nuevo detectaría una regresión.

---

## Triggers de Delegación a Subagentes (`Delegation Triggers`)

Ningún trigger está activo por defecto; ante la duda, trabaja *inline*. Cuando la condición de un trigger se cumple realmente, delegar es **obligatorio**:

- **Ask Trigger:** Decisión de producto o alcance abierta $\rightarrow$ 1 pregunta enfocada al usuario, parar y esperar.
- **Mapping Trigger:** Entender el módulo supera el lote inline o requiere $>5$ búsquedas secuenciales $\rightarrow$ delegar 1 subagente `explorer` de solo lectura (handoff $\le 2\text{k}$ tokens con evidencia `path:line` + 1 spot-check del padre).
- **Writer Trigger:** Delegar un subagente escritor (`implementer`) **únicamente** por:
  - *(a) Paralelismo real:* 2 o más unidades de comportamiento independientes con superficies de edición disjuntas (`## Allowed edit surfaces`) y $>100$ líneas/varios minutos de trabajo cada una.
  - *(b) Backstop de contexto:* Cuando la sesión principal supera ~150k tokens.
- **Verification Trigger:** Todo cambio cuya línea `Risk:` nombre uno de los ítems `1..6` exige verificación rigurosa (y un subagente `verifier` independiente con mentalidad de **refutación / disproval** que intente demostrar cómo falla el cambio usando pruebas en un directorio temporal `mktemp -d`).

### Superficies de Edición Permitidas (`## Allowed edit surfaces`)
Siempre que se delegue a un subagente escritor, el prompt debe incluir una sección `## Allowed edit surfaces` con las rutas exactas relativas al repositorio o globs estrechos donde tiene permiso de escribir. Nunca autorices `.` ni la raíz completa del repositorio.
