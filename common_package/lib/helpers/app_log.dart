import 'dart:developer' as developer;

typedef AppLogSink = void Function(
  String message, {
  Object? error,
  StackTrace? stackTrace,
  String? name,
});

AppLogSink? appLogSink;

void appLog(
  String message, {
  Object? error,
  StackTrace? stackTrace,
  String? name,
}) {
  appLogSink?.call(
    message,
    error: error,
    stackTrace: stackTrace,
    name: name,
  );
  developer.log(
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? '',
  );
}
