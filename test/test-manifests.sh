#!/usr/bin/env bash
# Tests for the plugin + marketplace manifests.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
command -v jq >/dev/null 2>&1 || { echo "jq required"; exit 64; }

P="$ROOT/.claude-plugin/plugin.json"
M="$ROOT/.claude-plugin/marketplace.json"

jq -e . "$P" >/dev/null 2>&1; assert_exit_code 0 $? "plugin.json is valid JSON"
jq -e . "$M" >/dev/null 2>&1; assert_exit_code 0 $? "marketplace.json is valid JSON"
assert_eq "codeman" "$(jq -r .name "$P")" "plugin name is codeman"

v="$(jq -r .version "$P")"
echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'
assert_exit_code 0 $? "version is semver ($v)"

assert_eq "codeman" "$(jq -r '.plugins[0].name' "$M")" "marketplace lists codeman"
assert_eq "." "$(jq -r '.plugins[0].source' "$M")" "marketplace source is repo root"

pass "manifests"
