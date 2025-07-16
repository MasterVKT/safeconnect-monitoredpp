
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/models/user.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/features/auth/models/auth_models.dart';

class AuthRepository {
  final AuthService _authService;
  
  AuthRepository(this._authService);
  
  Future<User?> getCurrentUser() async {
    return await _authService.getCurrentUser();
  }
  
  Future<AuthResult> pairDevice(String pairingCode) async {
    try {
      // Obtenir les informations sur l'appareil
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      
      // Créer les paramètres pour le jumelage
      final params = PairingParams(
        pairingCode: pairingCode,
        deviceInfo: deviceInfo,
      );
      
      // Envoyer la demande de jumelage
      final result = await _authService.pairDevice(params);
      
      return result;
    } catch (e) {
      return AuthResult.error(message: e.toString());
    }
  }
  
  Future<void> signOut() async {
    await _authService.signOut();
  }
}