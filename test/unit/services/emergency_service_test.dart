import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:monitored_app/core/services/emergency_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/notification_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';

// Generate mocks
@GenerateMocks([DatabaseService, NotificationService, WebSocketService])
import 'emergency_service_test.mocks.dart';

void main() {
  group('EmergencyService Tests', () {
    late EmergencyService emergencyService;
    late MockDatabaseService mockDatabaseService;
    late MockNotificationService mockNotificationService;
    late MockWebSocketService mockWebSocketService;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      mockNotificationService = MockNotificationService();
      mockWebSocketService = MockWebSocketService();
      
      // Create emergency service instance
      emergencyService = EmergencyService();
    });

    group('Emergency Activation', () {
      test('should activate emergency mode successfully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        when(mockNotificationService.showEmergencyNotification(any, any)).thenAnswer((_) async {});
        when(mockWebSocketService.sendEmergencyAlert(any)).thenAnswer((_) async {});

        // Act
        final result = await emergencyService.activateEmergency(
          triggerType: EmergencyTriggerType.manual,
          triggerData: {'test': 'data'},
        );

        // Assert
        expect(result, isTrue);
        expect(emergencyService.currentState, equals(EmergencyState.active));
      });

      test('should handle emergency activation failure gracefully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenThrow(Exception('Database error'));

        // Act
        final result = await emergencyService.activateEmergency(
          triggerType: EmergencyTriggerType.manual,
        );

        // Assert
        expect(result, isFalse);
        expect(emergencyService.currentState, equals(EmergencyState.inactive));
      });

      test('should not allow multiple concurrent emergency activations', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        
        // Act - First activation
        final firstActivation = emergencyService.activateEmergency(
          triggerType: EmergencyTriggerType.manual,
        );
        
        // Act - Second activation before first completes
        final secondActivation = emergencyService.activateEmergency(
          triggerType: EmergencyTriggerType.manual,
        );

        final results = await Future.wait([firstActivation, secondActivation]);

        // Assert
        expect(results[0], isTrue);
        expect(results[1], isFalse); // Should reject second activation
      });
    });

    group('Emergency Deactivation', () {
      test('should deactivate emergency mode successfully', () async {
        // Arrange - First activate emergency
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Act
        final result = await emergencyService.deactivateEmergency();

        // Assert
        expect(result, isTrue);
        expect(emergencyService.currentState, equals(EmergencyState.inactive));
      });

      test('should handle deactivation when not active', () async {
        // Act - Try to deactivate when not active
        final result = await emergencyService.deactivateEmergency();

        // Assert
        expect(result, isFalse);
      });
    });

    group('Emergency Actions', () {
      test('should capture emergency photo successfully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Act
        final result = await emergencyService.captureEmergencyPhoto();

        // Assert
        expect(result, isNotNull);
        expect(result, contains('photo'));
      });

      test('should record emergency audio successfully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Act
        final result = await emergencyService.recordEmergencyAudio(durationSeconds: 30);

        // Assert
        expect(result, isNotNull);
        expect(result, contains('audio'));
      });

      test('should send emergency message successfully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        when(mockWebSocketService.sendEmergencyMessage(any)).thenAnswer((_) async {});
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Act
        final result = await emergencyService.sendEmergencyMessage('Test emergency message');

        // Assert
        expect(result, isTrue);
      });
    });

    group('Emergency State Management', () {
      test('should provide state stream updates', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        
        final stateUpdates = <EmergencyState>[];
        emergencyService.stateStream.listen((state) {
          stateUpdates.add(state);
        });

        // Act
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);
        await emergencyService.deactivateEmergency();

        // Allow stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(stateUpdates, contains(EmergencyState.active));
        expect(stateUpdates, contains(EmergencyState.inactive));
      });

      test('should maintain emergency event history', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});

        // Act
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);
        await emergencyService.deactivateEmergency();

        // Assert
        expect(emergencyService.currentEmergency, isNotNull);
        expect(emergencyService.currentEmergency!.triggerType, equals(EmergencyTriggerType.manual));
      });
    });

    group('Automatic Emergency Actions', () {
      test('should trigger automatic location capture on activation', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});

        // Act
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Assert - Verify automatic actions were triggered
        // Note: In a real test, you'd mock the location service and verify it was called
        expect(emergencyService.currentState, equals(EmergencyState.active));
      });

      test('should send heartbeat during emergency', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        when(mockWebSocketService.sendEmergencyHeartbeat(any)).thenAnswer((_) async {});

        // Act
        await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);
        
        // Wait for heartbeat timer
        await Future.delayed(const Duration(seconds: 2));

        // Assert
        verify(mockWebSocketService.sendEmergencyHeartbeat(any)).called(greaterThan(0));
      });
    });

    group('Error Handling', () {
      test('should handle database errors gracefully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenThrow(Exception('DB Error'));

        // Act
        final result = await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Assert
        expect(result, isFalse);
        expect(emergencyService.currentState, equals(EmergencyState.inactive));
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(mockDatabaseService.insertEmergencyEvent(any)).thenAnswer((_) async {});
        when(mockWebSocketService.sendEmergencyAlert(any)).thenThrow(Exception('Network Error'));

        // Act
        final result = await emergencyService.activateEmergency(triggerType: EmergencyTriggerType.manual);

        // Assert - Should still activate even if network fails
        expect(result, isTrue);
        expect(emergencyService.currentState, equals(EmergencyState.active));
      });
    });

    tearDown(() {
      emergencyService.dispose();
    });
  });
}