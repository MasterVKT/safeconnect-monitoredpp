# Problème WebSocket — Analyse complète et solutions

**Date** : 2026-04-15
**Application** : XP SafeConnect — Application Surveillée (`monitored_app`)
**Statut** : 🟡 Partiellement résolu — corrections Flutter appliquées, configuration backend requise
**Priorité** : Haute

---

## Résumé exécutif

L'application surveillée tente de se connecter via WebSocket au backend après le jumelage, mais la connexion échoue silencieusement. La conséquence visible est que le tableau de bord affiche **"Déconnecté"** même après un jumelage réussi. Les commandes à distance (verrouillage, déverrouillage) et les mises à jour en temps réel sont donc non fonctionnelles.

L'investigation a révélé **deux causes racines distinctes** : l'une côté Flutter (déjà corrigée), l'autre côté déploiement backend (à corriger).

---

## Partie 1 — Diagnostic

### 1.1 Symptômes observés

| Symptôme | Fréquence |
|---|---|
| Dashboard affiche "Déconnecté" après jumelage | 100% |
| Aucune log "WebSocket: Connecting with deviceId=…" | 100% |
| Commandes à distance (verrouillage) non reçues | 100% |
| Reconnecter l'app ne résout pas le problème | 100% |

**Extrait de log caractéristique** (après jumelage réussi) :
```
I/flutter: [PAIRING] Storing paired device ID: 602fc129-93ae-436d-8666-67da00dd7443
I/flutter: [PAIRING] Connecting WebSocket...
I/flutter: [PAIRING] Starting DeviceService in background...
```
→ Absence totale de `WebSocket: Connecting with deviceId=…` et `WebSocket: Connected`.

### 1.2 Infrastructure backend existante

Contrairement à l'hypothèse initiale, le backend dispose déjà de l'infrastructure WebSocket complète :

| Composant | Fichier | État |
|---|---|---|
| Django Channels | `requirements.txt` (channels==4.1.0) | ✅ Installé |
| Channel Layer Redis | `requirements.txt` (channels-redis==4.2.0) | ✅ Installé |
| Application ASGI | `safeconnect/asgi.py` | ✅ Configurée |
| Routing WebSocket | `channels/routing.py` | ✅ Route `ws/device/<id>/` définie |
| Consumer `DeviceConsumer` | `channels/consumers.py` | ✅ Implémenté |
| CHANNEL_LAYERS (Redis) | `safeconnect/settings/base.py` | ✅ Configuré |
| `ASGI_APPLICATION` | `safeconnect/settings/base.py` | ✅ Défini |

---

## Partie 2 — Causes racines

### Cause #1 — Bug Flutter : `_webSocketService` est `null` au moment du jumelage *(CORRIGÉ)*

**Fichier** : `lib/core/services/auth_service.dart`

**Mécanisme du bug** :

```dart
class AuthService {
  WebSocketService? _webSocketService; // ← initialisé à null

  Future<void> initialize() async {
    _webSocketService = locator<WebSocketService>(); // ← assigné ici
    if (await isAuthenticated()) {
      await _webSocketService!.connect();
    }
  }

  Future<AuthResult> pairDevice(PairingParams params) async {
    // ... jumelage ...
    debugPrint('[PAIRING] Connecting WebSocket...');
    try {
      await _webSocketService?.connect(); // ← SILENCIEUX : _webSocketService est NULL !
    } catch (e) { ... }
  }
}
```

`initialize()` n'est pas appelé dans le flux de jumelage (`pairDevice()`). Le champ `_webSocketService` est donc `null`. L'opérateur null-safe `?.` transforme l'appel en no-op sans aucune erreur ni log. La connexion WebSocket n'est jamais tentée.

**Correction appliquée** :
```dart
// Avant (bug)
await _webSocketService?.connect();

// Après (corrigé)
await locator<WebSocketService>().connect(); // singleton toujours disponible
```

---

### Cause #2 — Serveur lancé en mode WSGI (`manage.py runserver`), non ASGI

**Impact** : Critique — même avec le bug Flutter corrigé, le WebSocket ne peut pas fonctionner si le serveur n'est pas en mode ASGI.

**Explication** :

`manage.py runserver` utilise le protocole **WSGI** (synchrone, HTTP uniquement). Le protocole WebSocket nécessite **ASGI** (asynchrone). Même si l'application ASGI est parfaitement configurée dans `safeconnect/asgi.py`, elle n'est jamais chargée par `manage.py runserver`.

```
┌─────────────────────────────────────────────────────┐
│  manage.py runserver                                 │
│  ↓                                                   │
│  Django WSGI Application (safeconnect/wsgi.py)      │
│  → HTTP uniquement                                   │
│  → WebSocket : connexion acceptée puis fermée        │
│    immédiatement (pas de handler WS)                 │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  daphne safeconnect.asgi:application                 │
│  ↓                                                   │
│  Django ASGI Application (safeconnect/asgi.py)      │
│  → HTTP : get_asgi_application()                     │
│  → WebSocket : ProtocolTypeRouter → URLRouter        │
│    → ws/device/<id>/ → DeviceConsumer ✅             │
└─────────────────────────────────────────────────────┘
```

### Cause #3 — Vérification des permissions du consumer (point de vigilance)

Dans `channels/consumers.py`, `DeviceConsumer.check_device_permission()` vérifie :

```python
def check_device_permission(self, user, device_id):
    device = Device.objects.get(id=device_id)
    if device.user == user:           # ← cas 1 : propriétaire du device
        return True

    has_permission = DevicePermission.objects.filter(
        monitored_device_id=device_id,
        monitoring_device__user=user, # ← cas 2 : parent via permission
        is_granted=True,
        revoked_at__isnull=True
    ).exists()
    return has_permission
```

L'app surveillée se connecte avec le token JWT de l'utilisateur parent (`ericvekout@gmail.com`). L'appareil surveillé (`602fc129-…`) appartient au même utilisateur. Le **cas 1** devrait donc passer.

⚠️ **Point de vigilance** : si un jour les appareils surveillés sont rattachés à un utilisateur différent de celui qui détient le token JWT (ex. token de l'enfant, device de l'enfant), la permission sera refusée avec code `4003`. Prévoir un log explicite dans ce cas.

---

## Partie 3 — Solution complète

### 3.1 Correction Flutter (déjà appliquée)

**Fichier modifié** : `lib/core/services/auth_service.dart` (ligne ~101)

```dart
// AVANT
await _webSocketService?.connect(); // null → no-op silencieux

// APRÈS
await locator<WebSocketService>().connect(); // singleton toujours prêt
```

**Résultat attendu dans les logs** après cette correction + lancement Daphne :
```
I/flutter: [PAIRING] Connecting WebSocket...
I/flutter: WebSocket: Connecting with deviceId=602fc129-93ae-436d-8666-67da00dd7443
I/flutter: WebSocket: Connected
```

---

### 3.2 Lancer le serveur en mode ASGI (Daphne)

**Option A — Daphne (recommandé pour le développement ASGI)**

```bash
cd h:\Projects\XP SafeConnect\safeconnect-env\safeconnect

# Activer l'environnement virtuel (si applicable)
# ..\Scripts\activate  (Windows) ou source ../bin/activate (Linux/Mac)

# Installer Daphne si absent
pip install daphne

# Lancer le serveur ASGI sur toutes les interfaces réseau
daphne -b 0.0.0.0 -p 8000 safeconnect.asgi:application
```

L'accès aux deux apps Flutter doit utiliser l'IP LAN de la machine de développement :
- Application surveillée : `flutter run --dart-define=API_BASE_URL=http://192.168.1.127:8000`
- Application moniteur : idem (emulateur : `http://10.0.2.2:8000`)

**Option B — Daphne via `INSTALLED_APPS` (manage.py runserver devient ASGI)**

Ajouter `'daphne'` en **première position** dans `INSTALLED_APPS` (fichier `safeconnect/settings/base.py`) :

```python
INSTALLED_APPS = [
    'daphne',    # ← DOIT être en premier
    'django.contrib.admin',
    'django.contrib.auth',
    # ... reste des apps
    'channels',
    # ...
]
```

Puis `manage.py runserver` utilisera automatiquement ASGI. Cette option est pratique mais moins explicite.

**Option C — Uvicorn (alternative moderne)**

```bash
pip install uvicorn[standard]
uvicorn safeconnect.asgi:application --host 0.0.0.0 --port 8000 --reload
```

---

### 3.3 Vérifier la connexion Redis

Django Channels utilise Redis comme channel layer. Redis doit être actif sur `127.0.0.1:6379` (configuration dans `settings/base.py`).

```bash
# Vérifier que Redis répond
redis-cli ping
# → PONG attendu

# Si Redis n'est pas démarré (Windows)
redis-server --daemonize no

# Ou via WSL
sudo service redis-server start
```

---

## Partie 4 — Architecture WebSocket en place

Voici l'architecture complète telle qu'elle est implémentée et comment les deux apps interagissent :

```
┌────────────────────┐          WebSocket         ┌───────────────────────┐
│  App Surveillée    │ ──── ws/device/<uuid>/ ───▶ │  DeviceConsumer       │
│  (monitored_app)   │                             │  channels/consumers.py│
│                    │ ◀──── commandes JSON ─────  │                       │
│  lock_device       │                             │  channel_layer        │
│  unlock_device     │                             │  group: device_<uuid> │
│  heartbeat         │                             └───────────────────────┘
└────────────────────┘                                        ↑ group_send
                                                              │
┌────────────────────┐          WebSocket         ┌───────────────────────┐
│  App Moniteur      │ ── ws/monitoring/<uuid>/ ──▶│  MonitoringConsumer   │
│  (monitor_app)     │                             │  channels/consumers.py│
│                    │ ──── command: lock ────────▶│                       │
│  remote lock/unlock│                             │  forward to device    │
│  status updates    │ ◀──── device_status ──────  │  group_send →         │
└────────────────────┘                             └───────────────────────┘
```

**Types de messages supportés par `DeviceConsumer`** :

| Message reçu (device → server) | Action |
|---|---|
| `{"type": "status_update", "battery": 85, "is_charging": true}` | Met à jour Device en DB + broadcast au groupe |
| `{"type": "heartbeat"}` | Met à jour `is_online=True` en DB |
| `{"type": "unlock_response", "success": true}` | Broadcast au groupe monitoring |
| `{"type": "sync_request"}` | Notifie les appareils surveillants |

**Types de messages envoyés au device (server → device)** :

| Message envoyé | Déclencheur |
|---|---|
| `{"type": "device_command", "command": "lock_device"}` | Parent clique "Verrouiller" |
| `{"type": "device_command", "command": "unlock_device"}` | Parent clique "Déverrouiller" |
| `{"type": "device_command", "command": "capture_media"}` | Parent demande capture |
| `{"type": "device_status", ...}` | Status broadcast |

---

## Partie 5 — Vérification étape par étape

### Étape 1 — Vérifier Redis

```bash
redis-cli ping
# Attendu : PONG
```

### Étape 2 — Lancer le serveur ASGI

```bash
daphne -b 0.0.0.0 -p 8000 safeconnect.asgi:application
# Attendu dans les logs Daphne :
# Django version 5.0.7, using settings 'safeconnect.settings.dev'
# Starting ASGI/Daphne version X.X development server at http://0.0.0.0:8000/
```

### Étape 3 — Tester la route WebSocket manuellement

```bash
# Obtenir un token JWT
TOKEN=$(curl -s -X POST http://192.168.1.127:8000/api/v1/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"ericvekout@gmail.com","password":"<mot_de_passe>"}' \
  | python -c "import sys,json; print(json.load(sys.stdin)['access'])")

# Tester la connexion WebSocket (installer wscat : npm install -g wscat)
wscat -c "ws://192.168.1.127:8000/ws/device/602fc129-93ae-436d-8666-67da00dd7443/?token=$TOKEN"
# Attendu : Connected (press CTRL+C to quit)
```

### Étape 4 — Lancer l'application surveillée

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.127:8000
```

**Logs attendus dans Flutter** :
```
I/flutter: [PAIRING] Connecting WebSocket...
I/flutter: WebSocket: Connecting with deviceId=602fc129-93ae-436d-8666-67da00dd7443
I/flutter: WebSocket: Connected
```

**Logs attendus dans Daphne** :
```
HTTP GET /api/v1/devices/validate-pairing-code/ 200
WebSocket HANDSHAKING /ws/device/602fc129-93ae-436d-8666-67da00dd7443/?token=... [192.168.1.x]
WebSocket CONNECT /ws/device/602fc129-93ae-436d-8666-67da00dd7443/?token=... [192.168.1.x]
```

### Étape 5 — Vérifier le dashboard

Le dashboard doit afficher **"Connecté"** immédiatement et en temps réel (non plus via la vérification de session locale, mais via le WebSocket actif).

---

## Résumé des modifications effectuées

| Fichier | Modification | État |
|---|---|---|
| `lib/core/services/auth_service.dart` | `_webSocketService?.connect()` → `locator<WebSocketService>().connect()` | ✅ Corrigé |
| `lib/features/home/main_screen.dart` | Isolation des appels async + `_quickCheckConnectionState()` | ✅ Corrigé (session précédente) |
| Serveur Django | Passer de `manage.py runserver` (WSGI) à `daphne` (ASGI) | ⏳ À faire |

---

**Contact** : Eric Vekout
**Dernière mise à jour** : 2026-04-15
