# Hexagonal RPA Orchestration Reference Examples

## 1. TypeScript Playwright Evidence Wrapper (`src/infrastructure/browser/rpa-runner.ts`)

```typescript
import path from 'node:path';
import type { Browser, BrowserContext, Page } from 'playwright';
import { ResultAsync } from 'neverthrow';
import { DomainError } from '../../domain/errors/domain-error.js';

export class RpaPortalError extends DomainError {
  readonly code = 'RPA_PORTAL_ERROR';
  readonly category = 'EXTERNAL_DEPENDENCY' as const;
}

export function runWithBrowserEvidence<T>(
  browser: Browser,
  options: {
    workItemId: string;
    evidenceDir: string;
    storageStatePath?: string;
  },
  task: (page: Page, context: BrowserContext) => Promise<T>,
): ResultAsync<T, RpaPortalError> {
  return ResultAsync.fromPromise(
    (async () => {
      const context = await browser.newContext({
        storageState: options.storageStatePath,
        acceptDownloads: true,
        viewport: { width: 1440, height: 900 },
      });

      await context.tracing.start({ screenshots: true, snapshots: true });
      const page = await context.newPage();

      try {
        const result = await task(page, context);
        await context.tracing.stop();
        return result;
      } catch (error) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const baseName = `${options.workItemId}-${timestamp}`;
        const tracePath = path.join(options.evidenceDir, `${baseName}-trace.zip`);
        const screenshotPath = path.join(options.evidenceDir, `${baseName}-error.png`);

        await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => undefined);
        await context.tracing.stop({ path: tracePath }).catch(() => undefined);

        throw new RpaPortalError(
          `RPA execution failed for item '${options.workItemId}' at URL '${page.url()}'`,
          { workItemId: options.workItemId, tracePath, screenshotPath, url: page.url() },
          error,
        );
      } finally {
        await context.close().catch(() => undefined);
      }
    })(),
    (err) => (err instanceof RpaPortalError ? err : new RpaPortalError('Unexpected RPA failure', {}, err)),
  );
}
```

---

## 2. Python RPA Settings & Resilient Context Manager (`src/infrastructure/browser/session.py`)

```python
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

from loguru import logger
from playwright.async_api import Browser, BrowserContext, Page
from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class RpaSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    portal_base_url: str = Field(..., description="Target portal root URL")
    portal_username: str
    portal_password: SecretStr
    headless: bool = True
    evidence_dir: Path = Path("./artifacts/evidence")
    navigation_timeout_ms: int = 30_000


@asynccontextmanager
async def traced_portal_page(
    browser: Browser,
    work_item_id: str,
    settings: RpaSettings,
    storage_state: Path | None = None,
) -> AsyncIterator[Page]:
    settings.evidence_dir.mkdir(parents=True, exist_ok=True)
    context: BrowserContext = await browser.new_context(
        storage_state=str(storage_state) if storage_state and storage_state.exists() else None,
        accept_downloads=True,
    )
    context.set_default_timeout(settings.navigation_timeout_ms)
    await context.tracing.start(screenshots=True, snapshots=True)
    page = await context.new_page()

    try:
        yield page
        await context.tracing.stop()
    except Exception as exc:
        ts = datetime.now(tz=timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        trace_file = settings.evidence_dir / f"{work_item_id}_{ts}_trace.zip"
        png_file = settings.evidence_dir / f"{work_item_id}_{ts}_error.png"

        try:
            await page.screenshot(path=str(png_file), full_page=True)
            await context.tracing.stop(path=str(trace_file))
        except Exception as capture_err:
            logger.warning("Failed to capture RPA evidence: {}", capture_err)

        logger.bind(
            work_item_id=work_item_id,
            current_url=page.url,
            trace=str(trace_file),
            screenshot=str(png_file),
        ).error("RPA task failed: {}", exc)
        raise
    finally:
        await context.close()
```
