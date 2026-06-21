import 'package:flutter_test/flutter_test.dart';
import 'package:monitored_app/core/sync/pending_sync_selector.dart';

class _PendingItem {
  final String type;
  final int priority;
  final int sequence;

  const _PendingItem(this.type, this.priority, this.sequence);
}

void main() {
  group('PendingSyncSelector', () {
    test('balances same-priority items across data types', () {
      final items = <_PendingItem>[
        ...List.generate(12, (index) => _PendingItem('sms', 2, index)),
        ...List.generate(4, (index) => _PendingItem('calls', 2, index)),
        ...List.generate(4, (index) => _PendingItem('app_usage', 2, index)),
      ];

      final selected = PendingSyncSelector.selectFairly(
        items: items,
        dataTypeOf: (item) => item.type,
        priorityOf: (item) => item.priority,
        totalLimit: 9,
        limitPerType: 10,
      );

      expect(
        selected.map((item) => item.type),
        <String>[
          'sms',
          'calls',
          'app_usage',
          'sms',
          'calls',
          'app_usage',
          'sms',
          'calls',
          'app_usage',
        ],
      );
    });

    test('preserves priority before balancing lower-priority types', () {
      final items = <_PendingItem>[
        const _PendingItem('calls', 1, 0),
        const _PendingItem('sms', 1, 0),
        const _PendingItem('media', 2, 0),
      ];

      final selected = PendingSyncSelector.selectFairly(
        items: items,
        dataTypeOf: (item) => item.type,
        priorityOf: (item) => item.priority,
        totalLimit: 2,
        limitPerType: 10,
      );

      expect(selected.map((item) => item.priority), everyElement(1));
    });

    test('enforces the per-type bootstrap quota', () {
      final items = List.generate(10, (index) => _PendingItem('sms', 2, index));

      final selected = PendingSyncSelector.selectFairly(
        items: items,
        dataTypeOf: (item) => item.type,
        priorityOf: (item) => item.priority,
        totalLimit: 10,
        limitPerType: 3,
      );

      expect(selected.map((item) => item.sequence), <int>[0, 1, 2]);
    });
  });
}
