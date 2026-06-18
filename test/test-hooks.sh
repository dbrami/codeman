#!/usr/bin/env bash
# Tests for the SessionStart/Stop hooks and their registration.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
command -v jq >/dev/null 2>&1 || { echo "jq required"; exit 64; }

H="$ROOT/hooks/hooks.json"
jq -e . "$H" >/dev/null 2>&1;            assert_exit_code 0 $? "hooks.json valid JSON"
jq -e '.hooks.SessionStart' "$H" >/dev/null 2>&1; assert_exit_code 0 $? "SessionStart registered"
jq -e '.hooks.Stop' "$H" >/dev/null 2>&1;         assert_exit_code 0 $? "Stop registered"

# daily-recap runs cleanly in a fresh repo
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
( cd "$tmp" && git init -q && bash "$ROOT/hooks/daily-recap.sh" >/dev/null 2>&1 )
assert_exit_code 0 $? "daily-recap runs in a fresh repo"

# hooks contain no identifying tokens
"$ROOT/scripts/security-scan.sh" --tree "$ROOT/hooks" --quiet
assert_exit_code 0 $? "hooks contain no identifying tokens"

pass "hooks"
