#!/usr/bin/env bash
# Insert skills/molt-note.md right after the SKILL.md frontmatter, so agents
# learn the daemon and permissions belong to Molt.
set -euo pipefail

skill=$1
note=$(cd "$(dirname "$0")/.." && pwd)/skills/molt-note.md

{
  awk '{ print } $0 == "---" && ++n == 2 { exit }' "$skill"
  echo
  cat "$note"
  awk 'found { print } $0 == "---" && ++n == 2 { found = 1 }' "$skill"
} > "$skill.tmp"
mv "$skill.tmp" "$skill"
