import '../../data/models/fetch_orders_usecase_model.dart';
import 'event_assistance_order_helper.dart';

/// Presentation-only classification of fields already returned by the orders API.
/// This never grants actions or infers supervised capabilities.
class WorkerOrderVisualIdentity {
  const WorkerOrderVisualIdentity({
    required this.title,
    required this.family,
    required this.isSupervised,
    required this.isSameDayRequest,
  });

  final String title;
  final String family;
  final bool isSupervised;
  final bool isSameDayRequest;

  factory WorkerOrderVisualIdentity.fromOrder(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    final isSupervised =
        order.bookingKind?.trim().toLowerCase() == 'supervised_team';
    final isEvent = EventAssistanceOrderHelper.isEventAssistance(
      order.propertyType,
    );
    final family = order.isHourlyWorker
        ? 'عامل بالساعة'
        : isEvent
        ? 'مساعدة مناسبات'
        : 'تنظيف';
    return WorkerOrderVisualIdentity(
      title: order.isHourlyWorker
          ? 'عامل بالساعة'
          : EventAssistanceOrderHelper.serviceTitle(
              propertyType: order.propertyType,
              customService: order.propertyDetails?.customService,
            ),
      family: family,
      isSupervised: isSupervised,
      // Existing "طلب ساخن" convention: booked on the same calendar day.
      // It is not an independently verified priority flag from the server.
      isSameDayRequest: _sameCalendarDay(order.createdAt, order.scheduledDate),
    );
  }

  static bool _sameCalendarDay(String? first, String? second) {
    if (first == null || second == null) return false;
    final a = DateTime.tryParse(first);
    final b = DateTime.tryParse(second);
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
