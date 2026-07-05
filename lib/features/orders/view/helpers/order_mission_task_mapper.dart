import '../../data/models/arrive_model.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

class MissionTaskItem {
  const MissionTaskItem({required this.label, this.detail});

  final String label;
  final String? detail;
}

class OrderMissionTaskMapper {
  const OrderMissionTaskMapper._();

  static List<MissionTaskItem> build({
    required FetchOrdersUsecaseModelDataItem order,
  }) {
    final items = <MissionTaskItem>[];
    final propertyDetails = order.propertyDetails;

    _addCountTask(items, 'غرف النوم', propertyDetails?.bedRooms);
    _addCountTask(items, 'الحمامات', propertyDetails?.bathrooms);
    _addCountTask(
      items,
      'المطابخ',
      propertyDetails?.kitchens ?? order.numberOfKitchens,
    );
    _addCountTask(
      items,
      'الشرفات',
      propertyDetails?.balconies ?? order.numberOfBalconies,
    );

    return items;
  }

  static List<MissionTaskItem> buildServicesInfo({
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
          detail: (service.quantity ?? 0) > 1 ? 'x${service.quantity}' : null,
        ),
      );
    }

    for (final addon in addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        MissionTaskItem(
          label: name,
          detail: (addon.quantity ?? 0) > 1 ? 'x${addon.quantity}' : null,
        ),
      );
    }

    return items;
  }

  static String keyFor(MissionTaskItem task, int index) => '${task.label}-$index';

  static void _addCountTask(List<MissionTaskItem> items, String label, int? count) {
    if (count == null || count <= 0) return;
    items.add(MissionTaskItem(label: label, detail: count.toString()));
  }
}
