#!/usr/bin/env python3
"""
Validator for MSlegro's agent-playbook.
Verifies:
1. Rule file byte limits (< 24 KB for AGENTS.md and core/*.md).
2. Skill structure (flat skills/<name>/SKILL.md, valid YAML frontmatter, <= 500 lines).
3. Zero broken relative Markdown links across AGENTS.md, core/*.md, and skills/*/SKILL.md.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

PLAYBOOK_ROOT = Path(__file__).resolve().parent.parent
MAX_RULE_BYTES = 24 * 1024  # 24 KB cap
MAX_SKILL_LINES = 500
MAX_DESCRIPTION_CHARS = 1024

FENCED_CODE_RE = re.compile(r"```[\s\S]*?```", re.MULTILINE)
INLINE_CODE_RE = re.compile(r"`[^`\n]+`")
MD_LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def strip_code_blocks(text: str) -> str:
    text = FENCED_CODE_RE.sub("", text)
    text = INLINE_CODE_RE.sub("", text)
    return text


def parse_frontmatter(text: str) -> dict[str, str] | None:
    if not text.startswith("---\n"):
        return None
    end_idx = text.find("\n---\n", 4)
    if end_idx == -1:
        return None
    raw_fm = text[4:end_idx]
    result: dict[str, str] = {}
    current_key: str | None = None
    for line in raw_fm.splitlines():
        if not line.strip() or line.strip().startswith("#"):
            continue
        if not line.startswith((" ", "\t")) and ":" in line:
            key, val = line.split(":", 1)
            current_key = key.strip()
            val = val.strip()
            if val in (">-", ">", "|", "|-"):
                result[current_key] = ""
            else:
                result[current_key] = val.strip("'\"")
        elif current_key is not None and line.startswith((" ", "\t")):
            result[current_key] = (result[current_key] + " " + line.strip()).strip()
    return result


def check_relative_links(md_file: Path, text: str) -> list[str]:
    errors: list[str] = []
    cleaned = strip_code_blocks(text)
    for match in MD_LINK_RE.finditer(cleaned):
        raw_target = match.group(1).strip()
        if not raw_target:
            continue
        # Strip optional title in markdown link: (path "title")
        target = raw_target.split()[0].strip("<>")
        if (
            target.startswith(("http://", "https://", "mailto:", "#", "file://", "conversation://"))
            or "{{" in target
        ):
            continue
        target_path_str = target.split("#", 1)[0]
        if not target_path_str:
            continue
        resolved = (md_file.parent / target_path_str).resolve()
        if not resolved.exists():
            rel_source = md_file.relative_to(PLAYBOOK_ROOT)
            errors.append(f"{rel_source}: broken relative link -> '{target}'")
    return errors


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    # 1. Validate AGENTS.md and core/*.md
    rule_files = [PLAYBOOK_ROOT / "AGENTS.md", *sorted((PLAYBOOK_ROOT / "core").glob("*.md"))]
    for rf in rule_files:
        if not rf.exists():
            errors.append(f"Missing required rule file: {rf.relative_to(PLAYBOOK_ROOT)}")
            continue
        size = rf.stat().st_size
        if size > MAX_RULE_BYTES:
            errors.append(
                f"{rf.relative_to(PLAYBOOK_ROOT)} exceeds 24 KB limit ({size} bytes > {MAX_RULE_BYTES} bytes)"
            )
        content = rf.read_text(encoding="utf-8")
        errors.extend(check_relative_links(rf, content))

    # 2. Validate skills/*
    skills_dir = PLAYBOOK_ROOT / "skills"
    skill_count = 0
    for item in sorted(skills_dir.iterdir()):
        if not item.is_dir() or item.name.startswith(("_", ".")):
            continue
        skill_count += 1
        skill_md = item / "SKILL.md"
        if not skill_md.exists():
            errors.append(f"skills/{item.name}: missing SKILL.md")
            continue

        content = skill_md.read_text(encoding="utf-8")
        lines = content.splitlines()
        if len(lines) > MAX_SKILL_LINES:
            errors.append(
                f"skills/{item.name}/SKILL.md has {len(lines)} lines (max {MAX_SKILL_LINES})"
            )

        fm = parse_frontmatter(content)
        if not fm:
            errors.append(f"skills/{item.name}/SKILL.md: missing or invalid YAML frontmatter")
        else:
            if not fm.get("name"):
                errors.append(f"skills/{item.name}/SKILL.md: frontmatter missing 'name'")
            desc = fm.get("description", "")
            if not desc:
                errors.append(f"skills/{item.name}/SKILL.md: frontmatter missing 'description'")
            elif len(desc) > MAX_DESCRIPTION_CHARS:
                errors.append(
                    f"skills/{item.name}/SKILL.md: description too long ({len(desc)} > {MAX_DESCRIPTION_CHARS} chars)"
                )

        errors.extend(check_relative_links(skill_md, content))

    print(f"Validated {len(rule_files)} core rule files and {skill_count} skills.")
    if warnings:
        for w in warnings:
            print(f"  [WARN] {w}")
    if errors:
        for e in errors:
            print(f"  [ERROR] {e}")
        return 1

    print("All playbook checks passed with 0 errors!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
