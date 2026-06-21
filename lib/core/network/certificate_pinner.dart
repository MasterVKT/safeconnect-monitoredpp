import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class CertificatePinner {
  // SHA-256 hashes of trusted certificate public keys
  static const Map<String, List<String>> _pinnedCertificates = {
    'api.safeconnect.com': [
      // Production certificate SHA-256 hash (replace with actual)
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      // Backup certificate SHA-256 hash
      'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    ],
    'staging-api.safeconnect.com': [
      // Staging certificate SHA-256 hash (replace with actual)
      'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
    ],
    'localhost': [
      // Development certificate (if needed)
      'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=',
    ],
  };

  /// Validates the certificate chain against pinned certificates
  static bool validateCertificateChain(List<X509Certificate> certChain, String hostname) {
    try {
      final pinnedHashes = _pinnedCertificates[hostname];
      if (pinnedHashes == null || pinnedHashes.isEmpty) {
        if (kDebugMode) {
          debugPrint('Certificate pinning: No pins configured for $hostname');
          return true; // Allow in debug mode
        }
        debugPrint('Certificate pinning: No pins found for $hostname');
        return false;
      }

      // Check each certificate in the chain
      for (final cert in certChain) {
        final certHash = _computeCertificateHash(cert);
        if (pinnedHashes.contains(certHash)) {
          debugPrint('Certificate pinning: Valid pin found for $hostname');
          return true;
        }
      }

      debugPrint('Certificate pinning: No valid pins found for $hostname');
      return false;
    } catch (e) {
      debugPrint('Certificate pinning error: $e');
      return false;
    }
  }

  /// Computes SHA-256 hash of certificate public key
  static String _computeCertificateHash(X509Certificate cert) {
    try {
      // Extract the DER-encoded certificate
      final certBytes = cert.der;
      
      // For simplicity, hash the entire certificate
      // In production, you should extract and hash only the public key
      final digest = sha256.convert(certBytes);
      return base64.encode(digest.bytes);
    } catch (e) {
      debugPrint('Error computing certificate hash: $e');
      return '';
    }
  }

  /// Validates a single certificate
  static bool validateCertificate(X509Certificate cert, String hostname) {
    return validateCertificateChain([cert], hostname);
  }

  /// Updates pinned certificates (for dynamic pinning)
  static void updatePinnedCertificates(String hostname, List<String> newHashes) {
    // In production, this should be done securely with signature verification
    debugPrint('Certificate pinning: Updating pins for $hostname');
    // Implementation would update the pinned certificates map
  }

  /// Generates emergency pins for backup (development use only)
  static List<String> generateEmergencyPins(String hostname) {
    if (!kDebugMode) {
      throw UnsupportedError('Emergency pins only available in debug mode');
    }
    
    // Generate fallback pins for development
    final random = Random.secure();
    return List.generate(2, (index) {
      final randomBytes = List.generate(32, (_) => random.nextInt(256));
      return base64.encode(randomBytes);
    });
  }
}

/// Extension for easier certificate validation
extension SecureHttpClient on HttpClient {
  void enableCertificatePinning() {
    badCertificateCallback = (cert, host, port) {
      debugPrint('Certificate validation for $host:$port');
      
      // Always check basic certificate validity first
      if (!_isValidCertificate(cert)) {
        debugPrint('Certificate basic validation failed for $host');
        return false;
      }
      
      // Then check certificate pinning
      return CertificatePinner.validateCertificate(cert, host);
    };
  }
  
  bool _isValidCertificate(X509Certificate cert) {
    try {
      // Check certificate dates
      final now = DateTime.now();
      final startDate = cert.startValidity;
      final endDate = cert.endValidity;
      
      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        debugPrint('Certificate date validation failed');
        return false;
      }
      
      // Additional basic validations can be added here
      return true;
    } catch (e) {
      debugPrint('Certificate validation error: $e');
      return false;
    }
  }
}

/// Secure HTTP client factory with certificate pinning
class SecureHttpClientFactory {
  static HttpClient createSecureClient() {
    final client = HttpClient();
    client.enableCertificatePinning();
    
    // Additional security configurations
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 15);
    
    return client;
  }
}