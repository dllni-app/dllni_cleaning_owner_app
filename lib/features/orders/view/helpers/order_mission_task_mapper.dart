import '../../data/models/arrive_model.dart';
import '../../data/models/cleaning_team_models.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'cleaning_enum_translations.dart';
import 'cleaning_room_display.dart';
import 'event_assistance_order_helper.dart';

class MissionTaskItem {
  const MissionTaskItem({required this.label, this.detail});

  final String label;
  final String? detail;
}

class OrderMissionTaskMapper {
  const OrderMissionTaskMapper._();

  static const List<String> _roomTypeOrder = <String>[
    'balcony',
    'bedroom',
    'kitchen',
    'bathroom',
    'corridor',
    'living_room',
    'hall',
  ];

  static const List<String> _sizeOrder = <String>['large', 'medium', 'small'];

  static List<MissionTaskItem> build({
    required FetchOrdersUsecaseModelDataItem order,
  }) {
    if (EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      return const <MissionTaskItem>[];
    }

    final rooms = _resolveRooms(order);
    if (rooms.isNotEmpty) {
      return _tasksFromRoomAssignments(rooms);
    }

    final breakdown = order.propertyDetails?.roomSizeBreakdown;
    if (breakdown != null && _hasAnyBreakdownCounts(breakdown)) {
      return _tasksFromBreakdown(
        breakdown,
        propertyDetails: order.propertyDetails,
      );
    }

    return const <MissionTaskItem>[];
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

  static List<CleaningRoomAssignmentModel> _resolveRooms(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    final assigned = order.myAssignedRooms;
    if (assigned.isNotEmpty) return assigned;
    return order.roomAssignments ?? const <CleaningRoomAssignmentModel>[];
  }

  static List<MissionTaskItem> _tasksFromRoomAssignments(
    List<CleaningRoomAssignmentModel> rooms,
  ) {
    return rooms
        .asMap()
        .entries
        .map((entry) => _taskFromRoomAssignment(entry.value, entry.key))
        .toList(growable: false);
  }

  static MissionTaskItem _taskFromRoomAssignment(
    CleaningRoomAssignmentModel room,
    int index,
  ) {
    final displayLabel = room.displayLabel?.trim();

    if (displayLabel != null &&
        displayLabel.isNotEmpty &&
        CleaningEnumTranslations.isArabicLabel(displayLabel)) {
      return MissionTaskItem(label: displayLabel);
    }

    final type = CleaningEnumTranslations.preferArabicLabel(
      room.roomTypeLabel,
      room.roomType,
      CleaningEnumTranslations.roomType,
      fallback: 'غرفة',
    );
    final size = CleaningEnumTranslations.preferArabicLabel(
      room.roomSizeLabel,
      room.roomSize,
      CleaningEnumTranslations.roomSize,
      fallback: '',
    );

    final ordinal = extractRoomNumber(room.roomKey) ??
        extractRoomNumber(displayLabel) ??
        index + 1;

    final hasSize = size.isNotEmpty && size != 'غير محدد';

    return MissionTaskItem(
      label: '$type $ordinal',
      detail: hasSize ? size : null,
    );
  }

  static List<MissionTaskItem> _tasksFromBreakdown(
    PropertyRoomSizeBreakdown breakdown, {
    PropertyDetailsData? propertyDetails,
  }) {
    final items = <MissionTaskItem>[];

    for (final roomType in _roomTypeOrder) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts == null) continue;

      final typeLabel = CleaningEnumTranslations.roomType(roomType);
      var ordinal = 1;

      for (final size in _sizeOrder) {
        final count = counts.countFor(size);
        if (count <= 0) continue;

        final sizeLabel = CleaningEnumTranslations.roomSize(size);
        for (var i = 0; i < count; i++) {
          items.add(
            MissionTaskItem(
              label: '$typeLabel $ordinal',
              detail: sizeLabel,
            ),
          );
          ordinal++;
        }
      }
    }

    if (breakdown.livingRoom == null || breakdown.livingRoom!.total <= 0) {
      final livingRoomTask = _livingRoomTaskFromLegacy(propertyDetails);
      if (livingRoomTask != null) items.add(livingRoomTask);
    }

    return items;
  }

  static MissionTaskItem? _livingRoomTaskFromLegacy(
    PropertyDetailsData? propertyDetails,
  ) {
    if (propertyDetails == null) return null;

    final sizeLabel = CleaningEnumTranslations.preferArabicLabel(
      propertyDetails.livingRoomSizeLabel,
      propertyDetails.livingRoomSize,
      CleaningEnumTranslations.livingRoomSize,
      fallback: '',
    );
    if (sizeLabel.isEmpty ||
        sizeLabel == 'غير محدد' ||
        sizeLabel == 'لا يوجد') {
      return null;
    }

    return MissionTaskItem(
      label: '${CleaningEnumTranslations.roomType('living_room')} 1',
      detail: sizeLabel,
    );
  }

  static bool _hasAnyBreakdownCounts(PropertyRoomSizeBreakdown breakdown) {
    for (final roomType in _roomTypeOrder) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts != null && counts.total > 0) return true;
    }
    return false;
  }
}
