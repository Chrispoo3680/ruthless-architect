# Changelog

All notable changes to Ruthless Architect are recorded here.

## [Unreleased]

### Changed

- Codex routing moved to GPT-6.1 Sol: `gpt-6.1-sol --effort high` for ordinary work, `gpt-6.1-sol --effort xhigh` for difficult work, and `gpt-6.1-sol`/`xhigh` as the recommended adversarial-review config. Retained approval-gated Astra escalation and documented the remaining scientific/security benchmark gaps.
- Added dated official benchmark/model sources, distinguished API pricing from subscription quota, and preserved effort policy without claiming benchmark proof of optimal review effort.
- Added GPT-6 Sol as the availability fallback before the existing GPT-5.6 routes, subject to task suitability and disclosure.
- Documented GPT-6.1 Sol's supported efforts and the plugin's `xhigh` ceiling; added the recommended review configuration to the setup guide.

### Fixed

- Quoted the skill description so its embedded colon parses as valid YAML frontmatter.

## [1.4.0] - 2026-09-24

### Added

- `CLAUDE_EXEC` as a first-class implementation route for context-local, settled, low/medium-risk work.
- `context_locality` as an implementation-routing dimension.
- `references/claude-runtime.md` with direct-execution, TDD, workspace, self-repair, and fresh-context-review rules.
- GitHub-ready repository files, installer/uninstaller scripts, CI, issue templates, contributing/security guidance, and version metadata.

### Changed

- Removed the old bias to delegate merely to conserve Claude quota.
- Routing now considers total orchestration/context duplication when Claude, Gemini, and Codex are all technically suitable.
- Phase 4 is explicitly a fresh-context review when Claude implemented a materially consequential unit.
- Added a two-focused-correction circuit breaker for `CLAUDE_EXEC`.

### Preserved

- Mandatory Codex adversarial plan review.
- Gemini absolute-workspace + `git -C` runtime contract and empirical health check.
- LOCAL fail-closed adapter requirement.
- Worktree-first autonomous-edit isolation and finite validation requirements.

## [1.3.0] - 2026-09-20

- Anchored Antigravity tasks to an explicit absolute `WORKSPACE ROOT`.
- Required native Gemini file tools to use absolute workspace paths and Git to use `git -C`.
- Hardened doctor to reject denied actions and misleading terminal `SUCCESS` results.

## [1.2.0] - 2026-09-14

- Added empirical Antigravity edit/shell health testing, structured output, timeouts, and permission fallback rules.

## [1.1.0] - 2026-09-13

- Added Gemini recon, implementation, and evidence-arbitration roles plus direct multi-model routing.

## [1.0.0] - 2026-09-13

- Initial hardened multi-model release with explicit planning approval, mandatory Codex adversarial plan review, bounded implementation routing, worktree isolation, and Claude-owned final verification.
