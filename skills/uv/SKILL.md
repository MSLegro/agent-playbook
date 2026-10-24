---
name: uv
description: >-
  Fast Python package, virtualenv, and project management with Astral uv
  (pyproject.toml, uv.lock, uv run, uv add, inline PEP 723 script metadata).
  Use when creating, running, or managing Python projects, dependencies, virtual
  environments, or standalone scripts.
  Keywords: uv, pyproject.toml, uv.lock, uv run, uv add, uv sync, python virtualenv, PEP 723.
  Do not use for Node.js package management — use pnpm.
---

# Python Dependency & Project Management with `uv`

## Activation Contract
Activate whenever working with Python projects, virtual environments, dependencies, CLI tools, or scripts.

## Hard Rules
1. **Never Use Global `pip install` or Unmanaged `venv`**:
   - Always use `uv` (`uv init`, `uv add`, `uv remove`, `uv sync`, `uv run`).
   - Never run `pip install <pkg>` directly in system Python.
2. **Commit `uv.lock` for Reproducible Builds**:
   - Every Python application or RPA worker MUST have a `pyproject.toml` and a committed `uv.lock`.
   - In CI/Docker, install dependencies with `uv sync --frozen --no-dev`.
3. **Execute Commands via `uv run`**:
   - Run entrypoints, linters, and tests via `uv run`:
     - `uv run pytest`
     - `uv run ruff check .`
     - `uv run python -m src.main`
4. **Self-Contained One-Off Scripts (PEP 723)**:
   - For standalone utility scripts, embed inline dependency metadata via `uv init --script script.py` and `uv add --script script.py <pkg>` so `uv run script.py` works on any machine with zero manual setup.

## Execution Pattern (`pyproject.toml` + Dockerfile)

```toml
[project]
name = "rpa-worker"
version = "0.1.0"
description = "Hexagonal RPA Worker"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "loguru>=0.7.2",
    "playwright>=1.50.0",
    "pydantic>=2.10.0",
    "pydantic-settings>=2.7.0",
]

[dependency-groups]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.25.0",
    "ruff>=0.9.0",
]
```

## Output Contract
- Dependencies declared in `pyproject.toml` (and dev tools in `[dependency-groups].dev`).
- All execution commands invoked through `uv run`.
