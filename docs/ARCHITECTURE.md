# Architecture

Ruthless Architect separates **decision authority**, **independent review**, **execution**, and **acceptance**.

## Authority

Claude owns requirements and architecture. The user explicitly approves consequential design decisions.

## Independent plan review

Codex adversarial review is a mandatory gate after plan approval. It exists to challenge Claude's assumptions before implementation begins.

## Direct execution routing

Each implementation unit is classified by:

```text
context_volume
context_locality
reasoning_density
risk
blast_radius
architecture status
```

Then routed directly:

```text
mechanical -> DETERMINISTIC
narrow + bounded + low risk -> LOCAL
context-local + settled + low/medium risk -> CLAUDE_EXEC
broad/cross-file/context-heavy + settled -> GEMINI
reasoning-dense/high-consequence/security-sensitive -> CODEX
unsettled architecture -> STOP / return to planning
```

These are heuristics, not model rankings. Project-specific benchmark history may refine them.

## Acceptance

Claude inspects the actual aggregate diff and reruns authoritative validation. When Claude implemented a materially consequential unit itself, Phase 4 uses a fresh review context when available to reduce implementation anchoring.
