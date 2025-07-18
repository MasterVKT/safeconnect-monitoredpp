# Guide d'Architecture - Application Surveillée XP SafeConnect

## 1. Vue d'ensemble

### 1.1 Objectif de l'application

L'application surveillée permet :
- La collecte sécurisée de données selon les permissions accordées
- Le fonctionnement continu en arrière-plan
- La transmission optimisée vers l'appareil surveillant
- Le respect de la vie privée avec consentement explicite
- La gestion des modes d'urgence et de sécurité

### 1.2 Contraintes spécifiques

**Différences avec l'app surveillante :**
- Focus sur la collecte et non l'affichage
- Optimisation batterie critique
- Fonctionnement arrière-plan prioritaire
- Interface minimale (mode normal) ou invisible
- Services natifs Android/iOS intégrés
- Résistance aux interruptions système

### 1.3 Architecture modulaire

**Organisation en couches :**
- **Couche UI** : Minimale, configuration et statut
- **Couche Services** : Collecteurs, synchronisation, urgence
- **Couche Native** : Modules platform-specific
- **Couche Données** : Cache local, queue de sync
- **Couche Sécurité** : Chiffrement, permissions

## 2. Structure du projet

### 2.1 Organisation des dossiers

```
lib/
├── app/                         # Configuration globale
│   ├── app.dart                # Point d'entrée minimal
│   ├── constants.dart          # Constantes système
│   ├── locator.dart           # Services locator
│   └── routes.dart            # Routes limitées
│
├── core/                       # Fonctionnalités core
│   ├── collectors/            # Collecteurs de données
│   │   ├── base_collector.dart
│   │   ├── sms_collector.dart
│   │   ├── calls_collector.dart
│   │   ├── location_collector.dart
│   │   ├── apps_collector.dart
│   │   └── media_collector.dart
│   │
│   ├── services/              # Services système
│   │   ├── background_service.dart
│   │   ├── sync_service.dart
│   │   ├── notification_service.dart
│   │   ├── battery_optimization_service.dart
│   │   ├── websocket_service.dart
│   │   └── emergency_service.dart
│   │
│   ├── native/                # Bridges natifs
│   │   ├── android_bridge.dart
│   │   └── ios_bridge.dart
│   │
│   └── utils/                 # Utilitaires
│       ├── permissions_manager.dart
│       ├── device_info_utils.dart
│       └── battery_utils.dart
│
├── features/                   # Features minimales
│   ├── pairing/              # Jumelage initial
│   ├── settings/             # Configuration
│   ├── status/               # État et infos
│   └── emergency/            # Mode urgence
│
├── android/                   # Code natif Android
│   └── app/src/main/kotlin/
│       ├── collectors/       # Collecteurs natifs
│       ├── services/         # Services Android
│       └── receivers/        # Broadcast receivers
│
└── ios/                      # Code natif iOS
    └── Runner/
        ├── Collectors/       # Collecteurs Swift
        └── Services/         # Services iOS
```

## 3. Architecture des services

### 3.1 Service principal en arrière-plan

**BackgroundService - Logique d'implémentation :**
```
Responsabilités :
- Démarrage au boot de l'appareil
- Maintien actif permanent
- Orchestration des collecteurs
- Gestion des ressources
- Adaptation selon batterie
- Recovery après kill système

Implémentation Android :
- Foreground Service obligatoire
- Notification persistante (visible ou discrète)
- WakeLock partiel si nécessaire
- WorkManager pour tâches périodiques
- JobScheduler pour optimisation batterie

Implémentation iOS :
- Background modes activés
- Location updates pour maintien
- Background fetch périodique
- Silent push pour réveil
- Limitations système acceptées
```

### 3.2 Architecture des collecteurs

**BaseCollector - Abstraction commune :**
```
Interface commune :
- start() : Démarrer la collecte
- stop() : Arrêter proprement
- collect() : Collecte immédiate
- configure(settings) : Appliquer config
- getLastData() : Dernières données
- clearCache() : Nettoyer local

Logique partagée :
- Gestion des permissions
- Throttling intelligent
- Cache local SQLite
- Compression données
- Batch pour envoi
- Retry mechanism
```

### 3.3 Services natifs

**Architecture des modules natifs :**
```
Android (Kotlin) :
- MethodChannel pour communication
- Services Android natifs
- ContentObserver pour SMS/Calls
- LocationManager/FusedLocation
- UsageStatsManager pour apps
- AccessibilityService pour messageries

iOS (Swift) - Limité :
- MethodChannel communication
- CoreLocation pour GPS
- Pas d'accès SMS/Calls
- Limites Background strict
- App Groups pour partage
```

## 4. Collecteurs de données

### 4.1 SMS Collector (Android uniquement)

**Logique d'implémentation :**
```
Fonctionnement :
- ContentObserver sur SMS Provider
- Écoute changements en temps réel
- Lecture via ContentResolver
- Filtrage selon configuration
- Chiffrement immédiat
- Stockage temporaire local

Optimisations :
- Cache des derniers IDs lus
- Batch par 50 messages
- Compression avant stockage
- Nettoyage après sync
```

### 4.2 Location Collector

**Logique de tracking GPS :**
```
Stratégie adaptative :
- High accuracy en urgence
- Balanced en utilisation normale
- Low power en batterie faible
- Géofencing pour efficacité
- Significant changes iOS

Fréquences :
- Urgence : 5 secondes
- Normal : 1-5 minutes
- Eco : 15-30 minutes
- Geofence : Sur événement
```

### 4.3 Apps Collector

**Surveillance des applications :**
```
Android :
- UsageStatsManager API
- Polling périodique (5 min)
- Events pour nouvelles installs
- Temps d'utilisation détaillé
- Categories via PackageManager

iOS :
- Très limité
- Liste apps installées impossible
- Seulement notifications visibles
```

### 4.4 Media Collector

**Capture de médias à distance :**
```
Screenshots :
- MediaProjection API (Android)
- Notification obligatoire
- Compression JPEG 80%
- Résolution adaptative

Photos :
- Camera2 API sans preview
- Capture silencieuse si possible
- Front/back camera switch
- Flash désactivé

Audio :
- MediaRecorder configuration
- Compression AAC
- Durée limitée (batterie)
- Niveau sonore monitoring
```

## 5. Optimisation batterie

### 5.1 Battery Optimization Service

**Logique d'adaptation dynamique :**
```
Niveaux de batterie :
- 100-50% : Fonctionnement normal
- 50-30% : Réduction fréquences
- 30-15% : Mode économie
- 15-5% : Urgence seulement
- <5% : Survie minimale

Actions par niveau :
- Ajuster intervals collecte
- Réduire précision GPS
- Différer syncs non critiques
- Compresser plus agressivement
- Désactiver features non essentielles
```

### 5.2 Stratégies d'économie

**Techniques d'optimisation :**
```
CPU/Wake :
- Batch operations
- Éviter wake locks longs
- Utiliser AlarmManager
- Grouper network calls
- Cache agressif

Network :
- WiFi preferred
- Compression maximale
- Delta sync seulement
- Multiplexing connexions
- Backoff exponential

Storage :
- Rotation logs ancien
- Compression SQLite
- Cleanup régulier
- Limites strictes
```

## 6. Synchronisation

### 6.1 Sync Service

**Architecture de synchronisation :**
```
Queue système :
- SQLite pour persistence
- Priorités par type données
- Ordre FIFO par priorité
- Retry avec backoff
- Confirmation avant delete

Stratégies :
- Immédiat : Urgence, alerts
- Rapide : Messages, calls (5 min)
- Normal : Locations, apps (15 min)
- Différé : Media, stats (WiFi)
```

### 6.2 Transfert optimisé

**Optimisation des transferts :**
```
Compression :
- GZIP pour JSON
- JPEG quality adaptive
- Audio bitrate variable
- Chunking gros fichiers
- Resume après interruption

Protocoles :
- HTTP/2 multiplexing
- WebSocket pour temps réel
- P2P pour media si possible
- Fallback progressif
```

## 7. Modes de fonctionnement

### 7.1 Mode Normal

**Interface visible standard :**
```
Comportement :
- Icône dans launcher
- Interface minimale info/config
- Notifications visibles
- Accès aux paramètres
- Possibilité de pause

UI limitée :
- État de surveillance
- Dernière synchronisation
- Niveau batterie impact
- Bouton urgence
- Paramètres basiques
```

### 7.2 Mode Discret

**Camouflage partiel :**
```
Modifications :
- Nom app générique
- Icône système-like
- Notifications minimales
- Accès via code
- Masquage partiel

Exemples noms :
- "System Update"
- "Device Care"
- "Security Service"
```

### 7.3 Mode Invisible

**Furtivité maximale :**
```
Caractéristiques :
- Pas d'icône launcher
- Pas d'entrée récents
- Notifications cachées
- Accès code compose
- Démarrage auto boot

Activation :
- Via code *#*#CODE#*#*
- Depuis app jumelle
- Intent spécifique
```

## 8. Sécurité et permissions

### 8.1 Gestion des permissions

**PermissionsManager - Logique :**
```
Permissions critiques Android :
- READ_SMS : Messages
- READ_CALL_LOG : Appels
- ACCESS_FINE_LOCATION : GPS
- RECORD_AUDIO : Enregistrement
- CAMERA : Photos
- SYSTEM_ALERT_WINDOW : Screenshots

Stratégie demande :
- Grouper par fonction
- Expliquer utilité
- Gérer refus gracefully
- Re-demander si besoin
- Fallback si refusé
```

### 8.2 Protection anti-désinstallation

**Mécanismes de protection :**
```
Android :
- Device Admin API
- Bloquer désinstallation
- Notification tentative
- Recovery après factory reset
- Multiple APK backup

iOS :
- MDM seulement
- Restrictions limitées
- Jailbreak detection
- Backup cloud config
```

## 9. Communication temps réel

### 9.1 WebSocket Service

**Connexion permanente :**
```
Maintien connexion :
- Reconnexion auto agressive
- Heartbeat 30 secondes
- Socket pooling
- Message queue offline
- Priority channels

Commandes reçues :
- Capture immediate
- Config update
- Mode change
- Emergency trigger
- Lock/unlock device
```

### 9.2 Push notifications

**Firebase Cloud Messaging :**
```
Types messages :
- Data only (silent)
- High priority wake
- Commands encoded
- Fallback polling

Traitement :
- Background handler
- Decode command
- Execute action
- Report result
```

## 10. Interface utilisateur minimale

### 10.1 Écrans essentiels

**Configuration minimale :**
```
Écrans requis :
1. Pairing : Code entrée
2. Permissions : Guide accord
3. Status : État surveillance
4. Emergency : Bouton SOS
5. Settings : Config basique

Pas d'écrans pour :
- Données collectées
- Historiques
- Statistiques
- Détails techniques
```

### 10.2 Design discret

**Principes UI :**
```
Guidelines :
- Minimaliste extrême
- Couleurs neutres
- Pas d'animations
- Textes essentiels
- Navigation simple
- Quick actions only
```

## 11. Tests spécifiques

### 11.1 Tests d'endurance

**Validation long terme :**
```
Scénarios :
- 72h fonctionnement continu
- Battery drain mesure
- Memory leaks detection
- Storage growth check
- Network usage total
- CPU usage average
```

### 11.2 Tests de résistance

**Robustesse système :**
```
Tests kill/restart :
- Force stop app
- Reboot device
- Clear cache/data
- Airplane mode
- Extreme battery saver
- Factory reset recovery
```

## 12. Considérations légales

### 12.1 Consentement

**Gestion du consentement :**
```
Adult mode :
- Signature digitale unique
- Explication claire données
- Révocation possible
- Preuve stockée

Parental mode :
- Vérification parentale
- Pas de consentement enfant
- Restrictions légales
- Logs complets
```

### 12.2 Conformité

**Respect réglementations :**
```
Obligations :
- RGPD compliance
- Data minimization
- Purpose limitation
- Security measures
- Audit trail
- Right to deletion
```