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
    final propertyDetails = order.propertyDetails;
    final cleaningModeLabel = _cleaningModeLabel(propertyDetails);

    // if (cleaningModeLabel != null) {
    //   items.add(MissionTaskItem(label: 'نوع التنظيف', detail: cleaningModeLabel));
    // }

    var hasExplicitTasks = false;

    for (final service in services) {
      final name = service.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(MissionTaskItem(label: name));
      hasExplicitTasks = true;
    }

    for (final addon in addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(MissionTaskItem(label: name));
      hasExplicitTasks = true;
    }

    if (hasExplicitTasks) return items;

    if (EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      final task = order.propertyDetails?.customService?.trim();
      if (task == null || task.isEmpty) return items;
      return <MissionTaskItem>[...items, MissionTaskItem(label: task)];
    }
    //
    // _addCountTask(items, 'عدد الغرف', propertyDetails?.rooms ?? order.numberOfRooms);
    _addCountTask(items, 'غرف النوم', propertyDetails?.bedRooms);
    _addCountTask(items, 'الحمامات', propertyDetails?.bathrooms);
    _addCountTask(items, 'المطابخ', propertyDetails?.kitchens ?? order.numberOfKitchens);
    _addCountTask(items, 'الشرفات', propertyDetails?.balconies ?? order.numberOfBalconies);

    // final livingRoomSize = _clean(propertyDetails?.livingRoomSizeLabel) ??
    //     _roomSizeLabel(propertyDetails?.livingRoomSize);
    // if (livingRoomSize != null) {
    //   items.add(MissionTaskItem(label: 'حجم الصالة', detail: livingRoomSize));
    // }

    return items;
  }

  static String keyFor(MissionTaskItem task, int index) => '${task.label}-$index';

  static void _addCountTask(List<MissionTaskItem> items, String label, int? count) {
    if (count == null || count <= 0) return;
    items.add(MissionTaskItem(label: label, detail: count.toString()));
  }

  static String? _clean(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String? _cleaningModeLabel(PropertyDetailsData? propertyDetails) {
    final explicitLabel = _clean(propertyDetails?.cleaningModeLabel);
    if (explicitLabel != null) return explicitLabel;

    switch (_clean(propertyDetails?.cleaningMode)?.toLowerCase()) {
      case 'regular':
        return 'تنظيف عادي';
      case 'deep':
        return 'تنظيف عميق';
      default:
        return null;
    }
  }

  static String? _roomSizeLabel(String? size) {
    switch (_clean(size)?.toLowerCase()) {
      case 'small':
        return 'صغير';
      case 'medium':
        return 'متوسط';
      case 'large':
        return 'كبير';
      case 'very_large':
        return 'كبير جداً';
      default:
        return null;
    }
  }
}
