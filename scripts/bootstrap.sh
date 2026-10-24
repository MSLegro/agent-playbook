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

sync_clean_skills_dir() {
  local target_skills_dir="$1"
  local label="$2"
  mkdir -p "$target_skills_dir"

  # Archive and remove any non-symlink (unmanaged/bloat) skills or manifests
  for existing in "$target_skills_dir"/* "$target_skills_dir"/.*; do
    local base
    base="$(basename "$existing")"
    if [ "$base" = "." ] || [ "$base" = ".." ]; then
      continue
    fi
    if [ -e "$existing" ] || [ -L "$existing" ]; then
      if [ ! -L "$existing" ]; then
        mkdir -p "$BACKUP_DIR/${label}-unmanaged-skills"
        mv "$existing" "$BACKUP_DIR/${label}-unmanaged-skills/$base"
      else
        rm -f "$existing"
      fi
    fi
  done

  # Link exclusively the curated playbook skills
  for skill_path in "$PLAYBOOK_DIR/skills"/*; do
    if [ -d "$skill_path" ]; then
      local skill_name
      skill_name="$(basename "$skill_path")"
      ln -sfn "$skill_path" "$target_skills_dir/$skill_name"
    fi
  done
}

echo "=== Bootstrapping MSlegro Agent Playbook from $PLAYBOOK_DIR ==="

# 1. Google Antigravity (~/.gemini/config)
AGY_CONFIG="$HOME/.gemini/config"
mkdir -p "$AGY_CONFIG"

backup_if_exists "$AGY_CONFIG/AGENTS.md"
backup_if_exists "$AGY_CONFIG/GEMINI.md"
backup_if_exists "$AGY_CONFIG/skills.json"
backup_if_exists "$AGY_CONFIG/hooks.json"

ln -sfn "$PLAYBOOK_DIR/AGENTS.md" "$AGY_CONFIG/AGENTS.md"
ln -sfn "$PLAYBOOK_DIR/GEMINI.md" "$AGY_CONFIG/GEMINI.md"
ln -sfn "$PLAYBOOK_DIR/core" "$AGY_CONFIG/core"
ln -sfn "$PLAYBOOK_DIR/adapters/antigravity/skills.json" "$AGY_CONFIG/skills.json"
ln -sfn "$PLAYBOOK_DIR/adapters/antigravity/hooks.json" "$AGY_CONFIG/hooks.json"

sync_clean_skills_dir "$AGY_CONFIG/skills" "antigravity"
echo "[antigravity] Cleaned bloat skills and linked $(ls -1d "$PLAYBOOK_DIR/skills"/* | wc -l) playbook entries into $AGY_CONFIG/skills"

# Write clean MCP servers config (removing dead/disabled datacloud entries)
MCP_CONFIG="$AGY_CONFIG/mcp_config.json"
cp "$PLAYBOOK_DIR/adapters/antigravity/mcp_config.template.json" "$MCP_CONFIG"
echo "[antigravity] Synced clean MCP servers in $MCP_CONFIG"

# 2. OpenCode (~/.config/opencode)
OPENCODE_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_DIR"

backup_if_exists "$OPENCODE_DIR/AGENTS.md"
ln -sfn "$PLAYBOOK_DIR/AGENTS.md" "$OPENCODE_DIR/AGENTS.md"
ln -sfn "$PLAYBOOK_DIR/core" "$OPENCODE_DIR/core"

sync_clean_skills_dir "$OPENCODE_DIR/skills" "opencode"
echo "[opencode] Cleaned legacy skills and linked $(ls -1d "$PLAYBOOK_DIR/skills"/* | wc -l) playbook entries into $OPENCODE_DIR/skills"

# 3. Claude Code (~/.claude)
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
ln -sfn "$PLAYBOOK_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
ln -sfn "$PLAYBOOK_DIR/core" "$CLAUDE_DIR/core"
ln -sfn "$PLAYBOOK_DIR/skills" "$CLAUDE_DIR/skills"
echo "[claude] Linked CLAUDE.md, core/, and skills into $CLAUDE_DIR"

echo "=== Bootstrap completed successfully! ==="
