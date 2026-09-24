# Codex runtime contract

Read this reference immediately before Phase 2 or when invoking Codex implementation work.

## Adversarial review

`/codex:adversarial-review` is `disable-model-invocation: true`. The Skill tool cannot run it. The user must run it manually; this is a human-in-the-loop gate, not an inconvenience to route around.

The command reviews a **git diff**, not an arbitrary filepath. The approved plan/spec must be committed and the review scoped with `--base <ref>`. Treat this as a mechanically verified precondition, not a reminder: inspect status, stage only the intended artifacts, inspect the staged diff, commit them, then verify that `git diff <base>...HEAD -- <spec> <plan>` (or the repository's equivalent) contains the current approved artifacts before composing the review command. An empty or stale diff cannot clear the gate.

Never use broad staging such as `git add .` merely to satisfy this gate when unrelated work may be present. Target the approved spec/plan paths explicitly. Preserve pre-existing staged work: do not run `git reset`, `git restore --staged`, or `git stash` merely to clear the index. Inspect the staged diff for the spec/plan paths specifically, then create a path-limited commit such as `git commit --only -- <spec> <plan>` (or a repository-equivalent safe mechanism) so unrelated staged entries remain staged and are not included in the review commit. Unless an explicit repository instruction or explicit user instruction prohibits agent-created commits, Claude creates the review commit itself; silence is not a prohibition and is not a reason to ask. If an explicit instruction prohibits agent-created commits, provide the exact targeted git commands to the user and stop until the committed state is verified.

The command accepts no `--model` or `--effort` flag. It uses the Codex CLI default. Read `~/.codex/config.toml` (`model` and `model_reasoning_effort`) and tell the user which routing the review will actually receive. Never append model/effort text as if it were a supported flag.

A suitable command must include:

- `--background` unless the user prefers `--wait`;
- `--base <ref>` for the committed spec/plan diff;
- focus text that the diff is a **SPEC AND IMPLEMENTATION PLAN, NOT CODE**;
- instructions to act as a ruthless senior auditor;
- `file:line` evidence for repository claims;
- `BLOCKING` / `NON-BLOCKING` classification and an explicit statement when there are no findings.

Do not substitute `codex exec`, the plugin companion script, `/codex:rescue`, the Codex rescue agent, or a subagent. If the command is unavailable, tell the user and stop.

## Rescue

## Execution workspace safety

For edit-capable `/codex:rescue` work, use an isolated git worktree or equivalent isolated repository workspace whenever the repository supports it. Treat the user's active working tree as developer-owned state, not a disposable agent sandbox. Before invoking `/codex:rescue`, make the assigned isolated worktree the invocation's current working directory and verify the path; after the invocation returns, restore Claude's orchestration context to the primary repository/workspace before unrelated work. The invocation pattern below has no path flag, so cwd is part of the safety contract.

If Codex must operate in a shared worktree, capture a pre-dispatch git baseline before every edit-capable invocation (`git status --porcelain`, unstaged diff, staged diff, and relevant untracked paths). If Codex modifies unauthorized files, do not use whole-file `git restore` / `git checkout`, automatic `git stash`, or improvised line surgery when those operations could destroy or hide pre-existing user changes. Use the baseline to isolate the worker delta; if safe recovery is not mechanically clear, stop and report the state.


`/codex:rescue` is model-invocable and accepts `--model` and `--effort`. Model slugs and effort values are separate; never invent a combined slug such as `<model>-ultra`.

Preferred routing while these installed slugs remain valid:

- ordinary feature work, CRUD, UI, normal integrations: `--model gpt-5.6-terra --effort high`
- difficult algorithms, concurrency/state, system-level logic, broad integration risk: `--model gpt-5.6-sol --effort medium`

If the installed Codex CLI/plugin has changed, inspect its current help/source/config and use a supported replacement rather than guessing. Exact runtime truth beats this reference.

Invocation pattern:

```text
/codex:rescue --model <valid-model> --effort <effort> <bounded worker contract>
```

For behavioral work requiring TDD, do not treat `/codex:rescue` narration or reported command output as proof of RED/GREEN. Claude-owned validation commands must be finite and non-interactive: use documented one-shot/CI modes rather than watch mode, dev servers, interactive UIs, or commands waiting for input. Prefer tool-specific terminating flags over blindly setting `CI=true`. The orchestrator owns verification: first dispatch a test-only unit with `ALLOWED SCOPE` restricted to exact test files plus strictly required named test fixtures/helpers, inspect that diff and reject unauthorized production changes, run the focused test itself to prove RED, then dispatch implementation and rerun the same test to prove GREEN before broader verification.

For each Codex execution unit, the initial implementation dispatch may be followed by at most two targeted repair dispatches. After the second failed repair, stop the unit; do not keep invoking `/codex:rescue`. Preserve the failed state and diff/error evidence in the isolated worker worktree when available; never automatically stash or clean unrelated developer state. Return to planning if the failure exposes a design defect, otherwise report the blocked unit.

## Plugin loading

Plugin commands register at process start. If a newly installed/updated command is missing, use `/reload-plugins` or restart Claude Code. Do not reach for a substitute workflow merely because the process has stale plugin registration.
