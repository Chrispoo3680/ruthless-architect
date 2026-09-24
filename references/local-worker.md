# Local worker adapter

This adapter is intentionally **disabled until the exact local model is installed and the OpenCode/Ollama harness is tested**. The recommended harness is OpenCode in non-interactive mode backed by a local Ollama provider. Claude must never invent an invocation.

## Status

```yaml
enabled: false
adapter: OpenCode non-interactive `run`
runtime: Ollama local API
model: null              # fill exact OpenCode provider/model id after `opencode models`
minimum_context: 64k     # OpenCode/Ollama recommendation for repository work
isolation: dedicated git worktree; invocation cwd/dir must be that worktree
```

Set `enabled: true` only after completing the health check and a disposable edit test.

## Expected installation

Ollama local runtime plus OpenCode CLI. Runtime truth beats this reference if installed versions differ.

Ollama API is expected at:

```text
http://localhost:11434
```

OpenCode should be configured with an Ollama provider targeting the local OpenAI-compatible endpoint (commonly `http://localhost:11434/v1`) or via Ollama's supported OpenCode integration.

## Invocation

After installation, inspect:

```bash
opencode --help
opencode run --help
opencode models
```

The current documented automation surface is `opencode run`, which accepts a prompt non-interactively and supports model selection. Use the exact executable/flags from the installed version.

Canonical intent after verification:

```bash
cd <isolated-worktree>
opencode run --model <verified-ollama-provider/model> "<bounded worker contract>"
```

If the installed CLI supports a documented `--dir` and/or structured `--format json`, prefer them, but do not invent flags. Cwd must still be verified for edit-capable execution.

## Health check

1. Verify Ollama:

```bash
ollama -v
curl -s http://localhost:11434/api/tags
```

2. Verify OpenCode:

```bash
command -v opencode
opencode --version
opencode models
opencode run --help
```

3. From a disposable git repository/worktree, run a bounded read-only prompt using the chosen local model.
4. Then run a disposable one-file edit with an exact validation command and confirm:
   - only the allowed file changed;
   - OpenCode can execute/observe the validation required by your chosen configuration;
   - the process exits without an interactive TUI;
   - output is sufficient for the worker handoff.

Only then set `enabled: true` and record the exact model id/invocation below.

## Configured values

```text
MODEL: <UNCONFIGURED>
INVOCATION: <UNCONFIGURED>
HEALTH CHECK RESULT: <UNCONFIGURED>
AUTONOMOUS COMMAND EXECUTION: yes | no | <UNCONFIGURED>
STRUCTURED OUTPUT: yes | no | <UNCONFIGURED>
```

## Inputs

The adapter receives the bounded worker contract from `delegation.md`. It must operate only in the assigned worktree and within allowed scope.

## Outputs

Return at minimum:

- status;
- changed files;
- exact validation commands/results if executed;
- material assumptions;
- unresolved issues;
- diff/commit reference.

## Safety requirements

- Isolated worktree first; verify invocation cwd.
- Never silently fall back to raw `ollama run` for autonomous coding. Raw generation is not the configured coding harness.
- No repository-wide semantic reconnaissance role. Mechanical discovery uses deterministic tools; broad semantic reconnaissance uses configured Gemini.
- Validation must be finite/non-interactive.
- Do not grant broader filesystem/repository scope than needed.
- Adapter failure makes `LOCAL` unavailable for that unit until reclassified.
