# codeman — Design Spec

> Historical record. The project was renamed `codeman` → `destrier` in v0.4.0 (see CHANGELOG). This dated spec is preserved as written; names/commands below reflect the codeman era.

**Date:** 2026-06-18
**Status:** Approved (ready for implementation plan)

## 1. Goal

Package a personal, generic code-improvement toolkit into a single product that
is installable through Claude Code in one command and publishable publicly on
GitHub. The toolkit bundles the author's own assets (a debugging skill, a
session-handover skill, two git hooks, a knowledgebase workflow, and two
code-graph/metrics scripts) and bootstraps two external tools — **gitnexus** and
**roborev** — by pulling them from their upstream git repositories.

The product is generic: it contains nothing identifiable to any project the
author works on, in its files **or its git history**. It is published under MIT.

## 2. Non-goals

- **Not** repackaging or vendoring gitnexus or roborev. They are cloned and
  built from their own git repos at setup time, and their own skills are
  installed by their own installers — codeman never copies them.
- **Not** shipping any knowledgebase content, session notes, memories, or
  project-specific configuration. Only the reusable machinery and empty
  templates travel.
- **Not** a general document toolkit. Domain-specific, non-code, and personal
  assets present in the author's local setup are out of scope and excluded.

## 3. Delivery vehicle

A Claude Code **plugin + marketplace** in a single public repo (`dbrami/codeman`),
plus a **bootstrap script** for the external binaries a plugin cannot install.

Install path:

1. `/plugin marketplace add dbrami/codeman`
2. `/plugin install codeman`  — loads skills, hooks, slash commands, and the
   gitnexus MCP server registration.
3. `/codeman-setup` — runs `scripts/bootstrap.sh` to clone + build gitnexus and
   roborev from git and wire them in.

Rationale: the plugin system is the native single-command vehicle for skills +
hooks + slash commands + MCP. The bootstrap covers what a plugin cannot do
(install third-party binaries), and is invoked explicitly so install never
mutates the user's machine silently.

## 4. Repository layout

```
codeman/
├── .claude-plugin/
│   ├── plugin.json                 # plugin manifest (name, version, components)
│   └── marketplace.json            # makes the repo self-installable as a marketplace
├── .mcp.json                       # registers gitnexus MCP via launcher script
├── skills/
│   ├── evidence-driven-debugging/
│   │   └── SKILL.md                # author's skill, made self-contained
│   └── session-handover/
│       └── SKILL.md                # NEW: encodes the KB session protocol
├── commands/
│   ├── codeman-setup.md            # bootstrap external tools
│   ├── codeman-kb-init.md          # init a KB session in the current repo
│   ├── codeman-precommit-install.md# install the critical-path git hook
│   ├── codeman-security-review.md  # security review of pending changes
│   └── codeman-flow-metrics.md     # throughput / cycle-time report
├── hooks/
│   ├── hooks.json                  # Stop + SessionStart registration
│   ├── commit-hygiene.sh           # author's Stop hook (already generic)
│   └── daily-recap.sh              # author's SessionStart hook (genericized)
├── scripts/
│   ├── bootstrap.sh                # clone + build gitnexus & roborev from git
│   ├── gitnexus-mcp-launch.sh      # launcher the .mcp.json points at
│   ├── kb-init.sh                  # author's KB initializer (generic already)
│   ├── critical-path-precommit.sh  # author's critical-path guard, genericized
│   ├── security-review-precommit.sh# optional pre-commit security gate template
│   └── flow-metrics.py             # author's metrics script (de-identified)
├── templates/
│   ├── session-summary.md          # empty KB session template
│   ├── INDEX.md                    # empty KB index template
│   └── identifying-tokens.denylist # de-identification grep denylist (generic)
├── docs/
│   └── design/2026-06-18-codeman-design.md  # this file (de-identified)
├── README.md
├── LICENSE                         # MIT
└── .gitignore
```

## 5. Bundled components (author's originals, genericized)

### 5.1 Skill: `evidence-driven-debugging`
Carried over verbatim except: the line directing the agent to "invoke alongside
`systematic-debugging`" (a third-party skill not shipped by codeman) is reworded
to a soft, optional mention so the skill stands alone. Scan for and remove any
project-specific examples. Approved for public release by the author.

### 5.2 Skill: `session-handover` (new)
Encodes the knowledgebase handover protocol as a reusable skill: at session
start, read the last N session summaries; during work, append dated, model-
labeled deltas to `docs/knowledgebase/sessions/YYYY-MM-DD-summary.md`; at end,
update `docs/knowledgebase/INDEX.md`. It references `scripts/kb-init.sh` and the
`templates/`. Contains no project names or actual notes.

### 5.3 Hook: `commit-hygiene.sh` (Stop)
Already generic. Warns on unpushed commits about: CLAUDE.md not updated,
README.md not updated (when source changed), no version file bumped (when source
changed), and 4+ unpushed commits. Kept as-is.

### 5.4 Hook: `daily-recap.sh` (SessionStart)
Genericized: remove the hard-coded personal notes/memory directory block. Keep
the git recap (last-24h commits, uncommitted changes, unpushed counts) for the
current repo. An optional memory-reminder section is gated behind a
`CODEMAN_MEMORY_DIR` env var that is unset by default.

### 5.5 KB scripts + templates
`kb-init.sh` initializes a dated session-summary file under
`docs/knowledgebase/sessions/` and prints the last 3 summaries. Generic already;
keep. Ship empty `session-summary.md` and `INDEX.md` templates. No content.

### 5.6 Graph/metrics scripts
- `critical-path-precommit.sh`: the author's pre-commit guard, genericized. The
  hard-coded project-specific file patterns and domain-specific labels are
  removed. Patterns are read from a user-editable `.codeman/critical-paths.txt`
  in the target repo (ships with commented examples, empty by default). When
  staged files match a pattern, it prints a gitnexus-impact checklist reminder;
  blocking is opt-in via `CODEMAN_PRECOMMIT_BLOCK=1`.
- `flow-metrics.py`: weekly throughput and cycle-time metrics via `gh`. Strip the
  project-board naming; repos are passed as args/config. Logic unchanged.

## 6. External tools — pulled from git, never bundled

`scripts/bootstrap.sh` (invoked by `/codeman-setup`) installs into
`~/.codeman/vendor/`:

- **gitnexus** — `git clone https://github.com/abhigyanpatwari/GitNexus.git`
  into `~/.codeman/vendor/gitnexus` → `npm install` (runs its postinstall/build)
  → `npm run build`. Exposes `gitnexus` (CLI) and an MCP server via
  `gitnexus serve`. Requires Node + git; needs no Go.
- **roborev** — installed via its **official installer**,
  `curl -fsSL https://roborev.io/install.sh | bash`, which downloads a prebuilt
  release binary (no Go toolchain or build step required — works for most users
  with no heavy dependencies). The bootstrap then runs `roborev init` and
  `roborev skills install` so roborev installs its own skills. codeman does not
  vendor or repackage roborev; it invokes roborev's own installer.

The bootstrap is idempotent (re-running updates the gitnexus clone via
`git pull` and re-runs the roborev installer, which is itself idempotent),
detects missing prerequisites (git, Node for gitnexus; a network connection for
the roborev installer) and degrades gracefully with a clear message and the
upstream install instructions rather than failing hard. A documented fallback
(`npm install -g gitnexus`) is noted in the README for users who prefer the
packaged gitnexus release over a source build.

## 7. MCP wiring

`.mcp.json` registers a single MCP server, `gitnexus`, whose command is
`${CLAUDE_PLUGIN_ROOT}/scripts/gitnexus-mcp-launch.sh`. The launcher resolves the
built gitnexus under `~/.codeman/vendor/gitnexus` (overridable via
`CODEMAN_GITNEXUS_DIR`) and execs its MCP serve entrypoint. If gitnexus is not
yet bootstrapped, the launcher exits with a message telling the user to run
`/codeman-setup`, so a missing dependency produces a readable error instead of a
crash loop.

## 8. Slash commands

- `/codeman-setup` — run the bootstrap.
- `/codeman-kb-init` — run `kb-init.sh` in the current repo.
- `/codeman-precommit-install` — symlink `critical-path-precommit.sh` as the
  current repo's `.git/hooks/pre-commit` and seed `.codeman/critical-paths.txt`.
- `/codeman-security-review` — run a security review of pending changes (see §10).
- `/codeman-flow-metrics` — run `flow-metrics.py` against the current repo (or
  args).

## 9. Privacy / de-identification

| Asset | Action |
|---|---|
| Personal bookmark-sync hook | Dropped entirely (personal feeds + keyword lists). |
| `daily-recap.sh` | Remove hard-coded personal notes/memory directory; memory section opt-in via `CODEMAN_MEMORY_DIR`. |
| `critical-path-precommit.sh` | Remove project-specific patterns + domain labels; patterns from user-editable config. |
| `flow-metrics.py` | Remove project-board naming; repos via args/config. |
| KB | Templates only; zero summaries, INDEX content, or memories. |
| This spec + all docs | Written generically — no project names, internal paths, domain terms, or claim references. |
| Everywhere (files + git history) | No project names, internal paths, or domain references. |

## 10. Development workflow: security review before every commit

Per requirement, **no commit is made until a security review of the pending
changes passes.** This applies to every commit in the codeman repo, and most
critically gates the first public push.

The review is a two-part gate:

1. **De-identification scan (always):** grep the entire pending tree against
   `templates/identifying-tokens.denylist` (a generic, configurable denylist of
   patterns that would identify the author's projects: internal paths, project
   codenames, domain-specific regulatory/claim terms). Zero matches required.
   Also scan for secrets (API keys, tokens, private keys, `.env` contents).
2. **Vulnerability review (for code/scripts):** review the pending diff for
   shell-injection, unsafe `eval`, unquoted expansions, path traversal, insecure
   `curl | bash` of unpinned sources, and unsafe handling of cloned third-party
   code. Use the available `security-review` capability; once codeman has
   bootstrapped roborev, prefer `roborev review --type security` and surface its
   findings.

If either part finds an issue, the commit is blocked, the issue is remediated,
and the gate re-runs. codeman ships this as a reusable capability:
`/codeman-security-review` (manual) and `scripts/security-review-precommit.sh`
(an opt-in `.git/hooks/pre-commit` template, installable per repo). For codeman's
own development the gate is run by the maintainer/agent before each commit.

## 11. License

MIT.

## 12. Acceptance criteria

1. `/plugin marketplace add dbrami/codeman` + `/plugin install codeman` loads the
   skills, hooks, and slash commands with no errors.
2. `/codeman-setup` builds gitnexus from its git repo into `~/.codeman/vendor/`
   and installs roborev via its official installer; on a machine missing Node
   (gitnexus) or network access (roborev) it prints a clear, actionable message
   instead of crashing.
3. The gitnexus MCP server starts via the launcher once bootstrapped, and prints
   a "run /codeman-setup" message when not.
4. `daily-recap.sh` and `commit-hygiene.sh` run with no reference to any personal
   or project-specific path.
5. `critical-path-precommit.sh` reads patterns from `.codeman/critical-paths.txt`
   and contains no project-specific patterns.
6. The security-review gate (§10) runs before every commit; a full-tree scan
   against the denylist and a secret scan return zero matches before any push.
7. `/codeman-security-review` runs and reports findings (denylist + vulnerability
   review), preferring roborev's security review when available.
8. `README.md` documents install, setup, and each command, generically.
