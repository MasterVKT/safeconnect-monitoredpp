import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/anti_tamper_service.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

@GenerateMocks([DatabaseService, StorageService, AntiTamperService, LocalAuthentication])
import 'security_service_test.mocks.dart';

void main() {
  group('SecurityService Tests', () {
    late SecurityService securityService;
    late MockDatabaseService mockDatabaseService;
    late MockStorageService mockStorageService;
    late MockAntiTamperService mockAntiTamperService;
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      mockStorageService = MockStorageService();
      mockAntiTamperService = MockAntiTamperService();
      mockLocalAuth = MockLocalAuthentication();
      securityService = SecurityService();
    });

    group('Authentication', () {
      test('should authenticate with biometrics successfully', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await securityService.authenticateWithBiometrics();

        // Assert
        expect(result, isTrue);
      });

      test('should fail biometric authentication when not supported', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await securityService.authenticateWithBiometrics();

        // Assert
        expect(result, isFalse);
      });

      test('should authenticate with PIN successfully', () async {
        // Arrange
        when(mockStorageService.getSecureData('security_pin'))
            .thenAnswer((_) async => 'hashed_pin_value');

        // Act
        final result = await securityService.authenticateWithPIN('1234');

        // Assert
        expect(result, isTrue);
      });

      test('should fail PIN authentication with wrong PIN', () async {
        // Arrange
        when(mockStorageService.getSecureData('security_pin'))
            .thenAnswer((_) async => 'different_hashed_value');

        // Act
        final result = await securityService.authenticateWithPIN('9999');

        // Assert
        expect(result, isFalse);
      });
    });

    group('Security Settings', () {
      test('should enable app lock successfully', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});

        // Act
        await securityService.enableAppLock(AuthMethod.biometric);

        // Assert
        expect(securityService.isAppLockEnabled, isTrue);
        expect(securityService.authMethod, equals(AuthMethod.biometric));
        verify(mockDatabaseService.setConfiguration('security_config', any)).called(1);
      });

      test('should disable app lock successfully', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        // Enable first
        await securityService.enableAppLock(AuthMethod.pin);

        // Act
        await securityService.disableAppLock();

        // Assert
        expect(securityService.isAppLockEnabled, isFalse);
        expect(securityService.authMethod, equals(AuthMethod.none));
      });

      test('should set security PIN successfully', () async {
        // Arrange
        when(mockStorageService.setSecureData(any, any)).thenAnswer((_) async {});

        // Act
        final result = await securityService.setPIN('1234');

        // Assert
        expect(result, isTrue);
        verify(mockStorageService.setSecureData('security_pin', any)).called(1);
      });

      test('should change security PIN successfully', () async {
        // Arrange
        when(mockStorageService.getSecureData('security_pin'))
            .thenAnswer((_) async => 'old_hashed_pin');
        when(mockStorageService.setSecureData(any, any)).thenAnswer((_) async {});

        // Set initial PIN
        await securityService.setPIN('1234');

        // Act
        final result = await securityService.changePIN('1234', '5678');

        // Assert
        expect(result, isTrue);
      });

      test('should fail to change PIN with wrong current PIN', () async {
        // Arrange
        when(mockStorageService.getSecureData('security_pin'))
            .thenAnswer((_) async => 'different_hashed_value');

        // Act
        final result = await securityService.changePIN('9999', '5678');

        // Assert
        expect(result, isFalse);
      });
    });

    group('Device Security Checks', () {
      test('should check device security status', () async {
        // Arrange
        when(mockAntiTamperService.checkRootAccess()).thenAnswer((_) async => false);
        when(mockAntiTamperService.checkDebugging()).thenAnswer((_) async => false);
        when(mockAntiTamperService.checkEmulator()).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);

        // Act
        final status = await securityService.getDeviceSecurityStatus();

        // Assert
        expect(status['isRooted'], isFalse);
        expect(status['isDebugging'], isFalse);
        expect(status['isEmulator'], isFalse);
        expect(status['biometricsAvailable'], isTrue);
      });

      test('should detect rooted device', () async {
        // Arrange
        when(mockAntiTamperService.checkRootAccess()).thenAnswer((_) async => true);

        // Act
        final isSecure = await securityService.isDeviceSecure();

        // Assert
        expect(isSecure, isFalse);
      });

      test('should detect debugging', () async {
        // Arrange
        when(mockAntiTamperService.checkRootAccess()).thenAnswer((_) async => false);
        when(mockAntiTamperService.checkDebugging()).thenAnswer((_) async => true);

        // Act
        final isSecure = await securityService.isDeviceSecure();

        // Assert
        expect(isSecure, isFalse);
      });

      test('should detect emulator environment', () async {
        // Arrange
        when(mockAntiTamperService.checkRootAccess()).thenAnswer((_) async => false);
        when(mockAntiTamperService.checkDebugging()).thenAnswer((_) async => false);
        when(mockAntiTamperService.checkEmulator()).thenAnswer((_) async => true);

        // Act
        final isSecure = await securityService.isDeviceSecure();

        // Assert
        expect(isSecure, isFalse);
      });
    });

    group('Security Events', () {
      test('should log security events', () async {
        // Arrange
        when(mockDatabaseService.logSecurityEvent(
          eventType: anyNamed('eventType'),
          description: anyNamed('description'),
          severity: anyNamed('severity'),
        )).thenAnswer((_) async {});

        // Act
        await securityService.logSecurityEvent(
          SecurityEventType.authenticationFailure,
          'Failed biometric authentication',
        );

        // Assert
        verify(mockDatabaseService.logSecurityEvent(
          eventType: anyNamed('eventType'),
          description: anyNamed('description'),
          severity: anyNamed('severity'),
        )).called(1);
      });

      test('should get security event history', () async {
        // Arrange
        final mockEvents = [
          {
            'type': 'authentication_failure',
            'description': 'Failed biometric auth',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        ];
        
        when(mockDatabaseService.getSecurityEvents(7))
            .thenAnswer((_) async => mockEvents);

        // Act
        final events = await securityService.getSecurityEventHistory(days: 7);

        // Assert
        expect(events, isNotEmpty);
        expect(events.length, equals(1));
        expect(events.first['type'], equals('authentication_failure'));
      });
    });

    group('Auto-Lock', () {
      test('should enable auto-lock with timeout', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});

        // Act
        await securityService.enableAutoLock(const Duration(minutes: 5));

        // Assert
        expect(securityService.isAutoLockEnabled, isTrue);
        expect(securityService.autoLockTimeout, equals(const Duration(minutes: 5)));
      });

      test('should disable auto-lock', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        // Enable first
        await securityService.enableAutoLock(const Duration(minutes: 5));

        // Act
        await securityService.disableAutoLock();

        // Assert
        expect(securityService.isAutoLockEnabled, isFalse);
      });

      test('should trigger auto-lock after timeout', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        await securityService.enableAutoLock(const Duration(milliseconds: 100));
        
        // Act - Update activity and wait for timeout
        securityService.updateLastActivity();
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert
        expect(securityService.isLocked, isTrue);
      });
    });

    group('Encryption', () {
      test('should encrypt data successfully', () async {
        // Act
        final encrypted = await securityService.encryptData('test data');

        // Assert
        expect(encrypted, isNotNull);
        expect(encrypted, isNot(equals('test data')));
      });

      test('should decrypt data successfully', () async {
        // Arrange
        final originalData = 'test data';
        final encrypted = await securityService.encryptData(originalData);

        // Act
        final decrypted = await securityService.decryptData(encrypted);

        // Assert
        expect(decrypted, equals(originalData));
      });

      test('should fail to decrypt invalid data', () async {
        // Act & Assert
        await expectLater(
          securityService.decryptData('invalid_encrypted_data'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Configuration Persistence', () {
      test('should save security configuration', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = SecurityConfiguration(
          appLockEnabled: true,
          authMethod: AuthMethod.biometric,
          autoLockEnabled: true,
          autoLockTimeout: Duration(minutes: 5),
        );

        // Act
        await securityService.updateConfiguration(config);

        // Assert
        verify(mockDatabaseService.setConfiguration('security_config', any)).called(1);
        expect(securityService.isAppLockEnabled, isTrue);
        expect(securityService.authMethod, equals(AuthMethod.biometric));
      });

      test('should load configuration on initialization', () async {
        // Arrange
        const savedConfig = '''
        {
          "appLockEnabled": true,
          "authMethod": "pin",
          "autoLockEnabled": true,
          "autoLockTimeoutMinutes": 10
        }
        ''';
        
        when(mockDatabaseService.getConfiguration('security_config'))
            .thenAnswer((_) async => savedConfig);

        // Act
        await securityService.initialize();

        // Assert
        expect(securityService.isAppLockEnabled, isTrue);
        expect(securityService.authMethod, equals(AuthMethod.pin));
        expect(securityService.autoLockTimeout, equals(const Duration(minutes: 10)));
      });
    });

    group('Error Handling', () {
      test('should handle biometric authentication errors gracefully', () async {
        // Arrange
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenThrow(PlatformException(code: 'BIOMETRIC_ERROR', message: 'Error'));

        // Act
        final result = await securityService.authenticateWithBiometrics();

        // Assert
        expect(result, isFalse);
      });

      test('should handle storage errors during PIN operations', () async {
        // Arrange
        when(mockStorageService.setSecureData(any, any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await securityService.setPIN('1234');

        // Assert
        expect(result, isFalse);
      });

      test('should handle database errors during event logging', () async {
        // Arrange
        when(mockDatabaseService.logSecurityEvent(
          eventType: anyNamed('eventType'),
          description: anyNamed('description'),
          severity: anyNamed('severity'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert - Should not throw
        await expectLater(
          securityService.logSecurityEvent(
            SecurityEventType.authenticationFailure,
            'Test event',
          ),
          completes,
        );
      });
    });

    tearDown(() {
      securityService.dispose();
    });
  });
}
