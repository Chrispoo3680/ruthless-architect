#!/usr/bin/env bash
set -u

ok=0
warn=0
fail=0
dangerous_fallback=0

if [ "${1:-}" = "--gemini-dangerous-fallback" ]; then
  dangerous_fallback=1
elif [ "${1:-}" != "" ]; then
  printf 'Usage: %s [--gemini-dangerous-fallback]\n' "$0" >&2
  exit 2
fi

pass(){ printf 'PASS  %s\n' "$*"; ok=$((ok+1)); }
warning(){ printf 'WARN  %s\n' "$*"; warn=$((warn+1)); }
failure(){ printf 'FAIL  %s\n' "$*"; fail=$((fail+1)); }
check_cmd(){ if command -v "$1" >/dev/null 2>&1; then pass "$1 -> $(command -v "$1")"; else failure "$1 not found"; fi; }

printf '%s\n' 'Ruthless Architect dependency doctor' '------------------------------------'
check_cmd git
check_cmd claude

agy_worker_test() {
  local extra_flag="${1:-}"
  local label="${2:-configured permissions}"
  local tmp repo schema stream err rcfile prompt rc unexpected status

  tmp="$(mktemp -d "${TMPDIR:-/tmp}/ruthless-agy-doctor.XXXXXX")" || return 1
  repo="$tmp/repo"
  schema="$tmp/expected-schema.json"
  stream="$tmp/agy-stream.ndjson"
  err="$tmp/agy-stderr.txt"
  rcfile="$tmp/agy-rc.txt"
  mkdir -p "$repo"

  (
    cd "$repo" || exit 90
    git init -q || exit 91
    printf 'hello\n' > sample.txt
    git add sample.txt
    git -c user.name='Ruthless Doctor' -c user.email='doctor@example.invalid' commit -qm baseline || exit 92
  ) || {
    warning "Antigravity health setup failed ($label)"
    rm -rf "$tmp"
    return 1
  }

  cat > "$schema" <<'JSON'
{
  "type": "object",
  "properties": {
    "status": {"type": "string"},
    "changed_files": {"type": "array", "items": {"type": "string"}},
    "git_command": {"type": "string"},
    "git_result": {"type": "string"}
  },
  "required": ["status", "changed_files", "git_command", "git_result"]
}
JSON

  prompt="RUTHLESS ARCHITECT HEALTH CHECK.
WORKSPACE ROOT: $repo
HARD BOUNDARY:
- Read and modify files only beneath WORKSPACE ROOT.
- Use native file tools with absolute paths rooted beneath WORKSPACE ROOT.
- Do not use shell utilities to inspect files.
- Do not access any path outside WORKSPACE ROOT.
TASK:
1. Read exactly $repo/sample.txt using a native file tool.
2. Change exactly $repo/sample.txt so its exact contents are: hello world
3. Do not create or modify any other repository file.
4. Then run exactly this one shell command and no other shell command:
   git -C $repo status --short
5. Return the requested structured result with status COMPLETE, changed_files, the exact git command, and its observed result."

  local -a cmd
  cmd=(agy --effort low --output-format stream-json --json-schema "$schema" --print-timeout 2m -p "$prompt")
  if [ -n "$extra_flag" ]; then cmd+=("$extra_flag"); fi

  (
    cd "$repo" || exit 93
    "${cmd[@]}" > "$stream" 2> "$err"
    printf '%s' "$?" > "$rcfile"
  )

  rc="$(cat "$rcfile" 2>/dev/null || printf 99)"
  if [ "$rc" -ne 0 ]; then
    warning "Antigravity end-to-end test ($label) exited $rc"
    sed -n '1,12p' "$err" 2>/dev/null | sed 's/^/      /' >&2 || true
    rm -rf "$tmp"
    return 1
  fi

  if [ "$(cat "$repo/sample.txt" 2>/dev/null || true)" != "hello world" ]; then
    warning "Antigravity end-to-end test ($label) did not make the expected absolute-workspace edit"
    rm -rf "$tmp"
    return 1
  fi

  status="$(git -C "$repo" status --porcelain --untracked-files=all)"
  if [ "$status" != ' M sample.txt' ]; then
    warning "Antigravity end-to-end test ($label) left unexpected repository state: ${status:-<clean>}"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Fq '"event":"result"' "$stream" && ! grep -Eq '"event"[[:space:]]*:[[:space:]]*"result"' "$stream"; then
    warning "Antigravity end-to-end test ($label) produced no terminal result event"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"SUCCESS"' "$stream"; then
    warning "Antigravity end-to-end test ($label) did not report terminal SUCCESS"
    rm -rf "$tmp"
    return 1
  fi

  # SUCCESS is not sufficient: reject any non-empty denied_actions.
  if grep -Eq '"denied_actions"[[:space:]]*:[[:space:]]*\[[[:space:]]*\{' "$stream"; then
    warning "Antigravity end-to-end test ($label) reported denied_actions despite terminal SUCCESS"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Fq "$repo/sample.txt" "$stream"; then
    warning "Antigravity end-to-end test ($label) did not show absolute-path access to sample.txt"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Eq '"tool_name"[[:space:]]*:[[:space:]]*"(view_file|read_file)"' "$stream"; then
    warning "Antigravity end-to-end test ($label) did not expose a native file-read step"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Eq '"tool_name"[[:space:]]*:[[:space:]]*"(write_to_file|replace_file_content|multi_replace_file_content|sed_file)"' "$stream"; then
    warning "Antigravity end-to-end test ($label) did not expose a native file-edit step"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Eq '"tool_name"[[:space:]]*:[[:space:]]*"run_command"' "$stream"; then
    warning "Antigravity end-to-end test ($label) did not expose the required Git run_command step"
    rm -rf "$tmp"
    return 1
  fi

  if ! grep -Fq "git -C $repo status --short" "$stream"; then
    warning "Antigravity end-to-end test ($label) did not execute Git using the required absolute-workspace git -C form"
    rm -rf "$tmp"
    return 1
  fi

  pass "Antigravity worker health ($label): absolute workspace read/edit + git -C + no denied actions + structured result"
  rm -rf "$tmp"
  return 0
}

if command -v agy >/dev/null 2>&1; then
  pass "agy -> $(command -v agy)"
  agy --version >/dev/null 2>&1 && pass 'agy --version' || warning 'agy --version failed'
  agy models >/dev/null 2>&1 && pass 'agy models (auth/model access looks available)' || warning 'agy models failed; authenticate/configure Antigravity before GEMINI routing'
  if agy --help 2>&1 | grep -q -- '--output-format' && \
     agy --help 2>&1 | grep -q -- '--json-schema' && \
     agy --help 2>&1 | grep -q -- '--print-timeout' && \
     agy --help 2>&1 | grep -q -- '--effort'; then
    pass 'agy headless structured-output/timeout/effort flags detected'
  else
    warning 'installed agy help does not expose expected headless flags; GEMINI adapter contract may need updating'
  fi

  if ! agy_worker_test '' 'configured permissions'; then
    warning 'GEMINI routing must remain disabled until the absolute-workspace health test passes'
    if [ "$dangerous_fallback" -eq 1 ]; then
      warning 'explicitly testing --dangerously-skip-permissions in the disposable doctor repository'
      if agy_worker_test '--dangerously-skip-permissions' 'dangerous fallback'; then
        warning 'dangerous fallback works, but this does NOT authorize silent use; record explicit opt-in before production use'
      else
        warning 'dangerous fallback also failed; GEMINI routing unavailable'
      fi
    else
      warning 'rerun with --gemini-dangerous-fallback only if you explicitly want to test the broad bypass in the disposable environment'
    fi
  fi
else
  warning 'agy not found; GEMINI routing unavailable until installed'
fi

if command -v ollama >/dev/null 2>&1; then
  pass "ollama -> $(command -v ollama)"
  if curl -fsS --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
    pass 'Ollama local API reachable at localhost:11434'
  else
    warning 'Ollama installed but local API is not reachable'
  fi
else
  warning 'ollama not found; LOCAL routing unavailable until installed'
fi

if command -v opencode >/dev/null 2>&1; then
  pass "opencode -> $(command -v opencode)"
  opencode run --help >/dev/null 2>&1 && pass 'opencode run is available' || warning 'opencode run unavailable; update local-worker.md to match installed CLI'
else
  warning 'opencode not found; recommended LOCAL harness unavailable'
fi

if [ -f "$HOME/.codex/config.toml" ]; then
  pass '~/.codex/config.toml exists'
else
  warning '~/.codex/config.toml not found; Codex review runtime config cannot be inspected from shell'
fi

if [ -f "$HOME/.gemini/antigravity-cli/settings.json" ]; then
  pass '~/.gemini/antigravity-cli/settings.json exists'
else
  warning 'Antigravity settings file not found yet (normally created after first interactive setup)'
fi

printf '\nSummary: %d pass, %d warning, %d fail\n' "$ok" "$warn" "$fail"
if [ "$fail" -gt 0 ]; then exit 1; fi
