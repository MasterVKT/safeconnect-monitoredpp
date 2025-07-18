# Guide d'Implémentation des Fonctionnalités - Application Surveillée

## 1. Configuration initiale et jumelage

### 1.1 Écran de jumelage

**Logique d'implémentation :**
```
Interface minimale avec :
- Champ de saisie du code à 6 chiffres
- Option scan QR code si caméra disponible
- Validation format (6 digits only)
- Indicateur de vérification en cours
- Message d'erreur si code invalide/expiré
- Auto-focus sur le champ code

Flux de jumelage :
1. Saisie/scan du code
2. Appel API POST /pairing/validate-code
3. Récupération des infos de surveillance
4. Affichage du consentement si adulte
5. Configuration des permissions
6. Activation des services
```

### 1.2 Consentement explicite (Mode adulte)

**Logique de présentation du consentement :**
```
Écran de consentement détaillé :
- Liste exhaustive des données collectées
- Fréquence de collecte par type
- Utilisation prévue des données
- Durée de conservation
- Droits de l'utilisateur
- Signature simplifiée (checkbox + nom)

Validation :
- Scroll obligatoire jusqu'en bas
- Checkbox "J'ai lu et compris"
- Saisie du nom pour signature
- Timestamp et hash du consentement
- Envoi sécurisé au backend
```

### 1.3 Configuration des permissions

**Logique de demande de permissions :**
```
Séquence optimisée :
1. Explication générale de l'utilité
2. Groupement logique des permissions :
   - Localisation (GPS + background)
   - Communications (SMS + Calls)
   - Médias (Camera + Microphone + Storage)
   - Système (Accessibility + Admin)
3. Gestion des refus avec alternatives
4. Possibilité de continuer en mode dégradé
5. Guide vers paramètres si changement d'avis

Android spécifique :
- Ignorer optimisation batterie
- Service d'accessibilité pour WhatsApp
- Admin device pour anti-désinstallation
- Overlay pour screenshots

iOS spécifique :
- Location "Always Allow"
- Notifications pour maintien background
- Restrictions système expliquées
```

## 2. Service en arrière-plan

### 2.1 Configuration du service principal

**Logique d'implémentation Android :**
```
ForegroundService setup :
- START_STICKY pour redémarrage auto
- Notification channel approprié
- WakeLock partiel si nécessaire
- Priority MAX pour survie
- Exclude from recents

Notification adaptative :
- Mode normal : "SafeConnect actif"
- Mode discret : "Mise à jour système"
- Mode invisible : Notification minimale

Démarrage au boot :
- BootReceiver avec permission
- Délai 10 secondes après boot
- Vérification état avant start
- Fallback sur WorkManager
```

**Logique d'implémentation iOS :**
```
Background modes :
- Location updates (principal)
- Background fetch
- Remote notifications (silent)
- Audio (si justifié)

Stratégies de maintien :
- Significant location changes
- Region monitoring circulaire
- Silent push périodique
- Background task scheduler
```

### 2.2 Orchestrateur de collecte

**DataCollectionOrchestrator - Logique :**
```
Responsabilités :
- Scheduler les collecteurs
- Adapter selon batterie/réseau
- Gérer les priorités
- Éviter les overlaps
- Logger les activités

Configuration adaptative :
batteryLevel > 50 && isCharging:
  - Tous collecteurs actifs
  - Fréquences maximales
  - Qualité maximale
  
batteryLevel > 30:
  - Fréquences normales
  - Qualité équilibrée
  
batteryLevel > 15:
  - Collecteurs essentiels
  - Fréquences réduites
  - Compression maximale
  
batteryLevel <= 15:
  - Urgence seulement
  - GPS basse précision
  - Sync différée
```

## 3. Collecteurs de données

### 3.1 SMS Collector (Android)

**Logique de collecte des SMS :**
```
ContentObserver implementation :
- Observer sur content://sms
- Filtrage des changements
- Lecture via ContentResolver
- Projection des colonnes nécessaires
- Gestion des MMS basiques

Traitement :
1. Détecter nouveau SMS
2. Lire les métadonnées
3. Extraire le contenu
4. Détecter mots-clés configurés
5. Chiffrer le message
6. Stocker en base locale
7. Marquer pour synchronisation

Optimisations :
- Cache last processed ID
- Batch reads par 50
- Skip messages anciens
- Compression du contenu
```

### 3.2 Call Logger

**Logique de collecte des appels :**
```
CallLog.Calls monitoring :
- ContentObserver sur call log
- PhoneStateListener pour temps réel
- Extraction : number, duration, type
- Enrichissement avec contacts
- Géolocalisation si disponible

Types d'appels :
- INCOMING : Entrants
- OUTGOING : Sortants  
- MISSED : Manqués
- REJECTED : Rejetés
- BLOCKED : Bloqués

Métadonnées :
- Numéro (hashé si besoin)
- Durée en secondes
- Timestamp précis
- Nom du contact
- Type d'appel
- Opérateur si disponible
```

### 3.3 Location Tracker

**Logique de tracking GPS :**
```
FusedLocationProvider config :
- Priority adaptative
- Interval dynamique
- FastestInterval protection
- SmallestDisplacement filter

Modes de précision :
HIGH_ACCURACY :
  - Interval : 5-30 secondes
  - Accuracy : PRIORITY_HIGH_ACCURACY
  - Displacement : 10 mètres

BALANCED :
  - Interval : 1-5 minutes
  - Accuracy : PRIORITY_BALANCED
  - Displacement : 50 mètres

LOW_POWER :
  - Interval : 5-15 minutes
  - Accuracy : PRIORITY_LOW_POWER
  - Displacement : 100 mètres

Enrichissement :
- Reverse geocoding différé
- Activity recognition
- Speed calculation
- Bearing changes
```

### 3.4 App Usage Monitor

**Logique de surveillance des apps :**
```
UsageStatsManager utilisation :
- Query interval : 5 minutes
- Time range : Last 24h rolling
- Aggregation par app
- Events pour installs/uninstalls

Données collectées :
- Package name
- Temps d'utilisation total
- Dernière utilisation
- Nombre de lancements
- Premier/dernier foreground
- Catégorie de l'app

Détection nouvelles apps :
- PackageManager monitoring
- BroadcastReceiver PACKAGE_ADDED
- Extraction infos de base
- Screenshot icône (si permis)
```

### 3.5 Media Capture Service

**Logique de capture à distance :**
```
Screenshot (Android) :
- MediaProjection API
- VirtualDisplay creation
- ImageReader pour capture
- Compression JPEG 80%
- Notification obligatoire

Photo capture :
- Camera2 API usage
- Pas de preview surface
- Configuration minimale
- Capture silencieuse
- Rotation correcte EXIF

Audio recording :
- MediaRecorder setup
- Format AAC pour taille
- Bitrate adaptatif
- Durée max configurée
- Niveau sonore monitoring
```

### 3.6 Messaging Apps Monitor

**Logique via AccessibilityService :**
```
WhatsApp monitoring :
- Écoute événements UI
- Filtrage package WhatsApp
- Extraction textes visibles
- Capture notifications
- Screenshot si nouveau message

Limitations :
- Contenu partiel seulement
- Dépend de l'UI
- Notifications plus fiables
- Performance impact

Fallback :
- NotificationListenerService
- Capture toutes notifications
- Parse le contenu
- Moins intrusif
```

## 4. Système de synchronisation

### 4.1 Sync Queue Manager

**Logique de gestion de la queue :**
```
Structure de queue :
- Table SQLite pour persistance
- Priorités : URGENT, HIGH, NORMAL, LOW
- FIFO par niveau de priorité
- Retry count et backoff
- Timestamp création/dernière tentative

Ajout à la queue :
1. Sérialiser les données
2. Compresser si > 1KB
3. Chiffrer le payload
4. Calculer la priorité
5. Insérer en DB
6. Déclencher sync si online

Traitement :
1. Sélectionner par priorité
2. Batch par type si possible
3. Envoyer au serveur
4. Attendre confirmation
5. Supprimer si succès
6. Retry si échec (max 5)
```

### 4.2 Network-Aware Sync

**Logique de synchronisation intelligente :**
```
Stratégies par réseau :
WiFi connecté :
  - Sync immédiate tous types
  - Uploads médias autorisés
  - Pas de compression max
  - Batch size : 100 items

4G/5G :
  - Données critiques seulement
  - Médias différés ou compressés
  - Compression maximale
  - Batch size : 50 items

3G/Edge :
  - Urgence seulement
  - Pas de médias
  - Ultra compression
  - Batch size : 10 items

Offline :
  - Queue locale seulement
  - Limite storage 100MB
  - Rotation FIFO si plein
```

## 5. Mode urgence

### 5.1 Déclencheurs d'urgence

**Logique d'activation :**
```
Déclencheurs multiples :
1. Bouton SOS in-app
2. Pattern volume buttons (ex: Vol+, Vol-, Vol+)
3. Shake detection (accelerometer)
4. Phrase vocale (si configuré)
5. Commande remote via WebSocket
6. Géofence spéciale

Activation :
- Notification surveillant immédiate
- Mode collecte intensive
- Bypass toutes limitations
- Priority maximum réseau
- Logs détaillés activation
```

### 5.2 Collecte intensive

**EmergencyCollector - Logique :**
```
Actions automatiques :
Location :
  - GPS haute précision
  - Update chaque 5 secondes
  - Pas de filter distance
  - Include altitude/speed

Photos :
  - Alternance front/back
  - Capture chaque 30 secondes
  - Résolution moyenne (économie)
  - Pas de flash

Audio :
  - Enregistrement continu
  - Segments de 1 minute
  - Upload immédiat
  - Compression minimale

Screenshots :
  - Si permission accordée
  - Chaque minute
  - Compression 60%

Environnement :
  - WiFi networks scan
  - Bluetooth devices
  - Niveau sonore ambiant
  - Luminosité capteur
```

### 5.3 Communication prioritaire

**Logique de transmission urgence :**
```
Canal dédié :
- WebSocket prioritaire
- Pas de rate limiting
- Reconnexion agressive
- Fallback HTTP POST
- Retry infini

Format messages :
{
  "type": "emergency",
  "severity": "CRITICAL",
  "location": {...},
  "timestamp": "...",
  "data": {
    // Données collectées
  }
}

Confirmation :
- ACK requis du serveur
- Reenvoi si pas d'ACK
- Stockage redondant local
```

## 6. Modes d'affichage

### 6.1 Mode Normal

**Interface standard :**
```
Écrans disponibles :
1. Status principal
   - État de surveillance actif/inactif
   - Dernière synchronisation
   - Utilisation batterie
   - Data usage

2. Paramètres basiques
   - Pause temporaire
   - Mode ne pas déranger
   - Notifications on/off
   - À propos

3. Urgence
   - Gros bouton SOS
   - Contacts d'urgence
   - Test du système

Design :
- Material Design standard
- Couleurs neutres
- Icônes système
- Textes clairs
```

### 6.2 Mode Discret

**Camouflage UI :**
```
Changements visuels :
- Nom : "System Service"
- Icône : Générique système
- Thème : Gris/blanc minimal
- Textes : Techniques obscurs

Notifications :
- Titre : "Service running"
- Contenu : Vide ou technique
- Icône : Android système
- Importance : LOW

Accès :
- Code dans dialer
- Long press menu caché
- Intent spécifique
```

### 6.3 Mode Invisible

**Absence totale UI :**
```
Masquage complet :
- Retrait du launcher
- Masquage des récents
- Pas de notifications
- Démarrage silencieux

Activation uniquement par :
- Code dialer : *#*#8233#*#*
- ADB command (dev)
- Commande remote
- App jumelle

Retour visible :
- Même codes d'accès
- Reset via jumelle
- Factory reset
```

## 7. Gestion de la batterie

### 7.1 Monitoring batterie

**BatteryOptimizationService :**
```
Surveillance continue :
- BatteryManager stats
- Niveau, température, santé
- Vitesse de décharge
- Temps restant estimé
- Source d'alimentation

Seuils d'action :
Level > 50% : Normal
Level 30-50% : Attention
Level 15-30% : Économie
Level 5-15% : Critique
Level < 5% : Survie

Actions automatiques :
- Ajuster fréquences
- Désactiver features
- Compression maximale
- Reports différés
```

### 7.2 Optimisations spécifiques

**Techniques d'économie :**
```
CPU :
- WakeLock minimal
- Batch processing
- Lazy initialization
- Thread pools réutilisés

Network :
- Connection pooling
- Request coalescing
- Compression adaptative
- Cache agressif

Sensors :
- Duty cycling GPS
- Passive providers
- Sensor batching
- Power-efficient mode

Storage :
- WAL mode SQLite
- Batch transactions
- Vacuum périodique
- Logs rotation
```

## 8. Sécurité locale

### 8.1 Protection des données

**Logique de sécurisation :**
```
Chiffrement local :
- SQLCipher pour DB
- AES-256 pour fichiers
- Clés dans Keystore
- IV unique par donnée

Obfuscation :
- Noms de tables aléatoires
- Colonnes encodées
- Pas de données en clair
- Métadonnées minimales

Nettoyage :
- Wipe après sync
- Secure delete
- Memory clearing
- Cache volatile
```

### 8.2 Anti-tampering

**Protection intégrité :**
```
Vérifications :
- Signature APK
- Root detection
- Debugger detection
- Emulator detection
- Hook detection

Actions si compromis :
- Log silencieux
- Notification serveur
- Mode dégradé
- Pas de données sensibles
```

## 9. Intégration native

### 9.1 Module Android (Kotlin)

**Architecture MethodChannel :**
```
Channels définis :
- sms_channel
- call_channel  
- location_channel
- media_channel
- system_channel

Méthodes exposées :
- startCollection(type, config)
- stopCollection(type)
- getLastData(type, count)
- captureMedia(type, params)
- getSystemInfo()
```

### 9.2 Module iOS (Swift)

**Intégration limitée :**
```
Fonctionnalités iOS :
- Location tracking only
- Basic device info
- Push notifications
- Limited background

Compensations :
- Notifications créatives
- Geofencing intensif
- Background fetch max
- User education
```

## 10. Logs et diagnostics

### 10.1 Système de logging

**Logique de journalisation :**
```
Niveaux adaptés :
- Production : ERROR only
- Debug : INFO et plus
- Jamais de données sensibles
- Rotation automatique

Événements loggés :
- Service lifecycle
- Collection events
- Sync status
- Errors/exceptions
- Permission changes
```

### 10.2 Diagnostics à distance

**Remote debugging :**
```
Commandes disponibles :
- Status check
- Force sync
- Clear cache
- Restart services
- Get logs (sanitized)
- Update config

Sécurité :
- Commandes signées
- Rate limited
- Audit trail
- No sensitive data
```