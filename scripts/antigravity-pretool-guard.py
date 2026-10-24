#!/usr/bin/env python3
"""
Antigravity PreToolUse guardrail hook for MSlegro's agent-playbook.
- Hard-denies AI attribution trailers (Co-Authored-By) in git commits.
- Forces user confirmation (force_ask) ONLY on destructive history/data commands
  (git push --force, git reset --hard, DROP TABLE/DATABASE, TRUNCATE TABLE).
- Allows normal git push seamlessly when requested by the user.
"""

from __future__ import annotations

import json
import re
import sys

AI_ATTRIBUTION_RE = re.compile(
    r"(co-authored-by\s*:|generated with claude|🤖\s*generated)",
    re.IGNORECASE,
)

DESTRUCTIVE_CMD_RE = re.compile(
    r"("
    r"git\s+push\s+.*(--force(?:-with-lease)?|-f\b)"
    r"|git\s+reset\s+--hard"
    r"|\bDROP\s+(?:TABLE|DATABASE|SCHEMA)\b"
    r"|\bTRUNCATE\s+TABLE\b"
    r")",
    re.IGNORECASE,
)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        print(json.dumps({"decision": "allow"}))
        return 0

    tool_call = payload.get("toolCall") or {}
    args = tool_call.get("args") or {}
    cmd = str(args.get("CommandLine") or "")

    if AI_ATTRIBUTION_RE.search(cmd):
        print(
            json.dumps(
                {
                    "decision": "deny",
                    "reason": "Playbook rule violation: AI attribution (Co-Authored-By) is strictly forbidden in commits.",
                }
            )
        )
        return 0

    if DESTRUCTIVE_CMD_RE.search(cmd):
        print(
            json.dumps(
                {
                    "decision": "force_ask",
                    "reason": "Destructive git/database operation detected by agent-playbook guardrails.",
                }
            )
        )
        return 0

    print(json.dumps({"decision": "allow"}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
