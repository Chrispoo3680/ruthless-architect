# Hardening history and observed failure modes

Read this only when maintaining, debugging, or regression-testing the skill. It is historical rationale, not normal execution context.

## Why the gates are explicit

Baseline testing showed that agents routinely rationalized away planning/approval under time pressure and wrote code before the user-approved plan existed. Later testing showed that merely requiring brainstorming was insufficient: agents compressed the pass or treated "use your defaults" as equivalent to user participation. The current Phase 1 wording exists to prevent these observed shortcuts.

Observed rationalizations included:

- "For a small/quick change the planning overhead costs more than it saves."
- "I'm not going to spec this out — just building."
- "The user is in a hurry, so I'll decide defaults and let them veto afterward."
- "I'll implement it myself; delegating is slower."
- "I'll compress brainstorming to a few questions."
- "I'll take 'use your defaults' as approval."

The skill is intentionally scoped to substantial/high-risk work so this rigor is not imposed on routine fixes.

## Why Phase 2 is user-run

A live run established that `/codex:adversarial-review` is `disable-model-invocation: true`. The agent then attempted to reproduce the reserved workflow through `codex exec` and the plugin companion script. That circumvention is now explicitly prohibited.

The same live run also established that the review operates on a git diff: an uncommitted/unscoped plan can yield a meaningless review. The plan/spec therefore must be committed and reviewed against `--base` with explicit focus text stating that the diff is a plan, not implementation code.

## Why reviewer findings are verified

A reviewer can be confidently wrong. Revising a correct plan to satisfy a false finding is worse than rejecting the finding. Phase 2 therefore requires verification against cited repository/package/API evidence before the plan changes.

## Why retries are capped

Repeated agent repair loops consume large contexts and often signal bad decomposition rather than insufficient persistence. Codex plan review is capped at two passes before splitting the feature. Local implementation is capped at two attempts before frontier escalation.

## Regression history from the original skill

Original notes recorded:

- RED baseline: Phase 1 approval gate breached in 4/4 runs; Phase 4 evidence gate held in 4/4.
- GREEN with skill: Phase 1 gate held and execution was delegated, but agents compressed Phase 1.
- Hardening added anti-compression and anti-default-bypass rules; subsequent runs completed the full brainstorming pass.
- A later live run exposed the blocked adversarial-review invocation and workaround behavior, leading to the explicit user-run Phase 2 and anti-circumvention rules.

When the workflow, tools, or gates change materially, rerun representative RED/GREEN scenarios and update this file with observed failures rather than hypothetical prose.

## 2026-09 Gemini / Antigravity expansion

The workflow was expanded only after verifying a local, non-interactive Antigravity surface (`agy -p`) that can operate on local files. Earlier proposals to use a Gemini API managed agent were rejected because that would introduce separate API billing and a remote sandbox that does not share local git-worktree state.

Hardening decisions:

- Gemini is a direct execution peer, not a mandatory middle rung between LOCAL and CODEX.
- Routing is based on context volume, reasoning density, risk, blast radius, settled architecture, quota availability among suitable peers, and project history.
- Formal local-model reconnaissance was removed. Mechanical discovery belongs to deterministic tools; broad semantic/context-heavy reconnaissance belongs to configured Gemini.
- Gemini factual arbitration is evidence discovery, never majority voting. Subjective architecture choices remain Claude/user decisions.
- Antigravity autonomous TDD is permitted only when the runtime contract verifies local cwd, non-interactive permissions, terminating commands, and observable validation evidence. Claude still performs final verification.
- No Gemini API/SDK/remote-agent fallback is allowed without explicit user approval.

## 2026-09 Antigravity headless-permission hardening

A review correctly identified that headless permission behavior is an operational failure point, but incorrectly claimed `always-proceed` was fabricated and that `--dangerously-skip-permissions` was mandatory. Current official Antigravity docs expose fine-grained `permissions.allow`, `toolPermission: always-proceed`, structured headless output, finite print timeouts, and the broad dangerous bypass.

Hardening decision:

- do not trust settings text alone; Gemini execution is enabled only after a disposable absolute-workspace native read/edit + `git -C` + structured-result health test succeeds;
- prefer fine-grained allow rules, then broader persistent policy only when justified;
- `--dangerously-skip-permissions` is explicit opt-in only and never silently injected by the skill;
- worktree isolation is not treated as a full OS/security sandbox;
- use structured headless output and finite `--print-timeout`;
- failed or non-terminal Antigravity runs disable Gemini routing rather than triggering improvised commands.


## 2026-09 Absolute-workspace Antigravity hardening

Empirical testing exposed two distinct Antigravity behaviors. Relative/vague workspace prompts caused native file tools to guess paths under `~/.gemini/antigravity-cli`, `$HOME`, or `/`, even though the init event reported the intended cwd. A subsequent test that supplied the exact absolute repository root succeeded: `view_file` and `write_to_file` operated on the correct file, and the remaining denial was isolated to a compound shell command. Replacing `cd <repo> && git ...` with `git -C <repo> ...` produced a clean run under the configured `command(git)` permission.

Hardening decisions:

- process cwd is necessary but not sufficient for Gemini; every Gemini contract receives an explicit absolute `WORKSPACE ROOT`;
- native file tools must use absolute paths beneath that root;
- Git commands must use `git -C <workspace-root> ...` instead of relying on shell `cd`;
- the Gemini doctor reproduces this exact pattern and requires no denied actions;
- Antigravity terminal `status: SUCCESS` never counts as success by itself because earlier runs reported SUCCESS despite denied actions and incomplete work;
- broad permission bypass is not required for the proven pattern and remains opt-in only.


## v1.4 — Claude execution route after stronger Claude / higher limits

Observed pressure: earlier versions treated Claude mainly as architect/orchestrator because quota conservation strongly favored delegation. With stronger Claude coding capability and higher usage limits, that bias can create unnecessary handoff/context duplication for units Claude already understands.

Hardening response:

- add `CLAUDE_EXEC` as a direct route for context-local, settled, low/medium-risk implementation;
- add `context_locality` to routing;
- prohibit delegating merely to conserve Claude quota;
- retain Codex as the mandatory independent plan adversary;
- require fresh-context review when Claude implemented materially consequential units;
- add a two-focused-correction circuit breaker so stronger Claude does not become an excuse for infinite self-repair.
