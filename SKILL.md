---
name: ruthless-architect
description: Use for substantial new features or high-risk changes that justify a gated lifecycle: optional Gemini reconnaissance, Claude requirements/design, explicit user approval, mandatory Codex adversarial plan review, direct implementation routing across deterministic tools/local/Claude/Gemini/Codex, and Claude-owned final acceptance. Do not use for routine fixes, tiny tweaks, or obviously mechanical changes.
---

# Ruthless Architect

A gated workflow for substantial feature development. Optimize for **frontier-model usage per accepted, high-quality change**, not for making every model participate.

Claude owns requirements, architecture, routing, escalation, and final acceptance, and may implement directly when it already holds the relevant context and delegation would mostly duplicate that context. Codex provides mandatory independent adversarial plan review and reasoning-dense/high-risk implementation. Gemini/Antigravity provides optional large-context reconnaissance, broad/context-heavy implementation, and evidence-based arbitration when configured. A configured local worker handles narrow, well-specified, low-risk implementation. Deterministic tools establish mechanical facts whenever possible.

## Core invariants

1. Run mandatory phases in order. No implementation before explicit user approval and the mandatory Codex plan-review gate clears.
2. Human approval is explicit. Never infer it from urgency, silence, sunk cost, or “use your defaults.”
3. Independent review stays independent. Final acceptance is based on the actual diff and verification evidence, not worker summaries.
4. Route each unit directly to the executor that is safest and most efficient for the task shape and current context. Claude itself is a valid executor when context locality is high. Do not delegate merely to conserve Claude quota, and do not force units through a LOCAL → GEMINI → CODEX ladder.
5. Budget/quota pressure may influence selection only among executors already suitable for the unit. It never weakens correctness standards or mandatory gates.
6. Prefer repository evidence, deterministic tools, `git diff`, tests, builds, type checks, linters, logs, and documented APIs over model claims.
7. A worker may not silently expand scope or make an unsettled architecture/product decision.
8. Avoid over-engineering. Implement only the approved behavior and what correctness requires.

## Required paths

Save approved artifacts only here:

- Spec: `docs/superpowers/specs/YYYY-MM-DD-<feature-name>-design.md`
- Plan: `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

Never save them in the repository root.

## Phase 0 — Reconnaissance (optional)

**Trigger:** before or during Phase 1, only when repository discovery is large, cross-cutting, multimodal, or would otherwise consume substantial Claude context.

1. Use deterministic repository tools first for mechanical discovery: `git`, `rg`/grep, LSP/symbol lookup, compiler/type-checker/linter output, AST tooling, package manifests, and existing project scripts.
2. Do not create a formal local-model reconnaissance phase. `LOCAL` is an implementation capability, not a repository-wide semantic mapper.
3. If deterministic discovery is insufficient because the relevant context is broad or multimodal, read `references/gemini-runtime.md`.
4. Run `GEMINI_RECON` only when the Gemini adapter is explicitly configured and healthy. Never invent an Antigravity/Gemini invocation.
5. Give Gemini the problem/recon objective, approved-known constraints if any, and the **exact absolute workspace root**. Require native file tools to use absolute paths beneath that root and Git commands to use `git -C <workspace-root> ...`. Do not rely on Antigravity inferring the repository from process cwd alone.
6. Require a compact evidence packet:

```text
RELEVANT SUBSYSTEMS
CALL / DATA FLOW
PUBLIC INTERFACES
STATE / DATA OWNERSHIP
LIKELY AFFECTED FILES
EXISTING TEST COVERAGE
OBSERVED INVARIANTS
UNCERTAIN ASSUMPTIONS
EVIDENCE: file/symbol references for substantive claims
```

7. Treat recon output as evidence to verify, not architecture. Claude remains responsible for design.

**Exit:** Claude has enough evidence to conduct requirements/design without stuffing unnecessary repository context into the main conversation, or Phase 0 is transparently skipped.

## Phase 1 — Requirements and design (Claude)

**Trigger:** this skill is invoked for a substantial feature or high-risk change.

1. Invoke `superpowers:brainstorming` and run the full requirements-discovery pass.
2. Stay in planning mode. Do not write implementation code.
3. Resolve material uncertainty: behavior, invariants, data shapes, edge/failure cases, compatibility, migrations, concurrency/state, security boundaries, rollout/rollback, observability, and test strategy as applicable.
4. When meaningful choices exist, present alternatives, recommend one, and explain the tradeoff. Do not manufacture choices for trivial details.
5. You may propose defaults, but do not answer material product/design questions on the user's behalf just to move faster.
6. Draft the design spec. Then invoke `superpowers:writing-plans` and draft an implementation plan.
7. Make the plan executable: identify components/files where known, dependencies/order, behavior changes, validation per unit, migration/rollback where relevant, and explicit non-goals.
8. Show both artifacts to the user.
9. **STOP and request explicit approval.** Do not save or advance before approval.

**Exit:** after explicit approval, save the spec and plan at the required paths using today's date and a kebab-case feature name.

## Phase 2 — Independent Codex plan review (user-run gate)

**Trigger:** the user approved the current spec/plan.

Before this phase, read `references/codex-runtime.md`.

1. Prepare a dedicated reviewable git state **before** composing the review command:
   - inspect `git status`, repository instructions, and the current branch/base;
   - identify the exact approved spec and plan paths;
   - unless an explicit repository/user instruction prohibits agent-created commits, Claude **MUST** create the review commit itself. Silence means commit; do not ask merely because policy is silent;
   - preserve pre-existing staged work. Never run `git reset`, `git restore --staged`, or `git stash` merely to clear the staging area;
   - stage only the exact approved spec/plan paths;
   - inspect `git diff --cached -- <spec> <plan>`;
   - create the review commit with a path-limited commit such as `git commit --only -- <spec> <plan>` or repository-safe equivalent;
   - if agent-created commits are explicitly prohibited, give the user exact targeted commands and **STOP** until completion is reported;
   - verify the committed diff against the chosen base contains the current spec/plan. Empty/stale/wrong-base diffs cannot clear this gate.
2. Determine the Codex configuration `/codex:adversarial-review` will actually use and tell the user.
3. Compose the complete user-run `/codex:adversarial-review` command and **STOP**.
4. Scope it with `--base <ref>` and explicitly state the diff is a **SPEC AND IMPLEMENTATION PLAN, NOT IMPLEMENTATION CODE**.
5. Require a ruthless senior audit for logical gaps, wrong repository assumptions, security/data-loss risks, edge cases, migration/rollback failures, concurrency/state defects, missing validation, and unnecessary complexity. Findings must cite `file:line` where repository evidence is claimed and be `BLOCKING` or `NON-BLOCKING`.
6. Do not recreate the reserved review through `codex exec`, companion scripts, `/codex:rescue`, subagents, or equivalent workarounds.
7. Treat reviewer findings as hypotheses. Independently verify every `BLOCKING` finding and every consequential `NON-BLOCKING` finding that would change behavior, architecture, migration/rollback, public API, security boundary, or validation strategy. Do not spend expensive investigation on clearly editorial/style/docs-only findings.
8. Record accepted consequential findings and resolutions:

```text
| Finding | Classification | Verified evidence | Resolution | Status |
```

9. Rerun rules:
   - verified `BLOCKING` → revise, commit, rerun;
   - consequential verified `NON-BLOCKING` → revise, commit, rerun;
   - editorial/non-design `NON-BLOCKING` → fix if useful; no mandatory rerun.
10. Maximum **two Codex adversarial-review passes**. If blocking findings remain after pass two, stop, split the feature, update the plan/findings table, and request explicit user approval of the split plan.
11. Before every `/codex:adversarial-review` command, state briefly that the pass is expensive in Codex usage; repeat-pass warnings must say it is another expensive pass.

### Conditional Gemini evidence arbitration

If Phase 2 exposes a **high-consequence factual disagreement** between Claude and Codex that can be resolved from repository/tool evidence, optionally invoke `GEMINI_ARBITRATION` after reading `references/gemini-runtime.md`.

- Give Gemini the requirement, Claude's claim, Codex's claim, exact question, and repository/workspace access. Do not spoon-feed only Claude-selected evidence when independent discovery is valuable.
- Gemini must investigate independently and return `SUPPORTED_CLAUDE`, `SUPPORTED_CODEX`, or `INCONCLUSIVE`, with concrete file/symbol evidence.
- This is evidence arbitration, not voting. `INCONCLUSIVE` is valid.
- Do **not** use Gemini to decide subjective architectural preferences. If multiple materially different architectures remain defensible after review, present them to the user for the consequential decision.
- Claude verifies consequential arbitration evidence before revising the plan.

**Exit:** Codex review has no unresolved blocking findings, and design-changing findings have been resolved/re-reviewed as required.

## Phase 3 — Decompose and directly route implementation (Claude orchestrates)

**Trigger:** Phase 2 clears.

Read `references/delegation.md`, plus the runtime reference for any selected worker.

1. Split the approved plan into bounded execution units.
2. For each unit classify:

```text
context_volume: small | medium | large
context_locality: low | medium | high
reasoning_density: low | medium | high
risk: low | medium | high
blast_radius: narrow | moderate | broad
architecture: settled | unsettled
```

3. Route **directly**, using the routing heuristics in `references/delegation.md`:
   - `DETERMINISTIC`: mechanical, exactly verifiable operations;
   - `LOCAL`: narrow, well-specified, low-risk implementation with settled architecture;
   - `CLAUDE_EXEC`: context-local implementation when architecture is settled, Claude already holds the necessary reasoning state, risk is low/medium, and delegation would mostly restate context or create more orchestration cost than value;
   - `GEMINI`: broad/cross-file/context-heavy implementation with settled architecture, especially when large repository context must be rediscovered or when Gemini and Codex are both suitable and Gemini quota/project history makes it preferable;
   - `CODEX`: reasoning-dense/high-consequence/security-sensitive/algorithmically difficult implementation, or work whose correctness cannot be bounded confidently for cheaper/context-local execution;
   - `architecture: unsettled` → **STOP** and return to Claude planning; do not delegate the decision.
4. `CLAUDE_EXEC` uses the current Claude Code session and requires no external adapter. `LOCAL` and `GEMINI` are available only when their runtime references contain a configured adapter and the required empirical health check succeeds. For Gemini, a settings file or successful text-only `agy -p` call is insufficient: the disposable absolute-workspace read/edit + `git -C` + structured-result health test in `scripts/doctor.sh` must pass under the configured permission mode. Do not invent fallback commands. If unavailable, reroute only to another executor already suitable for the unit.
5. Give every worker a bounded contract: objective, authoritative context, allowed scope, requirements, non-goals, exact terminating validation, success criteria, and compact handoff.
6. **TDD/evidence policy is harness-specific:**
   - **Claude (`CLAUDE_EXEC`):** Claude owns the whole observable loop directly: establish the focused test, run it and prove RED, implement only the approved behavior, rerun the same test and prove GREEN, then run broader VERIFY. Record exact commands/results. If the same defect survives two focused correction attempts without genuinely new evidence, stop and reclassify or return to planning instead of thrashing.
   - **Codex:** retain Claude-owned split orchestration. TEST-ONLY dispatch → scope check → Claude proves RED → implementation dispatch → Claude proves GREEN → broader VERIFY. Executor narration is not evidence.
   - **Gemini/Antigravity:** a configured adapter may perform RED → GREEN → VERIFY autonomously in one run only if `references/gemini-runtime.md` and the empirical doctor prove local shell execution, an explicitly supplied absolute isolated-worktree root, correct absolute-path native file access, successful `git -C <workspace-root> ...` execution, non-interactive permission behavior, finite timeout, structured tool/result evidence, and clean scope. Prefer fine-grained permissions; never silently add `--dangerously-skip-permissions`. The handoff must include exact commands/results. Claude still inspects scope/diff and independently reruns authoritative verification.
   - **Local:** internal RED → GREEN is allowed only if `references/local-worker.md` explicitly guarantees command execution and machine-verifiable evidence; otherwise use Claude-owned split orchestration.
   - Tests are evidence, not the specification. Never hard-code to tests.
7. Every validation command must be finite and non-interactive. Use documented one-shot/CI modes instead of watch modes, dev servers, interactive UIs, or commands waiting indefinitely for input.
8. **Worktree-first isolation:** use an isolated git worktree/equivalent for delegated autonomous edits whenever supported. `CLAUDE_EXEC` is not a delegated worker, but when the active tree contains unrelated developer work or the feature already uses an isolated implementation worktree, Claude should edit in the isolated feature workspace too. Otherwise Claude may edit the active worktree only within approved scope while preserving all pre-existing developer state. Before invoking an edit-capable worker, make that workspace the worker process cwd and verify it. **For Gemini, cwd is necessary but not sufficient:** also inject the exact absolute worktree path as `WORKSPACE ROOT`, require native file tools to use absolute paths beneath it, and require Git commands to use `git -C <workspace-root> ...`. Afterward restore orchestration to the primary repository. If shared-tree execution is unavoidable, capture the pre-dispatch status/unstaged/staged/untracked baseline. Never whole-file restore/checkout or auto-stash files that may contain pre-existing user work.
9. Workers may not silently expand scope. New design decisions escalate to Claude.
10. Retry limits:
   - `CLAUDE_EXEC`: if the same implementation defect survives two focused correction attempts without new evidence, stop and reclassify the unit or return to planning. Do not keep self-repairing indefinitely.
   - `LOCAL`: initial attempt + at most one targeted repair; then stop and reclassify/escalate based on the actual failure.
   - `GEMINI`: initial attempt + at most one targeted repair; then stop and reclassify. Do not automatically send it to Codex unless Codex is actually suitable for the revealed problem.
   - `CODEX`: initial implementation + at most two targeted repairs; after the second failed repair, **STOP** the unit and diagnose plan vs implementation failure.
   - Rephrasing the same task does not reset counters.
11. Keep independent units' contexts isolated. Do not shuttle full worker transcripts between agents.
12. After every unit, inspect the actual diff and validation evidence before marking it complete.

**Exit:** every execution unit is implemented, required unit validation succeeds, and the aggregate working tree is ready for independent review.

## Phase 4 — Fresh-context final review and acceptance (Claude)

**Trigger:** implementation units are complete.

1. Read the approved spec, final plan, and findings-to-resolution table.
2. Inspect the aggregate `git diff` or exact feature commits. Review changed code, not worker summaries.
3. Verify implementation against behavior, non-goals, every plan unit, compatibility/migration/security/state requirements where applicable, and scope boundaries.
4. Inspect tests for meaningful regression detection. Reject test-specific hard-coding or workarounds that merely satisfy the suite.
5. Prefer `superpowers:requesting-code-review` when appropriate. If Claude implemented any materially consequential unit through `CLAUDE_EXEC`, use a fresh-context review path before acceptance when available (for example a dedicated review subagent or equivalent isolated review context) so the implementation narrative does not substitute for review.
6. Run authoritative verification yourself: relevant tests plus build/typecheck/lint/static analysis as applicable. Use narrow commands first, then project-level verification needed for confidence. Every command must terminate and run non-interactively.
7. If defects are found, reclassify and route the repair using Phase 3 rather than reflexively returning it to the original worker. Respect each worker's per-unit retry budget.
8. If a high-consequence **factual** correctness dispute remains and Gemini arbitration is configured, `GEMINI_ARBITRATION` may gather independent evidence. Subjective architectural deadlocks go to the user.
9. Do not claim completion when required verification is skipped, failing, flaky without explanation, or unavailable. State the limitation.

Final handoff:

```text
STATUS
Complete | Blocked | Complete with stated limitation

IMPLEMENTED
Concise feature summary.

VERIFICATION
Commands run and results.

REVIEW
Important defects caught/fixed, or "no unresolved findings."

RESIDUAL RISK
Only real remaining uncertainty; omit if none.
```

**Exit:** implementation matches the approved spec/plan, independent review finds no unresolved correctness issue, and required verification passes.

## Mandatory stop conditions

Stop instead of advancing when:

- the user has not explicitly approved Phase 1;
- the mandatory Codex adversarial review has not cleared;
- implementation requires a material decision the approved plan does not settle;
- a selected worker adapter is not explicitly configured/healthy and no other already-suitable executor is available;
- a worker needs to escape assigned scope;
- a worker exhausts its repair budget;
- blocking plan-review findings remain after the second Codex pass;
- required verification fails or cannot be run without a clearly stated limitation;
- implementation materially diverges from the approved design.

Urgency, sunk cost, budget pressure, blocked reserved commands, benchmark reputation, or worker confidence never override these conditions.

For observed failure modes and rationale, read `references/hardening-history.md` only when modifying/debugging this skill.

## Context and token discipline

- Pass workers the smallest authoritative context needed for the assigned role. `GEMINI_RECON`/arbitration may independently discover broad repository evidence when that is the purpose of the role.
- Preserve decisions, findings, evidence, commands/results, and unresolved questions; discard narration and full reasoning transcripts.
- Use deterministic tools before asking an LLM to infer mechanically discoverable facts.
- Do not ask multiple frontier models to solve the same easy problem merely for consensus.
- Quota-aware routing applies only after task suitability is established.

## Principle

Claude decides what must be true, may implement context-local settled work directly, and independently accepts the result using fresh-context review when it also implemented consequential units. The user approves consequential decisions. Codex attacks the plan and handles reasoning-dense/high-consequence implementation. Gemini absorbs large-context reconnaissance, broad/context-heavy implementation, and evidence arbitration when its local Antigravity adapter is configured. Local workers absorb narrow, well-specified, low-risk implementation. Deterministic tools establish mechanical facts.
