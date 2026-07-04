import '../../data/models/arrive_model.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'event_assistance_order_helper.dart';

enum MissionTaskType { service, room, custom }

class MissionTaskItem {
  const MissionTaskItem({
    required this.label,
    this.detail,
    this.type = MissionTaskType.custom,
    this.id,
    this.roomKey,
    this.roomType,
  });

  final String label;
  final String? detail;
  final MissionTaskType type;
  final int? id;
  final String? roomKey;
  final String? roomType;

  Map<String, Object?> toCompletionPayload() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'label': label,
      if (type == MissionTaskType.service) 'name': label,
      if (detail != null && detail!.trim().isNotEmpty) 'detail': detail,
      if (roomKey != null && roomKey!.trim().isNotEmpty) 'roomKey': roomKey,
      if (roomType != null && roomType!.trim().isNotEmpty) 'roomType': roomType,
      if (type == MissionTaskType.room) 'displayLabel': label,
    };
  }
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

    var hasExplicitTasks = false;

    for (final service in services) {
      final name = service.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(MissionTaskItem(label: name, id: service.id, type: MissionTaskType.service));
      hasExplicitTasks = true;
    }

    for (final addon in addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(MissionTaskItem(label: name, id: addon.id, type: MissionTaskType.service));
      hasExplicitTasks = true;
    }

    if (!hasExplicitTasks && EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      final task = order.propertyDetails?.customService?.trim();
      if (task != null && task.isNotEmpty) {
        items.add(MissionTaskItem(label: task, type: MissionTaskType.service));
        hasExplicitTasks = true;
      }
    }

    final roomAssignments = order.roomAssignments ?? const <CleaningRoomAssignmentModel>[];
    if (roomAssignments.isNotEmpty) {
      for (final room in roomAssignments) {
        final label = room.displayLabel?.trim().isNotEmpty == true
            ? room.displayLabel!.trim()
            : (room.roomTypeLabel?.trim().isNotEmpty == true ? room.roomTypeLabel!.trim() : room.roomType?.trim());
        if (label == null || label.isEmpty) continue;
        items.add(MissionTaskItem(
          label: label,
          id: room.id,
          roomKey: room.roomKey,
          roomType: room.roomType,
          type: MissionTaskType.room,
        ));
      }
      return items;
    }

    if (hasExplicitTasks) return items;

    _addCountTask(items, 'غرف النوم', propertyDetails?.bedRooms, 'bedroom');
    _addCountTask(items, 'الحمامات', propertyDetails?.bathrooms, 'bathroom');
    _addCountTask(items, 'المطابخ', propertyDetails?.kitchens ?? order.numberOfKitchens, 'kitchen');
    _addCountTask(items, 'الشرفات', propertyDetails?.balconies ?? order.numberOfBalconies, 'balcony');

    return items;
  }

  static String keyFor(MissionTaskItem task, int index) => '${task.type.name}-${task.id ?? task.label}-$index';

  static void _addCountTask(List<MissionTaskItem> items, String label, int? count, String roomType) {
    if (count == null || count <= 0) return;
    items.add(MissionTaskItem(label: label, detail: count.toString(), roomType: roomType, type: MissionTaskType.room));
  }
}
