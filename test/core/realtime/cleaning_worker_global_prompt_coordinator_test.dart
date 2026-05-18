import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

void main() {
  group('CleaningWorkerGlobalPromptCoordinator', () {
    test(
      'ServiceExtensionRequested opens extension prompt only once per warning id',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        const payload = <String, dynamic>{
          'warningId': 100,
          'cleaningBookingId': 42,
          'requestedMinutes': 30,
        };

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          payload,
        );
        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          payload,
        );

        expect(shown.length, 1);
        expect(shown.first.warningId, 100);
      },
    );

    test('CompletionDecisionMade approved shows success alert once', () async {
      final alerts = <WorkerDecisionAlertData>[];
      final coordinator = CleaningWorkerGlobalPromptCoordinator(
        navigatorKey: GlobalKey<NavigatorState>(),
        pusherManager: _buildNoopPusherManager(),
        decisionAlertPresenter: (prompt) async {
          alerts.add(prompt);
          return true;
        },
      )..markStartedForTest();

      const payload = <String, dynamic>{
        'cleaningBookingId': 7,
        'decision': 'approved',
        'version': 1,
      };

      await coordinator.handleRealtimeEventForTest(
        CleaningRealtimeContract.completionDecisionMade,
        payload,
      );
      await coordinator.handleRealtimeEventForTest(
        CleaningRealtimeContract.completionDecisionMade,
        payload,
      );

      expect(alerts.length, 1);
      expect(alerts.first.isApproved, isTrue);
      expect(alerts.first.title, 'تم تأكيد إنهاء العمل');
      expect(alerts.first.navigateToMainOnOk, isTrue);
    });

    test('CompletionDecisionMade rejected shows failure alert', () async {
      final alerts = <WorkerDecisionAlertData>[];
      final coordinator = CleaningWorkerGlobalPromptCoordinator(
        navigatorKey: GlobalKey<NavigatorState>(),
        pusherManager: _buildNoopPusherManager(),
        decisionAlertPresenter: (prompt) async {
          alerts.add(prompt);
          return true;
        },
      )..markStartedForTest();

      await coordinator.handleRealtimeEventForTest(
        CleaningRealtimeContract.completionDecisionMade,
        const <String, dynamic>{
          'cleaningBookingId': 8,
          'decision': 'rejected',
          'version': 3,
        },
      );

      expect(alerts.length, 1);
      expect(alerts.first.isApproved, isFalse);
      expect(alerts.first.message, contains('إعادة إرسال طلب الإنهاء'));
      expect(alerts.first.navigateToMainOnOk, isFalse);
    });

    test(
      'CompletionDecisionMade extension_requested triggers pending-extension fallback',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          pendingRequestsLoader: () async =>
              const <WorkerPendingExtensionRequest>[
                WorkerPendingExtensionRequest(
                  warningId: 501,
                  bookingId: 22,
                  requestedMinutes: 45,
                ),
              ],
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.completionDecisionMade,
          const <String, dynamic>{
            'cleaningBookingId': 22,
            'decision': 'extension_requested',
            'version': 4,
          },
        );

        expect(shown.length, 1);
        expect(shown.first.warningId, 501);
        expect(shown.first.requestedMinutes, 45);
      },
    );

    test(
      'extension_requested then ServiceExtensionRequested does not duplicate same warning',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          pendingRequestsLoader: () async =>
              const <WorkerPendingExtensionRequest>[
                WorkerPendingExtensionRequest(
                  warningId: 909,
                  bookingId: 33,
                  requestedMinutes: 20,
                ),
              ],
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.completionDecisionMade,
          const <String, dynamic>{
            'cleaningBookingId': 33,
            'decision': 'extension_requested',
            'version': 5,
          },
        );

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 909,
            'cleaningBookingId': 33,
            'requestedMinutes': 20,
          },
        );

        expect(shown.length, 1);
      },
    );
  });
}

PusherManager _buildNoopPusherManager() {
  return PusherManager(clientBridge: _NoopPusherClientBridge(), authDio: Dio());
}

class _NoopPusherClientBridge implements PusherClientBridge {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

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
  }) async {}

  @override
  Future<void> subscribe({required String channelName}) async {}

  @override
  Future<void> unsubscribe({required String channelName}) async {}
}
