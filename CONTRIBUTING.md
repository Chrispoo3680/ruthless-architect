# Contributing

Ruthless Architect is a workflow/state-machine skill. A change that sounds smart but adds ambiguity can make the system worse.

## Principles

1. Prefer changes motivated by an observed, repeatable failure mode.
2. Keep `SKILL.md` concise enough to execute reliably; put runtime details and rationale in `references/`.
3. Do not invent CLI flags, model slugs, plugin commands, or harness capabilities.
4. Preserve user-owned Git state. Never “simplify” safety rules by assuming the working tree is disposable.
5. Treat model output as claims until supported by repository/tool/test evidence.
6. Avoid adding another mandatory model pass merely for consensus.

## Before opening a PR

Run:

```bash
make check
./scripts/doctor.sh
```

Warnings from optional adapters are acceptable when those adapters are intentionally unavailable. Syntax or package-structure failures are not.

If the change modifies workflow policy, add the motivating failure and hardening response to:

```text
references/hardening-history.md
```

If it changes user-visible behavior, update `CHANGELOG.md`.

## Pull requests

Explain:

- the observed failure or concrete goal;
- why the current policy is insufficient;
- the smallest rule change that fixes it;
- new failure modes introduced by the proposal;
- how you tested it.
