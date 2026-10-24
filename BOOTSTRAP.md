# AI Agent Self-Onboarding Protocol (`BOOTSTRAP.md`)

> **ATTENTION AI AGENT**: If the user gave you this repository URL (`https://github.com/MSlegro/agent-playbook`) or pointed you to `~/.config/agent-playbook`, follow these exact steps to configure yourself as **MSlegro's Engineering Pair Programmer**.

---

## Step 1: Clone or Update the Playbook

Ensure the repository is cloned at the canonical XDG configuration path `~/.config/agent-playbook`:

```bash
if [ ! -d "$HOME/.config/agent-playbook/.git" ]; then
  mkdir -p "$HOME/.config"
  git clone https://github.com/MSlegro/agent-playbook.git "$HOME/.config/agent-playbook"
else
  git -C "$HOME/.config/agent-playbook" pull --ff-only
fi
```

---

## Step 2: Run the Automated Bootstrap Script

Execute the idempotent installer to wire rules, skills, and MCP servers into your environment (creates timestamped backups of any pre-existing files):

```bash
chmod +x "$HOME/.config/agent-playbook/scripts/bootstrap.sh"
"$HOME/.config/agent-playbook/scripts/bootstrap.sh"
```

---

## Step 3: Agent-Specific Wiring Reference

If you need to inspect or configure a specific agent manually, use the mapping below:

### 1. Google Antigravity (`~/.gemini/config/`)
- **Global Rules**: Symlink `~/.gemini/config/AGENTS.md` and `~/.gemini/config/GEMINI.md` to `~/.config/agent-playbook/AGENTS.md`.
- **Skill Registry**: Copy or symlink `~/.config/agent-playbook/adapters/antigravity/skills.json` to `~/.gemini/config/skills.json` so Antigravity discovers `~/.config/agent-playbook/skills`.
- **MCP Servers**: Merge `engram`, `context7`, and `serena` from `adapters/antigravity/mcp_config.template.json` into `~/.gemini/config/mcp_config.json`.

### 2. OpenCode (`~/.config/opencode/`)
- **Global Rules**: Symlink `~/.config/opencode/AGENTS.md` to `~/.config/agent-playbook/AGENTS.md`.
- **Skills**: Symlink skill directories from `~/.config/agent-playbook/skills/*` into `~/.config/opencode/skills/`.
- **Config**: See `adapters/opencode/opencode.template.json`.

### 3. Claude Code (`~/.claude/`)
- **Global Rules**: Symlink `~/.claude/CLAUDE.md` to `~/.config/agent-playbook/CLAUDE.md`.
- **Skills**: Symlink `~/.claude/skills` to `~/.config/agent-playbook/skills`.

### 4. Cursor / Windsurf / Codex
- Point global rules or workspace `.cursorrules` / `AGENTS.md` to `~/.config/agent-playbook/AGENTS.md`.
- Or initialize any project repository with:
  ```bash
  ~/.config/agent-playbook/scripts/init-project.sh /path/to/project
  ```

---

## Step 4: Verify Installation & Integrity

Run the playbook validator to confirm zero broken links, valid YAML frontmatter, and adherence to context size budgets:

```bash
python3 "$HOME/.config/agent-playbook/scripts/validate-playbook.py"
```

---

## Step 5: Load Core Context & Confirm Readiness

1. Read `~/.config/agent-playbook/AGENTS.md` and the 6 core modules in `~/.config/agent-playbook/core/`.
2. Check if `engram` is available in `$PATH` (`which engram`) and load prior project context if applicable.
3. Greet **MSlegro** in direct, technical neutral/Colombian Spanish (*tú*) and confirm that the playbook, skills, and ODD workflow are active.
