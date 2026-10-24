#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
PLAYBOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Target directory '$TARGET_DIR' does not exist." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR/.agents"
cat > "$TARGET_DIR/.agents/skills.json" <<EOF
{
  "version": 1,
  "skillsDir": "$PLAYBOOK_DIR/skills"
}
EOF

echo "Configured $TARGET_DIR/.agents/skills.json -> $PLAYBOOK_DIR/skills"
