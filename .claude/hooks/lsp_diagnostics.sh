#!/usr/bin/env bash
# LSP Diagnostics Hook — PostToolUse
# Injecte les diagnostics compilateur après chaque écriture de fichier.
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('tool_input',{}).get('file_path','') or
      d.get('tool_input',{}).get('path','') or
      d.get('tool_input',{}).get('new_path','') or '')
" 2>/dev/null || echo "")

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"
DIAGS=""
TIMEOUT_CMD="timeout 15"

case "$EXT" in
  dart)
    if command -v dart &>/dev/null; then
      DIAGS=$($TIMEOUT_CMD dart analyze "$FILE_PATH" 2>&1 | grep -E "error|warning|hint|info" | head -30 || true)
    fi
    ;;
  ts|tsx|js|jsx)
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    if command -v tsc &>/dev/null; then
      if [[ -f "$ROOT/tsconfig.json" ]]; then
        DIAGS=$($TIMEOUT_CMD tsc --noEmit --project "$ROOT/tsconfig.json" 2>&1 | head -35 || true)
      else
        DIAGS=$($TIMEOUT_CMD tsc --noEmit --allowJs --strict "$FILE_PATH" 2>&1 | head -35 || true)
      fi
    fi
    ;;
  py)
    if command -v pyright &>/dev/null; then
      RAW=$($TIMEOUT_CMD pyright --outputjson "$FILE_PATH" 2>/dev/null || echo "{}")
      DIAGS=$(echo "$RAW" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    errs=d.get('generalDiagnostics',[])
    lines=[f\"L{e.get('range',{}).get('start',{}).get('line','?')+1} [{e.get('severity','?')}] {e.get('message','?')}\" for e in errs[:25]]
    print('\n'.join(lines))
except: pass
" 2>/dev/null || true)
    else
      DIAGS=$(python3 -m py_compile "$FILE_PATH" 2>&1 | head -15 || true)
    fi
    ;;
  go)
    if command -v go &>/dev/null; then
      DIAGS=$($TIMEOUT_CMD go vet ./... 2>&1 | head -25 || true)
    fi
    ;;
  rs)
    if command -v cargo &>/dev/null; then
      DIAGS=$($TIMEOUT_CMD cargo check --message-format=short 2>&1 | grep -v "^$" | head -25 || true)
    fi
    ;;
  *)
    exit 0
    ;;
esac

DIAGS_CLEAN=$(echo "$DIAGS" | grep -v "^$" | head -30 || true)

if [[ -z "$DIAGS_CLEAN" ]]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
RESUME="# Diagnostics LSP — \`$BASENAME\`\n\`\`\`\n$DIAGS_CLEAN\n\`\`\`\n> Corriger ces erreurs avant de continuer."

python3 -c "
import json, sys
reason = sys.argv[1]
out = {'hookSpecificOutput': {'hookEventName': 'PostToolUse', 'additionalContext': reason}}
print(json.dumps(out))
" "$RESUME" 2>/dev/null || true

exit 0
