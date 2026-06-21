#!/usr/bin/env bash
# Log Filter Hook — PreToolUse
# Filtre les fichiers logs/output volumineux, retourne uniquement les lignes critiques.
# NE cible PAS les fichiers source (gérés par ast_elision.py via T1).
set -uo pipefail

SEUIL_LIGNES=500
MAX_LIGNES_SORTIE=80

INPUT=$(cat)
FILE_PATH=$(python3 -c "
import json, sys
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path','') or ti.get('path','') or ti.get('relative_path','') or '')
" <<< "$INPUT" 2>/dev/null || echo "")

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

# Extensions source gérées par T1 — ne pas intercepter ici
SOURCE_EXTS=".py .ts .tsx .js .jsx .go .rs .rb .java .cpp .c .cs .kt .swift .php"
EXT="${FILE_PATH##*.}"
EXT=".${EXT,,}"
for se in $SOURCE_EXTS; do
  [[ "$EXT" == "$se" ]] && exit 0
done

# Cibles : logs, outputs, dumps (tout fichier non-source et volumineux)
LIGNES=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
[[ "$LIGNES" -lt "$SEUIL_LIGNES" ]] && exit 0

BASENAME=$(basename "$FILE_PATH")

# Extraire les lignes critiques (erreurs, exceptions, warnings, traces)
CRITIQUE=$(grep -iE \
  "error|exception|traceback|fatal|critical|fail|panic|abort|crash|assert|oom|killed|sigkill|timeout|refused|denied|unauthorized|forbidden|not found|cannot|unable|undefined|null pointer|stack overflow|segfault|core dump" \
  "$FILE_PATH" 2>/dev/null | head -n "$MAX_LIGNES_SORTIE" || true)

# Extraire les dernières lignes pour le contexte de fin d'exécution
DERNIERE=$(tail -n 20 "$FILE_PATH" 2>/dev/null || true)

if [[ -z "$CRITIQUE" && -z "$DERNIERE" ]]; then
  exit 0
fi

RESUME="# 🪵 Log Filter : \`$BASENAME\` ($LIGNES lignes → filtré automatiquement)
> Corps du fichier élidé. Seules les lignes critiques et la fin sont présentées.
> Pour lire le fichier complet : demander \`read_full:$FILE_PATH\`

### Lignes critiques détectées :
\`\`\`
$(echo "$CRITIQUE" | head -n 60)
\`\`\`

### Fin du fichier (20 dernières lignes) :
\`\`\`
$DERNIERE
\`\`\`"

python3 -c "
import json, sys
reason = sys.stdin.read()
out = {
  'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': 'deny',
    'permissionDecisionReason': reason
  }
}
print(json.dumps(out))
" <<< "$RESUME" 2>/dev/null || true

exit 0
