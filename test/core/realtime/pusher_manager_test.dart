import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

void main() {
  group('PusherManager', () {
    test(
      'ref-counts subscriptions and unsubscribes on last listener dispose',
      () async {
        final fakeBridge = _FakePusherClientBridge();
        final manager = PusherManager(clientBridge: fakeBridge);

        final handle1 = await manager.listen(
          channelName: 'private-test.1',
          onEvent: (_) {},
        );
        final handle2 = await manager.listen(
          channelName: 'private-test.1',
          onEvent: (_) {},
        );

        expect(fakeBridge.subscribeCalls, 1);
        expect(fakeBridge.subscribedChannels, contains('private-test.1'));

        await handle1.dispose();
        expect(fakeBridge.unsubscribeCalls, 0);

        await handle2.dispose();
        expect(fakeBridge.unsubscribeCalls, 1);
        expect(fakeBridge.unsubscribedChannels, contains('private-test.1'));
      },
    );

    test('resubscribes active channels after reconnect', () async {
      final fakeBridge = _FakePusherClientBridge();
      final manager = PusherManager(clientBridge: fakeBridge);

      final handle = await manager.listen(
        channelName: 'private-test.99',
        onEvent: (_) {},
      );
      expect(fakeBridge.subscribeCalls, 1);

      fakeBridge.emitConnectionState('disconnected', 'connected');
      fakeBridge.emitConnectionState('connected', 'disconnected');
      await Future<void>.delayed(Duration.zero);

      expect(fakeBridge.subscribeCalls, 2);

      await handle.dispose();
    });

    test('filters events by name', () async {
      final fakeBridge = _FakePusherClientBridge();
      final manager = PusherManager(clientBridge: fakeBridge);

      var receivedCount = 0;
      final handle = await manager.listen(
        channelName: 'private-test.filtered',
        eventNames: const <String>{'allowed.event'},
        onEvent: (_) => receivedCount++,
      );

      fakeBridge.emitEvent(
        PusherEvent(
          channelName: 'private-test.filtered',
          eventName: 'ignored.event',
          data: <String, dynamic>{'ok': false},
        ),
      );
      fakeBridge.emitEvent(
        PusherEvent(
          channelName: 'private-test.filtered',
          eventName: 'allowed.event',
          data: <String, dynamic>{'ok': true},
        ),
      );

      expect(receivedCount, 1);
      await handle.dispose();
    });
  });
}

class _FakePusherClientBridge implements PusherClientBridge {
  int connectCalls = 0;
  int disconnectCalls = 0;
  int subscribeCalls = 0;
  int unsubscribeCalls = 0;

  final List<String> subscribedChannels = <String>[];
  final List<String> unsubscribedChannels = <String>[];

  late void Function(String channelName, dynamic data) _onSubscriptionSucceeded;
  late void Function(String currentState, String previousState)
  _onConnectionStateChange;
  late void Function(PusherEvent event) _onEvent;

  @override
  Future<void> connect() async {
    connectCalls++;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
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
  }) async {
    _onSubscriptionSucceeded = onSubscriptionSucceeded;
    _onConnectionStateChange = onConnectionStateChange;
    _onEvent = onEvent;
  }

  @override
  Future<void> subscribe({required String channelName}) async {
    subscribeCalls++;
    subscribedChannels.add(channelName);
    _onSubscriptionSucceeded(channelName, <String, dynamic>{'ok': true});
  }

  @override
  Future<void> unsubscribe({required String channelName}) async {
    unsubscribeCalls++;
    unsubscribedChannels.add(channelName);
  }

  void emitConnectionState(String current, String previous) {
    _onConnectionStateChange(current, previous);
  }

  void emitEvent(PusherEvent event) {
    _onEvent(event);
  }
}
