import 'dart:collection';

class PendingSyncSelector {
  const PendingSyncSelector._();

  static List<T> selectFairly<T>({
    required Iterable<T> items,
    required String Function(T item) dataTypeOf,
    required int Function(T item) priorityOf,
    required int totalLimit,
    required int limitPerType,
  }) {
    if (totalLimit <= 0 || limitPerType <= 0) {
      return <T>[];
    }

    final queuesByPriority =
        SplayTreeMap<int, LinkedHashMap<String, Queue<T>>>();
    for (final item in items) {
      final queuesByType = queuesByPriority.putIfAbsent(
        priorityOf(item),
        LinkedHashMap<String, Queue<T>>.new,
      );
      queuesByType.putIfAbsent(dataTypeOf(item), Queue<T>.new).addLast(item);
    }

    final selected = <T>[];
    final selectedByType = <String, int>{};

    for (final queuesByType in queuesByPriority.values) {
      var selectedInRound = true;
      while (selected.length < totalLimit && selectedInRound) {
        selectedInRound = false;

        for (final entry in queuesByType.entries) {
          if (selected.length >= totalLimit) {
            break;
          }

          final dataType = entry.key;
          final queue = entry.value;
          final selectedCount = selectedByType[dataType] ?? 0;
          if (queue.isEmpty || selectedCount >= limitPerType) {
            continue;
          }

          selected.add(queue.removeFirst());
          selectedByType[dataType] = selectedCount + 1;
          selectedInRound = true;
        }
      }
    }

    return selected;
  }
}
