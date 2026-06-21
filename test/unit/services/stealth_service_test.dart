import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:monitored_app/core/services/stealth_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';

@GenerateMocks([DatabaseService, StorageService])
import 'stealth_service_test.mocks.dart';

void main() {
  group('StealthService Tests', () {
    late StealthService stealthService;
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      stealthService = StealthService();
    });

    group('Stealth Mode Activation', () {
      test('should activate stealth mode with valid configuration', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.calculator,
          hideFromRecents: true,
          hideNotifications: true,
        );

        // Act
        final result = await stealthService.activateStealthMode(config);

        // Assert
        expect(result, isTrue);
        expect(stealthService.currentConfig.mode, equals(StealthMode.moderate));
        expect(stealthService.isStealthActive, isTrue);
      });

      test('should reject invalid stealth configuration', () async {
        // Arrange
        const config = StealthConfiguration(
          mode: StealthMode.full,
          disguiseType: DisguiseType.custom,
          customAppName: null, // Invalid - custom type requires name
        );

        // Act
        final result = await stealthService.activateStealthMode(config);

        // Assert
        expect(result, isFalse);
        expect(stealthService.currentConfig.mode, equals(StealthMode.none));
      });

      test('should enable quick stealth with default settings', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});

        // Act
        final result = await stealthService.enableQuickStealth(
          duration: const Duration(minutes: 30),
        );

        // Assert
        expect(result, isTrue);
        expect(stealthService.currentConfig.mode, equals(StealthMode.moderate));
        expect(stealthService.currentConfig.disguiseType, equals(DisguiseType.calculator));
      });
    });

    group('Stealth Mode Deactivation', () {
      test('should deactivate stealth mode successfully', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.calculator,
        );
        
        await stealthService.activateStealthMode(config);

        // Act
        final result = await stealthService.deactivateStealthMode();

        // Assert
        expect(result, isTrue);
        expect(stealthService.currentConfig.mode, equals(StealthMode.none));
        expect(stealthService.isStealthActive, isFalse);
      });

      test('should handle deactivation when already inactive', () async {
        // Act
        final result = await stealthService.deactivateStealthMode();

        // Assert
        expect(result, isTrue);
        expect(stealthService.currentConfig.mode, equals(StealthMode.none));
      });
    });

    group('Disguise Options', () {
      test('should provide available disguise options', () async {
        // Act
        final options = await stealthService.getDisguiseOptions();

        // Assert
        expect(options, isMap);
        expect(options, contains('calculator'));
        expect(options, contains('flashlight'));
        expect(options, contains('weather'));
        
        final calculatorOption = options['calculator'] as Map<String, dynamic>;
        expect(calculatorOption, contains('name'));
        expect(calculatorOption, contains('description'));
        expect(calculatorOption, contains('features'));
      });

      test('should get correct disguise app name', () async {
        // Arrange
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.calculator,
        );
        
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        await stealthService.activateStealthMode(config);

        // Act
        final appName = await stealthService.getDisguiseAppName();

        // Assert
        expect(appName, equals('Calculator'));
      });

      test('should get custom app name when configured', () async {
        // Arrange
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.custom,
          customAppName: 'My Custom App',
        );
        
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        await stealthService.activateStealthMode(config);

        // Act
        final appName = await stealthService.getDisguiseAppName();

        // Assert
        expect(appName, equals('My Custom App'));
      });
    });

    group('Stealth Configuration Persistence', () {
      test('should save configuration to database', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.calculator,
          hideFromRecents: true,
        );

        // Act
        await stealthService.activateStealthMode(config);

        // Assert
        verify(mockDatabaseService.setConfiguration('stealth_configuration', any)).called(1);
      });

      test('should load configuration from database on initialization', () async {
        // Arrange
        const savedConfig = '''
        {
          "mode": "moderate",
          "disguiseType": "calculator",
          "hideFromRecents": true,
          "hideNotifications": false,
          "disableScreenshots": false,
          "enableIncognito": false,
          "customSettings": {}
        }
        ''';
        
        when(mockDatabaseService.getConfiguration('stealth_configuration'))
            .thenAnswer((_) async => savedConfig);

        // Act
        await stealthService.initialize();

        // Assert
        expect(stealthService.currentConfig.mode, equals(StealthMode.moderate));
        expect(stealthService.currentConfig.disguiseType, equals(DisguiseType.calculator));
        expect(stealthService.currentConfig.hideFromRecents, isTrue);
      });
    });

    group('Stealth Status and Settings', () {
      test('should provide accurate stealth status', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = StealthConfiguration(
          mode: StealthMode.full,
          disguiseType: DisguiseType.calculator,
          hideFromRecents: true,
          hideNotifications: true,
          disableScreenshots: true,
        );
        
        await stealthService.activateStealthMode(config);

        // Act
        final status = await stealthService.getStealthStatus();

        // Assert
        expect(status['active'], isTrue);
        expect(status['mode'], equals('full'));
        expect(status['disguiseType'], equals('calculator'));
        expect(status['hideFromRecents'], isTrue);
        expect(status['hideNotifications'], isTrue);
        expect(status['disableScreenshots'], isTrue);
      });

      test('should check stealth feature flags correctly', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          hideFromRecents: true,
          hideNotifications: false,
          disableScreenshots: true,
          enableIncognito: false,
        );
        
        await stealthService.activateStealthMode(config);

        // Act & Assert
        expect(stealthService.shouldHideFromRecents(), isTrue);
        expect(stealthService.shouldHideNotifications(), isFalse);
        expect(stealthService.shouldDisableScreenshots(), isTrue);
        expect(stealthService.isIncognitoEnabled(), isFalse);
      });
    });

    group('Configuration Stream', () {
      test('should emit configuration changes through stream', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        final configUpdates = <StealthConfiguration>[];
        stealthService.configStream.listen((config) {
          configUpdates.add(config);
        });

        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.calculator,
        );

        // Act
        await stealthService.activateStealthMode(config);
        await stealthService.deactivateStealthMode();

        // Allow stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(configUpdates.length, greaterThanOrEqualTo(2));
        expect(configUpdates.any((c) => c.mode == StealthMode.moderate), isTrue);
        expect(configUpdates.any((c) => c.mode == StealthMode.none), isTrue);
      });
    });

    group('Emergency Stealth Disable', () {
      test('should disable stealth in emergency situations', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenAnswer((_) async {});
        
        const config = StealthConfiguration(
          mode: StealthMode.full,
          disguiseType: DisguiseType.calculator,
        );
        
        await stealthService.activateStealthMode(config);

        // Act
        await stealthService.emergencyDisableStealth();

        // Assert
        expect(stealthService.currentConfig.mode, equals(StealthMode.none));
        expect(stealthService.isStealthActive, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle database errors gracefully', () async {
        // Arrange
        when(mockDatabaseService.setConfiguration(any, any)).thenThrow(Exception('DB Error'));
        
        const config = StealthConfiguration(
          mode: StealthMode.moderate,
          disguiseType: DisguiseType.calculator,
        );

        // Act
        final result = await stealthService.activateStealthMode(config);

        // Assert
        expect(result, isFalse);
        expect(stealthService.currentConfig.mode, equals(StealthMode.none));
      });

      test('should handle storage errors during initialization', () async {
        // Arrange
        when(mockDatabaseService.getConfiguration(any)).thenThrow(Exception('Storage Error'));

        // Act & Assert - Should not throw
        await expectLater(stealthService.initialize(), completes);
        expect(stealthService.isInitialized, isTrue);
      });
    });

    tearDown(() {
      stealthService.dispose();
    });
  });
}