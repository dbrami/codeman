---
description: Report weekly throughput and cycle-time metrics for one or more GitHub repos.
argument-hint: "[--weeks N] [--repo owner/name ...]"
---

Run flow metrics for the requested repositories (requires `gh` authenticated).
With no `--repo`, it infers the current repo from `git remote get-url origin`.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/flow-metrics.py" $ARGUMENTS
```

Summarize the throughput slope and the cycle-time p50/p85 for the user, and call
out any WIP-aging trend (growing WIP with flat throughput degrades cycle time
first — Little's Law).
