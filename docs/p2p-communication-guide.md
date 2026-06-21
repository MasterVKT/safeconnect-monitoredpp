# Guide de Communication P2P - Entre Applications Surveillée et Surveillante

## 1. Vue d'ensemble de la communication P2P

### 1.1 Objectif
La communication P2P (Peer-to-Peer) permet le transfert direct de données volumineuses entre l'application surveillée et l'application surveillante sans transiter par le serveur backend. Cette approche est principalement utilisée pour :
- Transfert de médias (photos, screenshots, enregistrements audio)
- Réduction de la charge serveur
- Économie de bande passante
- Réduction de la latence
- Transferts plus rapides sur réseau local

### 1.2 Architecture P2P

```
Application Surveillée                    Application Surveillante
     (Émetteur)                               (Récepteur)
         |                                         |
         |---- 1. Signaling via Backend --------->|
         |<--- 2. Négociation connexion --------->|
         |                                         |
         |==== 3. Connexion P2P directe =========>|
         |==== 4. Transfert de données ==========>|
         |==== 5. Confirmation ==================>|
         |                                         |
         |---- 6. Notification Backend ---------->|
```

### 1.3 Technologies utilisées
- **WebRTC** : Pour établir la connexion P2P
- **STUN/TURN** : Pour la traversée NAT
- **WebSocket** : Pour le signaling initial
- **TLS** : Pour sécuriser les échanges

## 2. Protocole de signaling

### 2.1 Initialisation du transfert P2P

**Étape 1 : Notification de disponibilité de média**

L'application surveillée notifie le backend qu'un média est prêt pour transfert P2P.

**WebSocket Message - Surveillée → Backend :**
```json
{
  "type": "P2P_MEDIA_AVAILABLE",
  "payload": {
    "media_id": "550e8400-e29b-41d4-a716-446655440000",
    "media_type": "PHOTO",
    "file_size": 2048576,
    "mime_type": "image/jpeg",
    "checksum": "sha256:abcdef123456...",
    "thumbnail_base64": "data:image/jpeg;base64,/9j/4AAQ...",
    "capture_timestamp": "2024-01-15T10:30:00Z",
    "metadata": {
      "width": 1920,
      "height": 1080,
      "camera": "back",
      "location": {
        "latitude": 48.8566,
        "longitude": 2.3522
      }
    },
    "transfer_preferences": {
      "preferred_method": "P2P",
      "fallback_allowed": true,
      "compression_level": "medium",
      "encryption_required": true
    }
  }
}
```

**Backend → Application Surveillante :**
```json
{
  "type": "P2P_MEDIA_READY",
  "payload": {
    "device_id": "device_12345",
    "media_id": "550e8400-e29b-41d4-a716-446655440000",
    "media_info": {
      "type": "PHOTO",
      "size": 2048576,
      "thumbnail": "data:image/jpeg;base64,/9j/4AAQ..."
    },
    "transfer_token": "temp_token_xyz789",
    "expires_at": "2024-01-15T10:35:00Z"
  }
}
```

### 2.2 Négociation de connexion P2P

**Étape 2 : Demande d'établissement de connexion**

**Application Surveillante → Backend → Application Surveillée :**
```json
{
  "type": "P2P_CONNECTION_REQUEST",
  "payload": {
    "request_id": "req_123456",
    "media_id": "550e8400-e29b-41d4-a716-446655440000",
    "transfer_token": "temp_token_xyz789",
    "ice_servers": [
      {
        "urls": "stun:stun.safeconnect.com:3478",
        "username": "",
        "credential": ""
      },
      {
        "urls": "turn:turn.safeconnect.com:3478",
        "username": "user123",
        "credential": "pass456"
      }
    ]
  }
}
```

### 2.3 Échange des candidats ICE

**Étape 3 : Offer SDP**

**Application Surveillée → Backend → Application Surveillante :**
```json
{
  "type": "P2P_SDP_OFFER",
  "payload": {
    "request_id": "req_123456",
    "sdp": {
      "type": "offer",
      "sdp": "v=0\r\no=- 4611731400430051336 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n..."
    }
  }
}
```

**Étape 4 : Answer SDP**

**Application Surveillante → Backend → Application Surveillée :**
```json
{
  "type": "P2P_SDP_ANSWER",
  "payload": {
    "request_id": "req_123456",
    "sdp": {
      "type": "answer",
      "sdp": "v=0\r\no=- 4611731400430051337 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n..."
    }
  }
}
```

**Étape 5 : Candidats ICE**

**Échange bidirectionnel des candidats :**
```json
{
  "type": "P2P_ICE_CANDIDATE",
  "payload": {
    "request_id": "req_123456",
    "candidate": {
      "candidate": "candidate:842163059 1 udp 1677729535 192.168.1.100 54321 typ srflx raddr 0.0.0.0 rport 0 generation 0 ufrag EEtu network-cost 50",
      "sdpMLineIndex": 0,
      "sdpMid": "0"
    }
  }
}
```

## 3. Protocole de transfert de données P2P

### 3.1 Établissement du DataChannel

Une fois la connexion WebRTC établie, un DataChannel est créé pour le transfert de fichiers.

**Configuration DataChannel :**
```
Channel name: "media_transfer"
Ordered: true
MaxRetransmits: 3
MaxPacketLifeTime: null
Protocol: "binary"
Negotiated: false
```

### 3.2 Protocole de transfert

**Message de début de transfert :**
```json
{
  "type": "TRANSFER_START",
  "media_id": "550e8400-e29b-41d4-a716-446655440000",
  "total_chunks": 256,
  "chunk_size": 8192,
  "total_size": 2048576,
  "checksum": "sha256:abcdef123456...",
  "encryption": {
    "algorithm": "AES-256-GCM",
    "key_derivation": "PBKDF2",
    "iv": "base64_encoded_iv"
  }
}
```

**Format des chunks de données :**
```
[4 bytes: chunk_index][4 bytes: chunk_size][N bytes: encrypted_data][32 bytes: chunk_hash]
```

**Message de progression :**
```json
{
  "type": "TRANSFER_PROGRESS",
  "chunks_received": 128,
  "total_chunks": 256,
  "bytes_received": 1048576,
  "total_bytes": 2048576,
  "percentage": 50,
  "speed_bps": 524288
}
```

**Message de fin de transfert :**
```json
{
  "type": "TRANSFER_COMPLETE",
  "media_id": "550e8400-e29b-41d4-a716-446655440000",
  "final_checksum": "sha256:abcdef123456...",
  "duration_ms": 4523,
  "average_speed_bps": 453232
}
```

### 3.3 Gestion des erreurs

**Message d'erreur pendant le transfert :**
```json
{
  "type": "TRANSFER_ERROR",
  "error_code": "CHECKSUM_MISMATCH",
  "error_message": "Chunk 156 checksum verification failed",
  "chunk_index": 156,
  "retry_possible": true,
  "fallback_available": true
}

// Codes d'erreur possibles :
// - CONNECTION_LOST : Connexion P2P perdue
// - CHECKSUM_MISMATCH : Erreur d'intégrité
// - TIMEOUT : Timeout pendant le transfert
// - STORAGE_FULL : Espace insuffisant
// - DECRYPTION_FAILED : Échec du déchiffrement
// - CANCELLED : Transfert annulé
```

### 3.4 Mécanisme de retry

**Demande de retransmission de chunks :**
```json
{
  "type": "CHUNK_RETRY_REQUEST",
  "missing_chunks": [156, 157, 203],
  "reason": "CHECKSUM_MISMATCH"
}
```

## 4. Sécurité du transfert P2P

### 4.1 Authentification mutuelle

**Vérification d'identité avant transfert :**
```json
{
  "type": "P2P_AUTH_CHALLENGE",
  "challenge": "random_nonce_abc123",
  "timestamp": "2024-01-15T10:30:00Z"
}

{
  "type": "P2P_AUTH_RESPONSE",
  "response": "HMAC-SHA256(challenge + shared_secret + timestamp)",
  "device_id": "device_12345"
}
```

### 4.2 Chiffrement des données

**Négociation des clés de session :**
```json
{
  "type": "KEY_EXCHANGE",
  "public_key": "base64_encoded_public_key",
  "key_algorithm": "ECDH-P256",
  "supported_ciphers": ["AES-256-GCM", "AES-128-GCM", "ChaCha20-Poly1305"]
}
```

**Dérivation de la clé de session :**
```
1. ECDH key agreement → shared_secret
2. session_key = HKDF(shared_secret, salt="SafeConnect_P2P_v1", info=context)
3. encryption_key = session_key[0:32]
4. mac_key = session_key[32:64]
```

## 5. Implémentation côté Application Surveillée

### 5.1 Service P2P Flutter

**Logique d'implémentation du P2PTransferService :**

```dart
class P2PTransferService {
  // Configuration WebRTC
  final Map<String, dynamic> rtcConfiguration = {
    'iceServers': [],
    'sdpSemantics': 'unified-plan',
  };
  
  // Méthodes principales :
  
  // 1. Initialiser une offre de transfert
  Future<void> initializeTransfer(MediaFile media) async {
    // - Notifier le backend via WebSocket
    // - Attendre la demande de connexion
    // - Créer PeerConnection
    // - Créer DataChannel
    // - Générer SDP offer
  }
  
  // 2. Gérer la connexion entrante
  Future<void> handleConnectionRequest(Map<String, dynamic> request) async {
    // - Valider le token de transfert
    // - Configurer ICE servers
    // - Créer PeerConnection
    // - Attendre SDP offer
    // - Créer SDP answer
  }
  
  // 3. Envoyer le fichier
  Future<void> sendFile(File mediaFile, String mediaId) async {
    // - Lire le fichier par chunks
    // - Chiffrer chaque chunk
    // - Envoyer via DataChannel
    // - Gérer la progression
    // - Vérifier les ACK
  }
  
  // 4. Gérer les erreurs et retry
  void handleTransferError(String errorCode, int chunkIndex) {
    // - Logger l'erreur
    // - Tenter retry si possible
    // - Fallback vers serveur si échec
  }
}
```

### 5.2 Intégration native Android

**P2P natif pour performances optimales :**

```kotlin
// MethodChannel pour contrôle depuis Flutter
class P2PNativeHandler(private val context: Context) {
    
    fun setupPeerConnection(config: Map<String, Any>): PeerConnection {
        // Initialiser WebRTC natif
        // Meilleure performance pour gros fichiers
        // Gestion mémoire optimisée
    }
    
    fun sendFileNative(filePath: String, chunkSize: Int) {
        // Lecture fichier optimisée
        // Streaming sans charger en mémoire
        // Chiffrement par chunks
    }
}
```

## 6. Implémentation côté Application Surveillante

### 6.1 Réception P2P

**Logique de réception des médias :**

```dart
class P2PReceiveService {
  // Buffer pour reconstruction du fichier
  final Map<int, Uint8List> chunkBuffer = {};
  
  // Méthodes principales :
  
  // 1. Demander un transfert
  Future<void> requestMediaTransfer(String mediaId, String deviceId) async {
    // - Vérifier la disponibilité du média
    // - Envoyer P2P_CONNECTION_REQUEST
    // - Attendre SDP offer
    // - Répondre avec SDP answer
  }
  
  // 2. Recevoir les chunks
  void onDataChannelMessage(dynamic data) {
    // - Parser le header du chunk
    // - Vérifier l'intégrité
    // - Stocker dans le buffer
    // - Envoyer ACK
    // - Reconstruire si complet
  }
  
  // 3. Reconstruire le fichier
  Future<File> reconstructFile(String mediaId) async {
    // - Vérifier tous les chunks reçus
    // - Déchiffrer les données
    // - Assembler le fichier
    // - Vérifier checksum final
    // - Sauvegarder localement
  }
}
```

## 7. Fallback et gestion d'erreurs

### 7.1 Stratégie de fallback

**Quand basculer vers le serveur :**
```
1. Échec établissement connexion P2P après 30 secondes
2. Plus de 3 erreurs de transfert consécutives
3. Vitesse de transfert < 10 KB/s pendant 1 minute
4. Demande explicite de l'utilisateur
5. Restrictions réseau détectées (firewall d'entreprise)
```

### 7.2 Message de fallback

**Notification de bascule vers serveur :**
```json
{
  "type": "P2P_FALLBACK_TO_SERVER",
  "media_id": "550e8400-e29b-41d4-a716-446655440000",
  "reason": "CONNECTION_FAILED",
  "attempts": 3,
  "fallback_url": "https://api.safeconnect.com/media/upload/550e8400-e29b-41d4-a716-446655440000"
}
```

## 8. Monitoring et métriques

### 8.1 Métriques de transfert P2P

**Données à collecter :**
```json
{
  "transfer_id": "transfer_789",
  "media_id": "550e8400-e29b-41d4-a716-446655440000",
  "start_time": "2024-01-15T10:30:00Z",
  "end_time": "2024-01-15T10:30:45Z",
  "duration_seconds": 45,
  "bytes_transferred": 2048576,
  "average_speed_kbps": 364,
  "peak_speed_kbps": 512,
  "connection_setup_time_ms": 2300,
  "retry_count": 1,
  "packet_loss_percentage": 0.05,
  "success": true,
  "fallback_used": false
}
```

## 9. Configuration et optimisations

### 9.1 Paramètres configurables

**Configuration P2P par défaut :**
```json
{
  "p2p_config": {
    "enabled": true,
    "chunk_size": 8192,
    "max_concurrent_transfers": 3,
    "connection_timeout_seconds": 30,
    "transfer_timeout_seconds": 300,
    "retry_attempts": 3,
    "min_speed_threshold_kbps": 10,
    "prefer_local_network": true,
    "compression": {
      "enabled": true,
      "level": "medium",
      "algorithms": ["gzip", "zstd"]
    },
    "encryption": {
      "algorithm": "AES-256-GCM",
      "key_exchange": "ECDH-P256"
    }
  }
}
```

### 9.2 Optimisations réseau local

**Détection et préférence réseau local :**
```
1. Vérifier si les deux appareils sont sur le même subnet
2. Utiliser mDNS/Bonjour pour découverte locale
3. Prioriser les candidats ICE locaux
4. Désactiver TURN si connexion locale établie
5. Augmenter chunk_size pour LAN (32KB)
```

## 10. Exemples d'utilisation

### 10.1 Transfert réussi de photo

**Séquence complète :**
```
1. App surveillée capture photo (2MB)
2. Notification P2P_MEDIA_AVAILABLE au backend
3. Backend notifie app surveillante
4. App surveillante demande transfert
5. Négociation WebRTC (2.3 secondes)
6. Transfert P2P démarré
7. 256 chunks transférés en 45 secondes
8. Vérification checksum OK
9. Photo sauvegardée et affichée
10. Confirmation au backend
```

### 10.2 Échec avec fallback serveur

**Gestion d'échec réseau :**
```
1. Tentative connexion P2P
2. Timeout après 30 secondes (firewall)
3. Notification P2P_FALLBACK_TO_SERVER
4. Upload via HTTPS au serveur
5. Serveur notifie app surveillante
6. Download HTTPS classique
7. Succès via méthode alternative
```

Cette documentation complète permet à un développeur (ou un modèle de langage) d'implémenter la communication P2P entre les deux applications de manière cohérente et sécurisée.