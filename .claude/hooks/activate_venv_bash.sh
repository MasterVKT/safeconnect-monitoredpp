#!/usr/bin/env bash
# Prepends .venv activation to every Bash tool command.
# Windows Git Bash path: .venv/Scripts/activate
# Linux/Mac fallback:   .venv/bin/activate
# Exits 0 (no-op) if jq unavailable or command empty — never blocks.

data=$(cat)
cmd=$(printf '%s' "$data" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$cmd" ]; then
  exit 0
fi

new_cmd="source \".venv/Scripts/activate\" 2>/dev/null || source \".venv/bin/activate\" 2>/dev/null || true; $cmd"

printf '%s' "$data" | jq --arg nc "$new_cmd" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: {command: $nc}}}' 2>/dev/null \
  || exit 0
