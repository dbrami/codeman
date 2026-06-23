#!/usr/bin/env bash
# Opt-in pre-commit gate: blocks commits whose staged content matches the
# de-identification denylist or secret patterns. Install by symlinking as
# .git/hooks/pre-commit.
set -uo pipefail
SCAN="${DESTRIER_SCAN:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/security-scan.sh}"
if ! bash "$SCAN" --staged; then
  {
    echo ""
    echo "Commit blocked by destrier security gate (identifying tokens or secrets in staged changes)."
    echo "Remediate the findings above, or bypass with: git commit --no-verify"
  } >&2
  exit 1
fi
exit 0
