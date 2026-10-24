#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/.config/agent-playbook-backups/$TIMESTAMP"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$target" "$BACKUP_DIR/$(basename "$target")"
    echo "[backup] Saved $target -> $BACKUP_DIR/$(basename "$target")"
  fi
}

echo "=== Bootstrapping MSlegro Agent Playbook from $PLAYBOOK_DIR ==="

# 1. Google Antigravity (~/.gemini/config)
AGY_CONFIG="$HOME/.gemini/config"
mkdir -p "$AGY_CONFIG/skills"

backup_if_exists "$AGY_CONFIG/AGENTS.md"
backup_if_exists "$AGY_CONFIG/GEMINI.md"
backup_if_exists "$AGY_CONFIG/skills.json"
backup_if_exists "$AGY_CONFIG/hooks.json"

ln -sfn "$PLAYBOOK_DIR/AGENTS.md" "$AGY_CONFIG/AGENTS.md"
ln -sfn "$PLAYBOOK_DIR/GEMINI.md" "$AGY_CONFIG/GEMINI.md"
ln -sfn "$PLAYBOOK_DIR/core" "$AGY_CONFIG/core"
ln -sfn "$PLAYBOOK_DIR/adapters/antigravity/skills.json" "$AGY_CONFIG/skills.json"
ln -sfn "$PLAYBOOK_DIR/adapters/antigravity/hooks.json" "$AGY_CONFIG/hooks.json"

# Link all playbook skills into ~/.gemini/config/skills while keeping existing GCP skills intact
for skill_path in "$PLAYBOOK_DIR/skills"/*; do
  if [ -d "$skill_path" ]; then
    skill_name="$(basename "$skill_path")"
    ln -sfn "$skill_path" "$AGY_CONFIG/skills/$skill_name"
  fi
done
echo "[antigravity] Linked AGENTS.md, GEMINI.md, core/, hooks.json, skills.json and playbook skills into $AGY_CONFIG"

# Merge engram, context7, and serena into ~/.gemini/config/mcp_config.json safely
MCP_CONFIG="$AGY_CONFIG/mcp_config.json"
python3 - "$MCP_CONFIG" "$PLAYBOOK_DIR/adapters/antigravity/mcp_config.template.json" <<'PY'
import json
import sys
from pathlib import Path

target_path = Path(sys.argv[1])
template_path = Path(sys.argv[2])

template_data = json.loads(template_path.read_text(encoding="utf-8"))
if target_path.exists():
    try:
        current_data = json.loads(target_path.read_text(encoding="utf-8"))
    except Exception:
        current_data = {"mcpServers": {}}
else:
    current_data = {"mcpServers": {}}

current_data.setdefault("mcpServers", {})
for name, cfg in template_data.get("mcpServers", {}).items():
    current_data["mcpServers"][name] = cfg

target_path.write_text(json.dumps(current_data, indent=2) + "\n", encoding="utf-8")
print(f"[antigravity] Updated MCP servers in {target_path}")
PY

# 2. OpenCode (~/.config/opencode)
OPENCODE_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_DIR/skills"

backup_if_exists "$OPENCODE_DIR/AGENTS.md"
ln -sfn "$PLAYBOOK_DIR/AGENTS.md" "$OPENCODE_DIR/AGENTS.md"
ln -sfn "$PLAYBOOK_DIR/core" "$OPENCODE_DIR/core"

# Remove retired sdd-* skills and broken legacy skills from ~/.config/opencode/skills
rm -rf "$OPENCODE_DIR/skills"/sdd-*
rm -rf "$OPENCODE_DIR/skills/nodejs-backend-patterns"

for skill_path in "$PLAYBOOK_DIR/skills"/*; do
  if [ -d "$skill_path" ]; then
    skill_name="$(basename "$skill_path")"
    rm -rf "$OPENCODE_DIR/skills/$skill_name"
    ln -sfn "$skill_path" "$OPENCODE_DIR/skills/$skill_name"
  fi
done
echo "[opencode] Linked AGENTS.md, core/, and $(ls -1d "$PLAYBOOK_DIR/skills"/* | wc -l) skills into $OPENCODE_DIR"

# 3. Claude Code (~/.claude)
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
ln -sfn "$PLAYBOOK_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
ln -sfn "$PLAYBOOK_DIR/core" "$CLAUDE_DIR/core"
ln -sfn "$PLAYBOOK_DIR/skills" "$CLAUDE_DIR/skills"
echo "[claude] Linked CLAUDE.md, core/, and skills into $CLAUDE_DIR"

echo "=== Bootstrap completed successfully! ==="
