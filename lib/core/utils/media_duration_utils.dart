int mediaDurationMillisecondsFromSeconds(
  dynamic value, {
  required int fallbackSeconds,
}) {
  final parsedSeconds = switch (value) {
    num seconds => seconds.toDouble(),
    String seconds => double.tryParse(seconds),
    _ => null,
  };
  final safeFallbackSeconds = fallbackSeconds >= 0 ? fallbackSeconds : 0;
  final seconds =
      parsedSeconds != null && parsedSeconds.isFinite && parsedSeconds >= 0
          ? parsedSeconds
          : safeFallbackSeconds.toDouble();

  return (seconds * Duration.millisecondsPerSecond).round();
}
