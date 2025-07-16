import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UnlockService {
  static const _platform = MethodChannel('com.xpsafeconnect.monitored_app/unlock');
  
  // Tente de déverrouiller l'appareil
  Future<bool> unlockDevice() async {
    try {
      // Appelle la méthode native pour déverrouiller l'appareil
      final result = await _platform.invokeMethod('unlockDevice');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to unlock device: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception during device unlock: $e');
      return false;
    }
  }
  
  // Vérifie si le déverrouillage est disponible sur cet appareil
  Future<bool> isUnlockAvailable() async {
    try {
      final result = await _platform.invokeMethod('isUnlockAvailable');
      return result == true;
    } catch (e) {
      debugPrint('Error checking unlock availability: $e');
      return false;
    }
  }
}