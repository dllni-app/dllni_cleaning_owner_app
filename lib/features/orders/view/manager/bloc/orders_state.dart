part of 'orders_bloc.dart';

class OrdersState {
  final BlocStatus? startWorkStatus;
  final StartWorkModel? startWork;
  final BlocStatus? securityCodeStatus;
  final SecurityCodeModel? securityCode;
  final BlocStatus? arriveStatus;
  final ArriveModel? arrive;
  final BlocStatus? rejectOrderUsecaseStatus;
  final RejectOrderUsecaseModel? rejectOrderUsecase;
  final BlocStatus? availabilityUsecaseStatus;
  final UpdateAvailabilityUsecaseModel? availabilityUsecase;
  final BlocStatus? rejectExtensionUsecaseStatus;
  final RejectExtensionUsecaseModel? rejectExtensionUsecase;
  final BlocStatus? acceptExtensionUsecaseStatus;
  final AcceptExtensionUsecaseModel? acceptExtensionUsecase;
  final PaginationStateModel<FetchExtensionRequestsUsecasModelDataItem>?
      extensionRequestsUsecas;
  final BlocStatus? cancelOrderStatus;
  final CancelOrderModel? cancelOrder;
  final BlocStatus? completeOrderUsecaseStatus;
  final CompleteOrderUsecaseModel? completeOrderUsecase;
  final BlocStatus? startTravelUsecaseStatus;
  final StartTravelUsecaseModel? startTravelUsecase;
  final BlocStatus? acceptOrderUsecaseStatus;
  final AcceptOrderUsecaseModel? acceptOrderUsecase;
  final BlocStatus? orderDetailsUsecaseStatus;
  final FetchOrderDetailsUsecaseModel? orderDetailsUsecase;
  final PaginationStateModel<FetchOrdersUsecaseModelDataItem>? ordersUsecase;
  final String? errorMessage;

  final int? selectedIndex;
  final int? currentStep;

  OrdersState({
    this.startWorkStatus,
    this.startWork,
    this.securityCodeStatus,
    this.securityCode,
    this.errorMessage,
    this.ordersUsecase = const PaginationStateModel(perPage: 10),
    this.orderDetailsUsecase,
    this.orderDetailsUsecaseStatus,
    this.acceptOrderUsecase,
    this.acceptOrderUsecaseStatus,
    this.startTravelUsecase,
    this.startTravelUsecaseStatus,
    this.completeOrderUsecase,
    this.completeOrderUsecaseStatus,
    this.cancelOrder,
    this.cancelOrderStatus,
    this.extensionRequestsUsecas = const PaginationStateModel(perPage: 10),
    this.acceptExtensionUsecase,
    this.acceptExtensionUsecaseStatus,
    this.rejectExtensionUsecase,
    this.rejectExtensionUsecaseStatus,
    this.availabilityUsecase,
    this.availabilityUsecaseStatus,
    this.rejectOrderUsecase,
    this.rejectOrderUsecaseStatus,
    this.selectedIndex = -1,
    this.arrive,
    this.arriveStatus,
    this.currentStep = 0,
  });

  OrdersState copyWith({
    StartWorkModel? startWork,
    BlocStatus? startWorkStatus,
    SecurityCodeModel? securityCode,
    BlocStatus? securityCodeStatus,
    String? errorMessage,
    PaginationStateModel<FetchOrdersUsecaseModelDataItem>? ordersUsecase,
    FetchOrderDetailsUsecaseModel? orderDetailsUsecase,
    BlocStatus? orderDetailsUsecaseStatus,
    AcceptOrderUsecaseModel? acceptOrderUsecase,
    BlocStatus? acceptOrderUsecaseStatus,
    StartTravelUsecaseModel? startTravelUsecase,
    BlocStatus? startTravelUsecaseStatus,
    CompleteOrderUsecaseModel? completeOrderUsecase,
    BlocStatus? completeOrderUsecaseStatus,
    CancelOrderModel? cancelOrder,
    BlocStatus? cancelOrderStatus,
    PaginationStateModel<FetchExtensionRequestsUsecasModelDataItem>?
        extensionRequestsUsecas,
    AcceptExtensionUsecaseModel? acceptExtensionUsecase,
    BlocStatus? acceptExtensionUsecaseStatus,
    RejectExtensionUsecaseModel? rejectExtensionUsecase,
    BlocStatus? rejectExtensionUsecaseStatus,
    UpdateAvailabilityUsecaseModel? availabilityUsecase,
    BlocStatus? availabilityUsecaseStatus,
    RejectOrderUsecaseModel? rejectOrderUsecase,
    BlocStatus? rejectOrderUsecaseStatus,
    int? selectedIndex,
    int? currentStep,
    ArriveModel? arrive,
    BlocStatus? arriveStatus,
  }) =>
      OrdersState(
        startWork: startWork ?? this.startWork,
        startWorkStatus: startWorkStatus ?? this.startWorkStatus,
        securityCode: securityCode ?? this.securityCode,
        securityCodeStatus: securityCodeStatus ?? this.securityCodeStatus,
        errorMessage: errorMessage ?? this.errorMessage,
        ordersUsecase: ordersUsecase ?? this.ordersUsecase,
        orderDetailsUsecase: orderDetailsUsecase ?? this.orderDetailsUsecase,
        orderDetailsUsecaseStatus:
            orderDetailsUsecaseStatus ?? this.orderDetailsUsecaseStatus,
        acceptOrderUsecase: acceptOrderUsecase ?? this.acceptOrderUsecase,
        acceptOrderUsecaseStatus:
            acceptOrderUsecaseStatus ?? this.acceptOrderUsecaseStatus,
        startTravelUsecase: startTravelUsecase ?? this.startTravelUsecase,
        startTravelUsecaseStatus:
            startTravelUsecaseStatus ?? this.startTravelUsecaseStatus,
        completeOrderUsecase:
            completeOrderUsecase ?? this.completeOrderUsecase,
        completeOrderUsecaseStatus:
            completeOrderUsecaseStatus ?? this.completeOrderUsecaseStatus,
        cancelOrder: cancelOrder ?? this.cancelOrder,
        cancelOrderStatus: cancelOrderStatus ?? this.cancelOrderStatus,
        extensionRequestsUsecas:
            extensionRequestsUsecas ?? this.extensionRequestsUsecas,
        acceptExtensionUsecase:
            acceptExtensionUsecase ?? this.acceptExtensionUsecase,
        acceptExtensionUsecaseStatus:
            acceptExtensionUsecaseStatus ?? this.acceptExtensionUsecaseStatus,
        rejectExtensionUsecase:
            rejectExtensionUsecase ?? this.rejectExtensionUsecase,
        rejectExtensionUsecaseStatus:
            rejectExtensionUsecaseStatus ?? this.rejectExtensionUsecaseStatus,
        availabilityUsecase: availabilityUsecase ?? this.availabilityUsecase,
        availabilityUsecaseStatus:
            availabilityUsecaseStatus ?? this.availabilityUsecaseStatus,
        rejectOrderUsecase: rejectOrderUsecase ?? this.rejectOrderUsecase,
        rejectOrderUsecaseStatus:
            rejectOrderUsecaseStatus ?? this.rejectOrderUsecaseStatus,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        arrive: arrive ?? this.arrive,
        arriveStatus: arriveStatus ?? this.arriveStatus,
        currentStep: currentStep ?? this.currentStep,
      );
}
