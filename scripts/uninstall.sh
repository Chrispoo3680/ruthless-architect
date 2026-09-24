#!/usr/bin/env bash
set -euo pipefail

target="${HOME}/.claude/skills/ruthless-architect"
if [[ -L "$target" || -d "$target" ]]; then
  rm -rf "$target"
  printf 'Removed %s\n' "$target"
else
  printf 'No Ruthless Architect installation found at %s\n' "$target"
fi
