import '../../data/models/arrive_model.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'event_assistance_order_helper.dart';

class MissionTaskItem {
  const MissionTaskItem({required this.label, this.detail});

  final String label;
  final String? detail;
}

class OrderMissionTaskMapper {
  const OrderMissionTaskMapper._();

  static List<MissionTaskItem> build({
    required FetchOrdersUsecaseModelDataItem order,
    required List<Service> services,
    required List<Addon> addons,
  }) {
    final items = <MissionTaskItem>[];

    for (final service in services) {
      final name = service.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        MissionTaskItem(
          label: name,
          detail: service.quantity == null ? null : 'x ${service.quantity}',
        ),
      );
    }

    for (final addon in addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        MissionTaskItem(
          label: name,
          detail: addon.quantity == null ? null : 'x ${addon.quantity}',
        ),
      );
    }

    if (items.isNotEmpty) return items;

    if (EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      final task = order.propertyDetails?.customService?.trim();
      if (task == null || task.isEmpty) return const <MissionTaskItem>[];

      final hours = EventAssistanceOrderHelper.resolveBookedHours(
        propertyHours: order.propertyDetails?.hours,
        totalHours: order.totalHours,
        estimatedHours: order.estimatedHours,
      );

      return <MissionTaskItem>[
        MissionTaskItem(
          label: task,
          detail: hours == null
              ? null
              : EventAssistanceOrderHelper.formatHoursDetail(hours),
        ),
      ];
    }

    return const <MissionTaskItem>[
      MissionTaskItem(label: 'تنظيف غرفة النوم', detail: 'x 2'),
      MissionTaskItem(label: 'تنظيف الحمامات', detail: 'x 2'),
      MissionTaskItem(label: 'تنظيف المطبخ'),
    ];
  }

  static String keyFor(MissionTaskItem task, int index) => '${task.label}-$index';
}
