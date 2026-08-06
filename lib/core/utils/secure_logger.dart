import 'package:flutter/foundation.dart';

class SecureLogger {
  static void log(String message, {String? tag}) {
    // Zero telemetry policy: NEVER log anything in release mode
    // to prevent ID, filepath, or metadata leaks into crash dumps or OS logcat.
    if (!kReleaseMode) {
      debugPrint('${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // In Release mode, we still enforce zero telemetry. No errors are sent to 
    // analytics providers per the Threat Model.
    if (!kReleaseMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint(error.toString());
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }
}
