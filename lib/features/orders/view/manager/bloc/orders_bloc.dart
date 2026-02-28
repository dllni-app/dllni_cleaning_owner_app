import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:common_package/helpers/pagination_helper.dart';
import 'package:common_package/helpers/droppable_helper.dart';
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

part 'orders_event.dart';

part 'orders_state.dart';

@injectable
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
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
    this.rejectOrderUsecaseUseCase,) : super(OrdersState()) {
    on<FetchOrdersUsecaseEvent>(_fetchOrdersUsecase, transformer: droppableProMax());
    on<FetchOrderDetailsUsecaseEvent>(_fetchOrderDetailsUsecase);
    on<AcceptOrderUsecaseEvent>(_acceptOrderUsecase);
    on<StartTravelUsecaseEvent>(_startTravelUsecase);
    on<CompleteOrderUsecaseEvent>(_completeOrderUsecase);
    on<CancelOrderEvent>(_cancelOrder);
    on<FetchExtensionRequestsUsecasEvent>(_fetchExtensionRequestsUsecas, transformer: droppableProMax());
    on<AcceptExtensionUsecaseEvent>(_acceptExtensionUsecase);
    on<RejectExtensionUsecaseEvent>(_rejectExtensionUsecase);
    on<UpdateAvailabilityUsecaseEvent>(_updateAvailabilityUsecase);
  
    on<RejectOrderUsecaseEvent>(_rejectOrderUsecase);}

  EventTransformer<T> droppableProMax<T extends EventWithReload>() {
    return (events, mapper) {
      return events.transform(ExhaustMapStreamTransformer(mapper));
    };
  }

  FutureOr<void> _fetchOrdersUsecase(FetchOrdersUsecaseEvent event, Emitter<OrdersState> emit) async {
    if (!state.ordersUsecase!.isEndPage || event.isReload) {
      emit(state.copyWith(ordersUsecase: state.ordersUsecase!.setLoading(isReload: event.isReload)));
      final res = await fetchOrdersUsecaseUseCase(event.params);
      res.fold(
        (l) {
          emit(
            state.copyWith(
              ordersUsecase: state.ordersUsecase!.setFaild(errorMessage: l.message),
              errorMessage: l.message,
            ),
          );
        },
        (r) {
          emit(state.copyWith(ordersUsecase: state.ordersUsecase!.setSuccess(data: r.data!)));
        },
      );
    }
  }

  FutureOr<void> _fetchOrderDetailsUsecase(FetchOrderDetailsUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(orderDetailsUsecaseStatus: BlocStatus.loading));
    final res = await fetchOrderDetailsUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(orderDetailsUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(orderDetailsUsecaseStatus: BlocStatus.success, orderDetailsUsecase: r));
      },
    );
  }

  FutureOr<void> _acceptOrderUsecase(AcceptOrderUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(acceptOrderUsecaseStatus: BlocStatus.loading));
    final res = await acceptOrderUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(acceptOrderUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(acceptOrderUsecaseStatus: BlocStatus.success, acceptOrderUsecase: r));
      },
    );
  }

  FutureOr<void> _startTravelUsecase(StartTravelUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(startTravelUsecaseStatus: BlocStatus.loading));
    final res = await startTravelUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(startTravelUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(startTravelUsecaseStatus: BlocStatus.success, startTravelUsecase: r));
      },
    );
  }

  FutureOr<void> _completeOrderUsecase(CompleteOrderUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(completeOrderUsecaseStatus: BlocStatus.loading));
    final res = await completeOrderUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(completeOrderUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(completeOrderUsecaseStatus: BlocStatus.success, completeOrderUsecase: r));
      },
    );
  }

  FutureOr<void> _cancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(cancelOrderStatus: BlocStatus.loading));
    final res = await cancelOrderUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(cancelOrderStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(cancelOrderStatus: BlocStatus.success, cancelOrder: r));
      },
    );
  }

  FutureOr<void> _fetchExtensionRequestsUsecas(FetchExtensionRequestsUsecasEvent event, Emitter<OrdersState> emit) async {
    if (!state.extensionRequestsUsecas!.isEndPage || event.isReload) {
      emit(state.copyWith(extensionRequestsUsecas: state.extensionRequestsUsecas!.setLoading(isReload: event.isReload)));
      final res = await fetchExtensionRequestsUsecasUseCase(event.params);
      res.fold(
        (l) {
          emit(
            state.copyWith(
              extensionRequestsUsecas: state.extensionRequestsUsecas!.setFaild(errorMessage: l.message),
              errorMessage: l.message,
            ),
          );
        },
        (r) {
          emit(state.copyWith(extensionRequestsUsecas: state.extensionRequestsUsecas!.setSuccess(data: r.data!)));
        },
      );
    }
  }

  FutureOr<void> _acceptExtensionUsecase(AcceptExtensionUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(acceptExtensionUsecaseStatus: BlocStatus.loading));
    final res = await acceptExtensionUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(acceptExtensionUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(acceptExtensionUsecaseStatus: BlocStatus.success, acceptExtensionUsecase: r));
      },
    );
  }

  FutureOr<void> _rejectExtensionUsecase(RejectExtensionUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(rejectExtensionUsecaseStatus: BlocStatus.loading));
    final res = await rejectExtensionUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(rejectExtensionUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(rejectExtensionUsecaseStatus: BlocStatus.success, rejectExtensionUsecase: r));
      },
    );
  }

  FutureOr<void> _updateAvailabilityUsecase(UpdateAvailabilityUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(availabilityUsecaseStatus: BlocStatus.loading));
    final res = await updateAvailabilityUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(availabilityUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(availabilityUsecaseStatus: BlocStatus.success, availabilityUsecase: r));
      },
    );
  }


  FutureOr<void> _rejectOrderUsecase(RejectOrderUsecaseEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(rejectOrderUsecaseStatus: BlocStatus.loading));
    final res = await rejectOrderUsecaseUseCase(event.params);
    res.fold((l) {
      emit(state.copyWith(
        rejectOrderUsecaseStatus: BlocStatus.failed,
        errorMessage: l.message,
      ));
    }, (r) {
      emit(state.copyWith(
        rejectOrderUsecaseStatus: BlocStatus.success,
        rejectOrderUsecase: r,
      ));
    });
  }}
