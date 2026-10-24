---
name: playbook-learn
description: >-
  Continuous self-improvement workflow to codify new engineering rules, lessons,
  architectural decisions, or skills directly into ~/.config/agent-playbook.
  Use when the user asks to save a lesson to their playbook, update global rules,
  or create/refine a reusable skill across agents.
  Keywords: playbook, learn, save rule, global skill, agent-playbook, evolve.
  Do not use for project-only tactical notes — use engram mem_save instead.
---

# Playbook Continuous Evolution (`playbook-learn`)

## Activation Contract
Activate this skill when:
- MSlegro says *"Guarda este aprendizaje en mi playbook"*, *"Agrega esta regla al playbook"*, or *"Crea/mejora una skill para esto"*.
- A systemic correction or architectural pattern emerges during a session that should apply permanently across all projects and AI agents.

## Hard Rules
1. **Sanitization First (Zero Leaks)**: `~/.config/agent-playbook` is a **public** repository (`MSlegro/agent-playbook`). NEVER write company names, internal server IPs, private domain names, database schemas, or credentials into any rule or skill. Abstract all examples into generic domain concepts.
2. **Respect Context Budgets**:
   - `AGENTS.md` and each file in `core/*.md` MUST remain `< 24 KB`.
   - Every `skills/<name>/SKILL.md` MUST remain `< 500` lines. Put extensive code samples in `skills/<name>/references/`.
3. **4-Part Description Contract**: Every `SKILL.md` frontmatter `description` (< 1024 chars) MUST include:
   - What it does.
   - `Use when...` trigger conditions.
   - `Keywords:` list.
   - `Do not use for X — use <other-skill>.` negative trigger.
4. **Zero Broken Links**: Every relative markdown link inside a skill or core rule MUST point to an existing file on disk.
5. **No AI Attribution**: Commits inside `~/.config/agent-playbook` must NEVER contain `Co-Authored-By` trailers.

## Decision Gates
- **Is it a project-specific fact (e.g., "port 4050 is used by auth service in repo X")?**
  -> Stop. Save it in `engram` (`mem_save` with `project` scope), NOT in `agent-playbook`.
- **Is it a universal coding law or workflow adjustment?**
  -> Update the appropriate file in `~/.config/agent-playbook/core/01..06-*.md`.
- **Is it a technology-specific pattern or repeatable procedure?**
  -> Update an existing skill in `~/.config/agent-playbook/skills/<skill-name>/SKILL.md` or create a new one.

## Execution Steps
1. **Locate Target**: Inspect `~/.config/agent-playbook/core/` and `~/.config/agent-playbook/skills/` to decide whether to update an existing file or create a new skill folder.
2. **Draft/Update Content**: Write concise, imperative rules (`Activation Contract`, `Hard Rules`, `Decision Gates`, `Execution Steps`, `Output Contract`). Move long examples (> 40 lines) into `references/examples.md`.
3. **Validate Playbook Integrity**:
   Run the validator script:
   ```bash
   python3 ~/.config/agent-playbook/scripts/validate-playbook.py
   ```
   Fix any reported frontmatter, line count, byte size, or broken link errors before proceeding.
4. **Sync Local Agent Symlinks (if new skill added)**:
   ```bash
   ~/.config/agent-playbook/scripts/bootstrap.sh
   ```
5. **Commit Changes**:
   Stage and commit inside `~/.config/agent-playbook` using Conventional Commits (`feat(skills): ...` or `docs(core): ...`). Ask MSlegro for confirmation before running `git push`.

## Output Contract
Report to MSlegro:
- Exact file(s) created or modified in `~/.config/agent-playbook`.
- Validation output from `validate-playbook.py`.
- Commit hash created (and ask whether to push to `origin/main` now).
