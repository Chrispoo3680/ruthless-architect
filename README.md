# Ruthless Architect

A Claude Code skill for substantial features and high-risk changes that need stronger planning, adversarial review, controlled multi-model execution, and evidence-based acceptance.

Ruthless Architect is deliberately **not** a general “ask every model” workflow. It routes each implementation unit to the executor that best fits the task shape and current context:

- **Deterministic tools** for mechanical discovery and transforms.
- **LOCAL** for narrow, well-specified, low-risk implementation when a local adapter is configured.
- **CLAUDE_EXEC** for context-local implementation when Claude already holds the relevant design/repository state and delegation would mostly duplicate context.
- **Gemini / Antigravity** for large-context reconnaissance, broad/cross-file implementation, and evidence arbitration when its local runtime passes health checks.
- **Codex** for mandatory adversarial plan review plus reasoning-dense/high-consequence implementation.

The user explicitly approves the design before implementation, and Claude owns final acceptance based on the actual diff and verification evidence.

## Why v1.4 adds `CLAUDE_EXEC`

Earlier versions biased strongly toward delegation to conserve Claude usage. With stronger Claude coding capability and higher usage limits, that can waste context by forcing Claude to restate work it already understands. v1.4 removes that quota-conservation bias: Claude may implement directly when context locality is high, risk is bounded, and delegation would cost more than it adds.

Codex remains the mandatory independent plan adversary. High-risk or reasoning-dense work is still routed by task fit, not by whichever model has spare quota.

## Workflow

```text
Optional Phase 0: deterministic discovery / Gemini recon
                    ↓
Phase 1: Claude requirements + design + implementation plan
                    ↓
              explicit user approval
                    ↓
Phase 2: mandatory Codex adversarial plan review
                    ↓
Phase 3: direct execution routing
   ┌──────────┬──────────┬─────────────┬──────────┬──────────┐
   │          │          │             │          │          │
   ▼          ▼          ▼             ▼          ▼          │
DETERMINISTIC LOCAL  CLAUDE_EXEC     GEMINI     CODEX       │
   │          │          │             │          │          │
   └──────────┴──────────┴─────────────┴──────────┴──────────┘
                    ↓
Phase 4: fresh-context Claude review + authoritative verification
```

## Repository layout

```text
.
├── SKILL.md
├── SETUP.md
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── VERSION
├── references/
│   ├── claude-runtime.md
│   ├── codex-runtime.md
│   ├── delegation.md
│   ├── gemini-runtime.md
│   ├── hardening-history.md
│   └── local-worker.md
├── scripts/
│   ├── doctor.sh
│   ├── install.sh
│   └── uninstall.sh
└── .github/
    ├── ISSUE_TEMPLATE/
    ├── pull_request_template.md
    └── workflows/ci.yml
```

## Install

Clone this repository, then either symlink it into Claude Code:

```bash
git clone <your-repo-url> ~/git/ruthless-architect
cd ~/git/ruthless-architect
./scripts/install.sh
```

or copy it instead:

```bash
./scripts/install.sh --copy
```

Claude Code personal skills live at:

```text
~/.claude/skills/ruthless-architect/
```

Then run:

```bash
~/.claude/skills/ruthless-architect/scripts/doctor.sh
```

See [SETUP.md](SETUP.md) for the full Codex, Antigravity, Ollama, OpenCode, permissions, worktree, and smoke-test setup.

## Runtime status

The skill is fail-closed:

- `CLAUDE_EXEC` uses the current Claude Code session and needs no external adapter.
- `GEMINI` is available only when the empirical Antigravity worker-health test passes.
- `LOCAL` is available only when `references/local-worker.md` is explicitly configured and healthy.
- Codex review remains mandatory for Ruthless Architect workflows.

Never infer that a model/harness is available from its reputation or installation alone.

## Safety model

Key invariants include:

- no implementation before explicit user approval and Codex plan review;
- no silent architecture decisions by workers;
- worktree-first isolation for autonomous edit workers;
- Antigravity receives an absolute `WORKSPACE ROOT` and uses `git -C <workspace>`;
- no broad reset/restore/stash that could destroy developer work;
- finite, non-interactive validation commands;
- bounded repair loops;
- worker narration never substitutes for tests/diffs/tool evidence;
- Antigravity `status: SUCCESS` is insufficient if actions were denied or expected edits/validation did not happen.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Changes to workflow policy should be motivated by a concrete observed failure mode whenever possible and recorded in `references/hardening-history.md`.

## License

No open-source license is selected in this repository template. See [LICENSE](LICENSE) before publishing publicly and replace it with the license you actually want.
