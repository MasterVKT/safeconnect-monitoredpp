import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ErrorLogger {
  static void logError(String message, dynamic error, StackTrace stackTrace) {
    // Log local
    debugPrint('ERROR: $message');

    try {
      // Log Crashlytics (non fatal)
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    } catch (loggingError) {
      debugPrint('Crashlytics logging skipped: $loggingError');
    }
  }
}
