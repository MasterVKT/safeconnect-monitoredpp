import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app/locator.dart';
import 'device_service.dart';

class NotificationService {
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
  }

  Future<void> registerFcmToken(String? token) async {
    if (token == null) return;

    try {
      if (!locator.isRegistered<DeviceService>()) {
        debugPrint(
            'FCM token registration deferred: DeviceService unavailable');
        return;
      }

      await locator<DeviceService>().registerFcmToken(token);
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'enregistrement du token FCM: ${e.runtimeType}');
    }
  }

  Future<void> showEmergencyNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'emergency_alerts',
        'Alertes d\'urgence',
        channelDescription: 'Notifications pour les situations d\'urgence',
        importance: Importance.max,
        priority: Priority.max,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        ongoing: true, // Keep the notification visible
        autoCancel: false,
        color: Colors.red,
        icon: '@drawable/emergency_icon',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        999, // Fixed ID for emergency notifications
        title,
        body,
        platformChannelSpecifics,
        payload: 'emergency_active',
      );

      debugPrint('Emergency notification shown: $title');
    } catch (e) {
      debugPrint('Error showing emergency notification: $e');
    }
  }

  Future<void> hideEmergencyNotification() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(999);
      debugPrint('Emergency notification hidden');
    } catch (e) {
      debugPrint('Error hiding emergency notification: $e');
    }
  }

  Future<void> showNotification(String title, String body,
      {String channel = 'default_channel'}) async {
    try {
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channel,
        channel == 'emergency_alerts'
            ? 'Alertes d\'urgence'
            : 'Notifications standard',
        importance: channel == 'emergency_alerts'
            ? Importance.max
            : Importance.defaultImportance,
        priority: channel == 'emergency_alerts'
            ? Priority.max
            : Priority.defaultPriority,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647, // Random ID
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<void> showTamperAlert(String tamperType, String details) async {
    await showNotification(
      'Security Alert - $tamperType',
      'Tamper detection: $details',
      channel: 'emergency_alerts',
    );
  }
}
