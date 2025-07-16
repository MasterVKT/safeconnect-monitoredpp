import 'dart:isolate';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/app/app.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/background_service.dart';
import 'package:monitored_app/background_service_entry.dart';
import 'package:monitored_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurer Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Capture des erreurs asynchrones non gérées
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialiser le service locator
  await setupLocator();

  // Initialiser la configuration
  await AppConfig().initialize();

  // Enregistrer le callback d'arrière-plan
  final callback = PluginUtilities.getCallbackHandle(backgroundServiceEntryPoint);
  final callbackRawHandle = callback?.toRawHandle();
  if (callbackRawHandle != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('callback_handle', callbackRawHandle);
  }

  // Configurer le port pour la communication entre isolates
  final ReceivePort port = ReceivePort();
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    'background_isolate_send_port',
  );

  // Écouter les messages de l'isolate d'arrière-plan
  port.listen((message) {
    if (message is Map<String, dynamic>) {
      debugPrint('Main isolate received: ${message['type']}');
    }
  });

  // Vérifier si l'utilisateur est déjà authentifié
  final currentUser = await locator<AuthService>().getCurrentUser();
  if (currentUser != null) {
    FirebaseCrashlytics.instance.setUserIdentifier(currentUser.id);

    // Démarrer les services en arrière-plan (première version)
    await locator<WebSocketService>().connect();
    locator<BatteryMonitorService>().startMonitoring();

    // Démarrer le service d'arrière-plan si auto-start est activé (deuxième version)
    final autoStartEnabled = await AppConfig().isAutoStartEnabled();
    if (autoStartEnabled) {
      await locator<BackgroundService>().startService();
    }
  }

  runApp(
    const ProviderScope(
      child: SafeConnectMonitored(),
    ),
  );
}