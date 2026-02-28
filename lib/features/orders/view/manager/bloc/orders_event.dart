part of 'orders_bloc.dart';

abstract class OrdersEvent {}

class FetchOrdersUsecaseEvent extends OrdersEvent with EventWithReload {
  final FetchOrdersUsecaseParams params;

  @override
  final bool isReload;

  FetchOrdersUsecaseEvent({required this.params, this.isReload = false});
}

class FetchOrderDetailsUsecaseEvent extends OrdersEvent {
  final FetchOrderDetailsUsecaseParams params;

  FetchOrderDetailsUsecaseEvent({required this.params});
}

class AcceptOrderUsecaseEvent extends OrdersEvent {
  final AcceptOrderUsecaseParams params;

  AcceptOrderUsecaseEvent({required this.params});
}

class StartTravelUsecaseEvent extends OrdersEvent {
  final StartTravelUsecaseParams params;

  StartTravelUsecaseEvent({required this.params});
}

class CompleteOrderUsecaseEvent extends OrdersEvent {
  final CompleteOrderUsecaseParams params;

  CompleteOrderUsecaseEvent({required this.params});
}

class CancelOrderEvent extends OrdersEvent {
  final CancelOrderParams params;

  CancelOrderEvent({required this.params});
}

class FetchExtensionRequestsUsecasEvent extends OrdersEvent with EventWithReload {
  final FetchExtensionRequestsUsecasParams params;

  @override
  final bool isReload;

  FetchExtensionRequestsUsecasEvent({required this.params, this.isReload = false});
}

class AcceptExtensionUsecaseEvent extends OrdersEvent {
  final AcceptExtensionUsecaseParams params;

  AcceptExtensionUsecaseEvent({required this.params});
}

class RejectExtensionUsecaseEvent extends OrdersEvent {
  final RejectExtensionUsecaseParams params;

  RejectExtensionUsecaseEvent({required this.params});
}

class UpdateAvailabilityUsecaseEvent extends OrdersEvent {
  final UpdateAvailabilityUsecaseParams params;

  UpdateAvailabilityUsecaseEvent({required this.params});
}

class RejectOrderUsecaseEvent extends OrdersEvent {
  final RejectOrderUsecaseParams params;

  RejectOrderUsecaseEvent({required this.params});
}
