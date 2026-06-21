import 'package:flutter_test/flutter_test.dart';
import 'package:monitored_app/core/services/bulk_collect_planner.dart';

void main() {
  group('BulkCollectPlanner', () {
    test('keeps each bulk request within backend item limits', () {
      final requests = BulkCollectPlanner.planRequests<int>(
        itemsByType: <String, List<int>>{
          'messages': List<int>.generate(149, (index) => index),
          'calls': List<int>.generate(140, (index) => index),
          'app_info': List<int>.generate(160, (index) => index),
        },
      );

      expect(requests, isNotEmpty);

      for (final request in requests) {
        expect(
          request.totalItems,
          lessThanOrEqualTo(BulkCollectLimits.defaultMaxItemsPerBulk),
        );

        final typeCounts = <String, int>{};
        for (final batch in request.batches) {
          typeCounts.update(
            batch.dataType,
            (count) => count + batch.itemCount,
            ifAbsent: () => batch.itemCount,
          );
        }

        for (final count in typeCounts.values) {
          expect(
            count,
            lessThanOrEqualTo(BulkCollectLimits.defaultMaxItemsPerDataType),
          );
        }
      }
    });

    test('preserves source indexes when chunking a data type', () {
      final requests = BulkCollectPlanner.planRequests<String>(
        itemsByType: <String, List<String>>{
          'messages': List<String>.generate(105, (index) => 'sms-$index'),
        },
      );

      final batches =
          requests.expand((request) => request.batches).toList(growable: false);

      expect(batches, hasLength(2));
      expect(batches.first.itemCount, 100);
      expect(batches.last.itemCount, 5);
      expect(batches.first.sourceIndexes.first, 0);
      expect(batches.first.sourceIndexes.last, 99);
      expect(batches.last.sourceIndexes, <int>[100, 101, 102, 103, 104]);
    });

    test('uses reduced limits for retry re-packing', () {
      final limits = const BulkCollectLimits(
        maxItemsPerBulk: 200,
        maxItemsPerDataType: 100,
      ).reducedForRetry();

      final requests = BulkCollectPlanner.planRequests<int>(
        itemsByType: <String, List<int>>{
          'messages': List<int>.generate(100, (index) => index),
          'calls': List<int>.generate(80, (index) => index),
        },
        limits: limits,
      );

      for (final request in requests) {
        expect(request.totalItems, lessThanOrEqualTo(100));
        for (final batch in request.batches) {
          expect(batch.itemCount, lessThanOrEqualTo(50));
        }
      }
    });
  });
}
