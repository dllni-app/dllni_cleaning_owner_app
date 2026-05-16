import 'dart:convert';

import 'package:logger/logger.dart';

/// Logs Pusher lifecycle, subscriptions, and events using the same
/// [PrettyPrinter] configuration as [LoggerInterceptor].
abstract final class PusherServiceLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 75,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static String _prettyJson(dynamic data) {
    try {
      if (data is String) {
        final decoded = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  static void skippedNoPusherKey() {
    _logger.w('[Pusher] skipped (empty pusher key)');
  }

  static void init({
    required String cluster,
    required bool hasApiKey,
    bool useTls = true,
    String? authEndpoint,
  }) {
    _logger.i(
      '[Pusher] init\n'
      'cluster: $cluster\n'
      'authEndpoint: ${authEndpoint ?? '(custom authorizer)'}\n'
      'useTLS: $useTls\n'
      'hasApiKey: $hasApiKey',
    );
  }

  static void connect() {
    _logger.i('[Pusher] connect()');
  }

  static void connectionStateChange(dynamic current, dynamic previous) {
    _logger.i('[Pusher] connection state => $current (previous: $previous)');
  }

  static void subscriptionSucceeded(String channel, dynamic data) {
    _logger.i(
      '[Pusher] subscription succeeded => $channel\n'
      'Data: ${_prettyJson(data)}',
    );
  }

  static void subscriptionError(String channel, dynamic message, dynamic e) {
    _logger.e(
      '[Pusher] subscription error => $channel\nmessage: $message',
      error: e,
    );
  }

  static void socketError(dynamic message, dynamic code, dynamic e) {
    _logger.e(
      '[Pusher] onError\n'
      'message: $message\n'
      'code: $code',
      error: e,
    );
  }

  static void event(
    String channel,
    String eventName,
    dynamic rawData, {
    int? eventReceivedAtMs,
    int? eventHandledAtMs,
    String? fallbackReason,
  }) {
    final message = StringBuffer()
      ..writeln('[Pusher] EVENT => $eventName')
      ..writeln('channel: $channel');
    if (eventReceivedAtMs != null) {
      message.writeln('eventReceivedAtMs: $eventReceivedAtMs');
    }
    if (eventHandledAtMs != null) {
      message.writeln('eventHandledAtMs: $eventHandledAtMs');
    }
    if (fallbackReason != null) {
      message.writeln('fallbackReason: $fallbackReason');
    }
    message.write('data: ${_prettyJson(rawData)}');
    _logger.i(message.toString());
  }

  static void subscribe(String channel) {
    _logger.i('[Pusher] SUBSCRIBE => $channel');
  }

  static void unsubscribe(String channel) {
    _logger.i('[Pusher] UNSUBSCRIBE => $channel');
  }

  static void authAuthorizerError(
    String channelName,
    Object e,
    StackTrace? stackTrace,
  ) {
    _logger.e(
      '[Pusher] broadcasting auth error => $channelName',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
