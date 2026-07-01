import '../../data/models/arrive_model.dart';
import '../../data/models/fetch_order_details_usecase_model.dart';

class OrderLifecycleSnapshot {
  const OrderLifecycleSnapshot({
    this.status,
    this.startedTravelAt,
    this.arrivedAt,
  });

  final String? status;
  final String? startedTravelAt;
  final String? arrivedAt;
}

class OrderLifecycleSnapshotHelper {
  const OrderLifecycleSnapshotHelper._();

  static const empty = OrderLifecycleSnapshot();

  static OrderLifecycleSnapshot resolve({
    required int bookingId,
    ArriveModel? arrive,
    FetchOrderDetailsUsecaseModel? orderDetails,
  }) {
    final arriveData = arrive?.data;
    if (arriveData?.id == bookingId) {
      return OrderLifecycleSnapshot(
        status: arriveData?.status,
        startedTravelAt: arriveData?.startedTravelAt,
        arrivedAt: arriveData?.arrivedAt,
      );
    }

    final detailsData = orderDetails?.data;
    if (detailsData?.id == bookingId) {
      return OrderLifecycleSnapshot(
        status: detailsData?.status,
        startedTravelAt: detailsData?.startedTravelAt,
        arrivedAt: detailsData?.arrivedAt,
      );
    }

    return empty;
  }
}
