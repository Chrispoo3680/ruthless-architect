#!/usr/bin/env bash
set -euo pipefail

mode=symlink
if [[ "${1:-}" == "--copy" ]]; then
  mode=copy
elif [[ -n "${1:-}" ]]; then
  printf 'Usage: %s [--copy]\n' "$0" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="${HOME}/.claude/skills"
target="${skills_dir}/ruthless-architect"
mkdir -p "$skills_dir"

if [[ -e "$target" || -L "$target" ]]; then
  backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
  mv "$target" "$backup"
  printf 'Backed up existing installation to %s\n' "$backup"
fi

if [[ "$mode" == copy ]]; then
  cp -a "$repo_root" "$target"
  rm -rf "$target/.git" "$target/.github"
  printf 'Installed copy at %s\n' "$target"
else
  ln -s "$repo_root" "$target"
  printf 'Installed symlink %s -> %s\n' "$target" "$repo_root"
fi

printf 'Run: %s/scripts/doctor.sh\n' "$target"
