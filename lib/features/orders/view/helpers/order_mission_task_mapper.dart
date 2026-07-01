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
      items.add(MissionTaskItem(label: name));
    }

    for (final addon in addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(MissionTaskItem(label: name));
    }

    if (items.isNotEmpty) return items;

    if (EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      final task = order.propertyDetails?.customService?.trim();
      if (task == null || task.isEmpty) return const <MissionTaskItem>[];
      return <MissionTaskItem>[MissionTaskItem(label: task)];
    }

    return const <MissionTaskItem>[];
  }

  static String keyFor(MissionTaskItem task, int index) => '${task.label}-$index';
}
