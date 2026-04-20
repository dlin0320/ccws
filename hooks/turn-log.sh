#!/usr/bin/env bash
# ccws turn-log hook
# Fires on Stop (main session) and SubagentStop (subagent completion).
# Appends a one-line entry to the active task's TURNS.md.
# Task resolution: current git branch must match .claude-workspace/task/<branch>/.
# Silently exits if no active task context is detected.

set -euo pipefail

input=$(cat)

stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')
[ "$stop_hook_active" = "true" ] && exit 0

cwd=$(echo "$input" | jq -r '.cwd // empty')
msg=$(echo "$input" | jq -r '.last_assistant_message // empty')
event=$(echo "$input" | jq -r '.hook_event_name // "Stop"')
[ -z "$cwd" ] || [ -z "$msg" ] && exit 0

workspace="$cwd/.claude-workspace"
[ -d "$workspace" ] || exit 0

branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
task_name="${branch//\//-}"
task_dir="$workspace/task/$task_name"
[ -d "$task_dir" ] || exit 0

case "$event" in
  Stop)         tag="[auto]" ;;
  SubagentStop) tag="[auto:subagent]" ;;
  *)            tag="[auto]" ;;
esac

summary=$(echo "$msg" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-240)
ts=$(date +"%Y-%m-%d %H:%M")
{
  echo ""
  echo "### $ts $tag"
  echo "$summary"
} >> "$task_dir/TURNS.md"
exit 0
