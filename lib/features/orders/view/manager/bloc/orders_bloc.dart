import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:common_package/common_package.dart';
import '../../../../../core/realtime/cleaning_realtime_contract.dart';
import '../../../data/models/cleaning_booking_status.dart';
import '../../../domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../../../data/models/fetch_order_details_usecase_model.dart';
import '../../../domain/usecases/accept_order_usecase_use_case.dart';
import '../../../data/models/accept_order_usecase_model.dart';
import '../../../domain/usecases/start_travel_usecase_use_case.dart';
import '../../../data/models/start_travel_usecase_model.dart';
import '../../../domain/usecases/complete_order_usecase_use_case.dart';
import '../../../data/models/complete_order_usecase_model.dart';
import '../../../domain/usecases/cancel_order_use_case.dart';
import '../../../data/models/cancel_order_details_model.dart';
import '../../../domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import '../../../data/models/fetch_extension_requests_usecas_model.dart';
import '../../../domain/usecases/accept_extension_usecase_use_case.dart';
import '../../../data/models/accept_extension_usecase_model.dart';
import '../../../domain/usecases/reject_extension_usecase_use_case.dart';
import '../../../data/models/reject_extension_usecase_model.dart';
import '../../../domain/usecases/update_availability_usecase_use_case.dart';
import '../../../data/models/update_availability_usecase_model.dart';
import '../../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../../data/models/reject_order_usecase_model.dart';
import '../../../domain/usecases/arrive_use_case.dart';
import '../../../data/models/arrive_model.dart';
import '../../../domain/usecases/post_booking_location_use_case.dart';
import '../../../domain/usecases/fetch_security_code_use_case.dart';
import '../../../data/models/security_code_model.dart';
import '../../../domain/usecases/start_work_use_case.dart';
import '../../../data/models/start_work_model.dart';
import '../../helpers/order_details_to_list_item_mapper.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../../helpers/orders_lifecycle_failure_message_mapper.dart';
import '../../helpers/orders_pending_order_list_hydrator.dart';
import '../../helpers/orders_realtime_hydration_policy.dart';
import '../../helpers/orders_worker_eligibility_cache.dart';
import '../../widgets/order_details/location_reporting_policy.dart';

part 'orders_event.dart';

part 'orders_state.dart';

@injectable
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ArriveUseCase arriveUseCase;
  final RejectOrderUsecaseUseCase rejectOrderUsecaseUseCase;
  final UpdateAvailabilityUsecaseUseCase updateAvailabilityUsecaseUseCase;
  final RejectExtensionUsecaseUseCase rejectExtensionUsecaseUseCase;
  final AcceptExtensionUsecaseUseCase acceptExtensionUsecaseUseCase;
  final FetchExtensionRequestsUsecasUseCase fetchExtensionRequestsUsecasUseCase;
  final CancelOrderUseCase cancelOrderUseCase;
  final CompleteOrderUsecaseUseCase completeOrderUsecaseUseCase;
  final StartTravelUsecaseUseCase startTravelUsecaseUseCase;
  final AcceptOrderUsecaseUseCase acceptOrderUsecaseUseCase;
  final FetchOrderDetailsUsecaseUseCase fetchOrderDetailsUsecaseUseCase;
  final FetchOrdersUsecaseUseCase fetchOrdersUsecaseUseCase;
  final PostBookingLocationUseCase postBookingLocationUseCase;
  final FetchSecurityCodeUseCase fetchSecurityCodeUseCase;
  final StartWorkUseCase startWorkUseCase;
  String _lastOrdersStatusFilter = CleaningBookingStatus.workerAssigned;
  int? _arrivingBookingId;
  int? _securityCodeInFlightForBookingId;
  int? _securityCodeLoadedForBookingId;

  OrdersBloc(
    this.fetchOrdersUsecaseUseCase,
    this.fetchOrderDetailsUsecaseUseCase,
    this.acceptOrderUsecaseUseCase,
    this.startTravelUsecaseUseCase,
    this.completeOrderUsecaseUseCase,
    this.cancelOrderUseCase,
    this.fetchExtensionRequestsUsecasUseCase,
    this.acceptExtensionUsecaseUseCase,
    this.rejectExtensionUsecaseUseCase,
    this.updateAvailabilityUsecaseUseCase,
    this.rejectOrderUsecaseUseCase,
    this.arriveUseCase,
    this.postBookingLocationUseCase,
    this.fetchSecurityCodeUseCase,
    this.startWorkUseCase,
  ) : super(OrdersState()) {
    on<FetchOrdersUsecaseEvent>(
      _fetchOrdersUsecase,
      transformer: droppableProMax(),
    );
    on<FetchOrderDetailsUsecaseEvent>(_fetchOrderDetailsUsecase);
    on<AcceptOrderUsecaseEvent>(_acceptOrderUsecase);
    on<StartTravelUsecaseEvent>(_startTravelUsecase);
    on<CompleteOrderUsecaseEvent>(_completeOrderUsecase);
    on<CancelOrderEvent>(_cancelOrder);
    on<FetchExtensionRequestsUsecasEvent>(
      _fetchExtensionRequestsUsecas,
      transformer: droppableProMax(),
    );
    on<AcceptExtensionUsecaseEvent>(_acceptExtensionUsecase);
    on<RejectExtensionUsecaseEvent>(_rejectExtensionUsecase);
    on<UpdateAvailabilityUsecaseEvent>(_updateAvailabilityUsecase);
    on<RejectOrderUsecaseEvent>(_rejectOrderUsecase);
    on<ArriveEvent>(_arrive);
    on<ChangeDetailsCurrentStep>(_changeDetailsStep);
    on<ReportBookingLocationEvent>(_reportBookingLocation);
    on<FetchSecurityCodeEvent>(_fetchSecurityCode);
    on<StartWorkEvent>(_startWork);
    on<SyncOrderFromRealtimeEvent>(_syncOrderFromRealtime);
    on<HydrateOrderListFromRealtimeEvent>(_hydrateOrderListFromRealtime);
    on<HydrateOrderDetailsFromRealtimeEvent>(_hydrateOrderDetailsFromRealtime);
    on<SyncPendingOrderFromRealtimeEvent>(_syncPendingOrderFromRealtime);
    on<SetOrdersListFilterEvent>(_setOrdersListFilter);
  }

  void _setOrdersListFilter(
    SetOrdersListFilterEvent event,
    Emitter<OrdersState> emit,
  ) {
    _lastOrdersStatusFilter = event.status;
  }

  EventTransformer<T> droppableProMax<T extends EventWithReload>() {
    return (events, mapper) {
      return events.transform(ExhaustMapStreamTransformer(maper: mapper));
    };
  }

  FutureOr<void> _changeDetailsStep(
    ChangeDetailsCurrentStep event,
    Emitter emit,
  ) {
    emit(state.copyWith(currentStep: event.step));
  }

  FutureOr<void> _fetchOrdersUsecase(
    FetchOrdersUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    _rememberOrdersListFilter(event.params);
    if (!state.ordersUsecase!.isEndPage || event.isReload) {
      if (event.silent) {
        final res = await fetchOrdersUsecaseUseCase(event.params);
        if (emit.isDone) return;
        res.fold(
          (l) {},
          (r) {
            _cacheWorkerEligibility(r);
            emit(
              state.copyWith(
                ordersUsecase: state.ordersUsecase!.setSuccessReplace(
                  data: r.data!,
                ),
              ),
            );
          },
        );
        return;
      }

      emit(
        state.copyWith(
          ordersUsecase: state.ordersUsecase!.setLoading(
            isReload: event.isReload,
          ),
        ),
      );
      final res = await fetchOrdersUsecaseUseCase(event.params);
      if (emit.isDone) return;
      res.fold(
        (l) {
          AppToast.showErrorGlobal(l.message);
          emit(
            state.copyWith(
              ordersUsecase: state.ordersUsecase!.setFaild(
                errorMessage: l.message,
              ),
              errorMessage: l.message,
            ),
          );
        },
        (r) {
          _cacheWorkerEligibility(r);
          emit(
            state.copyWith(
              ordersUsecase: state.ordersUsecase!.setSuccess(data: r.data!),
            ),
          );
        },
      );
    }
  }

  void _rememberOrdersListFilter(FetchOrdersUsecaseParams params) {
    _lastOrdersStatusFilter = params.status ?? _lastOrdersStatusFilter;
  }

  void _refreshOrdersList({required String status, bool silent = true}) {
    add(
      FetchOrdersUsecaseEvent(
        params: FetchOrdersUsecaseParams(page: 1, status: status),
        isReload: true,
        silent: silent,
      ),
    );
  }

  void _refreshLastOrdersList({bool silent = true}) {
    _refreshOrdersList(status: _lastOrdersStatusFilter, silent: silent);
  }

  void _refreshPendingOrders({bool silent = true}) {
    _refreshOrdersList(status: CleaningBookingStatus.pending, silent: silent);
  }

  void _refreshWorkerAssignedOrders({bool silent = true}) {
    _refreshOrdersList(
      status: CleaningBookingStatus.workerAssigned,
      silent: silent,
    );
  }

  void _refreshInProgressOrders({bool silent = true}) {
    _refreshOrdersList(status: CleaningBookingStatus.inProgress, silent: silent);
  }

  void _refreshOrderDetails(int bookingId) {
    add(
      FetchOrderDetailsUsecaseEvent(
        params: FetchOrderDetailsUsecaseParams(id: bookingId),
      ),
    );
  }

  void _refreshExtensionRequests() {
    add(
      FetchExtensionRequestsUsecasEvent(
        params: FetchExtensionRequestsUsecasParams(),
        isReload: true,
      ),
    );
  }

  FutureOr<void> _fetchOrderDetailsUsecase(
    FetchOrderDetailsUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(orderDetailsUsecaseStatus: BlocStatus.loading));
    final res = await fetchOrderDetailsUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            orderDetailsUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        final status = r.data?.status;
        final step = status != null
            ? OrderLifecyclePolicy.detailsStepForStatus(status)
            : state.currentStep;
        emit(
          state.copyWith(
            orderDetailsUsecaseStatus: BlocStatus.success,
            orderDetailsUsecase: r,
            currentStep: step,
          ),
        );
      },
    );
  }

  FutureOr<void> _acceptOrderUsecase(
    AcceptOrderUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        acceptOrderUsecaseStatus: BlocStatus.loading,
        selectedIndex: event.index,
      ),
    );
    final res = await acceptOrderUsecaseUseCase(event.params);
    await res.fold(
      (l) async {
        final message = _mapAcceptFailureMessage(l);
        AppToast.showErrorGlobal(message);
        _refreshOrderDetails(event.params.id);
        _refreshPendingOrders();
        if (emit.isDone) return;
        emit(
          state.copyWith(
            acceptOrderUsecaseStatus: BlocStatus.failed,
            errorMessage: message,
          ),
        );
      },
      (r) async {
        AppToast.showSuccessGlobal('تم قبول الطلب');
        final updatedOrder = await _fetchOrderListItemById(event.params.id);
        if (emit.isDone) return;

        final updatedStatus =
            (updatedOrder?.status ?? r.data?.status)?.trim().toLowerCase();
        final shouldKeepInPending =
            updatedOrder != null && updatedStatus == CleaningBookingStatus.pending;

        final nextOrders = shouldKeepInPending
            ? OrdersPendingOrderListHydrator.upsert(
                state.ordersUsecase!,
                updatedOrder,
              )
            : state.ordersUsecase!.removeWhere(
                (order) => order.id == event.params.id,
              );

        if (shouldKeepInPending) {
          _refreshOrderDetails(event.params.id);
        } else if (updatedStatus == CleaningBookingStatus.workerAssigned) {
          _refreshWorkerAssignedOrders();
          _refreshOrderDetails(event.params.id);
        } else {
          _refreshPendingOrders();
        }

        emit(
          state.copyWith(
            acceptOrderUsecaseStatus: BlocStatus.success,
            acceptOrderUsecase: r,
            currentStep: 1,
            ordersUsecase: nextOrders,
          ),
        );
      },
    );
  }

  FutureOr<void> _startTravelUsecase(
    StartTravelUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        startTravelUsecaseStatus: BlocStatus.loading,
        selectedIndex: event.index,
      ),
    );
    final res = await startTravelUsecaseUseCase(event.params);
    res.fold(
      (l) {
        final message = _mapLifecycleFailureMessage(
          l,
          invalidStateMessage: 'لا يمكن بدء التحرك في حالة الطلب الحالية.',
        );
        AppToast.showErrorGlobal(message);
        emit(
          state.copyWith(
            startTravelUsecaseStatus: BlocStatus.failed,
            errorMessage: message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم بدء التحرك');
        _refreshWorkerAssignedOrders();
        emit(
          state.copyWith(
            startTravelUsecaseStatus: BlocStatus.success,
            startTravelUsecase: r,
            currentStep: 2,
          ),
        );
      },
    );
  }

  FutureOr<void> _completeOrderUsecase(
    CompleteOrderUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(completeOrderUsecaseStatus: BlocStatus.loading));
    final res = await completeOrderUsecaseUseCase(event.params);
    res.fold(
      (l) {
        final message = _mapLifecycleFailureMessage(
          l,
          invalidStateMessage: 'لا يمكن إنهاء العمل في حالة الطلب الحالية.',
        );
        AppToast.showErrorGlobal(message);
        emit(
          state.copyWith(
            completeOrderUsecaseStatus: BlocStatus.failed,
            errorMessage: message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم إكمال الطلب');
        _refreshOrderDetails(event.params.id);
        _refreshInProgressOrders();
        _refreshWorkerAssignedOrders();
        emit(
          state.copyWith(
            completeOrderUsecaseStatus: BlocStatus.success,
            completeOrderUsecase: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _cancelOrder(
    CancelOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        cancelOrderStatus: BlocStatus.loading,
        selectedIndex: event.index,
      ),
    );
    final res = await cancelOrderUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            cancelOrderStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم إلغاء الطلب');
        _refreshLastOrdersList();
        emit(
          state.copyWith(
            cancelOrderStatus: BlocStatus.success,
            cancelOrder: r,
            ordersUsecase: state.ordersUsecase!.removeWhere(
              (order) => order.id == event.params.id,
            ),
          ),
        );
      },
    );
  }

  FutureOr<void> _fetchExtensionRequestsUsecas(
    FetchExtensionRequestsUsecasEvent event,
    Emitter<OrdersState> emit,
  ) async {
    if (!state.extensionRequestsUsecas!.isEndPage || event.isReload) {
      emit(
        state.copyWith(
          extensionRequestsUsecas: state.extensionRequestsUsecas!.setLoading(
            isReload: event.isReload,
          ),
        ),
      );
      final res = await fetchExtensionRequestsUsecasUseCase(event.params);
      res.fold(
        (l) {
          AppToast.showErrorGlobal(l.message);
          emit(
            state.copyWith(
              extensionRequestsUsecas: state.extensionRequestsUsecas!.setFaild(
                errorMessage: l.message,
              ),
              errorMessage: l.message,
            ),
          );
        },
        (r) {
          emit(
            state.copyWith(
              extensionRequestsUsecas: state.extensionRequestsUsecas!
                  .setSuccess(data: r.data!),
            ),
          );
        },
      );
    }
  }

  FutureOr<void> _acceptExtensionUsecase(
    AcceptExtensionUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(acceptExtensionUsecaseStatus: BlocStatus.loading));
    final res = await acceptExtensionUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            acceptExtensionUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم قبول طلب التمديد');
        _refreshExtensionRequests();
        emit(
          state.copyWith(
            acceptExtensionUsecaseStatus: BlocStatus.success,
            acceptExtensionUsecase: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _rejectExtensionUsecase(
    RejectExtensionUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(rejectExtensionUsecaseStatus: BlocStatus.loading));
    final res = await rejectExtensionUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            rejectExtensionUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم رفض طلب التمديد');
        _refreshExtensionRequests();
        emit(
          state.copyWith(
            rejectExtensionUsecaseStatus: BlocStatus.success,
            rejectExtensionUsecase: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _updateAvailabilityUsecase(
    UpdateAvailabilityUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(availabilityUsecaseStatus: BlocStatus.loading));
    final res = await updateAvailabilityUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            availabilityUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث التوفر');
        emit(
          state.copyWith(
            availabilityUsecaseStatus: BlocStatus.success,
            availabilityUsecase: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _rejectOrderUsecase(
    RejectOrderUsecaseEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        rejectOrderUsecaseStatus: BlocStatus.loading,
        selectedIndex: event.index,
      ),
    );
    final res = await rejectOrderUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            rejectOrderUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم رفض الطلب');
        _refreshPendingOrders();
        emit(
          state.copyWith(
            rejectOrderUsecaseStatus: BlocStatus.success,
            rejectOrderUsecase: r,
            ordersUsecase: state.ordersUsecase!.removeWhere(
              (order) => order.id == event.params.id,
            ),
          ),
        );
      },
    );
  }

  FutureOr<void> _arrive(ArriveEvent event, Emitter<OrdersState> emit) async {
    _arrivingBookingId = event.params.id;
    emit(
      state.copyWith(
        arriveStatus: BlocStatus.loading,
        selectedIndex: event.index,
      ),
    );
    final res = await arriveUseCase(event.params);
    res.fold(
      (l) {
        _arrivingBookingId = null;
        final message = _mapLifecycleFailureMessage(
          l,
          invalidStateMessage: 'لا يمكن تأكيد الوصول في حالة الطلب الحالية.',
        );
        AppToast.showErrorGlobal(message);
        emit(
          state.copyWith(
            arriveStatus: BlocStatus.failed,
            errorMessage: message,
          ),
        );
      },
      (r) {
        _arrivingBookingId = null;
        AppToast.showSuccessGlobal('تم تأكيد الوصول');
        final bookingId = r.data?.id ?? event.params.id;
        _refreshWorkerAssignedOrders();
        _refreshOrderDetails(bookingId);

        final embeddedCode = r.data == null
            ? null
            : SecurityCodeModel.tryFromBookingPayload(r.data!.toJson());
        final hasEmbeddedCode = embeddedCode?.data?.hasCode == true;
        final status = r.data?.status;
        final step = status == null
            ? 2
            : OrderLifecyclePolicy.detailsStepForStatus(status);
        emit(
          state.copyWith(
            arriveStatus: BlocStatus.success,
            arrive: r,
            currentStep: step,
            securityCode: hasEmbeddedCode ? embeddedCode : state.securityCode,
            securityCodeStatus: hasEmbeddedCode
                ? BlocStatus.success
                : state.securityCodeStatus,
          ),
        );

        if (hasEmbeddedCode) {
          _securityCodeLoadedForBookingId = bookingId;
        } else if (status == CleaningBookingStatus.awaitingStartVerification) {
          add(
            FetchSecurityCodeEvent(
              params: FetchSecurityCodeParams(id: bookingId),
            ),
          );
        }
      },
    );
  }

  FutureOr<void> _reportBookingLocation(
    ReportBookingLocationEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final bookingId = event.params.id;
    if (_arrivingBookingId == bookingId) return;

    final lifecycle = _bookingLifecycleSnapshot(bookingId);
    if ((lifecycle.status ?? '').toLowerCase() ==
        CleaningBookingStatus.awaitingStartVerification) {
      return;
    }
    if (!shouldReportWorkerLocation(
      status: lifecycle.status,
      startedTravelAt: lifecycle.startedTravelAt,
      arrivedAt: lifecycle.arrivedAt,
    )) {
      return;
    }

    final res = await postBookingLocationUseCase(event.params);
    res.fold(
      (l) => AppToast.showErrorGlobal(
        _mapLifecycleFailureMessage(
          l,
          invalidStateMessage: 'تعذر إرسال الموقع في حالة الطلب الحالية.',
        ),
      ),
      (_) {},
    );
  }

  FutureOr<void> _fetchSecurityCode(
    FetchSecurityCodeEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final bookingId = event.params.id;
    if (!event.force) {
      if (_securityCodeInFlightForBookingId == bookingId) return;
      final cached = state.securityCode?.data;
      if (_securityCodeLoadedForBookingId == bookingId &&
          cached?.hasCode == true) {
        return;
      }
    }

    _securityCodeInFlightForBookingId = bookingId;
    emit(state.copyWith(securityCodeStatus: BlocStatus.loading));
    final res = await fetchSecurityCodeUseCase(event.params);
    _securityCodeInFlightForBookingId = null;
    res.fold(
      (l) {
        final message = _mapLifecycleFailureMessage(
          l,
          invalidStateMessage: 'لا يمكن جلب رمز التحقق في حالة الطلب الحالية.',
        );
        if (event.force) {
          AppToast.showErrorGlobal(message);
        }
        emit(
          state.copyWith(
            securityCodeStatus: BlocStatus.failed,
            errorMessage: message,
          ),
        );
      },
      (r) {
        if (event.force) {
          AppToast.showSuccessGlobal('تم جلب رمز التحقق');
        }
        _securityCodeLoadedForBookingId = bookingId;
        emit(
          state.copyWith(
            securityCodeStatus: BlocStatus.success,
            securityCode: r,
          ),
        );
      },
    );
  }

  ({String? status, String? startedTravelAt, String? arrivedAt})
  _bookingLifecycleSnapshot(int bookingId) {
    final arrive = state.arrive?.data;
    if (arrive?.id == bookingId) {
      return (
        status: arrive?.status,
        startedTravelAt: arrive?.startedTravelAt,
        arrivedAt: arrive?.arrivedAt,
      );
    }

    final details = state.orderDetailsUsecase?.data;
    if (details?.id == bookingId) {
      return (
        status: details?.status,
        startedTravelAt: details?.startedTravelAt,
        arrivedAt: details?.arrivedAt,
      );
    }

    return (status: null, startedTravelAt: null, arrivedAt: null);
  }

  FutureOr<void> _startWork(
    StartWorkEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(startWorkStatus: BlocStatus.loading));
    final res = await startWorkUseCase(event.params);
    res.fold(
      (l) {
        final message = _mapLifecycleFailureMessage(
          l,
          invalidStateMessage: 'لا يمكن بدء العمل في حالة الطلب الحالية.',
        );
        AppToast.showErrorGlobal(message);
        emit(
          state.copyWith(
            startWorkStatus: BlocStatus.failed,
            errorMessage: message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم بدء العمل');
        _refreshOrderDetails(event.params.id);
        _refreshInProgressOrders();
        emit(
          state.copyWith(
            startWorkStatus: BlocStatus.success,
            startWork: r,
            currentStep: 3,
          ),
        );
      },
    );
  }

  void _syncOrderFromRealtime(
    SyncOrderFromRealtimeEvent event,
    Emitter<OrdersState> emit,
  ) {
    _refreshOrderDetails(event.bookingId);
  }

  void _hydrateOrderListFromRealtime(
    HydrateOrderListFromRealtimeEvent event,
    Emitter<OrdersState> emit,
  ) {
    if (!OrdersRealtimeHydrationPolicy.shouldRefreshLifecycleList(
      event.eventName,
    )) {
      return;
    }
    _refreshLastOrdersList();
  }

  void _hydrateOrderDetailsFromRealtime(
    HydrateOrderDetailsFromRealtimeEvent event,
    Emitter<OrdersState> emit,
  ) {
    if (!OrdersRealtimeHydrationPolicy.shouldRefreshLifecycleDetails(
      event.eventName,
    )) {
      return;
    }
    add(SyncOrderFromRealtimeEvent(bookingId: event.bookingId));
  }

  FutureOr<void> _syncPendingOrderFromRealtime(
    SyncPendingOrderFromRealtimeEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final bookingId = CleaningRealtimeContract.extractBookingId(event.payload);
    if (OrdersRealtimeHydrationPolicy.shouldIgnorePendingSync(
      eventName: event.eventName,
      payload: event.payload,
    )) {
      return;
    }

    if (bookingId == null) {
      _refreshPendingOrders();
      return;
    }

    final res = await fetchOrderDetailsUsecaseUseCase(
      FetchOrderDetailsUsecaseParams(id: bookingId),
    );
    if (emit.isDone) return;

    res.fold(
      (_) {
        if (!OrdersRealtimeHydrationPolicy
            .shouldRefetchPendingListWhenDetailsMissing(
          applyToPendingList: event.applyToPendingList,
        )) {
          return;
        }
        _refreshPendingOrders();
      },
      (response) {
        final details = response.data;
        if (details == null) {
          if (!OrdersRealtimeHydrationPolicy
              .shouldRefetchPendingListWhenDetailsMissing(
            applyToPendingList: event.applyToPendingList,
          )) {
            return;
          }
          _refreshPendingOrders();
          return;
        }

        if (OrdersRealtimeHydrationPolicy.canUpsertPendingOrder(
          status: details.status,
          applyToPendingList: event.applyToPendingList,
          lastOrdersStatusFilter: _lastOrdersStatusFilter,
        )) {
          final listItem = OrderDetailsToListItemMapper.fromDetails(details);
          emit(
            state.copyWith(
              ordersUsecase: OrdersPendingOrderListHydrator.upsert(
                state.ordersUsecase!,
                listItem,
              ),
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            ordersUsecase: state.ordersUsecase!.removeWhere(
              (order) => order.id == bookingId,
            ),
          ),
        );
      },
    );
  }

  Future<FetchOrdersUsecaseModelDataItem?> _fetchOrderListItemById(
    int bookingId,
  ) async {
    FetchOrdersUsecaseModelDataItem? listItem;
    final response = await fetchOrderDetailsUsecaseUseCase(
      FetchOrderDetailsUsecaseParams(id: bookingId),
    );
    response.fold((_) => null, (result) {
      final details = result.data;
      if (details == null) return;
      listItem = OrderDetailsToListItemMapper.fromDetails(details);
    });
    return listItem;
  }

  String _mapAcceptFailureMessage(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('already accepted') ||
        raw.contains('accepted by a worker') ||
        raw.contains('already been accepted') ||
        raw.contains('no longer available') ||
        raw.contains('not available')) {
      return OrderLifecyclePolicy.orderNoLongerAvailableMessage;
    }

    return _mapLifecycleFailureMessage(
      failure,
      invalidStateMessage: OrderLifecyclePolicy.orderNoLongerAvailableMessage,
    );
  }

  String _mapLifecycleFailureMessage(
    Failure failure, {
    required String invalidStateMessage,
  }) {
    return OrdersLifecycleFailureMessageMapper.map(
      failure,
      invalidStateMessage: invalidStateMessage,
    );
  }

  void _cacheWorkerEligibility(FetchOrdersUsecaseModel model) {
    OrdersWorkerEligibilityCache.saveFromOrdersResponse(model);
  }
}
