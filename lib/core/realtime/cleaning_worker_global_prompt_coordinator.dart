import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../features/main/view/screens/main_screen.dart';
import '../../features/orders/data/models/cleaning_booking_status.dart';
import '../../features/orders/data/models/fetch_orders_usecase_model.dart';
import '../../features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import '../../features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../../features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../features/orders/view/helpers/order_details_to_list_item_mapper.dart';
import '../../features/orders/view/helpers/order_lifecycle_policy.dart';
import '../../features/orders/view/manager/bloc/orders_bloc.dart';
import '../../features/orders/view/widgets/accept_order_bottom_sheet.dart';
import '../../features/orders/view/widgets/extension_request_action_sheet.dart';
import '../di/injection.dart';
import 'cleaning_realtime_contract.dart';
import 'pusher_manager.dart';

typedef WorkerExtensionPromptPresenter = Future<bool> Function(WorkerExtensionPromptData prompt);
typedef WorkerDecisionAlertPresenter = Future<bool> Function(WorkerDecisionAlertData prompt);
typedef WorkerPendingOrderPromptPresenter = Future<bool> Function(WorkerPendingOrderPromptData prompt);
typedef WorkerPendingExtensionRequestsLoader = Future<List<WorkerPendingExtensionRequest>> Function();
typedef WorkerPendingOrdersLoader = Future<List<FetchOrdersUsecaseModelDataItem>> Function();

class CleaningWorkerGlobalPromptCoordinator {
  CleaningWorkerGlobalPromptCoordinator({
    required GlobalKey<NavigatorState> navigatorKey,
    PusherManager? pusherManager,
    FetchExtensionRequestsUsecasUseCase? fetchExtensionRequestsUseCase,
    FetchOrderDetailsUsecaseUseCase? fetchOrderDetailsUseCase,
    FetchOrdersUsecaseUseCase? fetchOrdersUsecaseUseCase,
    WorkerExtensionPromptPresenter? extensionPromptPresenter,
    WorkerDecisionAlertPresenter? decisionAlertPresenter,
    WorkerPendingExtensionRequestsLoader? pendingRequestsLoader,
    WorkerPendingOrderPromptPresenter? pendingOrderPromptPresenter,
    WorkerPendingOrdersLoader? pendingOrdersLoader,
  })  : _navigatorKey = navigatorKey,
        _pusherManager = pusherManager ?? getIt<PusherManager>(),
        _fetchExtensionRequestsUseCase = fetchExtensionRequestsUseCase ??
            (getIt.isRegistered<FetchExtensionRequestsUsecasUseCase>()
                ? getIt<FetchExtensionRequestsUsecasUseCase>()
                : null),
        _fetchOrderDetailsUseCase = fetchOrderDetailsUseCase ??
            (getIt.isRegistered<FetchOrderDetailsUsecaseUseCase>()
                ? getIt<FetchOrderDetailsUsecaseUseCase>()
                : null),
        _fetchOrdersUsecaseUseCase = fetchOrdersUsecaseUseCase ??
            (getIt.isRegistered<FetchOrdersUsecaseUseCase>()
                ? getIt<FetchOrdersUsecaseUseCase>()
                : null),
        _extensionPromptPresenter = extensionPromptPresenter,
        _decisionAlertPresenter = decisionAlertPresenter,
        _pendingRequestsLoader = pendingRequestsLoader,
        _pendingOrderPromptPresenter = pendingOrderPromptPresenter,
        _pendingOrdersLoader = pendingOrdersLoader;

  final GlobalKey<NavigatorState> _navigatorKey;
  final PusherManager _pusherManager;
  final FetchExtensionRequestsUsecasUseCase? _fetchExtensionRequestsUseCase;
  final FetchOrderDetailsUsecaseUseCase? _fetchOrderDetailsUseCase;
  final FetchOrdersUsecaseUseCase? _fetchOrdersUsecaseUseCase;
  final WorkerExtensionPromptPresenter? _extensionPromptPresenter;
  final WorkerDecisionAlertPresenter? _decisionAlertPresenter;
  final WorkerPendingExtensionRequestsLoader? _pendingRequestsLoader;
  final WorkerPendingOrderPromptPresenter? _pendingOrderPromptPresenter;
  final WorkerPendingOrdersLoader? _pendingOrdersLoader;

  RealtimeListenerHandle? _workerListenerHandle;
  int? _listeningWorkerId;
  OrdersBloc? _promptBloc;
  Timer? _pollTimer;

  static const int _pollPageSize = 25;
  static const int _pollMaxPagesPerStatus = 6;
  static const Duration _pollInterval = Duration(seconds: 60);

  bool _started = false;
  bool _authBypassForTest = false;
  bool _workerChannelAuthWarningShown = false;
  bool _promptSheetOpen = false;
  bool _decisionDialogOpen = false;
  bool _extensionPollInFlight = false;
  bool _pendingOrderPollInFlight = false;

  final Set<int> _handledPendingPromptBookingIds = <int>{};
  final Set<int> _inFlightPendingPromptBookingIds = <int>{};
  final Set<int> _inFlightExtensionLookupBookingIds = <int>{};
  final Set<String> _handledCompletionDecisionKeys = <String>{};
  final Set<String> _handledRealtimeEventKeys = <String>{};
  final Map<int, _ExtensionPromptState> _extensionPromptStates = <int, _ExtensionPromptState>{};

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _pusherManager.ensureInitialized();
    await _ensureWorkerChannel();
    _runForegroundFallbackPoll();
    _scheduleStartupPostFramePoll();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_started) return;
      unawaited(_ensureWorkerChannel());
      _runForegroundFallbackPoll();
    });
  }

  Future<void> onAuthenticated({int? workerId, String? token}) async {
    if (!_started) await start();
    _resetPromptSessionState();
    await _ensureWorkerChannel(forceRebind: true);
    _runForegroundFallbackPoll();
  }

  Future<void> onLogout() async {
    await _detachWorkerListener();
    await _closePromptBloc();
    _resetPromptSessionState();
  }

  Future<void> onWorkerProfileChanged(int? workerId) async {
    await _ensureWorkerChannel(forceRebind: true);
    _runForegroundFallbackPoll();
  }

  Future<void> onAppResumed() async {
    if (!_started) return;
    await _ensureWorkerChannel();
    _runForegroundFallbackPoll();
  }

  void _runForegroundFallbackPoll() {
    unawaited(pollPendingExtensionPrompts());
    unawaited(pollPendingOrderPrompts());
  }

  void _scheduleStartupPostFramePoll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) return;
      _runForegroundFallbackPoll();
    });
  }

  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _detachWorkerListener();
    await _closePromptBloc();
    _resetPromptSessionState();
    _started = false;
  }

  Future<void> _ensureWorkerChannel({bool forceRebind = false}) async {
    if (!_started) return;
    if (!_hasToken()) {
      await _detachWorkerListener();
      await _closePromptBloc();
      _resetPromptSessionState();
      return;
    }

    final workerId = _readWorkerId();
    if (workerId == null || workerId <= 0) return;
    if (!forceRebind && _listeningWorkerId == workerId && _workerListenerHandle != null) return;

    await _detachWorkerListener();
    await _closePromptBloc();
    _resetPromptSessionState();

    final handle = await _pusherManager.listen(
      channelName: '${CleaningRealtimeContract.workerChannelPrefix}$workerId',
      eventNames: CleaningRealtimeContract.expandEventFilter(const <String>{
        CleaningRealtimeContract.serviceExtensionRequested,
        CleaningRealtimeContract.completionDecisionMade,
      }),
      onEvent: (event) {
        final normalized = CleaningRealtimeContract.normalizeEventName(event.eventName);
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

  Future<void> _onWorkerRealtimeEvent(String normalizedEvent, Map<String, dynamic> payload) async {
    if (!_started) return;
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    if (!_shouldHandleRealtimeEvent(normalizedEvent, unwrapped)) return;

    if (normalizedEvent == CleaningRealtimeContract.serviceExtensionRequested) {
      await _handleServiceExtensionRequested(unwrapped);
      return;
    }

    if (normalizedEvent == CleaningRealtimeContract.completionDecisionMade) {
      await _handleCompletionDecision(unwrapped);
    }
  }

  bool _shouldHandleRealtimeEvent(String eventName, Map<String, dynamic> payload) {
    final bookingId = CleaningRealtimeContract.extractBookingId(payload);
    final warningId = CleaningRealtimeContract.extractWarningId(payload);
    if (bookingId == null && warningId == null) return false;
    final key = <Object?>[
      eventName,
      bookingId,
      warningId,
      payload['decision'],
      payload['status'] ?? payload['orderStatus'],
      payload['version'],
      payload['decidedAt'] ?? payload['decided_at'] ?? payload['updatedAt'] ?? payload['updated_at'],
    ].join('|');
    if (_handledRealtimeEventKeys.contains(key)) return false;
    _handledRealtimeEventKeys.add(key);
    if (_handledRealtimeEventKeys.length > 250) {
      _handledRealtimeEventKeys.remove(_handledRealtimeEventKeys.first);
    }
    return true;
  }

  Future<void> handleRealtimeEvent(String eventName, Map<String, dynamic> payload) async {
    await _onWorkerRealtimeEvent(
      CleaningRealtimeContract.normalizeEventName(eventName),
      CleaningRealtimeContract.unwrapPayload(payload),
    );
  }

  @visibleForTesting
  Future<void> handleRealtimeEventForTest(String eventName, Map<String, dynamic> payload) {
    return handleRealtimeEvent(eventName, payload);
  }

  Future<void> pollPendingExtensionPrompts() async {
    if (!_started || (!_authBypassForTest && !_hasToken())) return;
    if (_extensionPollInFlight || _promptSheetOpen) return;

    _extensionPollInFlight = true;
    try {
      if (await _promptFirstPendingExtensionRequest()) return;
      await _promptExtensionsFromTimeExtensionOrders();
    } finally {
      _extensionPollInFlight = false;
    }
  }

  Future<void> pollPendingOrderPrompts() async {
    if (!_started || (!_authBypassForTest && !_hasToken())) return;
    if (_pendingOrderPollInFlight || _promptSheetOpen) return;

    _pendingOrderPollInFlight = true;
    try {
      await _promptFirstPendingOrder();
    } finally {
      _pendingOrderPollInFlight = false;
    }
  }

  @visibleForTesting
  static List<int> findTimeExtensionRequestedBookingIds(List<FetchOrdersUsecaseModelDataItem> orders) {
    return orders
        .where((order) => (order.status ?? '').trim().toLowerCase() == CleaningBookingStatus.timeExtensionRequested)
        .map((order) => order.id)
        .whereType<int>()
        .toList(growable: false);
  }

  @visibleForTesting
  static List<int> findPendingBookingIds(List<FetchOrdersUsecaseModelDataItem> orders) {
    return orders
        .where(OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker)
        .map((order) => order.id)
        .whereType<int>()
        .toList(growable: false);
  }

  Future<bool> _promptFirstPendingOrder() async {
    final pendingOrders = await _loadPendingOrders();
    for (final order in pendingOrders) {
      final shown = await _openPendingOrderPromptForOrder(order: order);
      if (shown) return true;
    }
    return false;
  }

  Future<bool> _promptFirstPendingExtensionRequest() async {
    final pending = await _loadPendingExtensionRequests();
    for (final request in pending) {
      final warningId = request.warningId;
      if (warningId == null) continue;
      final shown = await _openExtensionPromptForWarning(
        warningId: warningId,
        bookingId: request.bookingId,
        payload: const <String, dynamic>{},
        requestedMinutesOverride: request.requestedMinutes,
      );
      if (shown) return true;
    }
    return false;
  }

  Future<bool> _openPendingOrderPromptForOrder({required FetchOrdersUsecaseModelDataItem order}) async {
    final bookingId = order.id;
    if (bookingId == null) return false;
    if (!OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker(order)) return false;
    if (_handledPendingPromptBookingIds.contains(bookingId) || _inFlightPendingPromptBookingIds.contains(bookingId)) {
      return false;
    }

    _inFlightPendingPromptBookingIds.add(bookingId);
    try {
      final freshOrder = await _freshPromptablePendingOrder(order);
      if (freshOrder == null) return false;
      final shown = await _showPendingOrderSheet(order: freshOrder);
      if (shown) _handledPendingPromptBookingIds.add(bookingId);
      return shown;
    } finally {
      _inFlightPendingPromptBookingIds.remove(bookingId);
    }
  }

  Future<FetchOrdersUsecaseModelDataItem?> _freshPromptablePendingOrder(
    FetchOrdersUsecaseModelDataItem order,
  ) async {
    if (!OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker(order)) {
      return null;
    }

    final bookingId = order.id;
    final fetchDetails = _fetchOrderDetailsUseCase;
    if (bookingId == null || fetchDetails == null) return order;

    FetchOrdersUsecaseModelDataItem resolved = order;
    final response = await fetchDetails(FetchOrderDetailsUsecaseParams(id: bookingId));
    response.fold((_) => null, (result) {
      final details = result.data;
      if (details == null) return;
      resolved = OrderDetailsToListItemMapper.fromDetails(details);
    });

    return OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker(resolved)
        ? resolved
        : null;
  }

  Future<bool> _showPendingOrderSheet({required FetchOrdersUsecaseModelDataItem order}) async {
    if (!OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker(order)) return false;

    final presenter = _pendingOrderPromptPresenter;
    if (presenter != null) return presenter(WorkerPendingOrderPromptData(order: order));
    if (_promptSheetOpen) return false;

    final bloc = _ensurePromptBloc();
    _promptSheetOpen = true;
    try {
      for (var attempt = 0; attempt < 8; attempt++) {
        final context = _navigatorKey.currentContext;
        if (context != null && context.mounted) {
          await AcceptOrderBottomSheet.show(
            context,
            useRootNavigator: true,
            autoRejectOnClose: false,
            order: order,
            bloc: bloc,
            index: -1,
          );
          return true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return false;
    } finally {
      _promptSheetOpen = false;
    }
  }

  Future<void> _promptExtensionsFromTimeExtensionOrders() async {
    final fetchOrders = _fetchOrdersUsecaseUseCase;
    if (fetchOrders == null) return;

    for (var page = 1; page <= _pollMaxPagesPerStatus; page++) {
      final response = await fetchOrders(FetchOrdersUsecaseParams(page: page, perPage: _pollPageSize, status: CleaningBookingStatus.timeExtensionRequested));
      final orders = response.fold((_) => const <FetchOrdersUsecaseModelDataItem>[], (result) => result.data ?? const <FetchOrdersUsecaseModelDataItem>[]);
      if (orders.isEmpty) break;
      for (final bookingId in findTimeExtensionRequestedBookingIds(orders)) {
        final shown = await _openExtensionPromptFromPendingRequests(bookingId: bookingId, payload: const <String, dynamic>{});
        if (shown) return;
      }
      if (orders.length < _pollPageSize) break;
    }
  }

  @visibleForTesting
  void markStartedForTest({bool value = true}) {
    _started = value;
  }

  @visibleForTesting
  void markAuthBypassForTest({bool value = true}) {
    _authBypassForTest = value;
  }

  Future<void> _handleServiceExtensionRequested(Map<String, dynamic> payload) async {
    final warningId = CleaningRealtimeContract.extractWarningId(payload);
    final bookingId = CleaningRealtimeContract.extractBookingId(payload);
    if (warningId != null) {
      await _openExtensionPromptForWarning(warningId: warningId, bookingId: bookingId, payload: payload);
      return;
    }
    await _openExtensionPromptFromPendingRequests(bookingId: bookingId, payload: payload);
  }

  Future<void> _handleCompletionDecision(Map<String, dynamic> payload) async {
    final decision = (payload['decision'] ?? '').toString().trim().toLowerCase();
    if (decision.isEmpty) return;
    final bookingId = CleaningRealtimeContract.extractBookingId(payload);
    final decisionKey = _completionDecisionKey(bookingId: bookingId, decision: decision, payload: payload);
    if (decisionKey != null && _handledCompletionDecisionKeys.contains(decisionKey)) return;

    var handled = false;
    if (decision == 'approved') {
      handled = await _showDecisionAlert(const WorkerDecisionAlertData(isApproved: true, title: 'تم تأكيد إنهاء العمل', message: 'وافق العميل على إنهاء الخدمة بنجاح.', navigateToMainOnOk: true));
    } else if (decision == 'rejected') {
      handled = await _showDecisionAlert(const WorkerDecisionAlertData(isApproved: false, title: 'تم رفض إنهاء العمل', message: 'رفض العميل إنهاء الخدمة. يمكنك إعادة إرسال طلب الإنهاء.'));
    } else if (decision == 'extension_requested') {
      handled = await _openExtensionPromptFromPendingRequests(bookingId: bookingId, payload: payload);
    } else if (decision == 'extension_rejected') {
      handled = await _showDecisionAlert(
        WorkerDecisionAlertData(
          isApproved: false,
          title: 'تم إنهاء طلب التمديد',
          message: (payload['message'] ?? payload['completionMessage'])?.toString().trim().isNotEmpty == true
              ? (payload['message'] ?? payload['completionMessage']).toString().trim()
              : 'تم رفض طلب تمديد الوقت وتم إنهاء الطلب.',
          navigateToMainOnOk: true,
        ),
      );
    }

    if (handled && decisionKey != null) _handledCompletionDecisionKeys.add(decisionKey);
  }

  Future<bool> _openExtensionPromptForWarning({
    required int warningId,
    required int? bookingId,
    required Map<String, dynamic> payload,
    int? requestedMinutesOverride,
  }) async {
    final state = _extensionPromptStates[warningId];
    if (state == _ExtensionPromptState.showing || state == _ExtensionPromptState.pendingPrompt || state == _ExtensionPromptState.resolved) {
      return false;
    }

    _extensionPromptStates[warningId] = _ExtensionPromptState.pendingPrompt;
    try {
      final resolved = await _showExtensionSheet(
        warningId: warningId,
        bookingId: bookingId,
        requestedMinutes: requestedMinutesOverride ?? _resolveRequestedMinutes(payload),
        customerName: (payload['customerName'] ?? payload['customer_name'])?.toString(),
        additionalAmount: _asDouble(payload['additionalAmount'] ?? payload['additional_amount'] ?? payload['amount']),
        currency: (payload['currency'] ?? payload['currencyCode'] ?? payload['currency_code'])?.toString(),
        paymentMethod: (payload['paymentMethod'] ?? payload['payment_method'])?.toString(),
      );
      _extensionPromptStates[warningId] = resolved ? _ExtensionPromptState.resolved : _ExtensionPromptState.idle;
      return resolved;
    } catch (_) {
      _extensionPromptStates[warningId] = _ExtensionPromptState.idle;
      rethrow;
    }
  }

  Future<bool> _openExtensionPromptFromPendingRequests({required int? bookingId, required Map<String, dynamic> payload}) async {
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
    final enriched = await _enrichExtensionPromptData(
      bookingId: bookingId,
      requestedMinutes: requestedMinutes,
      customerName: customerName,
      additionalAmount: additionalAmount,
      currency: currency,
      paymentMethod: paymentMethod,
    );

    final presenter = _extensionPromptPresenter;
    if (presenter != null) {
      return presenter(WorkerExtensionPromptData(
        warningId: warningId,
        bookingId: bookingId,
        requestedMinutes: enriched.requestedMinutes,
        customerName: enriched.customerName,
        additionalAmount: enriched.additionalAmount,
        currency: enriched.currency,
        paymentMethod: enriched.paymentMethod,
      ));
    }
    if (_promptSheetOpen) return false;

    final bloc = _ensurePromptBloc();
    _promptSheetOpen = true;
    _extensionPromptStates[warningId] = _ExtensionPromptState.showing;
    try {
      for (var attempt = 0; attempt < 8; attempt++) {
        final context = _navigatorKey.currentContext;
        if (context != null && context.mounted) {
          return ExtensionRequestActionSheet.show(
            context,
            useRootNavigator: true,
            bloc: bloc,
            warningId: warningId,
            bookingId: bookingId,
            requestedMinutes: enriched.requestedMinutes,
            customerName: enriched.customerName,
            additionalAmount: enriched.additionalAmount,
            currency: enriched.currency,
            paymentMethod: enriched.paymentMethod,
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return false;
    } finally {
      _promptSheetOpen = false;
    }
  }

  Future<_ExtensionPromptEnrichment> _enrichExtensionPromptData({
    required int? bookingId,
    required int? requestedMinutes,
    required String? customerName,
    required double? additionalAmount,
    required String? currency,
    required String? paymentMethod,
  }) async {
    var resolvedCustomerName = customerName;
    var resolvedAmount = additionalAmount;
    var resolvedCurrency = currency;
    var resolvedPaymentMethod = paymentMethod;
    final needsDetails = bookingId != null && ((resolvedCustomerName == null || resolvedCustomerName.trim().isEmpty) || resolvedAmount == null || (resolvedPaymentMethod == null || resolvedPaymentMethod.trim().isEmpty));
    if (!needsDetails) {
      return _ExtensionPromptEnrichment(requestedMinutes: requestedMinutes, customerName: resolvedCustomerName, additionalAmount: resolvedAmount, currency: resolvedCurrency, paymentMethod: resolvedPaymentMethod);
    }

    final fetchDetails = _fetchOrderDetailsUseCase;
    if (fetchDetails == null) {
      return _ExtensionPromptEnrichment(requestedMinutes: requestedMinutes, customerName: resolvedCustomerName, additionalAmount: resolvedAmount, currency: resolvedCurrency, paymentMethod: resolvedPaymentMethod);
    }

    final response = await fetchDetails(FetchOrderDetailsUsecaseParams(id: bookingId));
    response.fold((_) => null, (result) {
      final details = result.data;
      if (details == null) return;
      if (resolvedCustomerName?.trim().isEmpty ?? true) resolvedCustomerName = details.customer?.name;
      if (resolvedAmount == null && requestedMinutes != null && requestedMinutes > 0) {
        final totalHours = details.totalHours;
        final totalPrice = details.totalPrice;
        if (totalHours != null && totalHours > 0 && totalPrice != null) {
          resolvedAmount = totalPrice / totalHours * (requestedMinutes / 60.0);
        }
      }
      if (resolvedPaymentMethod?.trim().isEmpty ?? true) resolvedPaymentMethod = 'cash_on_delivery';
    });

    return _ExtensionPromptEnrichment(requestedMinutes: requestedMinutes, customerName: resolvedCustomerName, additionalAmount: resolvedAmount, currency: resolvedCurrency, paymentMethod: resolvedPaymentMethod);
  }

  int? _resolveRequestedMinutes(Map<String, dynamic> payload) {
    return _asInt(payload['additionalMinutes'] ?? payload['additional_minutes'] ?? payload['requestedMinutes'] ?? payload['requested_minutes'] ?? payload['minutes']);
  }

  Future<bool> _showDecisionAlert(WorkerDecisionAlertData prompt) async {
    final presenter = _decisionAlertPresenter;
    if (presenter != null) return presenter(prompt);
    if (_decisionDialogOpen) return false;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return false;

    _decisionDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: Icon(prompt.isApproved ? Icons.check_circle_outline : Icons.error_outline, color: prompt.isApproved ? const Color(0xff16A34A) : const Color(0xffDC2626), size: 40),
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
                    navigator.pushNamedAndRemoveUntil('/main', (route) => false, arguments: MainScreenParam(returnedPageIndex: 0));
                  }
                },
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      );
      return true;
    } finally {
      _decisionDialogOpen = false;
    }
  }

  Future<List<WorkerPendingExtensionRequest>> _loadPendingExtensionRequests() async {
    final loader = _pendingRequestsLoader;
    if (loader != null) return loader();
    final fetchUseCase = _fetchExtensionRequestsUseCase;
    if (fetchUseCase == null) return const <WorkerPendingExtensionRequest>[];

    final response = await fetchUseCase(FetchExtensionRequestsUsecasParams());
    return response.fold((_) => const <WorkerPendingExtensionRequest>[], (result) {
      final list = result.data ?? const <dynamic>[];
      return list
          .where((item) => item.isPendingWorkerResponse)
          .map((item) => WorkerPendingExtensionRequest(
                warningId: _asInt(item.id),
                bookingId: _asInt(item.bookingId),
                requestedMinutes: _asInt(item.resolvedAdditionalMinutes),
              ))
          .toList(growable: false);
    });
  }

  Future<List<FetchOrdersUsecaseModelDataItem>> _loadPendingOrders() async {
    final loader = _pendingOrdersLoader;
    if (loader != null) {
      return loader().then(
        (orders) => orders
            .where(OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker)
            .toList(growable: false),
      );
    }
    final fetchUseCase = _fetchOrdersUsecaseUseCase;
    if (fetchUseCase == null) return const <FetchOrdersUsecaseModelDataItem>[];

    final collected = <FetchOrdersUsecaseModelDataItem>[];
    for (var page = 1; page <= _pollMaxPagesPerStatus; page++) {
      final response = await fetchUseCase(FetchOrdersUsecaseParams(page: page, perPage: _pollPageSize, status: CleaningBookingStatus.pending));
      final orders = response.fold((_) => const <FetchOrdersUsecaseModelDataItem>[], (result) => result.data ?? const <FetchOrdersUsecaseModelDataItem>[]);
      if (orders.isEmpty) break;
      collected.addAll(orders.where(OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker));
      if (orders.length < _pollPageSize) break;
    }
    return collected;
  }

  void _onWorkerRealtimeChannelError(RealtimeChannelError error) {
    if (error.statusCode != 403) return;
    if (_workerChannelAuthWarningShown) return;
    _workerChannelAuthWarningShown = true;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to connect realtime worker updates right now. The app will keep syncing in the background.')));
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
    if (bloc != null && !bloc.isClosed) await bloc.close();
  }

  void _resetPromptSessionState() {
    _promptSheetOpen = false;
    _decisionDialogOpen = false;
    _handledPendingPromptBookingIds.clear();
    _inFlightPendingPromptBookingIds.clear();
    _inFlightExtensionLookupBookingIds.clear();
    _handledCompletionDecisionKeys.clear();
    _handledRealtimeEventKeys.clear();
    _extensionPromptStates.clear();
  }

  String? _completionDecisionKey({required int? bookingId, required String decision, required Map<String, dynamic> payload}) {
    if (bookingId == null) return null;
    final discriminator = payload['version'] ?? payload['decidedAt'] ?? payload['decided_at'] ?? '';
    return '$bookingId|$discriminator|$decision';
  }

  int? _readWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}');
  }

  bool _hasToken() {
    final token = (SharedPreferencesHelper.getData(key: 'token') ?? '').toString().trim();
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

enum _ExtensionPromptState { idle, pendingPrompt, showing, resolved }

class WorkerExtensionPromptData {
  const WorkerExtensionPromptData({required this.warningId, required this.bookingId, required this.requestedMinutes, required this.customerName, required this.additionalAmount, required this.currency, required this.paymentMethod});
  final int warningId;
  final int? bookingId;
  final int? requestedMinutes;
  final String? customerName;
  final double? additionalAmount;
  final String? currency;
  final String? paymentMethod;
}

class WorkerPendingOrderPromptData {
  const WorkerPendingOrderPromptData({required this.order});
  final FetchOrdersUsecaseModelDataItem order;
}

class WorkerDecisionAlertData {
  const WorkerDecisionAlertData({required this.isApproved, required this.title, required this.message, this.navigateToMainOnOk = false});
  final bool isApproved;
  final String title;
  final String message;
  final bool navigateToMainOnOk;
}

class WorkerPendingExtensionRequest {
  const WorkerPendingExtensionRequest({required this.warningId, required this.bookingId, required this.requestedMinutes});
  final int? warningId;
  final int? bookingId;
  final int? requestedMinutes;
}

class _ExtensionPromptEnrichment {
  const _ExtensionPromptEnrichment({required this.requestedMinutes, required this.customerName, required this.additionalAmount, required this.currency, required this.paymentMethod});
  final int? requestedMinutes;
  final String? customerName;
  final double? additionalAmount;
  final String? currency;
  final String? paymentMethod;
}
