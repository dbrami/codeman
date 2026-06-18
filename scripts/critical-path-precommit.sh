#!/usr/bin/env bash
# Critical-path pre-commit guard.
# Warns when staged changes touch files matching user-defined critical paths,
# reminding you to run gitnexus impact analysis before committing.
# Patterns come from .codeman/critical-paths.txt (substring match, # comments).
# Non-blocking by default; set CODEMAN_PRECOMMIT_BLOCK=1 to block the commit.
#
# Install:  /codeman-precommit-install
#   (or: ln -sf <plugin>/scripts/critical-path-precommit.sh .git/hooks/pre-commit)
set -euo pipefail
BLOCK=${CODEMAN_PRECOMMIT_BLOCK:-0}
CFG=".codeman/critical-paths.txt"

[ -f "$CFG" ] || exit 0
staged_files=$(git diff --cached --name-only 2>/dev/null || true)
[ -z "$staged_files" ] && exit 0

# Portable read loop (avoid `mapfile`, which is bash 4+ only; macOS ships 3.2).
patterns=()
while IFS= read -r line; do
  patterns+=("$line")
done < <(grep -vE '^[[:space:]]*(#|$)' "$CFG" || true)
[ "${#patterns[@]}" -eq 0 ] && exit 0

critical=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  for p in "${patterns[@]}"; do
    if [[ "$f" == *"$p"* ]]; then critical+=("$f"); break; fi
  done
done <<< "$staged_files"

[ "${#critical[@]}" -eq 0 ] && exit 0

echo ""
echo "CRITICAL-PATH FILES IN STAGED CHANGES"
echo "====================================="
printf '  %s\n' "${critical[@]}"
echo ""
echo "Pre-commit checklist:"
echo "  [ ] gitnexus_impact was run for all modified symbols"
echo "  [ ] No HIGH/CRITICAL risk dependents left unupdated"
echo "  [ ] Blast radius reported and acknowledged"
echo "  [ ] gitnexus_detect_changes confirms scope matches intent"
echo ""
echo "Re-index after commit: npx gitnexus analyze"
echo ""
if [ "$BLOCK" = "1" ]; then
  echo "Commit blocked (CODEMAN_PRECOMMIT_BLOCK=1). Bypass: git commit --no-verify"
  exit 1
fi
exit 0
