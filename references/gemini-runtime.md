# Gemini / Antigravity runtime contract

Read this reference before `GEMINI_RECON`, `GEMINI`, or `GEMINI_ARBITRATION`.

## Adapter status

This reference targets the **local Google Antigravity CLI (`agy`)**, not the separately billed Gemini API managed-agent sandbox.

```yaml
enabled: conditional
adapter: Google Antigravity CLI
binary: agy
execution_mode: headless / print mode
prompt_flag: -p
workspace: local filesystem + explicit absolute WORKSPACE ROOT
authentication: cached Google OAuth through Antigravity CLI
```

`enabled: conditional` means Gemini routing is available only after the empirical health check below passes for the installed CLI, current authentication, current permission policy, and current machine. A settings file or text-only prompt is not sufficient.

If the installed CLI differs from this contract, inspect `agy --help`, `agy models`, and current official documentation, then update this reference. Runtime truth beats this file. Never substitute Gemini API managed agents, an SDK wrapper, or another billing path without explicit user approval.

## Non-negotiable workspace anchor

Antigravity must never be trusted to infer the repository solely from process cwd.

Every Gemini invocation receives an explicit absolute path:

```text
WORKSPACE ROOT: /absolute/path/to/isolated-worktree
```

The contract MUST also state:

```text
HARD BOUNDARY
- Read and modify files only beneath WORKSPACE ROOT.
- For native file tools, use absolute paths rooted beneath WORKSPACE ROOT.
- For Git commands, use: git -C <WORKSPACE ROOT> ...
- Do not rely on `cd <workspace> && git ...`.
- Do not access files outside WORKSPACE ROOT unless the approved task explicitly requires a named external path.
```

The worker process cwd should still be set to the isolated worktree, but cwd is only a secondary defense. The absolute workspace root is authoritative.

## Required runtime capabilities

Before Gemini routing is enabled, the installed runtime must demonstrate all of the following:

- non-interactive `agy -p` execution;
- local repository/worktree access;
- exact absolute-workspace file reads and writes;
- Git command execution via `git -C <workspace-root> ...` without interactive approval;
- finite timeout behavior;
- machine-readable output;
- a terminal result event;
- no denied actions;
- no unexpected out-of-scope edits during the health test.

Run `scripts/doctor.sh` after installation/configuration. If its Antigravity end-to-end worker test fails, treat all automated Gemini roles as unavailable even if `agy` launches successfully.

## Installation / authentication assumptions

Expected official installation pattern:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy --version
```

First-time login is interactive: launch `agy`, choose Google OAuth, complete browser login, accept terms, and trust only appropriate workspaces. The skill must not automate first-time account authorization.

## Model and effort selection

Do not hard-code a stale model slug in `SKILL.md`. Inspect:

```bash
agy models
agy --help
```

Use the exact model identifier accepted by the installed CLI.

Preferred role policy when supported by the installed CLI:

- `GEMINI_RECON`: `--effort low` by default; `medium` for difficult semantic mapping.
- `GEMINI` implementation: `--effort medium` by default; `high` for difficult but Gemini-suitable work.
- `GEMINI_ARBITRATION`: `--effort medium` or `high` according to consequence and evidence-tracing difficulty.

Do not invent unsupported effort levels and do not silently fall back to a different model if a pinned model is rejected.

## Structured output and timeout

Prefer machine-readable headless output rather than scraping prose.

For tool-call visibility use:

```bash
--output-format stream-json
```

Use `--json-schema` where practical to constrain the terminal handoff. Every invocation MUST set a finite `--print-timeout` appropriate to the unit.

A terminal Antigravity `status: SUCCESS` is **necessary but never sufficient**. A run counts as successful only when all of the following are true:

- `denied_actions` is absent or empty;
- required tool calls completed;
- expected files actually changed as required;
- no unexpected files changed;
- required validation commands ran successfully;
- the structured stream reached a terminal result;
- Claude independently inspects the resulting diff/evidence.

## Permissions

Headless mode has no interactive approval surface. Prove behavior empirically; do not trust configuration text alone.

Preferred order:

1. Fine-grained `permissions.allow` rules for the commands the worker actually needs, such as `command(git)`, project package managers, test runners, and build/typecheck tools.
2. Broader persistent permission modes only when the user deliberately accepts the wider authority.
3. `--dangerously-skip-permissions` only as an explicit opt-in diagnostic/fallback; never inject it silently.

A git worktree protects repository state but does **not** sandbox the user's filesystem, credentials, environment variables, or network. Never claim worktree isolation alone makes broad permission bypass safe.

Avoid granting generic shell utilities merely to compensate for vague prompts. Prefer Antigravity native file tools for file reads/writes and allow shell commands primarily for Git and project validation.

## Empirical health check

The health check must verify the exact worker pattern used in production.

In a disposable Git repository/worktree it must prove that Antigravity can:

1. start headlessly;
2. receive the disposable repository's **absolute path** as `WORKSPACE ROOT`;
3. read the named file through its native file tool using the absolute path;
4. edit exactly that file using the absolute path;
5. execute `git -C <absolute-workspace-root> status --short` successfully;
6. emit structured output with no denied actions;
7. reach a terminal success result;
8. terminate within a finite timeout;
9. leave no unexpected changed/untracked files.

The included `scripts/doctor.sh` performs this test. Failure disables automated `GEMINI_RECON`, `GEMINI`, and `GEMINI_ARBITRATION` until the runtime/configuration changes and the doctor passes.

## Workspace isolation and invocation

For edit-capable Gemini work:

1. create/select the isolated worker worktree;
2. obtain its exact absolute path;
3. make that worktree the `agy` process cwd;
4. inject the same path into the prompt as `WORKSPACE ROOT`;
5. require native file tools to use absolute paths beneath it;
6. require Git commands to use `git -C <WORKSPACE ROOT> ...`;
7. invoke `agy` headlessly with finite timeout and machine-readable output;
8. reject the run if denied actions occur, required commands do not execute, or out-of-scope paths/files are touched;
9. inspect the actual diff and independently verify it;
10. return Claude orchestration to the primary repository afterward.

Canonical shape after health verification:

```bash
WORKSPACE=/absolute/path/to/isolated-worktree
cd "$WORKSPACE"
agy \
  --model <verified-model-id> \
  --effort medium \
  --output-format stream-json \
  --print-timeout <finite-duration> \
  -p "$BOUNDED_CONTRACT"
```

The bounded contract itself must contain the absolute `WORKSPACE ROOT` and `git -C` rule. Do not add `--dangerously-skip-permissions` unless the adapter has been explicitly configured for that opt-in mode.

## GEMINI_RECON

Read-only semantic reconnaissance for large/cross-cutting/multimodal context.

Input:

```text
ROLE: GEMINI_RECON
OBJECTIVE: exact discovery question
WORKSPACE ROOT: /absolute/path/to/repository-or-worktree
AUTHORITATIVE CONTEXT: requirement/spec constraints known so far
HARD BOUNDARY: use absolute native-file paths beneath WORKSPACE ROOT; Git via git -C WORKSPACE ROOT; do not edit
NON-GOALS: do not redesign
OUTPUT: structured evidence packet with file/symbol citations
```

Required output:

```text
RELEVANT SUBSYSTEMS
CALL / DATA FLOW
PUBLIC INTERFACES
STATE / DATA OWNERSHIP
LIKELY AFFECTED FILES
EXISTING TEST COVERAGE
OBSERVED INVARIANTS
UNCERTAIN ASSUMPTIONS
EVIDENCE
```

Recon must not edit files. If it edits, reject the run.

## GEMINI implementation

Use only for a bounded approved unit with settled architecture. The contract in `delegation.md` is authoritative.

Antigravity may run RED → GREEN → VERIFY autonomously in one run only when the doctor has proven the absolute-workspace/native-file/`git -C` pattern and current permissions support the required project commands.

Every implementation contract must include:

```text
WORKSPACE ROOT: /absolute/path/to/isolated-worktree
HARD BOUNDARY:
- native file tools: absolute paths beneath WORKSPACE ROOT only
- Git: git -C WORKSPACE ROOT ...
- no external paths unless explicitly named
```

Prefer a structured terminal handoff containing at least:

```text
status
changed_files
red: command, result evidence, why the failure represents missing behavior
green: same focused command and result
verify: broader commands and results
residual_risk
```

Claude never accepts narration alone. Claude inspects the actual diff/scope and independently reruns authoritative verification.

Default retry budget: initial attempt + one targeted repair.

## GEMINI_ARBITRATION

Use only for high-consequence factual disagreements resolvable from repository/tool evidence.

Input:

```text
ROLE: GEMINI_ARBITRATION
WORKSPACE ROOT: /absolute/path/to/repository-or-worktree
REQUIREMENT: ...
CLAUDE CLAIM: ...
CODEX CLAIM: ...
QUESTION: exact factual issue to establish
HARD BOUNDARY: native file tools use absolute paths beneath WORKSPACE ROOT; Git via git -C WORKSPACE ROOT; read-only
INSTRUCTION: independently inspect the repository; do not vote by authority
```

Required output:

```text
VERDICT: SUPPORTED_CLAUDE | SUPPORTED_CODEX | INCONCLUSIVE
EVIDENCE: file/symbol references and concise reasoning
FALSE ASSUMPTIONS: if any
RESIDUAL UNCERTAINTY: if any
```

Claude verifies consequential evidence. `INCONCLUSIVE` is legitimate. Subjective architecture decisions are not arbitration tasks.

## Quota discipline

Google AI Pro provides Antigravity quota/allowance according to the user's current plan and settings. Do not silently enable paid overage. Quota availability may influence Gemini-vs-Codex selection only when both are technically suitable.
