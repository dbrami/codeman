# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-06-18

### Added
- `/codeman-setup` now verifies **all** prerequisites (git, rg, jq, node, npm,
  python3, gh, curl), grouped by the feature that needs them.
- `bootstrap.sh --install-deps` installs missing prerequisites via the detected
  package manager (brew/apt/dnf/yum); without it, the exact install command is
  shown per missing tool (codeman never installs system packages unasked).

## [0.1.0] - 2026-06-18

### Added
- Initial release: Claude Code plugin + self-marketplace (`dbrami/codeman`).
- Skills: `evidence-driven-debugging`, `session-handover`.
- Hooks: `daily-recap` (SessionStart), `commit-hygiene` (Stop).
- Commands: `codeman-setup`, `codeman-kb-init`, `codeman-precommit-install`,
  `codeman-security-review`, `codeman-flow-metrics`.
- Scripts: `security-scan` gate, `bootstrap` (gitnexus from git + roborev via
  official installer), gitnexus MCP launcher, `kb-init`, critical-path
  pre-commit guard, pre-commit security gate, `flow-metrics`.
- Knowledgebase templates and a generic de-identification denylist.
