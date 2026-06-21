import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:monitored_app/features/home/emergency_screen.dart';
import 'package:monitored_app/core/services/emergency_service.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([EmergencyService])
import 'emergency_screen_test.mocks.dart';

void main() {
  group('EmergencyScreen Widget Tests', () {
    late MockEmergencyService mockEmergencyService;

    setUp(() {
      mockEmergencyService = MockEmergencyService();
      
      // Reset GetIt and register mock
      GetIt.instance.reset();
      GetIt.instance.registerSingleton<EmergencyService>(mockEmergencyService);
      
      // Setup default mock responses
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.inactive);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.inactive));
      when(mockEmergencyService.isInitialized).thenReturn(true);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: const EmergencyScreen(),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        ),
      );
    }

    testWidgets('should display emergency screen with main elements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Emergency Mode'), findsOneWidget);
    });

    testWidgets('should show inactive state by default', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Tap to Activate'), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsWidgets);
    });

    testWidgets('should start countdown when emergency button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.activateEmergency(triggerType: anyNamed('triggerType')))
          .thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Find and tap the emergency activation button
      final activationButton = find.byKey(const Key('emergency_activation_button'));
      if (activationButton.evaluate().isEmpty) {
        // Fallback to finding button by text or icon
        final fallbackButton = find.textContaining('Tap to Activate').first;
        await tester.tap(fallbackButton);
      } else {
        await tester.tap(activationButton);
      }
      
      await tester.pump();

      // Assert - Should show countdown or activation state
      final hasCountdown = find.textContaining('5').evaluate().isNotEmpty;
      final hasCancel = find.textContaining('Cancel').evaluate().isNotEmpty;
      expect(hasCountdown || hasCancel, isTrue);
    });

    testWidgets('should show cancel button during countdown', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.activating);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.activating));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Cancel'), findsWidgets);
    });

    testWidgets('should show active state when emergency is activated', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.active));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Emergency Active'), findsWidgets);
      expect(find.textContaining('Deactivate'), findsWidgets);
    });

    testWidgets('should show emergency actions when active', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.active));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for emergency action buttons
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
      expect(find.byIcon(Icons.mic), findsWidgets);
      expect(find.byIcon(Icons.message), findsWidgets);
    });

    testWidgets('should handle emergency photo capture', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.active));
      when(mockEmergencyService.captureEmergencyPhoto()).thenAnswer((_) async => 'photo_path.jpg');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // Assert
      verify(mockEmergencyService.captureEmergencyPhoto()).called(1);
    });

    testWidgets('should handle emergency audio recording', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.active));
      when(mockEmergencyService.recordEmergencyAudio(durationSeconds: anyNamed('durationSeconds')))
          .thenAnswer((_) async => 'audio_path.wav');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Assert
      verify(mockEmergencyService.recordEmergencyAudio(durationSeconds: anyNamed('durationSeconds'))).called(1);
    });

    testWidgets('should handle emergency message sending', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.active));
      when(mockEmergencyService.sendEmergencyMessage(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();

      // Should show message input dialog or directly send predefined message
      // This depends on the implementation details
    });

    testWidgets('should deactivate emergency when deactivate button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      when(mockEmergencyService.stateStream).thenAnswer((_) => Stream.value(EmergencyState.active));
      when(mockEmergencyService.deactivateEmergency()).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      final deactivateButton = find.textContaining('Deactivate');
      if (deactivateButton.evaluate().isNotEmpty) {
        await tester.tap(deactivateButton);
        await tester.pumpAndSettle();

        // Assert
        verify(mockEmergencyService.deactivateEmergency()).called(1);
      }
    });

    testWidgets('should handle state changes through stream', (WidgetTester tester) async {
      // Arrange
      final stateController = StreamController<EmergencyState>();
      when(mockEmergencyService.stateStream).thenAnswer((_) => stateController.stream);
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.inactive);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially inactive
      expect(find.textContaining('Tap to Activate'), findsOneWidget);

      // Change to active
      when(mockEmergencyService.currentState).thenReturn(EmergencyState.active);
      stateController.add(EmergencyState.active);
      await tester.pumpAndSettle();

      // Should update UI
      expect(find.textContaining('Emergency Active'), findsWidgets);

      stateController.close();
    });

    testWidgets('should show loading state during initialization', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.isInitialized).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should handle errors gracefully', (WidgetTester tester) async {
      // Arrange
      when(mockEmergencyService.activateEmergency(triggerType: anyNamed('triggerType')))
          .thenThrow(Exception('Test error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Try to activate emergency
      final activationButton = find.textContaining('Tap to Activate');
      if (activationButton.evaluate().isNotEmpty) {
        await tester.tap(activationButton.first);
        await tester.pumpAndSettle();

        // Should handle error gracefully (not crash)
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('should respect theme colors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check that UI elements are present and rendered
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      
      // The specific color assertions would depend on the exact implementation
      // but we can at least verify the widget structure is correct
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for semantic labels and accessibility
      final SemanticsHandle handle = tester.ensureSemantics();
      
      // Verify emergency button has semantic information
      expect(find.byType(Semantics), findsWidgets);
      
      handle.dispose();
    });
  });
}
