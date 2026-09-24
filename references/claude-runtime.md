# Claude runtime contract

Read this reference before routing a unit to `CLAUDE_EXEC`.

## Purpose

`CLAUDE_EXEC` exists for **context-local implementation**: work where Claude already owns the relevant requirements/design/repository state and delegating would mostly duplicate context and add orchestration overhead. It is not a claim that Claude should implement everything.

The current Claude Code model is runtime truth. Prefer the strongest Claude model available for Ruthless Architect when practical, but do not hard-code a model slug into `SKILL.md`; model availability and plan limits change over time.

## Suitability

Use `CLAUDE_EXEC` when:

- architecture is settled;
- risk is low/medium;
- blast radius is narrow/moderate;
- context locality is high;
- Claude already has the relevant implementation context;
- delegation would require restating most of that context;
- independent-model execution is not itself part of the risk control.

Do not use it for high-consequence security boundaries, subtle concurrency/distributed-state work, difficult algorithms, or other units whose main value comes from an independent specialist executor.

## TDD / verification

Claude owns the full observable loop:

```text
focused test/check -> prove RED
implement approved behavior
same focused test/check -> prove GREEN
broader VERIFY
```

Record exact commands and results. Do not treat reasoning or narration as evidence. All validation must be finite and non-interactive.

## Workspace safety

`CLAUDE_EXEC` is not a delegated worker. Claude may edit the active worktree when it is safe to do so, but it must preserve all pre-existing developer state and remain within the approved scope.

Prefer an isolated feature worktree when:

- the active tree contains unrelated developer changes;
- other autonomous workers are using worktrees for the same feature;
- recovery/inspection would be clearer in isolation.

Never run broad reset/restore/stash operations merely to make Claude's own implementation easier.

## Self-repair circuit breaker

If the same implementation defect survives two focused correction attempts without genuinely new evidence, stop. Reclassify the unit, gather new evidence, or return to planning. Do not let Claude's stronger model or higher usage limits justify indefinite self-repair.

## Fresh-context review requirement

When `CLAUDE_EXEC` produced a materially consequential unit, Phase 4 should use a fresh review context when available (for example `superpowers:requesting-code-review`, a dedicated review subagent, or another isolated review mechanism) before acceptance. The reviewer should receive the approved spec/plan and actual diff, not the implementation narration.
