import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitored_app/core/collectors/bootstrap_checkpoint.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> createStorage(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final preferences = await SharedPreferences.getInstance();
    return StorageService(
      preferences,
      const FlutterSecureStorage(),
    );
  }

  test('state migration resets a potentially poisoned bootstrap', () async {
    final storage = await createStorage({
      'test_collector_state_version': 1,
      'test_collector_bootstrap_done': true,
      'test_collector_last_checkpoint_ms': 123456789,
    });
    final checkpoint = BootstrapCheckpoint(
      storageService: storage,
      keyPrefix: 'test_collector',
      historyWindow: const Duration(days: 90),
      stateVersion: 2,
    );

    await checkpoint.initialize();

    expect(checkpoint.isBootstrapPending, isTrue);
    expect(checkpoint.lastCheckpoint, isNull);
    expect(storage.getBool('test_collector_bootstrap_done'), isFalse);
    expect(storage.getInt('test_collector_last_checkpoint_ms'), isNull);
    expect(storage.getInt('test_collector_state_version'), 2);
  });

  test('successful empty scan can complete bootstrap', () async {
    final storage = await createStorage({
      'test_collector_state_version': 2,
    });
    final checkpoint = BootstrapCheckpoint(
      storageService: storage,
      keyPrefix: 'test_collector',
      historyWindow: const Duration(days: 90),
      stateVersion: 2,
    );
    final completedAt = DateTime(2026, 6, 9, 12);

    await checkpoint.initialize();
    await checkpoint.completeSuccessfulScan(completedAt);

    expect(checkpoint.isBootstrapPending, isFalse);
    expect(checkpoint.lastCheckpoint, completedAt);
    expect(storage.getBool('test_collector_bootstrap_done'), isTrue);
    expect(
      storage.getInt('test_collector_last_checkpoint_ms'),
      completedAt.millisecondsSinceEpoch,
    );
  });

  test('pending bootstrap resolves to the configured history window', () async {
    final storage = await createStorage({
      'test_collector_state_version': 2,
    });
    final checkpoint = BootstrapCheckpoint(
      storageService: storage,
      keyPrefix: 'test_collector',
      historyWindow: const Duration(days: 90),
      stateVersion: 2,
    );

    await checkpoint.initialize();
    final beforeResolve = DateTime.now();
    final resolved = checkpoint.resolve();
    final afterResolve = DateTime.now();

    expect(
      resolved.isBefore(beforeResolve.subtract(const Duration(days: 90))),
      isFalse,
    );
    expect(
      resolved.isAfter(afterResolve.subtract(const Duration(days: 90))),
      isFalse,
    );
  });
}
