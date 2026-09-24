# Ruthless Architect v1.4 — setup guide

This guide installs the skill and its runtime dependencies on a Linux/WSL-oriented development setup. Commands should be run from the same Linux environment where Claude Code will operate on your repositories.

## 0. What the workflow depends on

Required for the full workflow:

- Git with worktree support.
- Claude Code.
- The `ruthless-architect` skill package.
- `superpowers:brainstorming`, `superpowers:writing-plans`, and preferably `superpowers:requesting-code-review` in Claude Code.
- Your existing Codex integration exposing `/codex:adversarial-review` and `/codex:rescue`.
- Google Antigravity CLI (`agy`) for Gemini roles.
- Ollama + OpenCode for the recommended local-worker adapter.

The skill remains usable if Gemini or LOCAL is temporarily unavailable, but Phase 2 Codex review and Claude final verification are mandatory.

---

## 1. Install the Claude Code skill

Claude Code supports personal skills at:

```text
~/.claude/skills/<skill-name>/SKILL.md
```

If you cloned the GitHub repository, the recommended development install is a symlink so skill updates are immediate:

```bash
cd /path/to/ruthless-architect
./scripts/install.sh
```

For an independent copied installation instead:

```bash
./scripts/install.sh --copy
```

Manual copying is also valid:

```bash
mkdir -p ~/.claude/skills
rm -rf ~/.claude/skills/ruthless-architect
cp -a /path/to/ruthless-architect ~/.claude/skills/ruthless-architect
```

Expected layout:

```text
~/.claude/skills/ruthless-architect/
├── SKILL.md
├── SETUP.md
├── references/
│   ├── claude-runtime.md
│   ├── codex-runtime.md
│   ├── delegation.md
│   ├── gemini-runtime.md
│   ├── hardening-history.md
│   └── local-worker.md
└── scripts/
    └── doctor.sh
```

Claude Code detects skill changes live when the skills directory was already present at session start. If this is the first skill directory in the session, restart Claude Code.

Verify in Claude Code:

```text
/ruthless-architect
```

Do not use it for small fixes; its description intentionally scopes it to substantial/high-risk features.

---

## 2. Verify the Superpowers dependencies

Inside Claude Code, verify that these existing skills/plugin commands are available:

```text
/superpowers:brainstorming
/superpowers:writing-plans
/superpowers:requesting-code-review
```

If your Superpowers installation uses different names, update `SKILL.md` before using Ruthless Architect. Do not let Claude silently substitute a different planning workflow.

---

## 3. Verify the Codex integration

The skill assumes your existing Claude Code Codex integration provides:

```text
/codex:adversarial-review
/codex:rescue
```

`/codex:adversarial-review` is intentionally user-run. `/codex:rescue` is model-invocable.

Check your Codex CLI configuration:

```bash
cat ~/.codex/config.toml
```

The runtime reference expects the review command to use the defaults from that file because the adversarial-review command does not accept invented model/effort flags.

After installing/updating the Codex plugin, restart Claude Code or use its plugin reload mechanism if the commands do not appear.

Do a dry verification in a disposable repository before the first real feature: ensure the review command accepts `--base <ref>` and the rescue command's installed help matches `references/codex-runtime.md`. If the plugin changes, update the reference rather than guessing.

---

## 4. Install and authenticate Google Antigravity CLI

Official Linux/macOS install:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy --version
```

First-time setup is interactive:

```bash
agy
```

Choose Google OAuth, sign in with the Google account that receives the Google AI Pro family benefit, accept the terms, and trust a disposable/test workspace first.

Verify models and non-interactive mode:

```bash
agy models
agy --help
mkdir -p ~/tmp/agy-smoke
cd ~/tmp/agy-smoke
agy -p "Reply with exactly: ANTIGRAVITY_OK"
```

If that works, the non-interactive surface is available.

### Antigravity permissions and empirical worker health

Headless mode has no interactive approval prompt. Antigravity supports both fine-grained permission rules and broader global permission presets. Prefer the narrowest policy that lets the bounded worker complete its required repository operations.

The preferred order is:

1. configure fine-grained `permissions.allow` rules for only the Git/project commands and workspace writes the worker needs;
2. if fine-grained rules are impractical, consider the documented `toolPermission: "always-proceed"` preset, understanding that it is broader;
3. use `--dangerously-skip-permissions` only as an explicit per-run fallback that you deliberately opt into after testing it in a disposable environment. It is **not** the skill default.

Current settings live at:

```text
~/.gemini/antigravity-cli/settings.json
```

The CLI also exposes `/permissions` for managing fine-grained rules interactively. Example rule shapes supported by the current permission engine include scoped command and workspace-write allowances. Do not blindly copy a permission list between projects; allow only the finite commands your project actually needs.

For the proven Gemini health pattern, `command(git)` is the essential shell permission because file inspection/editing uses Antigravity's native file tools and Git is invoked as `git -C <workspace-root> ...`. Add project commands such as `command(npm)`, `command(npx)`, `command(pnpm)`, `command(pytest)`, etc. only when the actual project validation requires them. Avoid granting `cat`, `find`, or broad `command(*)` merely to compensate for vague worker prompts.

A git worktree protects repository state, but it is **not** a security sandbox for your home directory, credentials, environment variables, or network. Therefore, do not treat `--dangerously-skip-permissions` as safe merely because the worker runs in a worktree. Do **not** make `--sandbox` part of the canonical Gemini worker invocation unless a separate project-specific test proves it preserves the required repository/worktree semantics; empirical testing showed sandbox mode can change the tool execution context in ways that break Git discovery.

Most importantly, **do not trust configuration text alone**. After configuring permissions, run the included empirical doctor:

```bash
~/.claude/skills/ruthless-architect/scripts/doctor.sh
```

When `agy` is installed, the doctor creates a disposable temporary Git repository and verifies the exact production pattern:

- inject the repository's **absolute path** as `WORKSPACE ROOT`;
- read the expected file with a native file tool using its absolute path;
- edit exactly that file using its absolute path;
- run exactly `git -C <workspace-root> status --short`;
- produce machine-readable output with no denied actions;
- reach a terminal success result;
- terminate within a fixed timeout;
- avoid unexpected edits.

If that test fails, `GEMINI`, `GEMINI_RECON`, and `GEMINI_ARBITRATION` must be treated as unavailable regardless of what `settings.json` says.

If you intentionally want to test the broad permission bypass after the normal policy fails, run:

```bash
~/.claude/skills/ruthless-architect/scripts/doctor.sh --gemini-dangerous-fallback
```

That flag is only a disposable diagnostic. If it is the only mode that works and you decide to use it for real workers, record that decision explicitly in `references/gemini-runtime.md`; never let Claude silently add the bypass flag.

### Structured Antigravity output

The current headless CLI supports machine-readable output and finite execution ceilings. Verify the installed flags with `agy --help`, then prefer:

```bash
WORKSPACE=/absolute/path/to/isolated-worktree
cd "$WORKSPACE"
agy \
  --model <verified-model-id> \
  --effort medium \
  --output-format stream-json \
  --print-timeout 15m \
  -p "<bounded worker contract containing the exact WORKSPACE ROOT>"
```

For contracts where a fixed final handoff is valuable, also use `--json-schema` with a checked-in or generated schema. `stream-json` is particularly useful for worker runs because tool calls and the terminal result can be observed rather than inferred from prose.

### Prevent unintended paid overage

Google AI Pro provides baseline Antigravity quota and can optionally consume AI credits after baseline quota is exhausted. In Antigravity Settings/Models, set overage behavior to **Never** if you want a hard stop instead of credit spending.

### Optional manual Antigravity edit test

The doctor already performs the proven disposable absolute-workspace test. If you reproduce it manually, give Antigravity the exact absolute repository path, require native file reads/writes to use absolute paths under it, and use `git -C <absolute-workspace> ...` for Git. Do not rely on relative-path inference or `cd <workspace> && git ...`, and do not test broad permission bypasses in a real project first.

### Worktree trust caveat

Antigravity normally asks whether you trust a new workspace. A newly created git worktree may therefore require a one-time interactive trust approval before `agy -p` can operate there unattended. For your first real feature, after Claude creates the Gemini worker worktree, if the first non-interactive smoke check reports a trust problem:

```bash
cd <that-exact-gemini-worktree>
agy
```

Approve that workspace, then quit and rerun the non-interactive worker. Do not solve this by globally disabling workspace trust.

### Model policy

Do not copy a model slug from this guide. Run:

```bash
agy models
```

`references/gemini-runtime.md` uses role policy rather than fixed slugs: low/medium for recon, medium/high for implementation/arbitration when the corresponding installed variants exist.

---

## 5. Install Ollama for the local worker

Official Linux install:

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama -v
```

If the service is not already running:

```bash
ollama serve
```

or use your systemd service.

Verify NVIDIA visibility and Ollama:

```bash
nvidia-smi
curl http://localhost:11434/api/tags
```

Choose a coding-capable local model that fits your actual hardware and supports the context you need. Do not encode a model in the skill until you have benchmarked it. OpenCode/Ollama currently recommend at least a 64k context window for repository work.

Pull/run the model using the exact current Ollama model identifier you choose, then confirm it responds before integrating it with OpenCode.

---

## 6. Install OpenCode as the local autonomous harness

Install on Linux/macOS:

```bash
curl -fsSL https://opencode.ai/install | bash
opencode --version
```

Configure Ollama support using the supported integration:

```bash
ollama launch opencode --config
```

or configure the Ollama provider in `~/.config/opencode/opencode.json` using your local endpoint (`http://localhost:11434/v1`) and exact model id.

Verify:

```bash
opencode models
opencode run --help
```

The important capability is **non-interactive `opencode run`**, not the OpenCode TUI.

### Disposable local-worker test

Create another disposable repo/worktree and run something like:

```bash
cd ~/tmp/local-worker-test
opencode run --model <EXACT_PROVIDER/MODEL_FROM_opencode_models> \
  'Modify only sample.txt so it contains hello local. Do not touch any other file.'
```

Then inspect:

```bash
git status --short
git diff
```

Test whether the local harness can run your project's actual finite test commands and return usable evidence. If it cannot, that is okay: the skill will use Claude-owned split TDD for LOCAL.

### Enable LOCAL in the skill

Edit:

```text
~/.claude/skills/ruthless-architect/references/local-worker.md
```

Fill the exact model/invocation/health-check fields and change:

```yaml
enabled: false
```

to:

```yaml
enabled: true
```

only after the disposable test succeeds.

Do not configure `LOCAL` as raw `ollama run`; the adapter must be an autonomous coding harness able to read/edit the assigned worktree.

---

## 7. Git/worktree prerequisites

Verify:

```bash
git --version
git worktree list
```

For a manual smoke test:

```bash
cd /path/to/a/disposable/repo
git worktree add ../repo-worker-test -b worker-test
cd ../repo-worker-test
pwd
git status
```

Remove it afterward from the primary repo:

```bash
cd /path/to/a/disposable/repo
git worktree remove ../repo-worker-test
git branch -D worker-test
```

The skill requires every edit-capable autonomous worker to execute from the isolated worktree. For Codex/local workers, verified cwd remains the primary workspace binding. For Gemini, cwd alone is **not sufficient**: the bounded contract must also contain the exact absolute `WORKSPACE ROOT`; native file tools must use absolute paths beneath it; and Git commands must use `git -C <workspace-root> ...`.

---

## 8. Run the dependency doctor

From the installed skill:

```bash
~/.claude/skills/ruthless-architect/scripts/doctor.sh
```

It checks the presence/reachability of Git, Claude Code, Antigravity, Ollama, OpenCode, and common runtime config files. When `agy` is installed, it also runs the disposable empirical Antigravity absolute-workspace read/edit + `git -C` + structured-result worker test described above. Warnings are expected while optional adapters are not configured.

It cannot prove that Claude Code slash commands such as `/codex:rescue` or `/superpowers:brainstorming` are registered; verify those inside Claude Code.

---

## 9. First end-to-end test

Do not make the first run a production feature. Use a small disposable repository but invoke the full workflow.

Suggested test feature: add a tiny persistent preference with one API endpoint and tests, large enough to require a spec but small enough to inspect manually.

Expected sequence:

```text
/ruthless-architect
Phase 0: usually skip or Gemini recon smoke test
Phase 1: Claude requirements/spec/plan
YOU explicitly approve
Phase 2: plan/spec committed + you run Codex adversarial review
Phase 3: Claude classifies units and routes directly
  mechanical -> deterministic
  narrow bounded -> local
  context-local + settled + low/medium risk -> Claude
  broad/context-heavy -> Gemini
  dense/high-risk -> Codex
Phase 4: Claude independently reviews actual diff and reruns verification
```

Watch specifically for these regressions:

- implementation starts before your approval;
- Codex review is bypassed because it is inconvenient;
- Claude invents a worker command;
- a worker edits the primary dirty tree instead of an isolated worktree;
- `agy -p` reports `SUCCESS` despite non-empty `denied_actions`;
- Gemini uses relative paths or guesses paths outside the supplied absolute `WORKSPACE ROOT`;
- Gemini uses `cd <workspace> && git ...` instead of `git -C <workspace> ...`;
- local worker is used while `enabled: false`;
- Claude/Gemini/Codex is chosen merely by quota despite being a poor fit;
- Claude delegates a context-local unit only to conserve quota even though the handoff duplicates most of its current context;
- Claude self-repairs the same defect repeatedly instead of stopping after the circuit breaker;
- Gemini arbitration is treated as a vote;
- final verification trusts worker narration instead of rerunning commands.

---

## 10. Recommended steady-state configuration

Keep these properties:

```text
Claude: architecture, routing, context-local implementation, escalation, final acceptance
Codex: mandatory plan adversary + reasoning-dense/high-risk implementation
Gemini/Antigravity: large-context recon + broad implementation + factual arbitration
Local/Ollama/OpenCode: narrow low-risk implementation
Deterministic tools: mechanical discovery/transforms
User: explicit design approval + subjective consequential tie-breaks
```

Do not optimize this further until actual usage produces a repeatable failure mode. Record real failures in `references/hardening-history.md` and change one rule at a time.
