import 'dart:async';
import 'dart:io';

import 'package:common_package/helpers/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Captures console output to a file from the moment [init] is called.
/// Each app launch creates a new log file under `<documents>/logs/`.
abstract final class AppDebugLogger {
  static const _maxRetainedLogFiles = 30;

  static File? _logFile;
  static DebugPrintCallback? _originalDebugPrint;
  static FlutterExceptionHandler? _originalFlutterOnError;
  static bool Function(Object, StackTrace)? _originalPlatformOnError;

  static String? get logFilePath => _logFile?.path;

  static String _formatTimestamp(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    String three(int value) => value.toString().padLeft(3, '0');

    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}.'
        '${three(dateTime.millisecond)}';
  }

  static String _formatRunId(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    String three(int value) => value.toString().padLeft(3, '0');

    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)}_'
        '${two(dateTime.hour)}-${two(dateTime.minute)}-${two(dateTime.second)}-'
        '${three(dateTime.millisecond)}';
  }

  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }

      final runId = _formatRunId(DateTime.now());
      _logFile = File('${logsDir.path}/run_$runId.log');
      await _pruneOldLogs(logsDir);

      await _write(
        'SESSION',
        'Debug log started at ${DateTime.now().toIso8601String()}',
      );
      await _write('SESSION', 'Log file path: ${_logFile!.path}');

      appLogSink = _handleAppLog;

      _originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && message.isNotEmpty) {
          unawaited(_write('DEBUG', message));
        }
        _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      };

      _originalFlutterOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        unawaited(
          _write(
            'FLUTTER',
            details.exceptionAsString(),
            stackTrace: details.stack,
          ),
        );
        _originalFlutterOnError?.call(details);
      };

      _originalPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(_write('ASYNC', error.toString(), stackTrace: stack));
        return _originalPlatformOnError?.call(error, stack) ?? false;
      };

      debugPrint('App debug log file: ${_logFile!.path}');
    } catch (error, stackTrace) {
      debugPrint('AppDebugLogger.init failed: $error\n$stackTrace');
    }
  }

  static void recordPrint(String line) {
    unawaited(_write('PRINT', line));
  }

  static void recordError(
    String tag,
    Object error,
    StackTrace stackTrace,
  ) {
    unawaited(_write(tag, error.toString(), stackTrace: stackTrace));
  }

  static void _handleAppLog(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? name,
  }) {
    final tag = name == null || name.isEmpty ? 'LOG' : 'LOG:$name';
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.writeln();
      buffer.write('Error: $error');
    }
    unawaited(_write(tag, buffer.toString(), stackTrace: stackTrace));
  }

  static Future<void> _pruneOldLogs(Directory logsDir) async {
    final logFiles = logsDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.log'))
        .toList()
      ..sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

    for (final file in logFiles.skip(_maxRetainedLogFiles)) {
      try {
        file.deleteSync();
      } catch (_) {
        // Ignore cleanup failures.
      }
    }
  }

  static Future<void> _write(
    String tag,
    String message, {
    StackTrace? stackTrace,
  }) async {
    final file = _logFile;
    if (file == null) {
      return;
    }

    try {
      final timestamp = _formatTimestamp(DateTime.now());
      final buffer = StringBuffer('[$timestamp] [$tag] $message');
      if (stackTrace != null) {
        buffer.writeln();
        buffer.write(stackTrace);
      }

      await file.writeAsString(
        '${buffer.toString()}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Ignore file write failures so logging never crashes the app.
    }
  }
}
