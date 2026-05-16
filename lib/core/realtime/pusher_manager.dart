import 'dart:async';
import 'dart:convert';

import 'package:common_package/helpers/logger_interceptor.dart';
import 'package:common_package/helpers/pusher_service_logger.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/core/app_config.dart';
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

  final Map<String, int> _channelRefCount = <String, int>{};
  final Set<String> _subscribedChannels = <String>{};
  final Map<String, Map<int, _RealtimeListenerEntry>> _listenersByChannel =
      <String, Map<int, _RealtimeListenerEntry>>{};

  Future<void> ensureInitialized() async {
    if (AppConfig.pusherKey.isEmpty) {
      PusherServiceLogger.skippedNoPusherKey();
      return;
    }
    if (_initialized) return;

    PusherServiceLogger.init(
      cluster: AppConfig.pusherCluster,
      authEndpoint: '${AppConfig.baseUrl}/broadcasting/auth',
      hasApiKey: AppConfig.pusherKey.isNotEmpty,
      useTls: true,
    );

    await _clientBridge.init(
      apiKey: AppConfig.pusherKey,
      cluster: AppConfig.pusherCluster,
      useTls: true,
      onAuthorizer: _authorizePrivateChannel,
      onSubscriptionError: (message, e) {
        PusherServiceLogger.subscriptionError('(subscription)', message, e);
      },
      onError: (message, code, e) {
        PusherServiceLogger.socketError(message, code, e);
      },
      onSubscriptionSucceeded: (channelName, data) {
        PusherServiceLogger.subscriptionSucceeded(channelName, data);
      },
      onConnectionStateChange: _onConnectionStateChange,
      onEvent: _handleRawEvent,
    );

    PusherServiceLogger.connect();
    await _clientBridge.connect();
    _initialized = true;
  }

  Future<RealtimeListenerHandle> listen({
    required String channelName,
    Set<String>? eventNames,
    required RealtimeEventCallback onEvent,
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
      PusherServiceLogger.authAuthorizerError(channelName, e, st);
      rethrow;
    }
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
    final isConnected = currentState.toLowerCase() == 'connected';
    if (!isConnected) {
      _subscribedChannels.clear();
      return;
    }
    unawaited(_resubscribeActiveChannels());
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
          !listener.eventNames!.contains(rawEvent.eventName)) {
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
}

class _RealtimeListenerEntry {
  const _RealtimeListenerEntry({
    required this.id,
    required this.eventNames,
    required this.onEvent,
  });

  final int id;
  final Set<String>? eventNames;
  final RealtimeEventCallback onEvent;
}
