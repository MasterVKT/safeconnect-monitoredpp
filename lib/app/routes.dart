import 'package:flutter/material.dart';
import 'package:monitored_app/features/auth/views/pairing_screen.dart';
import 'package:monitored_app/features/auth/views/consent_screen.dart';
import 'package:monitored_app/features/auth/views/enhanced_permission_screen.dart';
import 'package:monitored_app/features/auth/views/setup_complete_screen.dart';
import 'package:monitored_app/features/home/main_screen.dart';
import 'package:monitored_app/features/home/emergency_screen.dart';
import 'package:monitored_app/features/home/shared_data_screen.dart';
import 'package:monitored_app/features/settings/views/stealth_settings_screen.dart';
import 'package:monitored_app/features/settings/views/security_settings_screen.dart';
import 'package:monitored_app/features/settings/media_settings_screen.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String consent = '/consent';
  static const String permissions = '/permissions';
  static const String setupComplete = '/setup-complete';
  static const String home = '/home';
  static const String sharedData = '/shared-data';
  static const String emergency = '/emergency';
  static const String stealthSettings = '/stealth-settings';
  static const String securitySettings = '/security-settings';
  static const String mediaSettings = '/media-settings';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        final pairingCode = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => PairingScreen(pairingCode: pairingCode));
      
      case AppRoutes.consent:
        return MaterialPageRoute(builder: (_) => const ConsentScreen());
      
      case AppRoutes.permissions:
        return MaterialPageRoute(builder: (_) => const EnhancedPermissionScreen());
      
      case AppRoutes.setupComplete:
        return MaterialPageRoute(builder: (_) => const SetupCompleteScreen());
      
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      
      case AppRoutes.sharedData:
        return MaterialPageRoute(builder: (_) => const SharedDataScreen());
      
      case AppRoutes.emergency:
        return MaterialPageRoute(builder: (_) => const EmergencyScreen());
      
      case AppRoutes.stealthSettings:
        return MaterialPageRoute(builder: (_) => const StealthSettingsScreen());
      
      case AppRoutes.securitySettings:
        return MaterialPageRoute(builder: (_) => const SecuritySettingsScreen());
      
      case AppRoutes.mediaSettings:
        return MaterialPageRoute(builder: (_) => const MediaSettingsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route inconnue: ${settings.name}'),
            ),
          ),
        );
    }
  }
}