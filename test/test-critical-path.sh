#!/usr/bin/env bash
# Tests for the critical-path pre-commit guard.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
SC="$ROOT/scripts/critical-path-precommit.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

(
  cd "$tmp" && git init -q
  mkdir -p .codeman && printf 'payments/\n' > .codeman/critical-paths.txt
  mkdir -p payments && echo "x" > payments/charge.js
  git add payments/charge.js
  bash "$SC" 2>&1 > out.txt
)
out="$(cat "$tmp/out.txt")"
assert_contains "$out" "CRITICAL-PATH" "warns on matching staged file"
assert_contains "$out" "gitnexus" "reminds about gitnexus impact"

# No project-specific patterns embedded in the scripts dir
"$ROOT/scripts/security-scan.sh" --tree "$ROOT/scripts" --quiet
assert_exit_code 0 $? "scripts dir clean of identifying tokens"

pass "critical-path"
