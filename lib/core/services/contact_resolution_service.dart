import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service pour résoudre les numéros de téléphone en noms de contacts
class ContactResolutionService {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/contacts');

  final Map<String, String?> _cache = {};
  final Set<String> _resolutionInProgress = {};

  /// Résout un numéro de téléphone en nom de contact
  /// Retourne le nom du contact s'il existe, sinon null
  Future<String?> resolveContactName(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return null;
    }

    // Vérifier le cache
    if (_cache.containsKey(phoneNumber)) {
      return _cache[phoneNumber];
    }

    // Éviter les résolutions multiples du même numéro
    if (_resolutionInProgress.contains(phoneNumber)) {
      return null;
    }

    try {
      _resolutionInProgress.add(phoneNumber);

      // Vérifier les permissions
      final contactsPermission = await Permission.contacts.request();
      if (!contactsPermission.isGranted) {
        debugPrint('[ContactResolution] Contacts permission not granted');
        return null;
      }

      // Appeler la méthode native pour résoudre le contact
      final contactName =
          await _channel.invokeMethod<String?>('getContactName', {
        'phone_number': phoneNumber,
      });

      // Mettre en cache le résultat
      _cache[phoneNumber] = contactName;

      if (contactName != null && contactName.isNotEmpty) {
        debugPrint('[ContactResolution] Resolved $phoneNumber to $contactName');
      }

      return contactName;
    } catch (e) {
      debugPrint('[ContactResolution] Error resolving contact: $e');
      return null;
    } finally {
      _resolutionInProgress.remove(phoneNumber);
    }
  }

  /// Efface le cache
  void clearCache() {
    _cache.clear();
    debugPrint('[ContactResolution] Cache cleared');
  }

  /// Obtient la taille du cache
  int getCacheSize() => _cache.length;
}
