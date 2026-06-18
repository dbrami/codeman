#!/usr/bin/env bash
# Tests for the de-identified flow-metrics script.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
command -v python3 >/dev/null 2>&1 || { echo "python3 required"; exit 64; }

# --help must work offline (no gh/git/network)
python3 "$ROOT/scripts/flow-metrics.py" --help >/dev/null 2>&1
assert_exit_code 0 $? "flow-metrics --help works offline"

# no identifying tokens in the scripts dir
"$ROOT/scripts/security-scan.sh" --tree "$ROOT/scripts" --quiet
assert_exit_code 0 $? "scripts dir clean of identifying tokens"

pass "flow-metrics"
