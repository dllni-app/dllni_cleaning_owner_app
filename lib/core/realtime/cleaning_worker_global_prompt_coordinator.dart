import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import '../../features/orders/view/manager/bloc/orders_bloc.dart';
import '../../features/orders/view/widgets/extension_request_action_sheet.dart';
import '../di/injection.dart';
import 'cleaning_realtime_contract.dart';
import 'pusher_manager.dart';

typedef WorkerExtensionPromptPresenter =
    Future<bool> Function(WorkerExtensionPromptData prompt);
typedef WorkerDecisionAlertPresenter =
    Future<bool> Function(WorkerDecisionAlertData prompt);
typedef WorkerPendingExtensionRequestsLoader =
    Future<List<WorkerPendingExtensionRequest>> Function();

class CleaningWorkerGlobalPromptCoordinator {
  CleaningWorkerGlobalPromptCoordinator({
    required GlobalKey<NavigatorState> navigatorKey,
    PusherManager? pusherManager,
    FetchExtensionRequestsUsecasUseCase? fetchExtensionRequestsUseCase,
    WorkerExtensionPromptPresenter? extensionPromptPresenter,
    WorkerDecisionAlertPresenter? decisionAlertPresenter,
    WorkerPendingExtensionRequestsLoader? pendingRequestsLoader,
  }) : _navigatorKey = navigatorKey,
       _pusherManager = pusherManager ?? getIt<PusherManager>(),
       _fetchExtensionRequestsUseCase = fetchExtensionRequestsUseCase,
       _extensionPromptPresenter = extensionPromptPresenter,
       _decisionAlertPresenter = decisionAlertPresenter,
       _pendingRequestsLoader = pendingRequestsLoader;

  final GlobalKey<NavigatorState> _navigatorKey;
  final PusherManager _pusherManager;
  final FetchExtensionRequestsUsecasUseCase? _fetchExtensionRequestsUseCase;
  final WorkerExtensionPromptPresenter? _extensionPromptPresenter;
  final WorkerDecisionAlertPresenter? _decisionAlertPresenter;
  final WorkerPendingExtensionRequestsLoader? _pendingRequestsLoader;

  RealtimeListenerHandle? _workerListenerHandle;
  int? _listeningWorkerId;
  OrdersBloc? _promptBloc;
  Timer? _channelBindingPoll;

  bool _started = false;
  bool _workerChannelAuthWarningShown = false;
  bool _extensionSheetOpen = false;
  bool _decisionDialogOpen = false;

  final Set<int> _handledExtensionWarningIds = <int>{};
  final Set<int> _inFlightExtensionWarningIds = <int>{};
  final Set<int> _inFlightExtensionLookupBookingIds = <int>{};
  final Set<String> _handledCompletionDecisionKeys = <String>{};

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _pusherManager.ensureInitialized();
    await _ensureWorkerChannel();
    _channelBindingPoll = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(_ensureWorkerChannel());
    });
  }

  Future<void> stop() async {
    _channelBindingPoll?.cancel();
    _channelBindingPoll = null;
    await _detachWorkerListener();
    await _closePromptBloc();
    _started = false;
  }

  Future<void> _ensureWorkerChannel() async {
    if (!_started) return;
    if (!_hasToken()) {
      await _detachWorkerListener();
      await _closePromptBloc();
      _resetPromptSessionState();
      return;
    }

    final workerId = _readWorkerId();
    if (workerId == null || workerId <= 0) return;
    if (_listeningWorkerId == workerId && _workerListenerHandle != null) {
      return;
    }

    await _detachWorkerListener();
    await _closePromptBloc();
    _resetPromptSessionState();

    final handle = await _pusherManager.listen(
      channelName: '${CleaningRealtimeContract.workerChannelPrefix}$workerId',
      eventNames: <String>{
        CleaningRealtimeContract.serviceExtensionRequested,
        CleaningRealtimeContract.completionDecisionMade,
      },
      onEvent: (event) {
        final normalized = CleaningRealtimeContract.normalizeEventName(
          event.eventName,
        );
        unawaited(_onWorkerRealtimeEvent(normalized, event.payload));
      },
      onChannelError: _onWorkerRealtimeChannelError,
    );

    _workerListenerHandle = handle;
    _listeningWorkerId = workerId;
    _workerChannelAuthWarningShown = false;
  }

  Future<void> _detachWorkerListener() async {
    final handle = _workerListenerHandle;
    _workerListenerHandle = null;
    _listeningWorkerId = null;
    await handle?.dispose();
  }

  Future<void> _onWorkerRealtimeEvent(
    String normalizedEvent,
    Map<String, dynamic> payload,
  ) async {
    if (!_started) return;

    if (normalizedEvent == CleaningRealtimeContract.serviceExtensionRequested) {
      await _handleServiceExtensionRequested(payload);
      return;
    }

    if (normalizedEvent == CleaningRealtimeContract.completionDecisionMade) {
      await _handleCompletionDecision(payload);
    }
  }

  @visibleForTesting
  Future<void> handleRealtimeEventForTest(
    String eventName,
    Map<String, dynamic> payload,
  ) async {
    await _onWorkerRealtimeEvent(
      CleaningRealtimeContract.normalizeEventName(eventName),
      payload,
    );
  }

  @visibleForTesting
  void markStartedForTest({bool value = true}) {
    _started = value;
  }

  Future<void> _handleServiceExtensionRequested(
    Map<String, dynamic> payload,
  ) async {
    final warningId = _asInt(payload['warningId'] ?? payload['warning_id']);
    final bookingId = CleaningRealtimeContract.extractBookingId(payload);

    if (warningId != null) {
      await _openExtensionPromptForWarning(
        warningId: warningId,
        bookingId: bookingId,
        payload: payload,
      );
      return;
    }

    await _openExtensionPromptFromPendingRequests(
      bookingId: bookingId,
      payload: payload,
    );
  }

  Future<void> _handleCompletionDecision(Map<String, dynamic> payload) async {
    final decision = (payload['decision'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (decision.isEmpty) return;

    final bookingId = CleaningRealtimeContract.extractBookingId(payload);
    final decisionKey = _completionDecisionKey(
      bookingId: bookingId,
      decision: decision,
      payload: payload,
    );
    if (decisionKey != null &&
        _handledCompletionDecisionKeys.contains(decisionKey)) {
      return;
    }

    var handled = false;
    if (decision == 'approved') {
      handled = await _showDecisionAlert(
        WorkerDecisionAlertData(
          isApproved: true,
          title: 'تم تأكيد إنهاء العمل',
          message: 'وافق العميل على إنهاء الخدمة بنجاح.',
          navigateToMainOnOk: true,
        ),
      );
    } else if (decision == 'rejected') {
      handled = await _showDecisionAlert(
        WorkerDecisionAlertData(
          isApproved: false,
          title: 'تم رفض إنهاء العمل',
          message: 'رفض العميل إنهاء الخدمة. يمكنك إعادة إرسال طلب الإنهاء.',
          navigateToMainOnOk: false,
        ),
      );
    } else if (decision == 'extension_requested') {
      handled = await _openExtensionPromptFromPendingRequests(
        bookingId: bookingId,
        payload: payload,
      );
    }

    if (handled && decisionKey != null) {
      _handledCompletionDecisionKeys.add(decisionKey);
    }
  }

  Future<bool> _openExtensionPromptForWarning({
    required int warningId,
    required int? bookingId,
    required Map<String, dynamic> payload,
    int? requestedMinutesOverride,
  }) async {
    if (_handledExtensionWarningIds.contains(warningId) ||
        _inFlightExtensionWarningIds.contains(warningId)) {
      return false;
    }

    _inFlightExtensionWarningIds.add(warningId);
    try {
      final shown = await _showExtensionSheet(
        warningId: warningId,
        bookingId: bookingId,
        requestedMinutes:
            requestedMinutesOverride ??
            _asInt(
              payload['requestedMinutes'] ??
                  payload['requested_minutes'] ??
                  payload['minutes'],
            ),
        customerName: (payload['customerName'] ?? payload['customer_name'])
            ?.toString(),
        additionalAmount: _asDouble(
          payload['additionalAmount'] ??
              payload['additional_amount'] ??
              payload['amount'],
        ),
        currency:
            (payload['currency'] ??
                    payload['currencyCode'] ??
                    payload['currency_code'])
                ?.toString(),
        paymentMethod: (payload['paymentMethod'] ?? payload['payment_method'])
            ?.toString(),
      );
      if (shown) {
        _handledExtensionWarningIds.add(warningId);
      }
      return shown;
    } finally {
      _inFlightExtensionWarningIds.remove(warningId);
    }
  }

  Future<bool> _openExtensionPromptFromPendingRequests({
    required int? bookingId,
    required Map<String, dynamic> payload,
  }) async {
    if (bookingId == null) return false;
    if (_inFlightExtensionLookupBookingIds.contains(bookingId)) return false;

    _inFlightExtensionLookupBookingIds.add(bookingId);
    try {
      final requests = await _loadPendingExtensionRequests();
      WorkerPendingExtensionRequest? match;
      for (final request in requests) {
        if (request.bookingId == bookingId && request.warningId != null) {
          match = request;
          break;
        }
      }
      if (match == null || match.warningId == null) return false;

      return _openExtensionPromptForWarning(
        warningId: match.warningId!,
        bookingId: match.bookingId ?? bookingId,
        payload: payload,
        requestedMinutesOverride: match.requestedMinutes,
      );
    } finally {
      _inFlightExtensionLookupBookingIds.remove(bookingId);
    }
  }

  Future<bool> _showExtensionSheet({
    required int warningId,
    required int? bookingId,
    required int? requestedMinutes,
    required String? customerName,
    required double? additionalAmount,
    required String? currency,
    required String? paymentMethod,
  }) async {
    final presenter = _extensionPromptPresenter;
    if (presenter != null) {
      return presenter(
        WorkerExtensionPromptData(
          warningId: warningId,
          bookingId: bookingId,
          requestedMinutes: requestedMinutes,
          customerName: customerName,
          additionalAmount: additionalAmount,
          currency: currency,
          paymentMethod: paymentMethod,
        ),
      );
    }
    if (_extensionSheetOpen) return false;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return false;

    final bloc = _ensurePromptBloc();
    _extensionSheetOpen = true;
    try {
      await ExtensionRequestActionSheet.show(
        context,
        useRootNavigator: true,
        bloc: bloc,
        warningId: warningId,
        bookingId: bookingId,
        requestedMinutes: requestedMinutes,
        customerName: customerName,
        additionalAmount: additionalAmount,
        currency: currency,
        paymentMethod: paymentMethod,
      );
      return true;
    } finally {
      _extensionSheetOpen = false;
    }
  }

  Future<bool> _showDecisionAlert(WorkerDecisionAlertData prompt) async {
    final presenter = _decisionAlertPresenter;
    if (presenter != null) {
      return presenter(prompt);
    }
    if (_decisionDialogOpen) return false;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return false;

    _decisionDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            icon: Icon(
              prompt.isApproved
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: prompt.isApproved
                  ? const Color(0xff16A34A)
                  : const Color(0xffDC2626),
              size: 40,
            ),
            title: Text(prompt.title, textAlign: TextAlign.center),
            content: Text(prompt.message, textAlign: TextAlign.center),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final navigator = Navigator.of(ctx, rootNavigator: true);
                    navigator.pop();
                    if (prompt.navigateToMainOnOk) {
                      navigator.pushNamedAndRemoveUntil(
                        '/main',
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('حسناً'),
                ),
              ),
            ],
          );
        },
      );
      return true;
    } finally {
      _decisionDialogOpen = false;
    }
  }

  Future<List<WorkerPendingExtensionRequest>>
  _loadPendingExtensionRequests() async {
    final loader = _pendingRequestsLoader;
    if (loader != null) {
      return loader();
    }

    final fetchUseCase = _fetchExtensionRequestsUseCase;
    if (fetchUseCase == null) {
      return const <WorkerPendingExtensionRequest>[];
    }

    final response = await fetchUseCase(FetchExtensionRequestsUsecasParams());
    return response.fold((_) => const <WorkerPendingExtensionRequest>[], (
      result,
    ) {
      final list = result.data ?? const <dynamic>[];
      return list
          .map(
            (item) => WorkerPendingExtensionRequest(
              warningId: _asInt(item.id),
              bookingId: _asInt(item.bookingId),
              requestedMinutes: _asInt(item.requestedMinutes),
            ),
          )
          .toList(growable: false);
    });
  }

  void _onWorkerRealtimeChannelError(RealtimeChannelError error) {
    if (error.statusCode != 403) return;
    if (_workerChannelAuthWarningShown) return;
    _workerChannelAuthWarningShown = true;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to connect realtime worker updates right now. The app will keep syncing in the background.',
        ),
      ),
    );
  }

  OrdersBloc _ensurePromptBloc() {
    final existing = _promptBloc;
    if (existing != null && !existing.isClosed) return existing;
    final bloc = getIt<OrdersBloc>();
    _promptBloc = bloc;
    return bloc;
  }

  Future<void> _closePromptBloc() async {
    final bloc = _promptBloc;
    _promptBloc = null;
    if (bloc != null && !bloc.isClosed) {
      await bloc.close();
    }
  }

  void _resetPromptSessionState() {
    _extensionSheetOpen = false;
    _decisionDialogOpen = false;
    _handledExtensionWarningIds.clear();
    _inFlightExtensionWarningIds.clear();
    _inFlightExtensionLookupBookingIds.clear();
    _handledCompletionDecisionKeys.clear();
  }

  String? _completionDecisionKey({
    required int? bookingId,
    required String decision,
    required Map<String, dynamic> payload,
  }) {
    if (bookingId == null) return null;
    final discriminator =
        payload['version'] ??
        payload['decidedAt'] ??
        payload['decided_at'] ??
        '';
    return '$bookingId|$discriminator|$decision';
  }

  int? _readWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}');
  }

  bool _hasToken() {
    final token = (SharedPreferencesHelper.getData(key: 'token') ?? '')
        .toString()
        .trim();
    return token.isNotEmpty;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

class WorkerExtensionPromptData {
  const WorkerExtensionPromptData({
    required this.warningId,
    required this.bookingId,
    required this.requestedMinutes,
    required this.customerName,
    required this.additionalAmount,
    required this.currency,
    required this.paymentMethod,
  });

  final int warningId;
  final int? bookingId;
  final int? requestedMinutes;
  final String? customerName;
  final double? additionalAmount;
  final String? currency;
  final String? paymentMethod;
}

class WorkerDecisionAlertData {
  const WorkerDecisionAlertData({
    required this.isApproved,
    required this.title,
    required this.message,
    this.navigateToMainOnOk = false,
  });

  final bool isApproved;
  final String title;
  final String message;
  final bool navigateToMainOnOk;
}

class WorkerPendingExtensionRequest {
  const WorkerPendingExtensionRequest({
    required this.warningId,
    required this.bookingId,
    required this.requestedMinutes,
  });

  final int? warningId;
  final int? bookingId;
  final int? requestedMinutes;
}
