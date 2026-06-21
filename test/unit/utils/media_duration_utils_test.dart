import 'package:flutter_test/flutter_test.dart';
import 'package:monitored_app/core/utils/media_duration_utils.dart';

void main() {
  group('mediaDurationMillisecondsFromSeconds', () {
    test('converts integer seconds to milliseconds', () {
      expect(
        mediaDurationMillisecondsFromSeconds(10, fallbackSeconds: 30),
        10000,
      );
    });

    test('preserves fractional seconds with millisecond precision', () {
      expect(
        mediaDurationMillisecondsFromSeconds(1.25, fallbackSeconds: 30),
        1250,
      );
    });

    test('accepts numeric strings returned by platform integrations', () {
      expect(
        mediaDurationMillisecondsFromSeconds('2.5', fallbackSeconds: 30),
        2500,
      );
    });

    test('uses the fallback for invalid or negative values', () {
      expect(
        mediaDurationMillisecondsFromSeconds(null, fallbackSeconds: 30),
        30000,
      );
      expect(
        mediaDurationMillisecondsFromSeconds(-1, fallbackSeconds: 30),
        30000,
      );
      expect(
        mediaDurationMillisecondsFromSeconds(null, fallbackSeconds: -1),
        0,
      );
    });
  });
}
