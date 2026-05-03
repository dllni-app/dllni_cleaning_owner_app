import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:common_package/common_package.dart';
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
  }

  EventTransformer<T> droppableProMax<T extends EventWithReload>() {
    return (events, mapper) {
      return events.transform(ExhaustMapStreamTransformer(mapper));
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
    if (!state.ordersUsecase!.isEndPage || event.isReload) {
      emit(
        state.copyWith(
          ordersUsecase: state.ordersUsecase!.setLoading(
            isReload: event.isReload,
          ),
        ),
      );
      final res = await fetchOrdersUsecaseUseCase(event.params);
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
          emit(
            state.copyWith(
              ordersUsecase: state.ordersUsecase!.setSuccess(data: r.data!),
            ),
          );
        },
      );
    }
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
        emit(
          state.copyWith(
            orderDetailsUsecaseStatus: BlocStatus.success,
            orderDetailsUsecase: r,
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
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            acceptOrderUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم قبول الطلب');
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.pending,
            ),
            isReload: true,
          ),
        );
        emit(
          state.copyWith(
            acceptOrderUsecaseStatus: BlocStatus.success,
            acceptOrderUsecase: r,
            currentStep: 1,
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
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            startTravelUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم بدء التحرك');
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.workerAssigned,
            ),
            isReload: true,
          ),
        );
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
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            completeOrderUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم إكمال الطلب');
        add(
          FetchOrderDetailsUsecaseEvent(
            params: FetchOrderDetailsUsecaseParams(id: event.params.id),
          ),
        );
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.inProgress,
            ),
            isReload: true,
          ),
        );
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.workerAssigned,
            ),
            isReload: true,
          ),
        );
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
    emit(state.copyWith(cancelOrderStatus: BlocStatus.loading));
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
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.workerAssigned,
            ),
            isReload: true,
          ),
        );
        emit(
          state.copyWith(cancelOrderStatus: BlocStatus.success, cancelOrder: r),
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
        add(
          FetchExtensionRequestsUsecasEvent(
            params: FetchExtensionRequestsUsecasParams(),
            isReload: true,
          ),
        );
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
        add(
          FetchExtensionRequestsUsecasEvent(
            params: FetchExtensionRequestsUsecasParams(),
            isReload: true,
          ),
        );
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
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.pending,
            ),
            isReload: true,
          ),
        );
        emit(
          state.copyWith(
            rejectOrderUsecaseStatus: BlocStatus.success,
            rejectOrderUsecase: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _arrive(ArriveEvent event, Emitter<OrdersState> emit) async {
    emit(
      state.copyWith(
        arriveStatus: BlocStatus.loading,
        selectedIndex: event.index,
      ),
    );
    final res = await arriveUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            arriveStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم تأكيد الوصول');
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.workerAssigned,
            ),
            isReload: true,
          ),
        );
        final status = r.data?.status;
        final step = status == CleaningBookingStatus.awaitingStartVerification
            ? 4
            : status == CleaningBookingStatus.inProgress
            ? 3
            : 3;
        emit(
          state.copyWith(
            arriveStatus: BlocStatus.success,
            arrive: r,
            currentStep: step,
          ),
        );
      },
    );
  }

  FutureOr<void> _reportBookingLocation(
    ReportBookingLocationEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final res = await postBookingLocationUseCase(event.params);
    res.fold((l) => AppToast.showErrorGlobal(l.message), (_) {});
  }

  FutureOr<void> _fetchSecurityCode(
    FetchSecurityCodeEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(securityCodeStatus: BlocStatus.loading));
    final res = await fetchSecurityCodeUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            securityCodeStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم جلب رمز التحقق');
        emit(
          state.copyWith(
            securityCodeStatus: BlocStatus.success,
            securityCode: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _startWork(
    StartWorkEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(startWorkStatus: BlocStatus.loading));
    final res = await startWorkUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            startWorkStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم بدء العمل');
        add(
          FetchOrderDetailsUsecaseEvent(
            params: FetchOrderDetailsUsecaseParams(id: event.params.id),
          ),
        );
        add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.inProgress,
            ),
            isReload: true,
          ),
        );
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

  FutureOr<void> _syncOrderFromRealtime(
    SyncOrderFromRealtimeEvent event,
    Emitter<OrdersState> emit,
  ) {
    add(
      FetchOrderDetailsUsecaseEvent(
        params: FetchOrderDetailsUsecaseParams(id: event.bookingId),
      ),
    );
  }
}
