---
name: turborepo
description: >-
  Turborepo monorepo architecture, turbo.json task pipelines (dependsOn, outputs,
  inputs, persistent), internal shared packages, and pnpm workspace filtering.
  Use when configuring or optimizing monorepos with Turborepo and pnpm workspaces.
  Keywords: turborepo, turbo.json, monorepo, dependsOn, ^build, outputs, pnpm workspaces.
  Do not use for single-package npm scripts — use pnpm.
---

# Turborepo Monorepo Best Practices

## Activation Contract
Activate when creating, configuring, or debugging multi-package monorepos using `turbo` (`turbo.json`) and `pnpm-workspace.yaml`.

## Hard Rules
1. **Explicit Task Dependencies (`dependsOn: ["^build"]`)**:
   - Ensure `build`, `typecheck`, and `test` tasks declare `"dependsOn": ["^build"]` when downstream apps depend on compiled artifacts from `packages/*`.
2. **Accurate Cache `outputs` & `inputs`**:
   - Always declare `"outputs": ["dist/**", ".next/**", "!.next/cache/**"]` on `build` tasks so Turborepo caches build artifacts accurately.
   - Mark `dev` / `watch` tasks with `"cache": false` and `"persistent": true`.
3. **Strict Environment Variable Hashing (`env` / `globalEnv`)**:
   - List every build-affecting environment variable in task `"env"` or root `"globalEnv"` so cache hits never serve stale environment configurations across staging and production.
4. **Internal Package Exports (Just-in-Time vs Compiled)**:
   - Shared internal packages (`@repo/ui`, `@repo/domain`, `@repo/config`) MUST declare explicit `"exports"` in `package.json` and isolated `tsconfig.json` extending `@repo/typescript-config`.

## Execution Pattern (`turbo.json`)

```json
{
  "$schema": "https://turbo.build/schema.json",
  "ui": "tui",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", ".env*"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": []
    },
    "lint": {
      "dependsOn": ["^lint"],
      "outputs": []
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

## Output Contract
- Valid `turbo.json` v2 (`"tasks"` key, never legacy `"pipeline"` key).
- Deterministic `inputs`, `outputs`, and `env` declarations.
