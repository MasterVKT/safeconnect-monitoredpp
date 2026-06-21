#!/usr/bin/env bash
# Repo-Map Hook — PreToolUse
# Injecte la Repo-Map une seule fois par session au démarrage d'une tâche.
set -uo pipefail

MARKER_DIR=".claude/.repomap_sessions"
CACHE_MD=".claude/.repomap_cache.md"
CACHE_MAX_AGE=1800  # 30 minutes en secondes

mkdir -p "$MARKER_DIR"

# Nettoyer les anciens marqueurs (>2h)
find "$MARKER_DIR" -name "*.marker" -mmin +120 -delete 2>/dev/null || true

# Identifier la session via le PID du shell parent
SESSION_ID="${PPID:-$$}"
MARKER_FILE="$MARKER_DIR/${SESSION_ID}.marker"

# Ne pas injecter si déjà fait dans cette session
if [[ -f "$MARKER_FILE" ]]; then
  exit 0
fi

# Générer ou lire depuis le cache
CARTE=""
if [[ -f "$CACHE_MD" ]]; then
  AGE=$(( $(date +%s) - $(date -r "$CACHE_MD" +%s 2>/dev/null || echo 0) ))
  if [[ $AGE -lt $CACHE_MAX_AGE ]]; then
    CARTE=$(cat "$CACHE_MD" 2>/dev/null || echo "")
  fi
fi

if [[ -z "$CARTE" ]]; then
  PY=""
  if [[ -f ".venv/Scripts/python.exe" ]]; then
    PY=".venv/Scripts/python.exe"
  elif command -v python3 &>/dev/null; then
    PY="python3"
  elif command -v python &>/dev/null; then
    PY="python"
  fi
  if [[ -n "$PY" ]]; then
    CARTE=$("$PY" .claude/repomap.py 2>/dev/null || echo "")
  fi
fi

if [[ -z "$CARTE" ]]; then
  exit 0
fi

# Marquer cette session comme ayant déjà reçu la Repo-Map
touch "$MARKER_FILE"

# Construire le message d'injection
NOTE="$CARTE

---
> Repo-Map injectée automatiquement. Cette carte structure l'ensemble du projet.
> Continuer la même requête : l'agent dispose maintenant du contexte global."

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
" <<< "$NOTE" 2>/dev/null || true

exit 0
