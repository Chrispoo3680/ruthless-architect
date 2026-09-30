# Codex runtime contract

Read this reference immediately before Phase 2 or when invoking Codex implementation work.

## Adversarial review

`/codex:adversarial-review` is `disable-model-invocation: true`. The Skill tool cannot run it. The user must run it manually; this is a human-in-the-loop gate, not an inconvenience to route around.

The command reviews a **git diff**, not an arbitrary filepath. The approved plan/spec must be committed and the review scoped with `--base <ref>`. Treat this as a mechanically verified precondition, not a reminder: inspect status, stage only the intended artifacts, inspect the staged diff, commit them, then verify that `git diff <base>...HEAD -- <spec> <plan>` (or the repository's equivalent) contains the current approved artifacts before composing the review command. An empty or stale diff cannot clear the gate.

Never use broad staging such as `git add .` merely to satisfy this gate when unrelated work may be present. Target the approved spec/plan paths explicitly. Preserve pre-existing staged work: do not run `git reset`, `git restore --staged`, or `git stash` merely to clear the index. Inspect the staged diff for the spec/plan paths specifically, then create a path-limited commit such as `git commit --only -- <spec> <plan>` (or a repository-equivalent safe mechanism) so unrelated staged entries remain staged and are not included in the review commit. Unless an explicit repository instruction or explicit user instruction prohibits agent-created commits, Claude creates the review commit itself; silence is not a prohibition and is not a reason to ask. If an explicit instruction prohibits agent-created commits, provide the exact targeted git commands to the user and stop until the committed state is verified.

The command accepts no `--model` or `--effort` flag. It uses the Codex CLI default. Read `~/.codex/config.toml` (`model` and `model_reasoning_effort`) and tell the user which routing the review will actually receive. Never append model/effort text as if it were a supported flag.

Recommended review configuration in `~/.codex/config.toml`:

```toml
model = "gpt-6.1-sol"
model_reasoning_effort = "xhigh"
```

GPT-6.1 Sol is the preferred default for Codex review and implementation when available to the account/client. If the configured model differs, report the actual routing rather than claiming the recommended one. Changing the config also changes the default for any `/codex:rescue` call without `--model`.

### Evidence for model selection (checked 2026-09-30)

- OpenAI reports that GPT-6.1 Sol matches Astra on DeepSWE v1.1 at roughly one-fifth the task cost and exceeds GPT-6 Sol's best score by 6.4 percentage points at lower reasoning effort. This supports upgrading the coding default. Astra still leads on Terminal-Bench Science 0.1 at maximum effort (68.1%) and is recommended for the most difficult scientific research tasks. [Launch benchmarks](https://openai.com/index/introducing-gpt-6-1-sol/)
- Astra retains a lead on security evaluations: SEC-Bench Pro pass@1 is 85.4% for Astra, 78.8% for GPT-6.1 Sol, and 66.3% for GPT-6 Sol. This supports retaining Astra as an option for especially difficult security work. [System card addendum](https://deploymentsafety.openai.com/gpt-6-1-sol/exploitbench---internal-port-juneaugust-2026)
- GPT-6.1 Sol Standard API input/output prices are $2/$10 per million tokens, versus Astra's $10/$50. API prices and benchmark task costs do not establish a fixed ChatGPT subscription quota ratio. [Sol model documentation](https://developers.openai.com/api/docs/models/gpt-6.1-sol) · [Astra model documentation](https://developers.openai.com/api/docs/models/gpt-6-astra)

These are provider evaluations in the stated harnesses, not measurements of this skill's adversarial plan review. The `high` implementation and `xhigh` difficult-work/review settings below preserve the existing workflow policy; the published results do not establish an optimal effort for every unit. Use actual project outcomes to refine effort. [Codex model guidance](https://learn.chatgpt.com/docs/models) recommends GPT-6.1 Sol for complex coding when available.

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

- ordinary feature work, CRUD, UI, normal integrations: `--model gpt-6.1-sol --effort high`
- difficult algorithms, concurrency/state, system-level logic, broad integration risk: `--model gpt-6.1-sol --effort xhigh`

`gpt-6-astra` remains an explicit escalation. Offer it (`--model gpt-6-astra --effort medium`) only when the user approves the extra quota spend and either a GPT-6.1 Sol unit has used up its repair budget without exposing a design defect, or the unit is unusually reasoning-dense and high-risk, especially difficult scientific or security work. Maximum-effort benchmark results do not predict Astra's performance at `medium`; choose a higher supported effort only with task-specific justification and approval of the extra spend. `gpt-6-luna` remains intended for focused, repeatable work such as extraction and summarization; it is not a default Ruthless Architect implementation route.

If `gpt-6.1-sol` is unavailable to the account/client, report that limitation and use the prior `gpt-6-sol` route at the same effort only if it is available and still suitable for the unit. If GPT-6 Sol is also unavailable, retain the existing GPT-5.6 fallbacks (`gpt-5.6-terra` for ordinary work, `gpt-5.6-sol` for difficult work) at the same supported effort and tell the user. A fallback is not a claim of equivalent capability; recheck task fit before dispatch. For adversarial review, inspect the actual CLI configuration and report any fallback before composing the user-run command.

GPT-6.1 Sol supports `low`, `medium`, `high`, `xhigh`, and `max`; it does not support `none` or `minimal`. The installed plugin's `--effort` flag accepts only `none`, `minimal`, `low`, `medium`, `high`, and `xhigh`, so the usable GPT-6.1 Sol efforts through `/codex:rescue` are `low`, `medium`, `high`, and `xhigh`. Never pass `max` or `ultra` through this plugin, or `none`/`minimal` to GPT-6.1 Sol. [Supported model efforts](https://developers.openai.com/api/docs/models/gpt-6.1-sol)

If the installed Codex CLI/plugin has changed, inspect its current help/source/config and use a supported replacement rather than guessing. Exact runtime truth beats this reference.

Invocation pattern:

```text
/codex:rescue --model <valid-model> --effort <effort> <bounded worker contract>
```

For behavioral work requiring TDD, do not treat `/codex:rescue` narration or reported command output as proof of RED/GREEN. Claude-owned validation commands must be finite and non-interactive: use documented one-shot/CI modes rather than watch mode, dev servers, interactive UIs, or commands waiting for input. Prefer tool-specific terminating flags over blindly setting `CI=true`. The orchestrator owns verification: first dispatch a test-only unit with `ALLOWED SCOPE` restricted to exact test files plus strictly required named test fixtures/helpers, inspect that diff and reject unauthorized production changes, run the focused test itself to prove RED, then dispatch implementation and rerun the same test to prove GREEN before broader verification.

For each Codex execution unit, the initial implementation dispatch may be followed by at most two targeted repair dispatches. After the second failed repair, stop the unit; do not keep invoking `/codex:rescue`. Preserve the failed state and diff/error evidence in the isolated worker worktree when available; never automatically stash or clean unrelated developer state. Return to planning if the failure exposes a design defect, otherwise report the blocked unit.

## Plugin loading

Plugin commands register at process start. If a newly installed/updated command is missing, use `/reload-plugins` or restart Claude Code. Do not reach for a substitute workflow merely because the process has stale plugin registration.
