import 'package:monitored_app/core/services/storage_service.dart';

class BootstrapCheckpoint {
  BootstrapCheckpoint({
    required StorageService storageService,
    required String keyPrefix,
    required Duration historyWindow,
    required int stateVersion,
  })  : _storageService = storageService,
        _lastCheckpointKey = '${keyPrefix}_last_checkpoint_ms',
        _bootstrapDoneKey = '${keyPrefix}_bootstrap_done',
        _stateVersionKey = '${keyPrefix}_state_version',
        _historyWindow = historyWindow,
        _stateVersion = stateVersion;

  final StorageService _storageService;
  final String _lastCheckpointKey;
  final String _bootstrapDoneKey;
  final String _stateVersionKey;
  final Duration _historyWindow;
  final int _stateVersion;

  DateTime? _lastCheckpoint;
  bool _bootstrapDone = false;

  bool get isBootstrapPending => !_bootstrapDone;
  DateTime? get lastCheckpoint => _lastCheckpoint;

  Future<void> initialize() async {
    final storedVersion = _storageService.getInt(_stateVersionKey) ?? 0;
    if (storedVersion < _stateVersion) {
      await reset();
      await _storageService.setInt(_stateVersionKey, _stateVersion);
      return;
    }

    _bootstrapDone = _storageService.getBool(_bootstrapDoneKey) ?? false;
    final checkpointMs = _storageService.getInt(_lastCheckpointKey);
    if (checkpointMs != null && checkpointMs > 0) {
      _lastCheckpoint = DateTime.fromMillisecondsSinceEpoch(checkpointMs);
    }
  }

  DateTime resolve({Duration fallback = const Duration(hours: 24)}) {
    if (!_bootstrapDone) {
      return DateTime.now().subtract(_historyWindow);
    }

    return _lastCheckpoint ?? DateTime.now().subtract(fallback);
  }

  Future<void> completeSuccessfulScan(DateTime checkpoint) async {
    _lastCheckpoint = checkpoint;
    await _storageService.setInt(
      _lastCheckpointKey,
      checkpoint.millisecondsSinceEpoch,
    );

    if (!_bootstrapDone) {
      _bootstrapDone = true;
      await _storageService.setBool(_bootstrapDoneKey, true);
    }
  }

  Future<void> reset() async {
    _lastCheckpoint = null;
    _bootstrapDone = false;
    await _storageService.remove(_lastCheckpointKey);
    await _storageService.setBool(_bootstrapDoneKey, false);
  }
}
