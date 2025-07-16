import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';
import '../../app/locator.dart';
import '../utils/device_utils.dart';

class NotificationService {
  final ApiClient _apiClient = locator<ApiClient>();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> setupPushNotifications() async {
    // Demander les permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true, // Pour les alertes urgentes
    );

    // Configurer les canaux Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel emergencyChannel =
          AndroidNotificationChannel(
        'emergency_alerts',
        'Alertes d\'urgence',
        description: 'Notifications pour les situations d\'urgence',
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        showBadge: true,
      );

      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
        'default_channel',
        'Notifications standard',
        description: 'Notifications classiques de l\'application',
        importance: Importance.defaultImportance,
      );

      const AndroidNotificationChannel silentChannel =
          AndroidNotificationChannel(
        'silent_channel',
        'Notifications discrètes',
        description: 'Notifications sans son ni vibration',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(emergencyChannel);
      await androidPlugin?.createNotificationChannel(defaultChannel);
      await androidPlugin?.createNotificationChannel(silentChannel);
    } // Added missing closing brace here

    // Configurer les notifications en premier plan
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Récupérer et enregistrer le token FCM
    final fcmToken = await FirebaseMessaging.instance.getToken();
    await registerFcmToken(fcmToken);

    // Gérer le renouvellement du token
    FirebaseMessaging.instance.onTokenRefresh.listen(registerFcmToken);
  }

  Future<void> registerFcmToken(String? token) async {
    if (token == null) return;

    try {
      await _apiClient.post('/devices/update-fcm-token', data: {
        'token': token,
        'device_id': await DeviceUtils.getDeviceIdentifier(),
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du token FCM: $e');
    }
  }
}
