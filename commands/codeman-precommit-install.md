---
description: Install codeman's critical-path pre-commit guard into the current git repo.
---

Install the critical-path guard as this repo's pre-commit hook and seed its config.

```bash
set -e
test -d .git || { echo "Not a git repo"; exit 1; }
mkdir -p .codeman
if [ ! -f .codeman/critical-paths.txt ]; then
  cat > .codeman/critical-paths.txt <<'EOF'
# One path substring per line. Files whose staged path contains a line below
# trigger a gitnexus-impact checklist reminder before commit. '#' = comment.
# Examples:
# payments/
# auth/
# migrations/
EOF
fi
chmod +x "${CLAUDE_PLUGIN_ROOT}/scripts/critical-path-precommit.sh"
ln -sf "${CLAUDE_PLUGIN_ROOT}/scripts/critical-path-precommit.sh" .git/hooks/pre-commit
echo "Installed. Edit .codeman/critical-paths.txt to define your critical paths."
```

Set `CODEMAN_PRECOMMIT_BLOCK=1` in the environment to make the guard block
commits instead of only warning.
