---
name: rpa-hexagonal-orchestration
description: >-
  Hexagonal RPA (Robotic Process Automation) architecture with Playwright in TypeScript
  and Python (uv, pydantic-settings, loguru), resilient web automation against legacy
  portals, automatic session/trace capture on failure, and idempotent database persistence.
  Use when building, debugging, or refactoring RPA bots, portal scrapers, document
  upload/extraction pipelines, or scheduled automation workers.
  Keywords: rpa, playwright, automation, bot, python uv, pydantic-settings, loguru, trace, idempotent scraping.
  Do not use for standard web app E2E test suites — use playwright-best-practices.
---

# Hexagonal RPA Orchestration (TypeScript & Python `uv`)

## Activation Contract
Activate this skill when creating, maintaining, or troubleshooting Robotic Process Automation (RPA) bots, portal extraction/upload pipelines, or hybrid browser + database workers in either **TypeScript (Node.js + Playwright)** or **Python (`uv` + `playwright` + `pydantic-settings` + `loguru`)**.

## Hard Rules

### 1. Hexagonal Separation in RPA
- **Never mix Playwright selectors (`page.locator`) with database queries (`mssql`/`pyodbc`) or business rules in the same file.**
- Separate every RPA project into:
  - `domain/`: WorkItem entities, state machine (`PENDING` -> `IN_PROGRESS` -> `COMPLETED` | `FAILED_RETRYABLE` | `FAILED_PERMANENT`), and port interfaces (`PortalAutomationPort`, `WorkQueuePort`).
  - `application/`: Orchestration use cases managing batch loops, concurrency limits, and retry policies.
  - `infrastructure/browser/`: Page Objects / Portal Adapters encapsulating Playwright interactions, authentication, and evidence capture.
  - `infrastructure/persistence/`: Database or queue adapters tracking item status idempotently.

### 2. Zero Fixed Sleeps (`waitForTimeout` / `time.sleep` Forbidden)
- Never use `page.waitForTimeout(5000)` or `time.sleep(5)` to wait for page loads or AJAX modals.
- Always synchronize on explicit UI or network states:
  - `await expect(locator).toBeVisible({ timeout: 15_000 })`
  - `await page.waitForResponse(res => res.url().includes('/api/target') && res.status() === 200)`
  - `await locator.waitFor({ state: 'attached' })`

### 3. Mandatory Failure Evidence (Traces, Screenshots & HTML Snapshots)
- External government/healthcare/enterprise portals change DOM structure and fail unpredictably.
- Every RPA execution unit MUST start Playwright tracing (`context.tracing.start({ screenshots: true, snapshots: true })`) and, on any error:
  1. Save `trace-<workItemId>-<timestamp>.zip`.
  2. Capture a full-page screenshot (`fullPage: true`).
  3. Log the failure with `workItemId`, current URL, and step name using structured logging (`pino` or `loguru`).
  4. Discard traces on clean success to avoid filling disk space.

### 4. Idempotent Checkpointing & Session Reuse
- Before processing a work item, verify its status in persistence so restarting a crashed batch never double-submits a form or re-uploads a document.
- Persist and reuse authenticated browser `storageState` (`auth-state.json`) with expiration checks instead of logging in from scratch on every single item.

### 5. Python RPA Standards (`uv` + `pydantic-settings` + `loguru`)
- Manage dependencies exclusively via `uv` (`pyproject.toml` + `uv.lock`).
- Validate all environment variables (`PORTAL_URL`, `PORTAL_USER`, `HEADLESS`, `DB_DSN`) at startup with `pydantic-settings` (`BaseSettings`).
- Use `dict[str, Any]` / `list[str]` and `X | None` (Python 3.11+ typing).

## Decision Gates
- **Is the failure caused by a portal timeout / 502 / expired session?**
  -> Classify as `RetryablePortalError`, invalidate cached `storageState`, re-authenticate once, and retry the work item.
- **Is the failure caused by invalid business data on the form (e.g., invalid document ID or missing required attachment)?**
  -> Classify as `PermanentBusinessError`, record the exact portal validation message in the database, and immediately move to the next work item without retrying.

## Output Contract
When generating or refactoring an RPA bot:
1. Define the `WorkItem` state transitions and `PortalAutomationPort` in `domain/`.
2. Implement the Playwright adapter in `infrastructure/browser/` with automatic trace/screenshot capture on exception.
3. Ensure browser contexts (`context.close()`) and downloads are always cleaned up in `finally` blocks.

## References
- Complete TypeScript (`ResultAsync` + Playwright Trace Wrapper) and Python (`uv` + `pydantic-settings` + `loguru` context manager) RPA templates: see [examples.md](references/examples.md).
