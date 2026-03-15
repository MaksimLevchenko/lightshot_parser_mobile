import 'package:flutter/foundation.dart';

enum AppLogLevel {
  info,
  warning,
  error,
}

final class AppLogger {
  const AppLogger._();

  static void info(String message, {String scope = 'app'}) {
    _log(AppLogLevel.info, message, scope: scope);
  }

  static void warning(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      AppLogLevel.warning,
      message,
      scope: scope,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      AppLogLevel.error,
      message,
      scope: scope,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    AppLogLevel level,
    String message, {
    required String scope,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(level)) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelName = switch (level) {
      AppLogLevel.info => 'INFO',
      AppLogLevel.warning => 'WARN',
      AppLogLevel.error => 'ERROR',
    };

    _write('[$timestamp][$levelName][$scope] $message');

    if (error != null) {
      _write('[$timestamp][$levelName][$scope] $error');
    }

    if (stackTrace != null) {
      for (final line in stackTrace.toString().split('\n')) {
        if (line.trim().isEmpty) {
          continue;
        }
        _write('[$timestamp][$levelName][$scope] $line');
      }
    }
  }

  static void _write(String line) {
    debugPrintSynchronously(line);
  }

  static bool _shouldLog(AppLogLevel level) {
    if (kDebugMode) {
      return true;
    }

    return level != AppLogLevel.info;
  }
}
