# Delegation contract

Read this reference for Phase 3 and any delegated implementation/recon/arbitration.

## Capability prerequisites

`CLAUDE_EXEC`, `LOCAL`, `GEMINI`, and `CODEX` are real execution capabilities, not labels to improvise. `CLAUDE_EXEC` uses the current Claude Code session; the others require their runtime contracts.

Before selecting one:

1. Read its runtime reference.
2. Confirm the adapter is explicitly configured, callable, and healthy.
3. Confirm workspace/cwd, tool permissions, model/runtime, validation behavior, retry budget, and any harness-specific workspace-anchor requirements.
4. If unavailable, do not invent a substitute command. Reclassify only among executors already suitable for the task.

Runtime references:

- `references/claude-runtime.md`
- `references/local-worker.md`
- `references/gemini-runtime.md`
- `references/codex-runtime.md`

## Classification before routing

Classify every implementation unit on these axes:

```text
context_volume: small | medium | large
context_locality: low | medium | high
reasoning_density: low | medium | high
risk: low | medium | high
blast_radius: narrow | moderate | broad
architecture: settled | unsettled
```

`architecture: unsettled` is not an execution route. Stop and return to Claude planning.

## Routing heuristics

These are defaults, not claims that one frontier model is universally smarter.

### DETERMINISTIC

Prefer repository/tooling when the operation is mechanical and reliably verifiable:

- exact search/replace or language-aware rename;
- formatting;
- existing generators/codemods;
- `git` inspection;
- `rg`/grep/LSP/symbol lookup;
- compiler/type-checker/linter/static-analysis feedback;
- AST/tool-driven transforms.

Do not spend LLM quota to infer facts deterministic tools can establish.


### CLAUDE_EXEC

Use Claude directly when the implementation is already well represented in the current Claude context and delegation would mostly duplicate context rather than add independent capability. Prefer it when all apply:

- architecture and behavior are settled;
- `context_locality` is high: Claude already holds the relevant design/repository state;
- risk is low or medium;
- blast radius is narrow or moderate;
- the work is not primarily valuable because of an independent second model;
- direct implementation is cheaper in orchestration/context than constructing and reviewing a worker handoff.

Good candidates: glue code after planning, small-to-medium cross-file changes tightly coupled to the just-approved design, fixes found during final review, and implementation where the handoff would largely restate what Claude already knows.

Do not use `CLAUDE_EXEC` merely because Claude quota is available. High-consequence/security-sensitive/reasoning-dense work should still route to the executor best suited to it, and broad repository rediscovery may still favor Gemini.

### LOCAL

Use a configured local worker for **narrow, bounded, low-risk implementation** when all apply:

- behavior and architecture are settled;
- scope fits named files/components or a tight change surface;
- acceptance criteria and validation are exact;
- failure is reliably detectable;
- no material security, authorization, cryptography, risky migration, distributed-state, concurrency, or broad public-API risk;
- context fits the configured local model/harness comfortably.

Good candidates: DTOs/types, ordinary CRUD, serialization/mapping, boilerplate, repetitive call-site changes, straightforward tests, bounded refactors with fixed semantics.

Do not create a formal repository-wide local reconnaissance role. Mechanical discovery is deterministic; broad semantic discovery is `GEMINI_RECON` when configured.

### GEMINI

Use configured Antigravity/Gemini when the architecture is settled and the task benefits from **broad repository context, cross-file execution, or large change surface**, including:

- broad multi-file features;
- framework or API migrations with fixed target semantics;
- large refactors where many files must be understood together;
- frontend/UI work where multimodal context materially helps;
- repository-wide semantic reconnaissance (`GEMINI_RECON`);
- evidence arbitration (`GEMINI_ARBITRATION`).

Gemini is a frontier peer, not merely a fallback between LOCAL and CODEX. When both Gemini and Codex are suitable, quota availability and historical project performance may choose between them.

### CODEX

Use Codex by default for work that is **reasoning-dense or high-consequence**, especially:

- subtle algorithms/performance tradeoffs;
- concurrency, distributed state, state machines/lifecycles;
- security/authorization boundaries;
- risky migrations/data-loss hazards;
- ambiguous root-cause debugging;
- isolated but correctness-dense logic;
- work where a cheaper worker's correctness cannot be bounded confidently.

Codex also remains the mandatory Phase 2 adversarial plan reviewer.

## Quota-aware choice

Quota is a tie-breaker, not a safety classifier.

1. Determine which executors are technically suitable.
2. If exactly one is suitable, use it regardless of quota pressure.
3. If Claude, Gemini, and/or Codex are all suitable, prefer the option with the lowest total orchestration cost and healthier quota, unless project benchmark/history strongly favors one.
4. Higher Claude limits are not a reason to hoard work inside Claude; they simply remove the old bias to delegate context-local work for quota conservation.
5. Never route high-risk work to LOCAL merely because frontier quota is low.

## Workspace isolation

Delegated autonomous edits are **worktree-first**.

When supported:

1. create/select an isolated git worktree or equivalent workspace;
2. make it the worker process's current working directory;
3. verify the path before invocation;
4. for Gemini, also pass that exact absolute path as `WORKSPACE ROOT`; require native file tools to use absolute paths beneath it and Git commands to use `git -C <workspace-root> ...`;
5. run the worker there;
6. inspect diff/status there;
7. restore Claude orchestration to the primary repository afterward.

If shared-tree execution is unavoidable, capture before every edit-capable dispatch:

```text
git status --porcelain
unstaged diff
staged diff
relevant untracked paths
```

Never use broad `git restore`, `git checkout`, automatic `git stash`, or improvised line surgery when those operations could overwrite/hide pre-existing developer work. If safe isolation of worker changes is unclear, stop and report the recovery state.

## Claude direct-execution contract

`CLAUDE_EXEC` does not need a worker prompt, but Claude must still make the unit explicit before editing:

```text
OBJECTIVE
ALLOWED SCOPE
REQUIREMENTS
NON-GOALS
FOCUSED TEST / RED CONDITION
BROADER VERIFY
```

If those fields cannot be stated clearly, the unit is not ready for direct implementation.

## Bounded worker contract

Every implementation worker receives:

```text
OBJECTIVE
Exact approved behavior to implement.

WORKSPACE ROOT
Absolute isolated-worktree path. Required for Gemini. Native file tools must use absolute paths beneath it; Git commands must use `git -C <workspace-root> ...`.

AUTHORITATIVE CONTEXT
Relevant approved spec/plan sections and only necessary context.

ALLOWED SCOPE
Exact files/components the worker may modify. Scope expansion requires escalation.

REQUIREMENTS
Concrete behavior, compatibility, state/security/migration requirements that apply.

NON-GOALS
Things not to redesign, refactor, or "improve."

VALIDATION
Exact focused and broader commands. All must be finite and non-interactive.

SUCCESS CRITERIA
Observable conditions that must hold.

HANDOFF
STATUS: PASS | FAIL | NEEDS_ESCALATION
CHANGED FILES: ...
VALIDATION: exact commands + observable results
ASSUMPTIONS: only material assumptions
UNRESOLVED: remaining concerns
DIFF/COMMIT: reference to resulting change
```

Do not request or forward long reasoning transcripts.

## TDD / verification by harness

### Claude (`CLAUDE_EXEC`)

Claude performs the observable loop directly:

1. establish the focused test or deterministic failing condition;
2. run it and prove RED for the intended missing behavior;
3. implement only the approved unit;
4. rerun the same check and prove GREEN;
5. run broader VERIFY;
6. record exact commands/results for Phase 4.

If the same defect survives two focused correction attempts without genuinely new evidence, stop and reclassify the unit or return to planning.

### Codex

For behavioral `/codex:rescue` work, Claude owns state transitions:

1. TEST-ONLY dispatch, restricted to exact tests plus strictly required named fixtures/helpers.
2. Claude inspects diff; unauthorized production/out-of-scope edits reject the dispatch.
3. Claude runs exact focused test and proves a valid RED caused by missing behavior.
4. IMPLEMENTATION dispatch.
5. Claude reruns the same focused test and proves GREEN.
6. Claude runs broader VERIFY.

Codex narration or reported console output is not RED/GREEN proof.

### Gemini / Antigravity

Antigravity may execute RED → GREEN → VERIFY autonomously in one run **only if** `gemini-runtime.md` confirms:

- local shell execution is available;
- invocation cwd is the isolated worktree;
- the contract includes the exact absolute `WORKSPACE ROOT`;
- native file reads/writes are proven against absolute paths under that root;
- Git commands use `git -C <workspace-root> ...` rather than relying on `cd`;
- non-interactive tool permissions are configured **and empirically proven by the disposable absolute-workspace edit + `git -C` health check**;
- validation commands terminate;
- final handoff includes exact commands and observable outcomes.

Claude still inspects scope/diff and reruns authoritative validation independently before acceptance.

### Local worker

Internal RED → GREEN is allowed only if `local-worker.md` explicitly documents repository-command execution and machine-verifiable evidence. Otherwise use Claude-owned split orchestration.

## Validation discipline

Every RED/GREEN/VERIFY command must terminate and run non-interactively. Before use, determine whether a project command can enter watch mode, start a server/UI, or wait for input. Use documented one-shot/non-watch/CI forms. Prefer tool-specific flags over blindly setting `CI=true`.

## Retry / escalation

### CLAUDE_EXEC

- implement the approved unit directly;
- allow up to two focused correction attempts on the same defect when each attempt is grounded in concrete failure evidence;
- after that, stop and reclassify or return to planning instead of continuing self-repair.

### LOCAL

- initial attempt;
- at most one targeted repair using exact current failure evidence;
- after another failure, unexplained regression, uncertainty, or scope expansion: stop and reclassify the unit.

Do not automatically escalate to Gemini or Codex. Diagnose the failure and choose the executor whose capability matches the revealed problem.

### GEMINI

- initial attempt;
- at most one targeted repair;
- then stop and reclassify.

Do not let a long autonomous agent loop substitute for the external retry budget. Internal self-correction during one bounded Antigravity run is allowed, but the run must respect the contract and terminate.

### CODEX

- initial implementation dispatch;
- at most two targeted repair dispatches;
- rephrasing/broadening does not reset the counter;
- after the second failed repair, stop. Preserve failed diff/evidence in the isolated worktree, diagnose plan vs implementation failure, and return to planning if a material design change is required.

## Evidence arbitration

`GEMINI_ARBITRATION` is for concrete factual disputes, not voting.

Use it only when:

- the disagreement is consequential;
- it can be resolved from repository/tool evidence;
- the Gemini runtime is configured and healthy.

Gemini should independently explore the repository and return one of:

```text
SUPPORTED_CLAUDE
SUPPORTED_CODEX
INCONCLUSIVE
```

with file/symbol evidence. Claude verifies consequential evidence. Subjective architecture tradeoffs go to the user.
