import 'dart:async';
import 'dart:convert';

import 'package:common_package/helpers/logger_interceptor.dart';
import 'package:common_package/helpers/pusher_service_logger.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/core/app_config.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class RealtimeEvent {
  const RealtimeEvent({
    required this.channelName,
    required this.eventName,
    required this.payload,
    required this.receivedAtMs,
  });

  final String channelName;
  final String eventName;
  final Map<String, dynamic> payload;
  final int receivedAtMs;
}

class RealtimeChannelError {
  const RealtimeChannelError({
    required this.channelName,
    required this.message,
    this.statusCode,
    this.rawError,
  });

  final String channelName;
  final String message;
  final int? statusCode;
  final dynamic rawError;
}

class RealtimeListenerHandle {
  RealtimeListenerHandle(this._disposeInternal);

  final Future<void> Function() _disposeInternal;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _disposeInternal();
  }
}

typedef RealtimeEventCallback = void Function(RealtimeEvent event);
typedef RealtimeChannelErrorCallback =
    void Function(RealtimeChannelError error);

abstract class PusherClientBridge {
  Future<void> init({
    required String apiKey,
    required String cluster,
    required bool useTls,
    required Future<Map<String, dynamic>> Function(
      String channelName,
      String socketId,
      dynamic options,
    )
    onAuthorizer,
    required void Function(String message, dynamic error) onSubscriptionError,
    required void Function(String message, int? code, dynamic error) onError,
    required void Function(String channelName, dynamic data)
    onSubscriptionSucceeded,
    required void Function(String currentState, String previousState)
    onConnectionStateChange,
    required void Function(PusherEvent event) onEvent,
  });

  Future<void> connect();

  Future<void> disconnect();

  Future<void> subscribe({required String channelName});

  Future<void> unsubscribe({required String channelName});
}

class PusherChannelsClientBridge implements PusherClientBridge {
  PusherChannelsClientBridge(this._inner);

  final PusherChannelsFlutter _inner;

  @override
  Future<void> connect() {
    return _inner.connect();
  }

  @override
  Future<void> disconnect() {
    return _inner.disconnect();
  }

  @override
  Future<void> init({
    required String apiKey,
    required String cluster,
    required bool useTls,
    required Future<Map<String, dynamic>> Function(
      String channelName,
      String socketId,
      dynamic options,
    )
    onAuthorizer,
    required void Function(String message, dynamic error) onSubscriptionError,
    required void Function(String message, int? code, dynamic error) onError,
    required void Function(String channelName, dynamic data)
    onSubscriptionSucceeded,
    required void Function(String currentState, String previousState)
    onConnectionStateChange,
    required void Function(PusherEvent event) onEvent,
  }) {
    return _inner.init(
      apiKey: apiKey,
      cluster: cluster,
      useTLS: useTls,
      onAuthorizer: onAuthorizer,
      onSubscriptionError: onSubscriptionError,
      onError: onError,
      onSubscriptionSucceeded: onSubscriptionSucceeded,
      onConnectionStateChange: onConnectionStateChange,
      onEvent: onEvent,
    );
  }

  @override
  Future<void> subscribe({required String channelName}) {
    return _inner.subscribe(channelName: channelName);
  }

  @override
  Future<void> unsubscribe({required String channelName}) {
    return _inner.unsubscribe(channelName: channelName);
  }
}

class PusherManager {
  PusherManager({PusherClientBridge? clientBridge, Dio? authDio})
    : _clientBridge =
          clientBridge ??
          PusherChannelsClientBridge(PusherChannelsFlutter.getInstance()),
      _authDio =
          authDio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              responseType: ResponseType.json,
              contentType: Headers.formUrlEncodedContentType,
            ),
          ) {
    _authDio.interceptors.add(LoggerInterceptor());
  }

  final PusherClientBridge _clientBridge;
  final Dio _authDio;

  bool _initialized = false;
  int _nextListenerId = 0;
  Completer<void>? _initializationCompleter;
  Completer<void>? _connectionCompleter;

  final Map<String, int> _channelRefCount = <String, int>{};
  final Set<String> _subscribedChannels = <String>{};
  final Map<String, Map<int, _RealtimeListenerEntry>> _listenersByChannel =
      <String, Map<int, _RealtimeListenerEntry>>{};

  Future<void> ensureInitialized() async {
    if (AppConfig.pusherKey.isEmpty) return;

    // 1. إذا كان مهيأً ومتصلاً، لا تفعل شيئاً
    if (_initialized && _connectionCompleter != null) {
      return _connectionCompleter!.future;
    }

    // 2. إذا كانت هناك عملية جارية، انتظرها
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();
    _connectionCompleter = Completer<void>();

    try {
      await _clientBridge.init(
        apiKey: AppConfig.pusherKey,
        cluster: AppConfig.pusherCluster,
        useTls: true, // يفضل دائماً استخدام TLS للاتصال الآمن
        onAuthorizer: _authorizePrivateChannel, // الدالة التي تقوم بعملية الـ Auth مع السيرفر
        onSubscriptionError: _handleSubscriptionError, // التعامل مع أخطاء الاشتراك
        onError: _handleSocketError, // التعامل مع أخطاء الاتصال العامة
        onSubscriptionSucceeded: (channelName, data) {
          PusherServiceLogger.subscriptionSucceeded(channelName, data);
        },
        onConnectionStateChange: _onConnectionStateChange, // لمراقبة حالات الاتصال (Connected/Disconnected)
        onEvent: _handleRawEvent, // الدالة الأساسية لاستقبال كل الأحداث القادمة من Pusher
      );

      // ربط الـ Completer بعملية الاتصال
      await _clientBridge.connect();

      _initialized = true;
      _initializationCompleter!.complete();
      _connectionCompleter!.complete();
    } catch (e) {
      _initializationCompleter!.completeError(e);
      _initializationCompleter = null;
      _connectionCompleter = null;
      rethrow;
    }
  }

  Future<RealtimeListenerHandle> listen({
    required String channelName,
    Set<String>? eventNames,
    required RealtimeEventCallback onEvent,
    RealtimeChannelErrorCallback? onChannelError,
  }) async {
    if (AppConfig.pusherKey.isEmpty) {
      return RealtimeListenerHandle(() async {});
    }
    await ensureInitialized();
    if (!_initialized) {
      return RealtimeListenerHandle(() async {});
    }

    final normalizedEvents = eventNames?.map((e) => e.trim()).toSet();
    final listenerId = _nextListenerId++;
    final channelListeners = _listenersByChannel.putIfAbsent(
      channelName,
      () => <int, _RealtimeListenerEntry>{},
    );
    channelListeners[listenerId] = _RealtimeListenerEntry(
      id: listenerId,
      eventNames: normalizedEvents,
      onEvent: onEvent,
      onChannelError: onChannelError,
    );

    final nextRefCount = (_channelRefCount[channelName] ?? 0) + 1;
    _channelRefCount[channelName] = nextRefCount;
    if (nextRefCount == 1) {
      await _subscribeChannel(channelName);
    }

    return RealtimeListenerHandle(() async {
      await _removeListener(channelName, listenerId);
    });
  }

  Future<void> disposeAllForSession() async {
    _listenersByChannel.clear();
    _channelRefCount.clear();
    final channels = _subscribedChannels.toList(growable: false);
    for (final channel in channels) {
      await _unsubscribeChannel(channel);
    }
    _subscribedChannels.clear();
    if (_initialized) {
      await _clientBridge.disconnect();
    }
    _initialized = false;
    _initializationCompleter = null;
    _connectionCompleter = null;
  }

  Future<Map<String, dynamic>> _authorizePrivateChannel(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    try {
      final token = (SharedPreferencesHelper.getData(key: 'token') ?? '')
          .toString();
      final res = await _authDio.post<Map<String, dynamic>>(
        '/broadcasting/auth',
        data: <String, dynamic>{
          'channel_name': channelName,
          'socket_id': socketId,
        },
        options: Options(
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );
      final body = res.data;
      if (body == null || body['auth'] == null) {
        throw StateError('Invalid broadcasting auth response');
      }
      return <String, dynamic>{
        'auth': body['auth'],
        if (body['channel_data'] != null) 'channel_data': body['channel_data'],
      };
    } catch (e, st) {
      _emitChannelError(
        channelName: channelName,
        message: 'Broadcasting auth failed',
        statusCode: _extractStatusCode(e),
        rawError: e,
      );
      PusherServiceLogger.authAuthorizerError(channelName, e, st);
      rethrow;
    }
  }

  void _handleSubscriptionError(String message, dynamic error) {
    final channelName = _extractChannelNameFromMessage(message);
    if (channelName != null) {
      _emitChannelError(
        channelName: channelName,
        message: message,
        statusCode: _extractStatusCode(error) ?? _extractStatusCode(message),
        rawError: error,
      );
      PusherServiceLogger.subscriptionError(channelName, message, error);
      return;
    }
    PusherServiceLogger.subscriptionError('(subscription)', message, error);
  }

  void _handleSocketError(String message, int? code, dynamic error) {
    final channelName = _extractChannelNameFromMessage(message);
    if (channelName != null) {
      _emitChannelError(
        channelName: channelName,
        message: message,
        statusCode: code ?? _extractStatusCode(error),
        rawError: error,
      );
    }
    PusherServiceLogger.socketError(message, code, error);
  }

  Future<void> _removeListener(String channelName, int listenerId) async {
    final listeners = _listenersByChannel[channelName];
    if (listeners == null) return;

    listeners.remove(listenerId);
    if (listeners.isEmpty) {
      _listenersByChannel.remove(channelName);
    }

    final currentRefCount = _channelRefCount[channelName] ?? 0;
    if (currentRefCount <= 1) {
      _channelRefCount.remove(channelName);
      await _unsubscribeChannel(channelName);
      return;
    }

    _channelRefCount[channelName] = currentRefCount - 1;
  }

  Future<void> _subscribeChannel(String channelName) async {
    if (_subscribedChannels.contains(channelName)) return;
    PusherServiceLogger.subscribe(channelName);
    await _clientBridge.subscribe(channelName: channelName);
    _subscribedChannels.add(channelName);
  }

  Future<void> _unsubscribeChannel(String channelName) async {
    if (!_subscribedChannels.contains(channelName)) return;
    PusherServiceLogger.unsubscribe(channelName);
    await _clientBridge.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    PusherServiceLogger.connectionStateChange(currentState, previousState);

    final state = currentState.toLowerCase();

    // 1. لا تقم بمسح _subscribedChannels هنا أبداً.
    // مكتبة Pusher تحتفظ بقائمة الاشتراكات داخلياً وتحاول إعادة الاتصال بها تلقائياً.
    // مسحها يمنع النظام من معرفة القنوات التي يجب أن يعيد الاشتراك بها.

    // 2. إذا أصبح الاتصال جاهزاً (CONNECTED)، تأكد فقط من أن جميع القنوات التي
    // تحتاجها (المخزنة في _channelRefCount) قد تم الاشتراك بها فعلياً.
    if (state == 'connected') {
      unawaited(_resubscribeActiveChannels());
    }
  }

  Future<void> _resubscribeActiveChannels() async {
    final channels = _channelRefCount.keys.toList(growable: false);
    for (final channelName in channels) {
      if (_subscribedChannels.contains(channelName)) continue;
      await _subscribeChannel(channelName);
    }
  }

  void _handleRawEvent(PusherEvent rawEvent) {
    final channelName = rawEvent.channelName;
    final listeners = _listenersByChannel[channelName];
    if (listeners == null || listeners.isEmpty) return;

    final receivedAtMs = DateTime.now().millisecondsSinceEpoch;
    final payload = _parsePayload(rawEvent.data);
    final realtimeEvent = RealtimeEvent(
      channelName: channelName,
      eventName: rawEvent.eventName,
      payload: payload,
      receivedAtMs: receivedAtMs,
    );

    PusherServiceLogger.event(
      rawEvent.channelName,
      rawEvent.eventName,
      rawEvent.data,
      eventReceivedAtMs: receivedAtMs,
    );

    for (final listener in listeners.values) {
      if (listener.eventNames != null &&
          !CleaningRealtimeContract.matchesEventFilter(
            listener.eventNames!,
            rawEvent.eventName,
          )) {
        continue;
      }
      listener.onEvent(realtimeEvent);
      final handledAtMs = DateTime.now().millisecondsSinceEpoch;
      PusherServiceLogger.event(
        rawEvent.channelName,
        rawEvent.eventName,
        rawEvent.data,
        eventReceivedAtMs: receivedAtMs,
        eventHandledAtMs: handledAtMs,
      );
    }
  }

  Map<String, dynamic> _parsePayload(dynamic rawData) {
    if (rawData is Map) {
      return rawData.map((key, value) => MapEntry(key.toString(), value));
    }
    if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  void _emitChannelError({
    required String channelName,
    required String message,
    int? statusCode,
    dynamic rawError,
  }) {
    final listeners = _listenersByChannel[channelName];
    if (listeners == null || listeners.isEmpty) return;
    final channelError = RealtimeChannelError(
      channelName: channelName,
      message: message,
      statusCode: statusCode,
      rawError: rawError,
    );
    for (final listener in listeners.values) {
      final callback = listener.onChannelError;
      if (callback == null) continue;
      callback(channelError);
    }
  }

  String? _extractChannelNameFromMessage(dynamic rawMessage) {
    final message = '$rawMessage';
    final match = RegExp(r'private-[A-Za-z0-9_.-]+').firstMatch(message);
    return match?.group(0);
  }

  int? _extractStatusCode(dynamic value) {
    if (value is DioException) {
      return value.response?.statusCode;
    }
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Map) {
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      return _extractStatusCode(
        map['statusCode'] ?? map['status_code'] ?? map['status'] ?? map['code'],
      );
    }
    final text = '$value';
    final match = RegExp(r'\b(4\d{2}|5\d{2})\b').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }
}

class _RealtimeListenerEntry {
  const _RealtimeListenerEntry({
    required this.id,
    required this.eventNames,
    required this.onEvent,
    required this.onChannelError,
  });

  final int id;
  final Set<String>? eventNames;
  final RealtimeEventCallback onEvent;
  final RealtimeChannelErrorCallback? onChannelError;
}
