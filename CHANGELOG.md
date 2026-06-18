# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

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
