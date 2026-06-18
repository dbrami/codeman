#!/usr/bin/env bash
# Tests for the pre-commit security gate template.
# The leak fixture is built at runtime with a split prefix so this source file
# stays scan-clean.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
home='/Users/'

(
  cd "$tmp" && git init -q
  printf '%sx/Projects/leak\n' "$home" > bad.txt
  git add bad.txt
  bash "$ROOT/scripts/security-review-precommit.sh" >/dev/null 2>&1
)
assert_exit_code 1 $? "precommit blocks a staged leak"

# A clean staged file passes
(
  cd "$tmp" && git rm -q --cached bad.txt && rm -f bad.txt
  echo "just generic code" > ok.txt && git add ok.txt
  bash "$ROOT/scripts/security-review-precommit.sh" >/dev/null 2>&1
)
assert_exit_code 0 $? "precommit allows clean staged content"

pass "security-review"
