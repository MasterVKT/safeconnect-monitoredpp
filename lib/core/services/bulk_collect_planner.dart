import 'dart:math' as math;

class BulkCollectLimits {
  static const int defaultMaxItemsPerBulk = 200;
  static const int defaultMaxItemsPerDataType = 100;

  final int maxItemsPerBulk;
  final int maxItemsPerDataType;

  const BulkCollectLimits({
    this.maxItemsPerBulk = defaultMaxItemsPerBulk,
    this.maxItemsPerDataType = defaultMaxItemsPerDataType,
  })  : assert(maxItemsPerBulk > 0),
        assert(maxItemsPerDataType > 0);

  int get maxItemsPerBatch => math.min(maxItemsPerBulk, maxItemsPerDataType);

  BulkCollectLimits reducedForRetry() {
    return BulkCollectLimits(
      maxItemsPerBulk: math.max(1, maxItemsPerBulk ~/ 2),
      maxItemsPerDataType: math.max(1, maxItemsPerDataType ~/ 2),
    );
  }
}

class BulkCollectBatch<T> {
  final String dataType;
  final List<T> items;
  final List<int> sourceIndexes;

  const BulkCollectBatch({
    required this.dataType,
    required this.items,
    required this.sourceIndexes,
  }) : assert(items.length == sourceIndexes.length);

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  List<BulkCollectBatch<T>> split(int maxItemsPerBatch) {
    if (items.isEmpty) {
      return <BulkCollectBatch<T>>[];
    }

    final chunkSize = math.max(1, maxItemsPerBatch);
    final chunks = <BulkCollectBatch<T>>[];

    for (var start = 0; start < items.length; start += chunkSize) {
      final end = math.min(start + chunkSize, items.length);
      chunks.add(
        BulkCollectBatch<T>(
          dataType: dataType,
          items: List<T>.unmodifiable(items.sublist(start, end)),
          sourceIndexes:
              List<int>.unmodifiable(sourceIndexes.sublist(start, end)),
        ),
      );
    }

    return chunks;
  }
}

class BulkCollectRequest<T> {
  final List<BulkCollectBatch<T>> batches;

  const BulkCollectRequest({
    required this.batches,
  });

  int get totalItems {
    return batches.fold<int>(0, (sum, batch) => sum + batch.itemCount);
  }
}

class BulkCollectPlanner {
  const BulkCollectPlanner._();

  static List<BulkCollectRequest<T>> planRequests<T>({
    required Map<String, List<T>> itemsByType,
    BulkCollectLimits limits = const BulkCollectLimits(),
  }) {
    final typeChunks = <BulkCollectBatch<T>>[];
    final maxChunkSize = limits.maxItemsPerBatch;

    for (final entry in itemsByType.entries) {
      final items = entry.value;
      for (var start = 0; start < items.length; start += maxChunkSize) {
        final end = math.min(start + maxChunkSize, items.length);
        typeChunks.add(
          BulkCollectBatch<T>(
            dataType: entry.key,
            items: List<T>.unmodifiable(items.sublist(start, end)),
            sourceIndexes:
                List<int>.unmodifiable(List<int>.generate(end - start, (i) {
              return start + i;
            })),
          ),
        );
      }
    }

    return packBatches<T>(typeChunks, limits: limits);
  }

  static List<BulkCollectRequest<T>> packBatches<T>(
    Iterable<BulkCollectBatch<T>> batches, {
    BulkCollectLimits limits = const BulkCollectLimits(),
  }) {
    final pending = <BulkCollectBatch<T>>[];
    for (final batch in batches) {
      if (batch.isEmpty) {
        continue;
      }

      pending.addAll(batch.split(limits.maxItemsPerBatch));
    }

    final requests = <BulkCollectRequest<T>>[];

    while (pending.isNotEmpty) {
      final requestBatches = <BulkCollectBatch<T>>[];
      final requestDataTypes = <String>{};
      var requestItems = 0;
      var index = 0;

      while (index < pending.length) {
        final candidate = pending[index];
        final repeatsType = requestDataTypes.contains(candidate.dataType);
        final exceedsTotal =
            requestItems + candidate.itemCount > limits.maxItemsPerBulk;

        if (repeatsType || exceedsTotal) {
          index++;
          continue;
        }

        requestBatches.add(candidate);
        requestDataTypes.add(candidate.dataType);
        requestItems += candidate.itemCount;
        pending.removeAt(index);

        if (requestItems == limits.maxItemsPerBulk) {
          break;
        }
      }

      if (requestBatches.isEmpty) {
        requestBatches.add(pending.removeAt(0));
      }

      requests.add(
        BulkCollectRequest<T>(
          batches: List<BulkCollectBatch<T>>.unmodifiable(requestBatches),
        ),
      );
    }

    return requests;
  }
}
