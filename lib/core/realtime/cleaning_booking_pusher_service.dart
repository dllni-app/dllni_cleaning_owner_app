import 'dart:convert';

import 'package:common_package/helpers/logger_interceptor.dart';
import 'package:common_package/helpers/pusher_service_logger.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../app_config.dart';

typedef CleaningBookingEventHandler =
    void Function(String eventName, Map<String, dynamic> payload);

@lazySingleton
class CleaningBookingPusherService {
  CleaningBookingPusherService() {
    _authDio.interceptors.add(LoggerInterceptor());
  }

  final Dio _authDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      responseType: ResponseType.json,
      contentType: Headers.formUrlEncodedContentType,
    ),
  );
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _initialized = false;
  String? _activeBookingChannel;
  String? _activeWorkerChannel;
  final Map<int, CleaningBookingEventHandler> _bookingHandlers = {};
  final Map<int, CleaningBookingEventHandler> _workerHandlers = {};

  void setBookingHandler(int bookingId, CleaningBookingEventHandler? onEvent) {
    if (onEvent == null) {
      _bookingHandlers.remove(bookingId);
      return;
    }
    _bookingHandlers[bookingId] = onEvent;
  }

  void setWorkerHandler(int workerId, CleaningBookingEventHandler? onEvent) {
    if (onEvent == null) {
      _workerHandlers.remove(workerId);
      return;
    }
    _workerHandlers[workerId] = onEvent;
  }

  Future<void> ensureInitialized() async {
    await _ensureInit();
  }

  Future<void> _ensureInit() async {
    if (AppConfig.pusherKey.isEmpty) {
      PusherServiceLogger.skippedNoPusherKey();
      return;
    }
    if (_initialized) return;

    PusherServiceLogger.init(
      cluster: AppConfig.pusherCluster,
      useTls: true,
      hasApiKey: AppConfig.pusherKey.isNotEmpty,
    );

    await _pusher.init(
      apiKey: AppConfig.pusherKey,
      cluster: AppConfig.pusherCluster,
      useTLS: true,
      onConnectionStateChange: (current, previous) {
        PusherServiceLogger.connectionStateChange(current, previous);
      },
      onError: (message, code, e) {
        PusherServiceLogger.socketError(message, code, e);
      },
      onSubscriptionSucceeded: (channelName, data) {
        PusherServiceLogger.subscriptionSucceeded(channelName, data);
      },
      onSubscriptionError: (message, e) {
        PusherServiceLogger.subscriptionError('(subscription)', message, e);
      },
      onEvent: _handleEvent,
      onAuthorizer: (channelName, socketId, options) async {
        try {
          final token = (SharedPreferencesHelper.getData(key: 'token') ?? '')
              .toString();
          final res = await _authDio.post<Map<String, dynamic>>(
            '/broadcasting/auth',
            data: <String, dynamic>{
              'socket_id': socketId,
              'channel_name': channelName,
            },
            options: Options(
              headers: <String, dynamic>{
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
                if (token.isNotEmpty) 'Authorization': 'Bearer $token',
              },
            ),
          );
          final body = res.data;
          if (body == null || body['auth'] == null) {
            throw StateError('Invalid broadcasting auth response');
          }
          return <String, dynamic>{
            'auth': body['auth'],
            if (body['channel_data'] != null)
              'channel_data': body['channel_data'],
          };
        } catch (e, st) {
          PusherServiceLogger.authAuthorizerError(channelName, e, st);
          rethrow;
        }
      },
    );
    PusherServiceLogger.connect();
    await _pusher.connect();
    _initialized = true;
  }

  void _handleEvent(PusherEvent event) {
    PusherServiceLogger.event(
      event.channelName,
      event.eventName,
      event.data,
    );
    final channel = event.channelName;
    final payload = _parsePayload(event.data);
    if (channel.startsWith('private-cleaning-booking.')) {
      final id = int.tryParse(channel.split('.').last);
      if (id == null) return;
      _bookingHandlers[id]?.call(event.eventName, payload);
      return;
    }
    if (channel.startsWith('private-cleaning-worker.')) {
      final id = int.tryParse(channel.split('.').last);
      if (id == null) return;
      _workerHandlers[id]?.call(event.eventName, payload);
    }
  }

  Map<String, dynamic> _parsePayload(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    return const {};
  }

  Future<void> subscribeBookingChannel(int bookingId) async {
    if (AppConfig.pusherKey.isEmpty) return;
    await _ensureInit();
    final name = 'private-cleaning-booking.$bookingId';
    if (_activeBookingChannel == name) return;
    if (_activeBookingChannel != null) {
      PusherServiceLogger.unsubscribe(_activeBookingChannel!);
      await _pusher.unsubscribe(channelName: _activeBookingChannel!);
    }
    _activeBookingChannel = name;
    PusherServiceLogger.subscribe(name);
    await _pusher.subscribe(channelName: name);
  }

  Future<void> subscribeWorkerChannel(int workerId) async {
    if (AppConfig.pusherKey.isEmpty) return;
    await _ensureInit();
    final name = 'private-cleaning-worker.$workerId';
    if (_activeWorkerChannel == name) return;
    if (_activeWorkerChannel != null) {
      PusherServiceLogger.unsubscribe(_activeWorkerChannel!);
      await _pusher.unsubscribe(channelName: _activeWorkerChannel!);
    }
    _activeWorkerChannel = name;
    PusherServiceLogger.subscribe(name);
    await _pusher.subscribe(channelName: name);
  }

  Future<void> unsubscribeBookingChannel(int bookingId) async {
    final name = 'private-cleaning-booking.$bookingId';
    if (_activeBookingChannel != name) return;
    PusherServiceLogger.unsubscribe(name);
    await _pusher.unsubscribe(channelName: name);
    _activeBookingChannel = null;
  }

  Future<void> unsubscribeWorkerChannel(int workerId) async {
    final name = 'private-cleaning-worker.$workerId';
    if (_activeWorkerChannel != name) return;
    PusherServiceLogger.unsubscribe(name);
    await _pusher.unsubscribe(channelName: name);
    _activeWorkerChannel = null;
  }
}
