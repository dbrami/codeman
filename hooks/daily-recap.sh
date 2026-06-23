#!/usr/bin/env bash
# SessionStart hook — daily recap of recent work in the current repo.
# Shows last-24h commits, uncommitted changes, and unpushed counts.
set -uo pipefail
TODAY=$(date +%Y-%m-%d)
PROJECT_DIRS=("$PWD")
recap=""

git_section=""
for dir in "${PROJECT_DIRS[@]}"; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  commits=$(git -C "$dir" log --oneline --since="24 hours ago" --format="  %h %s" 2>/dev/null)
  [ -n "$commits" ] && git_section+="### $name"$'\n'"$commits"$'\n\n'
done
if [ -n "$git_section" ]; then
  recap+="## Commits (last 24h)"$'\n'"$git_section"
else
  recap+="## Commits (last 24h)"$'\n'"_No commits in the last 24 hours._"$'\n\n'
fi

dirty_section=""
for dir in "${PROJECT_DIRS[@]}"; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  status=$(git -C "$dir" status --short 2>/dev/null | head -10)
  if [ -n "$status" ]; then
    count=$(echo "$status" | wc -l | tr -d ' ')
    dirty_section+="### $name ($count files)"$'\n'"$status"$'\n\n'
  fi
done
[ -n "$dirty_section" ] && recap+="## Uncommitted Changes"$'\n'"$dirty_section"

unpushed_section=""
for dir in "${PROJECT_DIRS[@]}"; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  upstream=$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null) || continue
  ahead=$(git -C "$dir" rev-list "${upstream}..HEAD" --count 2>/dev/null || echo 0)
  [ "$ahead" -gt 0 ] && unpushed_section+="- **$name**: $ahead commit(s) ahead of $upstream"$'\n'
done
[ -n "$unpushed_section" ] && recap+="## Unpushed"$'\n'"$unpushed_section"$'\n'

# Optional, opt-in: surface a personal notes/memory directory if the user sets one.
if [ -n "${DESTRIER_MEMORY_DIR:-}" ] && [ -d "$DESTRIER_MEMORY_DIR" ]; then
  recap+="## Notes"$'\n'"Review notes in \$DESTRIER_MEMORY_DIR for context."$'\n'
fi

[ -z "$recap" ] && exit 0
msg="# Daily Recap — $TODAY"$'\n\n'"$recap"
if command -v jq >/dev/null 2>&1; then
  jq -n --arg m "$msg" '{"systemMessage": $m}'
else
  printf '%s\n' "$msg"
fi
exit 0
