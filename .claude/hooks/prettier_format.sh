#!/usr/bin/env bash
# PRETTIER NON DÉTECTÉ — hook présent mais inactif.
# Installer prettier (npm install -D prettier) pour activer.
# Prettier Format Hook — PostToolUse
# Formate automatiquement les fichiers JS/TS/CSS/HTML après écriture.
set -uo pipefail

# Extensions cibles pour Prettier
PRETTIER_EXTS=".js .jsx .ts .tsx .css .scss .less .html .json .md .yaml .yml"

INPUT=$(cat)
FILE_PATH=$(python3 -c "
import json, sys
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path','') or ti.get('path','') or ti.get('new_path','') or '')
" <<< "$INPUT" 2>/dev/null || echo "")

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"
EXT=".${EXT,,}"
MATCH=0
for ext in $PRETTIER_EXTS; do
  [[ "$EXT" == "$ext" ]] && MATCH=1 && break
done
[[ $MATCH -eq 0 ]] && exit 0

# Localiser prettier (local project > global)
PRETTIER_BIN=""
[[ -f "node_modules/.bin/prettier" ]] && PRETTIER_BIN="node_modules/.bin/prettier"
[[ -z "$PRETTIER_BIN" ]] && command -v prettier &>/dev/null && PRETTIER_BIN="prettier"
[[ -z "$PRETTIER_BIN" ]] && exit 0

# Formater le fichier silencieusement
timeout 10 "$PRETTIER_BIN" --write "$FILE_PATH" &>/dev/null || true

exit 0
