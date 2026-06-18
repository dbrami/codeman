#!/usr/bin/env bash
# Minimal assert helpers for codeman's plain-bash test suite.
#
# Assertions record failures in _FAILED. Tests end with `pass "<name>"`, which
# exits non-zero if any assertion failed. We deliberately do NOT use an EXIT
# trap here, because individual tests set their own EXIT trap for tmpdir
# cleanup (which would clobber a trap defined here).
_FAILED=0
fail()  { echo "FAIL: $1" >&2; _FAILED=1; }
pass()  {
  if [ "$_FAILED" != 0 ]; then echo "FAILED: $1" >&2; exit 1; fi
  echo "PASS: $1"
}
assert_exit_code() { # expected actual msg
  if [ "$1" = "$2" ]; then echo "  ok: $3 (exit $2)"; else fail "$3 (expected exit $1, got $2)"; fi
}
assert_eq() { # expected actual msg
  if [ "$1" = "$2" ]; then echo "  ok: $3"; else fail "$3 (expected '$1', got '$2')"; fi
}
assert_contains() { # haystack needle msg
  if printf '%s' "$1" | grep -qF -- "$2"; then echo "  ok: $3"; else fail "$3 (missing '$2')"; fi
}
