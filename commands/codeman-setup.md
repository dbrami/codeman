---
description: Bootstrap codeman's external tools — build gitnexus from git and install roborev via its official installer.
---

Run the codeman bootstrap. It first verifies every prerequisite (git, rg, jq,
node, npm, python3, gh, curl), then installs gitnexus (git clone + build) and
roborev (official installer); neither tool is vendored or repackaged by codeman.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh"
```

If any prerequisite is missing, the script prints the exact install command for
the user's platform. To have codeman install the missing prerequisites
automatically via the detected package manager (brew/apt/dnf/yum), re-run with:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh" --install-deps
```

After it finishes, tell the user to restart Claude Code so the gitnexus MCP
server loads, and to run `gitnexus analyze` once per repository they want indexed.
