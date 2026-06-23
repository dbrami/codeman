---
description: Security-review the pending changes — de-identification + secret scan, plus roborev security review when available.
---

Perform destrier's security gate on the current pending changes.

1. Run the de-identification + secret scan on staged changes:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/security-scan.sh" --staged || true
```

2. If `roborev` is installed, run its security review and surface findings:

```bash
command -v roborev >/dev/null 2>&1 && roborev review --type security --wait \
  || echo "roborev not installed; run /destrier-setup to add deeper security review."
```

Report all findings. Do not advise committing until both the scan is clean and
any roborev security findings are resolved.
