import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:monitored_app/core/services/anti_tamper_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/notification_service.dart';
import 'package:flutter/services.dart';

@GenerateMocks([DatabaseService, NotificationService, MethodChannel])
import 'anti_tamper_service_test.mocks.dart';

void main() {
  group('AntiTamperService Tests', () {
    late AntiTamperService antiTamperService;
    late MockDatabaseService mockDatabaseService;
    late MockNotificationService mockNotificationService;
    late MockMethodChannel mockMethodChannel;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      mockNotificationService = MockNotificationService();
      mockMethodChannel = MockMethodChannel();
      antiTamperService = AntiTamperService();
    });

    group('Tamper Detection', () {
      test('should detect root access on Android', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('checkRootAccess'))
            .thenAnswer((_) async => true);

        // Act
        final isRooted = await antiTamperService.checkRootAccess();

        // Assert
        expect(isRooted, isTrue);
      });

      test('should detect debugging attempts', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('checkDebugging'))
            .thenAnswer((_) async => true);

        // Act
        final isDebugging = await antiTamperService.checkDebugging();

        // Assert
        expect(isDebugging, isTrue);
      });

      test('should detect emulator environment', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('checkEmulator'))
            .thenAnswer((_) async => true);

        // Act
        final isEmulator = await antiTamperService.checkEmulator();

        // Assert
        expect(isEmulator, isTrue);
      });

      test('should detect hooking attempts', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('checkHooking'))
            .thenAnswer((_) async => true);

        // Act
        final isHooked = await antiTamperService.checkHooking();

        // Assert
        expect(isHooked, isTrue);
      });
    });

    group('Protection Levels', () {
      test('should set basic protection level', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});

        // Act
        await antiTamperService.setProtectionLevel(TamperDetectionLevel.basic);

        // Assert
        expect(antiTamperService.currentProtectionLevel, equals(TamperDetectionLevel.basic));
        verify(mockDatabaseService.setConfiguration('anti_tamper_config', any)).called(1);
      });

      test('should set advanced protection level', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});

        // Act
        await antiTamperService.setProtectionLevel(TamperDetectionLevel.advanced);

        // Assert
        expect(antiTamperService.currentProtectionLevel, equals(TamperDetectionLevel.advanced));
      });

      test('should set paranoid protection level', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});

        // Act
        await antiTamperService.setProtectionLevel(TamperDetectionLevel.paranoid);

        // Assert
        expect(antiTamperService.currentProtectionLevel, equals(TamperDetectionLevel.paranoid));
      });
    });

    group('Runtime Protection', () {
      test('should start runtime protection successfully', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        when(mockMethodChannel.invokeMethod('startRuntimeProtection'))
            .thenAnswer((_) async => true);

        // Act
        final result = await antiTamperService.startRuntimeProtection();

        // Assert
        expect(result, isTrue);
        expect(antiTamperService.isRuntimeProtectionActive, isTrue);
      });

      test('should stop runtime protection successfully', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('stopRuntimeProtection'))
            .thenAnswer((_) async => true);
        
        // Start protection first
        await antiTamperService.startRuntimeProtection();

        // Act
        final result = await antiTamperService.stopRuntimeProtection();

        // Assert
        expect(result, isTrue);
        expect(antiTamperService.isRuntimeProtectionActive, isFalse);
      });

      test('should handle runtime protection failure gracefully', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('startRuntimeProtection'))
            .thenThrow(PlatformException(code: 'FAILED', message: 'Protection failed'));

        // Act
        final result = await antiTamperService.startRuntimeProtection();

        // Assert
        expect(result, isFalse);
        expect(antiTamperService.isRuntimeProtectionActive, isFalse);
      });
    });

    group('Integrity Monitoring', () {
      test('should perform integrity check successfully', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('verifyAppSignature'))
            .thenAnswer((_) async => true);
        when(mockMethodChannel.invokeMethod('checkDebugging'))
            .thenAnswer((_) async => false);
        when(mockMethodChannel.invokeMethod('checkHooking'))
            .thenAnswer((_) async => false);

        // Act
        final result = await antiTamperService.performIntegrityCheck();

        // Assert
        expect(result, isTrue);
      });

      test('should fail integrity check when signature is invalid', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('verifyAppSignature'))
            .thenAnswer((_) async => false);

        // Act
        final result = await antiTamperService.performIntegrityCheck();

        // Assert
        expect(result, isFalse);
      });

      test('should fail integrity check when debugging detected', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('verifyAppSignature'))
            .thenAnswer((_) async => true);
        when(mockMethodChannel.invokeMethod('checkDebugging'))
            .thenAnswer((_) async => true);

        // Act
        final result = await antiTamperService.performIntegrityCheck();

        // Assert
        expect(result, isFalse);
      });
    });

    group('Tamper Response', () {
      test('should handle tamper detection with appropriate response', () async {
        // Arrange
        when(mockDatabaseService.logTamperAttempt(any, any, any))
            .thenAnswer((_) async {});
        when(mockNotificationService.showTamperAlert(any, any))
            .thenAnswer((_) async {});

        // Act
        await antiTamperService.handleTamperDetection(
          TamperType.rootAccess,
          'Root access detected',
        );

        // Assert
        verify(mockDatabaseService.logTamperAttempt(any, any, any)).called(1);
        verify(mockNotificationService.showTamperAlert(any, any)).called(1);
      });

      test('should trigger app termination on critical tamper', () async {
        // Arrange
        when(mockDatabaseService.logTamperAttempt(any, any, any))
            .thenAnswer((_) async {});

        await antiTamperService.setProtectionLevel(TamperDetectionLevel.paranoid);

        // Act
        await antiTamperService.handleTamperDetection(
          TamperType.hookingDetection,
          'Critical hooking detected',
        );

        // Assert
        verify(mockDatabaseService.logTamperAttempt(any, any, any)).called(1);
      });
    });

    group('Configuration Management', () {
      test('should save configuration to database', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = AntiTamperConfiguration(
          detectionLevel: TamperDetectionLevel.advanced,
          enableRuntimeProtection: true,
          enableIntegrityChecks: true,
        );

        // Act
        await antiTamperService.updateConfiguration(config);

        // Assert
        verify(mockDatabaseService.setConfiguration('anti_tamper_config', any)).called(1);
        expect(antiTamperService.currentConfiguration.detectionLevel, equals(TamperDetectionLevel.advanced));
      });

      test('should load configuration from database on initialization', () async {
        // Arrange
        const savedConfig = '''
        {
          "detectionLevel": "advanced",
          "enableRuntimeProtection": true,
          "enableIntegrityChecks": true,
          "enableAntiDebugging": false
        }
        ''';
        
        when(mockDatabaseService.getConfiguration('anti_tamper_config'))
            .thenAnswer((_) async => savedConfig);

        // Act
        await antiTamperService.initialize();

        // Assert
        expect(antiTamperService.currentConfiguration.detectionLevel, equals(TamperDetectionLevel.advanced));
        expect(antiTamperService.currentConfiguration.enableRuntimeProtection, isTrue);
      });
    });

    group('Monitoring and Alerts', () {
      test('should provide tamper detection status', () async {
        // Arrange
        await antiTamperService.setProtectionLevel(TamperDetectionLevel.advanced);
        await antiTamperService.startRuntimeProtection();

        // Act
        final status = await antiTamperService.getTamperDetectionStatus();

        // Assert
        expect(status['protectionLevel'], equals('advanced'));
        expect(status['runtimeProtectionActive'], isTrue);
        expect(status['lastIntegrityCheck'], isNotNull);
      });

      test('should emit tamper detection events through stream', () async {
        // Arrange
        final tamperEvents = <TamperEvent>[];
        antiTamperService.tamperEventStream.listen((event) {
          tamperEvents.add(event);
        });

        // Act
        await antiTamperService.handleTamperDetection(
          TamperType.rootAccess,
          'Test tamper event',
        );

        // Allow stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(tamperEvents.length, equals(1));
        expect(tamperEvents.first.type, equals('ROOTACCESS'));
        expect(tamperEvents.first.description, equals('Test tamper event'));
      });
    });

    group('Error Handling', () {
      test('should handle platform exceptions gracefully', () async {
        // Arrange
        when(mockMethodChannel.invokeMethod('checkRootAccess'))
            .thenThrow(PlatformException(code: 'UNAVAILABLE', message: 'Method not available'));

        // Act & Assert - Should not throw
        await expectLater(antiTamperService.checkRootAccess(), completes);
      });

      test('should handle database errors during configuration save', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any))
            .thenThrow(Exception('Database error'));

        // Act
        const config = AntiTamperConfiguration(
          detectionLevel: TamperDetectionLevel.basic,
        );
        
        // Should not throw
        await expectLater(
          antiTamperService.updateConfiguration(config),
          completes,
        );
      });
    });

    tearDown(() {
      antiTamperService.dispose();
    });
  });
}
