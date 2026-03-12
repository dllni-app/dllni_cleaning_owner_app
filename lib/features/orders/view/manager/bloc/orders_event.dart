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

  final int index;

  AcceptOrderUsecaseEvent({required this.params, required this.index});
}

class StartTravelUsecaseEvent extends OrdersEvent {
  final StartTravelUsecaseParams params;

  final int index;

  StartTravelUsecaseEvent({required this.params, required this.index});
}

class CompleteOrderUsecaseEvent extends OrdersEvent {
  final CompleteOrderUsecaseParams params;

  CompleteOrderUsecaseEvent({required this.params});
}

class CancelOrderEvent extends OrdersEvent {
  final CancelOrderParams params;

  final int index;

  CancelOrderEvent({required this.params, required this.index});
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

  final int index;

  RejectOrderUsecaseEvent({required this.params, required this.index});
}

class ArriveEvent extends OrdersEvent {
  final ArriveParams params;
  final int index;

  ArriveEvent({required this.params, required this.index});
}

class ChangeDetailsCurrentStep extends OrdersEvent {
  final int step;

  ChangeDetailsCurrentStep({required this.step});
}
