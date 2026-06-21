import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/database_service.dart';

class CollectionLeaseOwner {
  static const String mainIsolate = 'main_isolate';
  static const String backgroundIsolate = 'background_isolate';

  const CollectionLeaseOwner._();
}

class CollectionOwnershipService {
  final DatabaseService _databaseService;

  CollectionOwnershipService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? locator<DatabaseService>();

  Future<bool> tryAcquire({
    required String owner,
    required Duration ttl,
  }) async {
    try {
      return await _databaseService.tryAcquireCollectionLease(
        owner: owner,
        ttl: ttl,
      );
    } catch (e, stackTrace) {
      debugPrint('Collection lease acquisition failed for $owner: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> heartbeat(String owner) async {
    try {
      return await _databaseService.touchCollectionLease(owner);
    } catch (e, stackTrace) {
      debugPrint('Collection lease heartbeat failed for $owner: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> release(String owner) async {
    try {
      await _databaseService.releaseCollectionLease(owner);
    } catch (e, stackTrace) {
      debugPrint('Collection lease release failed for $owner: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<String?> currentOwner() {
    return _databaseService.getCollectionLeaseOwner();
  }
}
