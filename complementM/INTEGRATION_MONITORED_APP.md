# Guide d'Intégration - Application Surveillée (Monitored App)

**Version**: 1.0
**Date**: Janvier 2025
**Backend API**: XP SafeConnect v1

---

## ⚠️ Important : Système de Surveillance Générique

**XP SafeConnect est un système de surveillance générique** qui peut être utilisé dans différents contextes légaux avec consentement :

- 👨‍👩‍👧 **Contrôle parental** : Appareil de l'enfant surveillé par le parent
- 💼 **Gestion professionnelle** : Appareil professionnel surveillé par l'employeur
- 👴 **Assistance médicale** : Appareil surveillé pour raisons de sécurité/santé
- 🔒 **Autres cas d'usage** avec consentement approprié

**Terminologie utilisée dans ce guide :**

- **"Utilisateur surveillant" / "Appareil surveillant"** → USER_TYPE='MONITOR' (celui qui surveille)
- **"Utilisateur surveillé" / "Appareil surveillé"** → USER_TYPE='MONITORED' (celui qui est surveillé)

Les exemples peuvent illustrer un cas parent-enfant, mais **le système et le code sont totalement génériques**.

---

## 📱 Vue d'Ensemble

Ce guide détaillé explique comment intégrer l'**application surveillée** avec le backend XP SafeConnect.

Cette application collecte les données et exécute les commandes reçues de l'appareil surveillant.

### Caractéristiques de l'Application Surveillée

- **Utilisateur**: Personne surveillée (USER_TYPE='MONITORED')
- **Rôle**: Collecter et envoyer les données au backend
- **Fonctionnalités principales**:
  - Enregistrement et couplage avec l'appareil surveillant
  - Collecte automatique des données (localisation, appels, messages, usage apps)
  - Réception des commandes à distance (capture, verrouillage, rafraîchissement)
  - Mode urgence
  - Services en arrière-plan pour la surveillance continue

---

## 🔧 Configuration Initiale

### 1. Dépendances Flutter

Ajoutez ces packages dans `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP & API
  dio: ^5.4.0

  # Stockage sécurisé
  flutter_secure_storage: ^9.0.0

  # Notifications Push (FCM)
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9

  # Permissions
  permission_handler: ^11.1.0

  # Localisation
  geolocator: ^10.1.0

  # Téléphonie (appels, SMS)
  call_log: ^4.0.0
  sms_maintained: ^1.0.0

  # Usage des applications
  app_usage: ^3.0.0
  device_apps: ^2.2.0

  # Services en arrière-plan
  workmanager: ^0.5.1

  # État
  provider: ^6.1.1

  # QR Code (pour le couplage)
  mobile_scanner: ^3.5.5

  # Images & Médias
  camera: ^0.10.5+7
  image_picker: ^1.0.5
```

### 2. Configuration Firebase

Créez un fichier `lib/core/config/firebase_config.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Demander la permission pour les notifications
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  static Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
```

### 3. Configuration API Client

Créez `lib/core/api/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String BASE_URL = 'https://api.xpsafeconnect.com/api/v1';

  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() : dio = Dio(BaseOptions(
    baseUrl: BASE_URL,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ajouter le token JWT
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Gérer le refresh du token si 401
        if (error.response?.statusCode == 401) {
          final newToken = await _refreshToken();
          if (newToken != null) {
            // Retry la requête avec le nouveau token
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            return handler.resolve(await dio.fetch(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      final response = await dio.post(
        '/users/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'];
      await _storage.write(key: 'access_token', value: newAccessToken);

      return newAccessToken;
    } catch (e) {
      print('Token refresh failed: $e');
      return null;
    }
  }
}
```

---

## 🔐 1. Authentification & Enregistrement

### 1.1 Enregistrement de l'Appareil Surveillé

L'appareil surveillé doit être enregistré avec `user_type='MONITORED'`.

Créez `lib/features/auth/data/repositories/auth_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  /// Enregistrement d'un appareil surveillé
  Future<RegisterResponse> registerMonitoredDevice({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/users/register/',
        data: {
          'email': email,
          'password': password,
          'password_confirm': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'user_type': 'MONITORED', // Important: Type surveillé
        },
      );

      // Sauvegarder les tokens
      await _storage.write(key: 'access_token', value: response.data['access']);
      await _storage.write(key: 'refresh_token', value: response.data['refresh']);
      await _storage.write(key: 'user_id', value: response.data['user']['id'].toString());

      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Connexion
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/users/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      await _storage.write(key: 'access_token', value: response.data['access']);
      await _storage.write(key: 'refresh_token', value: response.data['refresh']);
      await _storage.write(key: 'user_id', value: response.data['user']['id'].toString());

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');

      await _apiClient.dio.post(
        '/users/logout/',
        data: {'refresh': refreshToken},
      );

      // Nettoyer le stockage local
      await _storage.deleteAll();
    } catch (e) {
      print('Logout error: $e');
      await _storage.deleteAll();
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'];
      }
      return 'Erreur: ${error.response!.statusCode}';
    }
    return 'Erreur de connexion';
  }
}

class RegisterResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  RegisterResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      accessToken: json['access'],
      refreshToken: json['refresh'],
      user: User.fromJson(json['user']),
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access'],
      refreshToken: json['refresh'],
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      userType: json['userType'],
    );
  }
}
```

---

## 📱 2. Couplage de l'Appareil

### 2.1 Enregistrement de l'Appareil

Après l'authentification, l'appareil doit s'enregistrer dans le système.

Créez `lib/features/devices/data/repositories/device_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/firebase_config.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  /// Enregistrer cet appareil dans le backend
  Future<Device> registerDevice({
    required String deviceName,
  }) async {
    try {
      // Récupérer les infos de l'appareil
      final deviceInfo = await _getDeviceInfo();
      final fcmToken = await FirebaseConfig.getFCMToken();

      final response = await _apiClient.dio.post(
        '/devices/',
        data: {
          'device_name': deviceName,
          'device_model': deviceInfo['model'],
          'os_version': deviceInfo['osVersion'],
          'app_version': deviceInfo['appVersion'],
          'fcm_token': fcmToken,
        },
      );

      return Device.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupérer les informations de cet appareil
  Future<Device> getMyDevice() async {
    try {
      final response = await _apiClient.dio.get('/devices/my_device/');
      return Device.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mettre à jour le token FCM
  Future<void> updateFCMToken(String fcmToken) async {
    try {
      final device = await getMyDevice();

      await _apiClient.dio.patch(
        '/devices/${device.id}/',
        data: {'fcm_token': fcmToken},
      );
    } catch (e) {
      print('FCM token update error: $e');
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String model = 'Unknown';
    String osVersion = 'Unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.model ?? 'iPhone';
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      print('Device info error: $e');
    }

    return {
      'model': model,
      'osVersion': osVersion,
      'appVersion': packageInfo.version,
    };
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'];
      }
      return 'Erreur: ${error.response!.statusCode}';
    }
    return 'Erreur de connexion';
  }
}

class Device {
  final int id;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final String? fcmToken;
  final bool isActive;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    this.fcmToken,
    required this.isActive,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      deviceName: json['deviceName'],
      deviceModel: json['deviceModel'],
      osVersion: json['osVersion'],
      fcmToken: json['fcmToken'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

### 2.2 Couplage avec Appareil Surveillant (Code de Couplage)

L'appareil surveillé doit générer un code de couplage que le parent utilisera.

```dart
class PairingRepository {
  final ApiClient _apiClient;

  PairingRepository(this._apiClient);

  /// Générer un code de couplage pour cet appareil
  Future<PairingCode> generatePairingCode() async {
    try {
      final response = await _apiClient.dio.post('/devices/generate_pairing_code/');

      return PairingCode(
        code: response.data['pairingCode'],
        expiresAt: DateTime.parse(response.data['expiresAt']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Vérifier le statut du couplage
  Future<bool> isPaired() async {
    try {
      final response = await _apiClient.dio.get('/devices/pairing_status/');
      return response.data['isPaired'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les appareils qui surveillent cet appareil
  Future<List<MonitoringDevice>> getMonitoringDevices() async {
    try {
      final response = await _apiClient.dio.get('/devices/monitoring_devices/');

      return (response.data as List)
          .map((json) => MonitoringDevice.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting monitoring devices: $e');
      return [];
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      return error.response!.data['detail'] ?? 'Erreur ${error.response!.statusCode}';
    }
    return 'Erreur de connexion';
  }
}

class PairingCode {
  final String code;
  final DateTime expiresAt;

  PairingCode({required this.code, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class MonitoringDevice {
  final int id;
  final String deviceName;
  final String ownerName;
  final String permissionType;

  MonitoringDevice({
    required this.id,
    required this.deviceName,
    required this.ownerName,
    required this.permissionType,
  });

  factory MonitoringDevice.fromJson(Map<String, dynamic> json) {
    return MonitoringDevice(
      id: json['id'],
      deviceName: json['deviceName'],
      ownerName: json['ownerName'],
      permissionType: json['permissionType'],
    );
  }
}
```

**Exemple d'interface de couplage:**

```dart
class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final PairingRepository _pairingRepo = PairingRepository(ApiClient());
  PairingCode? _pairingCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);

    try {
      final code = await _pairingRepo.generatePairingCode();
      setState(() {
        _pairingCode = code;
        _isLoading = false;
      });

      // Auto-refresh si expiré
      Future.delayed(code.expiresAt.difference(DateTime.now()), () {
        if (mounted && _pairingCode != null && _pairingCode!.isExpired) {
          _generateCode();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Couplage avec Parent')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _pairingCode != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Code de Couplage',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _pairingCode!.code,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Valide jusqu\'à ${DateFormat('HH:mm:ss').format(_pairingCode!.expiresAt)}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 40),
                      Text(
                        'Entrez ce code dans l\'application Parent',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _generateCode,
                        child: Text('Régénérer le Code'),
                      ),
                    ],
                  )
                : Text('Erreur de génération du code'),
      ),
    );
  }
}
```

---

## 📍 3. Collecte et Envoi de la Localisation

### 3.1 Service de Localisation en Arrière-Plan

Créez `lib/features/location/data/repositories/location_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/api/api_client.dart';

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository(this._apiClient);

  /// Envoyer la position actuelle au backend
  Future<void> sendLocation(Position position) async {
    try {
      await _apiClient.dio.post(
        '/location/update/',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
        },
      );
    } on DioException catch (e) {
      print('Location send error: $e');
      // Ne pas bloquer si échec - retry plus tard
    }
  }

  /// Récupérer et envoyer la position en une seule action
  Future<void> collectAndSendLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print('Location permission denied');
        return;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Envoyer au backend
      await sendLocation(position);
    } catch (e) {
      print('Location collection error: $e');
    }
  }
}
```

### 3.2 Service en Arrière-Plan pour la Localisation

Utilisez `workmanager` pour la collecte périodique.

Créez `lib/core/services/background_location_service.dart`:

```dart
import 'package:workmanager/workmanager.dart';
import '../../features/location/data/repositories/location_repository.dart';
import '../api/api_client.dart';

class BackgroundLocationService {
  static const String LOCATION_TASK = "locationCollectionTask";

  /// Initialiser le service en arrière-plan
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Démarrer la collecte périodique (toutes les 15 minutes)
  static Future<void> startPeriodicCollection() async {
    await Workmanager().registerPeriodicTask(
      LOCATION_TASK,
      LOCATION_TASK,
      frequency: Duration(minutes: 15), // Minimum autorisé par Android
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Arrêter la collecte
  static Future<void> stopPeriodicCollection() async {
    await Workmanager().cancelByUniqueName(LOCATION_TASK);
  }
}

/// Callback exécuté en arrière-plan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == BackgroundLocationService.LOCATION_TASK) {
        final apiClient = ApiClient();
        final locationRepo = LocationRepository(apiClient);

        await locationRepo.collectAndSendLocation();
      }
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}
```

**Démarrage du service dans l'app:**

```dart
// Dans main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await FirebaseConfig.initialize();

  // Initialiser le service de localisation en arrière-plan
  await BackgroundLocationService.initialize();
  await BackgroundLocationService.startPeriodicCollection();

  runApp(MyApp());
}
```

---

## 📞 4. Collecte des Appels et Messages

### 4.1 Repository pour Appels

Créez `lib/features/calls/data/repositories/calls_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:call_log/call_log.dart';
import '../../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CallsRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CallsRepository(this._apiClient);

  /// Collecter et envoyer les appels récents
  Future<void> syncCallHistory() async {
    try {
      // Récupérer la dernière date de sync
      final lastSyncStr = await _storage.read(key: 'last_call_sync');
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : DateTime.now().subtract(Duration(days: 7));

      // Récupérer les appels depuis la dernière sync
      Iterable<CallLogEntry> entries = await CallLog.get();

      // Filtrer les appels récents
      final recentCalls = entries.where((call) {
        final callDate = DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0);
        return callDate.isAfter(lastSync);
      }).toList();

      if (recentCalls.isEmpty) {
        print('No new calls to sync');
        return;
      }

      // Préparer les données
      final callsData = recentCalls.map((call) => {
        'contact_name': call.name ?? 'Inconnu',
        'phone_number': call.number ?? '',
        'call_type': _mapCallType(call.callType),
        'duration': call.duration ?? 0,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0).toIso8601String(),
      }).toList();

      // Envoyer au backend
      await _apiClient.dio.post(
        '/calls/sync/',
        data: {'calls': callsData},
      );

      // Mettre à jour la dernière sync
      await _storage.write(key: 'last_call_sync', value: DateTime.now().toIso8601String());

      print('Synced ${callsData.length} calls');
    } on DioException catch (e) {
      print('Call sync error: $e');
    }
  }

  String _mapCallType(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return 'INCOMING';
      case CallType.outgoing:
        return 'OUTGOING';
      case CallType.missed:
        return 'MISSED';
      case CallType.rejected:
        return 'REJECTED';
      default:
        return 'UNKNOWN';
    }
  }
}
```

### 4.2 Repository pour Messages

Créez `lib/features/messages/data/repositories/messages_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:sms_maintained/sms.dart';
import '../../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MessagesRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  MessagesRepository(this._apiClient);

  /// Collecter et envoyer les messages récents
  Future<void> syncMessages() async {
    try {
      // Récupérer la dernière date de sync
      final lastSyncStr = await _storage.read(key: 'last_message_sync');
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : DateTime.now().subtract(Duration(days: 7));

      // Récupérer les messages
      SmsQuery query = SmsQuery();
      List<SmsMessage> messages = await query.querySms(
        kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
      );

      // Filtrer les messages récents
      final recentMessages = messages.where((msg) {
        return msg.date != null && msg.date!.isAfter(lastSync);
      }).toList();

      if (recentMessages.isEmpty) {
        print('No new messages to sync');
        return;
      }

      // Préparer les données
      final messagesData = recentMessages.map((msg) => {
        'contact_name': msg.address ?? 'Inconnu',
        'phone_number': msg.address ?? '',
        'message_type': msg.kind == SmsMessageKind.sent ? 'SENT' : 'RECEIVED',
        'content': msg.body ?? '',
        'timestamp': msg.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
      }).toList();

      // Envoyer au backend
      await _apiClient.dio.post(
        '/messages/sync/',
        data: {'messages': messagesData},
      );

      // Mettre à jour la dernière sync
      await _storage.write(key: 'last_message_sync', value: DateTime.now().toIso8601String());

      print('Synced ${messagesData.length} messages');
    } on DioException catch (e) {
      print('Message sync error: $e');
    }
  }
}
```

### 4.3 Service en Arrière-Plan pour Appels & Messages

Ajoutez ces tâches dans `workmanager`:

```dart
class BackgroundSyncService {
  static const String CALLS_SYNC_TASK = "callsSyncTask";
  static const String MESSAGES_SYNC_TASK = "messagesSyncTask";

  /// Démarrer la sync périodique des appels
  static Future<void> startCallsSync() async {
    await Workmanager().registerPeriodicTask(
      CALLS_SYNC_TASK,
      CALLS_SYNC_TASK,
      frequency: Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Démarrer la sync périodique des messages
  static Future<void> startMessagesSync() async {
    await Workmanager().registerPeriodicTask(
      MESSAGES_SYNC_TASK,
      MESSAGES_SYNC_TASK,
      frequency: Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

/// Mettre à jour le callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final apiClient = ApiClient();

      switch (task) {
        case BackgroundLocationService.LOCATION_TASK:
          final locationRepo = LocationRepository(apiClient);
          await locationRepo.collectAndSendLocation();
          break;

        case BackgroundSyncService.CALLS_SYNC_TASK:
          final callsRepo = CallsRepository(apiClient);
          await callsRepo.syncCallHistory();
          break;

        case BackgroundSyncService.MESSAGES_SYNC_TASK:
          final messagesRepo = MessagesRepository(apiClient);
          await messagesRepo.syncMessages();
          break;
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}
```

---

## 📱 5. Collecte de l'Usage des Applications

### 5.1 Repository pour Usage Apps

Créez `lib/features/app_usage/data/repositories/app_usage_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:app_usage/app_usage.dart';
import 'package:device_apps/device_apps.dart';
import '../../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppUsageRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppUsageRepository(this._apiClient);

  /// Collecter et envoyer l'usage des apps
  Future<void> syncAppUsage() async {
    try {
      // Récupérer la dernière sync
      final lastSyncStr = await _storage.read(key: 'last_app_usage_sync');
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : DateTime.now().subtract(Duration(days: 1));

      // Récupérer l'usage des apps
      DateTime endDate = DateTime.now();
      List<AppUsageInfo> usageStats = await AppUsage().getAppUsage(lastSync, endDate);

      if (usageStats.isEmpty) {
        print('No app usage to sync');
        return;
      }

      // Préparer les données
      final usageData = usageStats.map((usage) => {
        'app_name': usage.appName,
        'package_name': usage.packageName,
        'usage_duration': usage.usage.inSeconds,
        'date': endDate.toIso8601String().split('T')[0], // Date only
      }).toList();

      // Envoyer au backend
      await _apiClient.dio.post(
        '/app-usage/sync/',
        data: {'usage': usageData},
      );

      // Mettre à jour la dernière sync
      await _storage.write(key: 'last_app_usage_sync', value: endDate.toIso8601String());

      print('Synced ${usageData.length} app usage records');
    } on DioException catch (e) {
      print('App usage sync error: $e');
    }
  }

  /// Récupérer la liste des apps installées
  Future<List<Application>> getInstalledApps() async {
    return await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
  }
}
```

### 5.2 Service en Arrière-Plan pour Usage Apps

Ajoutez la tâche dans workmanager:

```dart
class BackgroundSyncService {
  static const String APP_USAGE_SYNC_TASK = "appUsageSyncTask";

  static Future<void> startAppUsageSync() async {
    await Workmanager().registerPeriodicTask(
      APP_USAGE_SYNC_TASK,
      APP_USAGE_SYNC_TASK,
      frequency: Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

// Mettre à jour le dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final apiClient = ApiClient();

      switch (task) {
        // ... autres tasks

        case BackgroundSyncService.APP_USAGE_SYNC_TASK:
          final appUsageRepo = AppUsageRepository(apiClient);
          await appUsageRepo.syncAppUsage();
          break;
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}
```

---

## 🎥 6. Capture de Médias à Distance

### 6.1 Gestion des Notifications FCM

L'appareil surveillé reçoit des commandes via FCM.

Créez `lib/core/services/fcm_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/media/presentation/handlers/media_capture_handler.dart';
import '../../features/location/data/repositories/location_repository.dart';
import '../../features/devices/presentation/handlers/device_lock_handler.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialiser FCM et configurer les handlers
  static Future<void> initialize() async {
    // Demander la permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler pour messages en avant-plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handler pour messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handler quand l'app est ouverte via une notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.data}');
    _processCommand(message.data);
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
    _processCommand(message.data);
  }

  static Future<void> _processCommand(Map<String, dynamic> data) async {
    final commandType = data['type'];

    switch (commandType) {
      case 'SCREENSHOT_REQUEST':
        await MediaCaptureHandler.handleScreenshotRequest(data);
        break;

      case 'PHOTO_REQUEST':
        await MediaCaptureHandler.handlePhotoRequest(data);
        break;

      case 'AUDIO_REQUEST':
        await MediaCaptureHandler.handleAudioRequest(data);
        break;

      case 'LOCATION_REFRESH':
        await LocationRepository(ApiClient()).collectAndSendLocation();
        break;

      case 'REMOTE_LOCK_REQUEST':
        await DeviceLockHandler.lockDevice(data);
        break;

      case 'REMOTE_UNLOCK_REQUEST':
        await DeviceLockHandler.unlockDevice(data);
        break;

      case 'SYNC_TRIGGER':
        await _triggerFullSync();
        break;

      default:
        print('Unknown command type: $commandType');
    }
  }

  static Future<void> _triggerFullSync() async {
    final apiClient = ApiClient();

    // Sync tout
    await LocationRepository(apiClient).collectAndSendLocation();
    await CallsRepository(apiClient).syncCallHistory();
    await MessagesRepository(apiClient).syncMessages();
    await AppUsageRepository(apiClient).syncAppUsage();
  }
}

/// Handler pour messages en arrière-plan (doit être top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.data}');
  await FCMService._processCommand(message.data);
}
```

### 6.2 Handler pour Capture de Médias

Créez `lib/features/media/presentation/handlers/media_capture_handler.dart`:

```dart
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/api/api_client.dart';

class MediaCaptureHandler {
  static final ApiClient _apiClient = ApiClient();

  /// Gérer une requête de screenshot
  static Future<void> handleScreenshotRequest(Map<String, dynamic> data) async {
    try {
      final requestId = data['request_id'];

      // Sur Android, utiliser un service natif pour capturer l'écran
      // (Nécessite permissions spéciales - MediaProjection API)
      // Pour iOS, impossible sans jailbreak

      // Notification que la capture a échoué ou est non supportée
      await _notifyCaptureStatus(requestId, 'SCREENSHOT', 'FAILED',
        reason: 'Screenshot non supporté sur cet appareil');
    } catch (e) {
      print('Screenshot error: $e');
    }
  }

  /// Gérer une requête de photo
  static Future<void> handlePhotoRequest(Map<String, dynamic> data) async {
    try {
      final requestId = data['request_id'];
      final camera = data['camera'] ?? 'FRONT'; // FRONT or BACK

      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      CameraDescription? selectedCamera;

      if (camera == 'FRONT') {
        selectedCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } else {
        selectedCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      // Initialiser la caméra
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      // Attendre un peu pour la mise au point
      await Future.delayed(Duration(milliseconds: 500));

      // Capturer la photo
      final XFile photo = await controller.takePicture();

      // Envoyer la photo au backend
      await _uploadMedia(requestId, 'PHOTO', File(photo.path));

      // Libérer la caméra
      await controller.dispose();

      // Supprimer le fichier temporaire
      await File(photo.path).delete();

    } catch (e) {
      print('Photo capture error: $e');
      final requestId = data['request_id'];
      await _notifyCaptureStatus(requestId, 'PHOTO', 'FAILED', reason: e.toString());
    }
  }

  /// Gérer une requête d'enregistrement audio
  static Future<void> handleAudioRequest(Map<String, dynamic> data) async {
    try {
      final requestId = data['request_id'];
      final durationSeconds = data['duration'] ?? 30; // Durée par défaut 30s

      // Initialiser le recorder
      final recorder = Record();

      // Vérifier les permissions
      if (!await recorder.hasPermission()) {
        await _notifyCaptureStatus(requestId, 'AUDIO', 'FAILED',
          reason: 'Permission audio refusée');
        return;
      }

      // Créer un fichier temporaire
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Démarrer l'enregistrement
      await recorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc,
      );

      // Attendre la durée spécifiée
      await Future.delayed(Duration(seconds: durationSeconds));

      // Arrêter l'enregistrement
      await recorder.stop();

      // Envoyer l'audio au backend
      await _uploadMedia(requestId, 'AUDIO', File(filePath));

      // Supprimer le fichier temporaire
      await File(filePath).delete();

    } catch (e) {
      print('Audio capture error: $e');
      final requestId = data['request_id'];
      await _notifyCaptureStatus(requestId, 'AUDIO', 'FAILED', reason: e.toString());
    }
  }

  /// Upload du média au backend
  static Future<void> _uploadMedia(String requestId, String mediaType, File file) async {
    try {
      // Préparer le FormData
      final formData = FormData.fromMap({
        'request_id': requestId,
        'media_type': mediaType,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      // Envoyer au backend
      await _apiClient.dio.post(
        '/media/upload_capture/',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      print('Media uploaded successfully: $mediaType');
    } catch (e) {
      print('Media upload error: $e');
      await _notifyCaptureStatus(requestId, mediaType, 'FAILED', reason: 'Upload failed');
    }
  }

  /// Notifier le backend du statut de la capture
  static Future<void> _notifyCaptureStatus(
    String requestId,
    String mediaType,
    String status, {
    String? reason,
  }) async {
    try {
      await _apiClient.dio.post(
        '/media/capture_status/',
        data: {
          'request_id': requestId,
          'status': status,
          'reason': reason,
        },
      );
    } catch (e) {
      print('Status notification error: $e');
    }
  }
}
```

---

## 🔒 7. Gestion du Verrouillage à Distance

### 7.1 Handler pour Lock/Unlock

Créez `lib/features/devices/presentation/handlers/device_lock_handler.dart`:

```dart
import 'package:flutter/services.dart';

class DeviceLockHandler {
  static const platform = MethodChannel('com.xpsafeconnect.monitored/device_lock');

  /// Verrouiller l'appareil
  static Future<void> lockDevice(Map<String, dynamic> data) async {
    try {
      // Afficher un overlay de verrouillage personnalisé
      // Pour un vrai verrouillage système, nécessite des permissions admin

      await platform.invokeMethod('lockDevice', {
        'message': data['message'] ?? 'Appareil verrouillé par un parent',
      });

      print('Device locked');
    } catch (e) {
      print('Lock device error: $e');
    }
  }

  /// Déverrouiller l'appareil
  static Future<void> unlockDevice(Map<String, dynamic> data) async {
    try {
      await platform.invokeMethod('unlockDevice');
      print('Device unlocked');
    } catch (e) {
      print('Unlock device error: $e');
    }
  }
}
```

**Implémentation native Android (Kotlin):**

Dans `android/app/src/main/kotlin/com/xpsafeconnect/monitored/MainActivity.kt`:

```kotlin
package com.xpsafeconnect.monitored

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.xpsafeconnect.monitored/device_lock"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockDevice" -> {
                    if (devicePolicyManager.isAdminActive(adminComponent)) {
                        devicePolicyManager.lockNow()
                        result.success(true)
                    } else {
                        result.error("NO_ADMIN", "Device admin not active", null)
                    }
                }
                "unlockDevice" -> {
                    // Unlock se fait en supprimant l'overlay ou en réinitialisant le password
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

---

## 🚨 8. Mode Urgence

### 8.1 Repository pour Mode Urgence

Créez `lib/features/emergency/data/repositories/emergency_repository.dart`:

```dart
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class EmergencyRepository {
  final ApiClient _apiClient;

  EmergencyRepository(this._apiClient);

  /// Déclencher le mode urgence
  Future<Emergency> triggerEmergency({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/emergency/trigger/',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return Emergency.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Envoyer une mise à jour de localisation pendant l'urgence
  Future<void> updateEmergencyLocation({
    required int emergencyId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _apiClient.dio.post(
        '/emergency/$emergencyId/location/',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } catch (e) {
      print('Emergency location update error: $e');
    }
  }

  /// Vérifier s'il y a une urgence active
  Future<Emergency?> getActiveEmergency() async {
    try {
      final response = await _apiClient.dio.get('/emergency/status/');

      if (response.data['isActive']) {
        return Emergency.fromJson(response.data['emergency']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      return error.response!.data['detail'] ?? 'Erreur ${error.response!.statusCode}';
    }
    return 'Erreur de connexion';
  }
}

class Emergency {
  final int id;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime triggeredAt;

  Emergency({
    required this.id,
    required this.status,
    this.latitude,
    this.longitude,
    required this.triggeredAt,
  });

  factory Emergency.fromJson(Map<String, dynamic> json) {
    return Emergency(
      id: json['id'],
      status: json['status'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      triggeredAt: DateTime.parse(json['triggeredAt']),
    );
  }
}
```

### 8.2 Widget Bouton d'Urgence

```dart
class EmergencyButton extends StatefulWidget {
  @override
  _EmergencyButtonState createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton> {
  final EmergencyRepository _emergencyRepo = EmergencyRepository(ApiClient());
  final LocationRepository _locationRepo = LocationRepository(ApiClient());
  bool _isEmergency = false;

  Future<void> _triggerEmergency() async {
    // Confirmer avec l'utilisateur
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mode Urgence'),
        content: Text('Voulez-vous déclencher le mode urgence? Votre position sera partagée en temps réel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Déclencher'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition();

      // Déclencher l'urgence
      await _emergencyRepo.triggerEmergency(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() => _isEmergency = true);

      // Démarrer les mises à jour de localisation fréquentes
      _startEmergencyLocationUpdates();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mode urgence activé'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _startEmergencyLocationUpdates() {
    // Envoyer la localisation toutes les 30 secondes
    Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!_isEmergency) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition();
        final emergency = await _emergencyRepo.getActiveEmergency();

        if (emergency != null) {
          await _emergencyRepo.updateEmergencyLocation(
            emergencyId: emergency.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      } catch (e) {
        print('Emergency location update error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _isEmergency ? null : _triggerEmergency,
      backgroundColor: _isEmergency ? Colors.orange : Colors.red,
      child: Icon(
        _isEmergency ? Icons.warning : Icons.sos,
        size: 32,
      ),
    );
  }
}
```

---

## ⚙️ 9. Permissions Android

### 9.1 Configuration des Permissions

Dans `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions de base -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Localisation -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- Appels -->
    <uses-permission android:name="android.permission.READ_CALL_LOG" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />

    <!-- Messages -->
    <uses-permission android:name="android.permission.READ_SMS" />
    <uses-permission android:name="android.permission.RECEIVE_SMS" />

    <!-- Contacts -->
    <uses-permission android:name="android.permission.READ_CONTACTS" />

    <!-- Stockage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <!-- Caméra -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Microphone -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Usage des apps (nécessite settings spéciaux) -->
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions" />

    <!-- Admin device (pour verrouillage) -->
    <uses-permission android:name="android.permission.BIND_DEVICE_ADMIN" />

    <!-- Services en arrière-plan -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <application>
        <!-- ... -->
    </application>
</manifest>
```

### 9.2 Demande des Permissions

Créez `lib/core/services/permissions_service.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  /// Demander toutes les permissions nécessaires
  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.phone,
      Permission.sms,
      Permission.contacts,
      Permission.storage,
      Permission.camera,
      Permission.microphone,
    ].request();

    // Vérifier si toutes sont accordées
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print('Some permissions denied');
      return false;
    }

    // Permission spéciale pour usage stats
    if (!await Permission.appTrackingTransparency.isGranted) {
      await _requestUsageStatsPermission();
    }

    return true;
  }

  static Future<void> _requestUsageStatsPermission() async {
    // Ouvrir les paramètres pour activer manuellement
    await openAppSettings();
  }

  /// Vérifier les permissions critiques
  static Future<bool> hasRequiredPermissions() async {
    return await Permission.location.isGranted &&
           await Permission.locationAlways.isGranted;
  }
}
```

---

## 🔄 10. Architecture Complète de l'App

### 10.1 Structure du Projet

```
lib/
├── core/
│   ├── api/
│   │   └── api_client.dart
│   ├── config/
│   │   └── firebase_config.dart
│   └── services/
│       ├── background_location_service.dart
│       ├── background_sync_service.dart
│       ├── fcm_service.dart
│       └── permissions_service.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   └── presentation/
│   │       └── pages/
│   │           ├── login_page.dart
│   │           └── register_page.dart
│   │
│   ├── devices/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       ├── device_repository.dart
│   │   │       └── pairing_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── pairing_page.dart
│   │       └── handlers/
│   │           └── device_lock_handler.dart
│   │
│   ├── location/
│   │   └── data/
│   │       └── repositories/
│   │           └── location_repository.dart
│   │
│   ├── calls/
│   │   └── data/
│   │       └── repositories/
│   │           └── calls_repository.dart
│   │
│   ├── messages/
│   │   └── data/
│   │       └── repositories/
│   │           └── messages_repository.dart
│   │
│   ├── app_usage/
│   │   └── data/
│   │       └── repositories/
│   │           └── app_usage_repository.dart
│   │
│   ├── media/
│   │   └── presentation/
│   │       └── handlers/
│   │           └── media_capture_handler.dart
│   │
│   └── emergency/
│       ├── data/
│       │   └── repositories/
│       │       └── emergency_repository.dart
│       └── presentation/
│           └── widgets/
│               └── emergency_button.dart
│
└── main.dart
```

### 10.2 Main.dart Complet

```dart
import 'package:flutter/material.dart';
import 'core/config/firebase_config.dart';
import 'core/services/background_location_service.dart';
import 'core/services/background_sync_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/permissions_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await FirebaseConfig.initialize();

  // Initialiser FCM
  await FCMService.initialize();

  // Demander les permissions
  await PermissionsService.requestAllPermissions();

  // Démarrer les services en arrière-plan
  await BackgroundLocationService.initialize();
  await BackgroundLocationService.startPeriodicCollection();
  await BackgroundSyncService.startCallsSync();
  await BackgroundSyncService.startMessagesSync();
  await BackgroundSyncService.startAppUsageSync();

  runApp(MonitoredApp());
}

class MonitoredApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XP SafeConnect - Monitored',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(Duration(seconds: 2));

    // Vérifier si l'utilisateur est connecté
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token != null) {
      // Utilisateur connecté → Page principale
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      // Non connecté → Page de connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'XP SafeConnect',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Monitored App'),
            SizedBox(height: 40),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('XP SafeConnect - Surveillé'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Application active',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Surveillance en cours...'),
          ],
        ),
      ),
      floatingActionButton: EmergencyButton(),
    );
  }
}
```

---

## 📊 11. Récapitulatif des Endpoints Utilisés

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/users/register/` | POST | Enregistrement avec user_type='MONITORED' |
| `/users/login/` | POST | Connexion |
| `/users/logout/` | POST | Déconnexion |
| `/users/token/refresh/` | POST | Rafraîchir le token |
| `/devices/` | POST | Enregistrer cet appareil |
| `/devices/my_device/` | GET | Récupérer infos de cet appareil |
| `/devices/generate_pairing_code/` | POST | Générer code de couplage |
| `/devices/pairing_status/` | GET | Statut du couplage |
| `/location/update/` | POST | Envoyer position GPS |
| `/calls/sync/` | POST | Synchroniser historique appels |
| `/messages/sync/` | POST | Synchroniser messages |
| `/app-usage/sync/` | POST | Synchroniser usage apps |
| `/media/upload_capture/` | POST | Uploader média capturé |
| `/media/capture_status/` | POST | Notifier statut capture |
| `/emergency/trigger/` | POST | Déclencher mode urgence |
| `/emergency/status/` | GET | Vérifier urgence active |
| `/emergency/{id}/location/` | POST | Mise à jour localisation urgence |

---

## ✅ 12. Checklist d'Intégration

- [ ] Configuration Firebase (FCM)
- [ ] Configuration API Client avec tokens JWT
- [ ] Enregistrement utilisateur MONITORED
- [ ] Enregistrement de l'appareil
- [ ] Génération code de couplage
- [ ] Service localisation en arrière-plan
- [ ] Service sync appels en arrière-plan
- [ ] Service sync messages en arrière-plan
- [ ] Service sync usage apps en arrière-plan
- [ ] Handler FCM pour commandes
- [ ] Handler capture photo
- [ ] Handler capture audio
- [ ] Handler lock/unlock appareil
- [ ] Bouton mode urgence
- [ ] Demande permissions Android
- [ ] Tests sur appareil réel

---

## 🔒 13. Sécurité & Bonnes Pratiques

### 13.1 Stockage Sécurisé

```dart
// TOUJOURS utiliser FlutterSecureStorage pour les tokens
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
```

### 13.2 Chiffrement des Données

Pour les données sensibles (messages, appels), envisagez le chiffrement avant envoi:

```dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final key = Key.fromSecureRandom(32);
  static final iv = IV.fromSecureRandom(16);
  static final encrypter = Encrypter(AES(key));

  static String encrypt(String plainText) {
    return encrypter.encrypt(plainText, iv: iv).base64;
  }
}
```

### 13.3 Validation des Commandes FCM

```dart
// Vérifier que les commandes FCM viennent bien du backend
static Future<void> _processCommand(Map<String, dynamic> data) async {
  // Vérifier signature ou token
  if (!_isValidCommand(data)) {
    print('Invalid command signature');
    return;
  }

  // Traiter la commande
  // ...
}
```

---

## 📞 14. Support & Debugging

### 14.1 Logs

Utilisez un système de logging centralisé:

```dart
import 'package:logger/logger.dart';

final logger = Logger();

// Dans votre code
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error, stackTrace);
```

### 14.2 Monitoring des Services

Créez un endpoint de santé:

```dart
class HealthCheckRepository {
  Future<void> sendHealthCheck() async {
    await _apiClient.dio.post('/devices/health_check/', data: {
      'location_service': _isLocationServiceRunning,
      'fcm_token': await FirebaseConfig.getFCMToken(),
      'last_sync': await _storage.read(key: 'last_call_sync'),
    });
  }
}
```

---

## 🎯 Conclusion

Cette documentation complète vous permet d'intégrer entièrement l'**application surveillée** (Monitored App) avec le backend XP SafeConnect.

### Points Clés:

1. **Services en arrière-plan** pour collecte automatique des données
2. **FCM** pour recevoir et exécuter les commandes à distance
3. **Permissions** Android complètes pour accès aux données
4. **Architecture modulaire** pour faciliter la maintenance
5. **Sécurité** avec tokens JWT et stockage sécurisé

**Pour toute question ou support:**
- Email: support@xpsafeconnect.com
- Documentation API: https://api.xpsafeconnect.com/swagger/

---

**XP SafeConnect - Monitored App Integration Guide v1.0**
*Janvier 2025*
